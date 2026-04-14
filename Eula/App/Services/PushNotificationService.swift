import Foundation
import UIKit
import UserNotifications

@MainActor
final class PushNotificationService {
    static let shared = PushNotificationService()

    private let session = URLSession.shared
    private let tokenStorageService = "com.eula.push"
    private let currentTokenAccount = "current_device_token"
    private let uploadedTokenAccount = "uploaded_device_token"

    func prepareForLaunch() async {
        await retryPendingUploadIfNeeded()

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            registerForRemoteNotifications()
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                guard granted else {
                    log("notification permission was declined")
                    return
                }
                registerForRemoteNotifications()
            } catch {
                log("notification authorization request failed: \(error.localizedDescription)")
            }
        case .denied:
            log("notification permission is denied")
        @unknown default:
            log("notification authorization status is unknown")
        }
    }

    func handleDeviceToken(_ deviceToken: Data) async {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        guard !token.isEmpty else {
            log("received an empty APNs token")
            return
        }

        _ = KeychainHelper.saveString(token, service: tokenStorageService, account: currentTokenAccount)
        log("received APNs token: \(token)")

        let uploadedToken = KeychainHelper.loadString(service: tokenStorageService, account: uploadedTokenAccount)
        guard uploadedToken != token else {
            log("APNs token is unchanged, skip upload")
            return
        }

        await uploadDeviceTokenIfNeeded(token)
    }

    func handleRegistrationFailure(_ error: Error) {
        log("failed to register for remote notifications: \(error.localizedDescription)")
    }

    private func retryPendingUploadIfNeeded() async {
        guard let currentToken = KeychainHelper.loadString(service: tokenStorageService, account: currentTokenAccount),
              !currentToken.isEmpty
        else {
            return
        }

        let uploadedToken = KeychainHelper.loadString(service: tokenStorageService, account: uploadedTokenAccount)
        guard uploadedToken != currentToken else {
            return
        }

        log("retry pending APNs token upload")
        await uploadDeviceTokenIfNeeded(currentToken)
    }

    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
        log("requested remote notification registration")
    }

    private func uploadDeviceTokenIfNeeded(_ token: String) async {
        guard let url = AppConfig.apnsDeviceTokenURL else {
            log("skip APNs token upload because endpoint is unavailable")
            return
        }

        let payload = APNSDeviceTokenRequest(
            deviceNo: DeviceIdentity.deviceID(),
            deviceToken: token
        )

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody = try JSONEncoder().encode(payload)

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                log("APNs token upload failed because response is not HTTP")
                return
            }

            let responseBody = String(data: data, encoding: .utf8) ?? "<binary>"
            log("APNs token upload response status=\(httpResponse.statusCode), body=\(responseBody)")

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                return
            }

            do {
                let apiResponse = try JSONDecoder().decode(APNSDeviceTokenResponse.self, from: data)
                guard apiResponse.isSuccess else {
                    log("APNs token upload was rejected: \(apiResponse.resolvedMessage)")
                    return
                }

                _ = KeychainHelper.saveString(token, service: tokenStorageService, account: uploadedTokenAccount)
                log("APNs token upload succeeded")
            } catch {
                if let responseString = try? JSONDecoder().decode(String.self, from: data),
                   !responseString.isEmpty {
                    _ = KeychainHelper.saveString(token, service: tokenStorageService, account: uploadedTokenAccount)
                    log("APNs token upload succeeded (string response)")
                } else {
                    log("APNs token response decode failed: \(error.localizedDescription)")
                    log("APNs token response decode error: \(error)")
                    log("APNs token response raw data: \(responseBody)")
                }
            }
        } catch {
            log("APNs token upload failed: \(error.localizedDescription)")
        }
    }

    private func log(_ message: String) {
        StoreKitLogger.shared.log("[Push] \(message)")
        #if DEBUG
        print("[Push] \(message)")
        #endif
    }
}

private struct APNSDeviceTokenRequest: Encodable {
    let deviceNo: String
    let deviceToken: String
}

private struct APNSDeviceTokenResponse: Decodable {
    let code: Int?
    let msg: String?
    let message: String?
    let data: String?
    
    var isSuccess: Bool {
        code == 0 || code == 200
    }
    
    var resolvedMessage: String {
        if let message, !message.isEmpty {
            return message
        }
        if let msg, !msg.isEmpty {
            return msg
        }
        return "The APNs token upload failed."
    }
}
