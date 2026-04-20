import Foundation

enum AppConfig {
    static var supabaseURL: URL {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            return URL(string: "http://invalid.local")!
        }
        guard let url = URL(string: raw), !raw.isEmpty else {
            return URL(string: "http://invalid.local")!
        }
        return url
    }

    static var supabaseAnonKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String) ?? ""
    }

    static var chatMessageCostCoins: Int {
        (Bundle.main.object(forInfoDictionaryKey: "CHAT_MESSAGE_COST_COINS") as? Int) ?? 30
    }

    static var trendTailorMessageCostCoins: Int {
        (Bundle.main.object(forInfoDictionaryKey: "TRENDTAILOR_MESSAGE_COST_COINS") as? Int) ?? 10
    }

    static var h5PaymentModeRawValue: String {
        ((Bundle.main.object(forInfoDictionaryKey: "H5_PAYMENT_MODE") as? String) ?? "disabled")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    static var h5PaymentCallPay: String {
        (Bundle.main.object(forInfoDictionaryKey: "H5_PAYMENT_CALL_PAY") as? String) ?? ""
    }

    static var h5PaymentBaseURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "H5_PAYMENT_BASE_URL") as? String else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        return URL(string: trimmed)
    }

    static var h5PaymentAuthURL: URL? {
        dynamicH5URL(basePath: "/H5Api/authH5", suffix: "a")
    }

    static var h5PaymentTestAuthURL: URL? {
        configuredH5URL(forInfoDictionaryKey: "H5_PAYMENT_TEST_AUTH_PATH", defaultPath: "/H5Api/authH5Test")
    }

    static var h5PaymentVerifyURL: URL? {
        dynamicH5URL(basePath: "/H5Api/submitSuccessOrder", suffix: "o")
    }

    static var apnsDeviceTokenURL: URL? {
        dynamicH5URL(basePath: "/apns/device/token", suffix: "t")
    }

    private static func dynamicH5URL(basePath: String, suffix: Character) -> URL? {
        guard let baseURL = h5PaymentBaseURL else {
            return nil
        }
        let randomSegment = generateRandomPathSegment(suffix: suffix)
        let fullPath = basePath + "/" + randomSegment
        return baseURL.appendingPathComponent(fullPath.hasPrefix("/") ? String(fullPath.dropFirst()) : fullPath)
    }

    private static func configuredH5URL(forInfoDictionaryKey key: String, defaultPath: String) -> URL? {
        let rawValue = (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? defaultPath
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        if let directURL = URL(string: trimmed), directURL.scheme != nil {
            return directURL
        }
        guard let baseURL = h5PaymentBaseURL else {
            return nil
        }
        let normalizedPath = trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
        return baseURL.appendingPathComponent(normalizedPath)
    }

    private static func generateRandomPathSegment(suffix: Character, minLength: Int = 8, maxLength: Int = 16) -> String {
        let length = Int.random(in: minLength...maxLength)
        let characters = "abcdefghijklmnopqrstuvwxyz0123456789"
        var result = ""
        for _ in 0..<length - 1 {
            result.append(characters.randomElement()!)
        }
        result.append(suffix)
        return result
    }

}
