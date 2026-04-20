//
//  EulaApp.swift
//  Eula
//
//  Created by Zhan Si on 2026/1/6.
//

import SwiftUI
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Debug: 打印动态生成的API路径
        print("🔍 [Debug] h5PaymentAuthURL: \(AppConfig.h5PaymentAuthURL?.absoluteString ?? "nil")")
        print("🔍 [Debug] h5PaymentVerifyURL: \(AppConfig.h5PaymentVerifyURL?.absoluteString ?? "nil")")
        print("🔍 [Debug] apnsDeviceTokenURL: \(AppConfig.apnsDeviceTokenURL?.absoluteString ?? "nil")")

        Task {
            await PushNotificationService.shared.prepareForLaunch()
        }
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task {
            await PushNotificationService.shared.handleDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        PushNotificationService.shared.handleRegistrationFailure(error)
    }
}

@main
struct EulaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
