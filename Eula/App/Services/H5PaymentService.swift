import CommonCrypto
import CoreTelephony
import CryptoKit
import Foundation
import StoreKit
import UIKit

enum H5PaymentError: LocalizedError {
    case authFailed(String)
    case verificationFailed(String)
    case invalidEntryURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .authFailed(let message):
            return message
        case .verificationFailed(let message):
            return message
        case .invalidEntryURL:
            return "The web recharge link is invalid."
        case .invalidResponse:
            return "The payment service returned an invalid response."
        }
    }
}

actor H5PaymentService {
    static let shared = H5PaymentService()

    private let session = URLSession.shared

    func fetchTopUpURL() async throws -> URL? {
        let mode = H5PaymentMode(rawValue: AppConfig.h5PaymentModeRawValue) ?? .disabled
        guard let endpoint = endpoint(for: mode) else {
            return nil
        }

        let response: H5PaymentResponse<String> = try await sendRequest(
            to: endpoint,
            body: buildAuthRequest()
        )

        guard response.code == 200, let rawURL = response.data?.trimmingCharacters(in: .whitespacesAndNewlines), !rawURL.isEmpty else {
            throw H5PaymentError.authFailed(response.resolvedMessage)
        }

        guard let url = URL(string: rawURL) else {
            throw H5PaymentError.invalidEntryURL
        }
        return url
    }

    func submitSuccessfulOrder(transactionID: String, receiptData: String?) async throws {
        let mode = H5PaymentMode(rawValue: AppConfig.h5PaymentModeRawValue) ?? .disabled
        guard mode != .disabled else {
            return
        }
        guard let endpoint = AppConfig.h5PaymentVerifyURL else {
            return
        }

        let request = buildVerifyRequest(transactionID: transactionID, receiptData: receiptData)
        let response: H5PaymentResponse<String> = try await sendRequest(to: endpoint, body: request)
        guard response.code == 200 else {
            throw H5PaymentError.verificationFailed(response.resolvedMessage)
        }
    }

    private func endpoint(for mode: H5PaymentMode) -> URL? {
        switch mode {
        case .disabled:
            return nil
        case .production:
            return AppConfig.h5PaymentAuthURL
        case .test:
            return AppConfig.h5PaymentTestAuthURL
        }
    }

    private func sendRequest<Response: Decodable, Body: Encodable>(
        to url: URL,
        body: Body
    ) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let encodedBody = try JSONEncoder().encode(body)
        request.httpBody = try encryptedBodyData(from: encodedBody)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw H5PaymentError.invalidResponse
        }
        let responseData = try decodedResponseData(from: data)
        guard (200 ... 299).contains(httpResponse.statusCode) else {
            if let apiResponse = try? JSONDecoder().decode(H5PaymentResponse<String>.self, from: responseData) {
                throw H5PaymentError.verificationFailed(apiResponse.resolvedMessage)
            }
            throw H5PaymentError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(Response.self, from: responseData)
        } catch {
            throw H5PaymentError.invalidResponse
        }
    }

    private func encryptedBodyData(from data: Data) throws -> Data {
        guard H5PaymentCryptoConfig.enableRequestEncryption else {
            return data
        }
        guard let jsonString = String(data: data, encoding: .utf8),
              let encryptedString = H5PaymentCrypto.encrypt(jsonString, secretKey: H5PaymentCryptoConfig.secretKey),
              let encryptedData = encryptedString.data(using: .utf8)
        else {
            throw H5PaymentError.invalidResponse
        }
        return encryptedData
    }

    private func decodedResponseData(from data: Data) throws -> Data {
        guard H5PaymentCryptoConfig.enableResponseDecryption,
              let responseString = String(data: data, encoding: .utf8),
              !responseString.isEmpty
        else {
            return data
        }

        var encryptedString = responseString
        if responseString.hasPrefix("\"") && responseString.hasSuffix("\""),
           let unwrapped = try? JSONDecoder().decode(String.self, from: data)
        {
            encryptedString = unwrapped
        }

        guard H5PaymentCrypto.isBase64(encryptedString),
              let decryptedString = H5PaymentCrypto.decrypt(encryptedString, secretKey: H5PaymentCryptoConfig.secretKey),
              let decryptedData = decryptedString.data(using: .utf8)
        else {
            return data
        }
        return decryptedData
    }

    private func buildAuthRequest() -> H5PaymentAuthRequest {
        let deviceInfo = H5PaymentDeviceInfo.capture()
        return H5PaymentAuthRequest(
            bundleId: Bundle.main.bundleIdentifier ?? "",
            deviceNo: DeviceIdentity.deviceID(),
            requestIp: deviceInfo.requestIP,
            card: deviceInfo.hasSimCard,
            cnInput: deviceInfo.hasChineseKeyboard,
            cnLanguage: deviceInfo.isChineseLanguage,
            userAgent: deviceInfo.userAgent,
            timezone: TimeZone.current.identifier,
            appVersion: appVersion(),
            callPay: AppConfig.h5PaymentCallPay.isEmpty ? nil : AppConfig.h5PaymentCallPay,
            autozone: deviceInfo.isAutomaticTimezone,
            lg: Locale.preferredLanguages.first,
            lgs: Locale.preferredLanguages,
            wifi: deviceInfo.isOnWiFi,
            charge: deviceInfo.isCharging,
            powerLevel: deviceInfo.batteryLevel
        )
    }

    private func buildVerifyRequest(transactionID: String, receiptData: String?) -> H5PaymentVerifyRequest {
        let deviceInfo = H5PaymentDeviceInfo.capture()
        return H5PaymentVerifyRequest(
            deviceNo: DeviceIdentity.deviceID(),
            appVersion: appVersion(),
            requestIp: deviceInfo.requestIP,
            bundleId: Bundle.main.bundleIdentifier ?? "",
            transactionId: transactionID,
            receiptData: receiptData,
            version: "v2"
        )
    }

    private func appVersion() -> String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0.0"
    }
}

private enum H5PaymentMode: String {
    case disabled
    case production
    case test
}

private enum H5PaymentCryptoConfig {
    static let enableRequestEncryption = true
    static let enableResponseDecryption = true
    static let secretKey = "MySecretKey2024!@#$%^&*()_+={}"
}

private enum H5PaymentCrypto {
    private static let ivSize = 16

    static func encrypt(_ plainText: String?, secretKey: String) -> String? {
        guard let plainText, !plainText.isEmpty else {
            return plainText
        }
        do {
            let keyBytes = keyBytes(for: secretKey)
            let ivBytes = Array(keyBytes.prefix(ivSize))
            guard let data = plainText.data(using: .utf8) else {
                return nil
            }
            let encrypted = try crypt(
                operation: CCOperation(kCCEncrypt),
                data: data,
                key: keyBytes,
                iv: ivBytes
            )
            return encrypted.base64EncodedString()
        } catch {
            return nil
        }
    }

    static func decrypt(_ cipherText: String?, secretKey: String) -> String? {
        guard let cipherText, !cipherText.isEmpty,
              let encrypted = Data(base64Encoded: cipherText)
        else {
            return cipherText
        }
        do {
            let keyBytes = keyBytes(for: secretKey)
            let ivBytes = Array(keyBytes.prefix(ivSize))
            let decrypted = try crypt(
                operation: CCOperation(kCCDecrypt),
                data: encrypted,
                key: keyBytes,
                iv: ivBytes
            )
            return String(data: decrypted, encoding: .utf8)
        } catch {
            return nil
        }
    }

    static func isBase64(_ string: String?) -> Bool {
        guard let string, !string.isEmpty else {
            return false
        }
        return Data(base64Encoded: string) != nil
    }

    private static func keyBytes(for secretKey: String) -> Data {
        let secretData = Data(secretKey.utf8)
        let digest = SHA256.hash(data: secretData)
        return Data(digest)
    }

    private static func crypt(
        operation: CCOperation,
        data: Data,
        key: Data,
        iv: [UInt8]
    ) throws -> Data {
        let keyBytes = [UInt8](key)
        let dataBytes = [UInt8](data)
        var outputBytes = [UInt8](repeating: 0, count: dataBytes.count + kCCBlockSizeAES128)
        var outputLength: size_t = 0

        let status = CCCrypt(
            operation,
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            keyBytes,
            key.count,
            iv,
            dataBytes,
            dataBytes.count,
            &outputBytes,
            outputBytes.count,
            &outputLength
        )

        guard status == kCCSuccess else {
            throw H5PaymentError.invalidResponse
        }
        return Data(bytes: outputBytes, count: outputLength)
    }
}

private struct H5PaymentResponse<T: Decodable>: Decodable {
    let code: Int
    let msg: String?
    let message: String?
    let data: T?

    var resolvedMessage: String {
        if let message, !message.isEmpty {
            return message
        }
        if let msg, !msg.isEmpty {
            return msg
        }
        return "The payment service request failed."
    }
}

private struct H5PaymentAuthRequest: Encodable {
    let bundleId: String
    let deviceNo: String
    let requestIp: String
    let card: Bool
    let cnInput: Bool
    let cnLanguage: Bool
    let userAgent: String
    let timezone: String
    let appVersion: String
    let callPay: String?
    let autozone: Bool
    let lg: String?
    let lgs: [String]
    let wifi: Bool
    let charge: Bool
    let powerLevel: Int
}

private struct H5PaymentVerifyRequest: Encodable {
    let deviceNo: String
    let appVersion: String
    let requestIp: String
    let bundleId: String
    let transactionId: String
    let receiptData: String?
    let version: String
}

private struct H5PaymentDeviceInfo {
    let requestIP: String
    let hasSimCard: Bool
    let hasChineseKeyboard: Bool
    let isChineseLanguage: Bool
    let userAgent: String
    let isAutomaticTimezone: Bool
    let isOnWiFi: Bool
    let isCharging: Bool
    let batteryLevel: Int

    static func capture() -> H5PaymentDeviceInfo {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let currentBatteryLevel = UIDevice.current.batteryLevel
        let batteryLevel = currentBatteryLevel < 0 ? 0 : Int((currentBatteryLevel * 100).rounded())
        let batteryState = UIDevice.current.batteryState
        let resolvedRequestIP = requestIP()

        return H5PaymentDeviceInfo(
            requestIP: resolvedRequestIP,
            hasSimCard: hasSimCard(),
            hasChineseKeyboard: hasChineseKeyboard(),
            isChineseLanguage: Locale.preferredLanguages.contains(where: { $0.hasPrefix("zh") }),
            userAgent: "\(UIDevice.current.systemName)/\(UIDevice.current.systemVersion) (\(UIDevice.current.model))",
            isAutomaticTimezone: TimeZone.current.identifier == NSTimeZone.system.identifier,
            isOnWiFi: !resolvedRequestIP.isEmpty,
            isCharging: batteryState == .charging || batteryState == .full,
            batteryLevel: batteryLevel
        )
    }

    private static func requestIP() -> String {
        var address = ""
        var interfacePointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfacePointer) == 0, let firstAddress = interfacePointer else {
            return address
        }

        defer { freeifaddrs(interfacePointer) }

        for pointer in sequence(first: firstAddress, next: { $0.pointee.ifa_next }) {
            let interface = pointer.pointee
            let addressFamily = interface.ifa_addr.pointee.sa_family
            guard addressFamily == UInt8(AF_INET) else {
                continue
            }

            let name = String(cString: interface.ifa_name)
            guard name == "en0" || name == "pdp_ip0" else {
                continue
            }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(
                interface.ifa_addr,
                socklen_t(interface.ifa_addr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                socklen_t(0),
                NI_NUMERICHOST
            )
            return String(cString: hostname)
        }
        return address
    }

    private static func hasSimCard() -> Bool {
        let networkInfo = CTTelephonyNetworkInfo()
        guard let carriers = networkInfo.serviceSubscriberCellularProviders else {
            return false
        }
        return !carriers.isEmpty
    }

    private static func hasChineseKeyboard() -> Bool {
        let keyboards = UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String] ?? []
        return keyboards.contains(where: { keyboard in
            keyboard.contains("zh") || keyboard.contains("Hans") || keyboard.contains("Hant") || keyboard.contains("Chinese")
        })
    }
}

extension AppStore {
    static func receiptBase64() -> String? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL)
        else {
            return nil
        }
        return receiptData.base64EncodedString()
    }
}
