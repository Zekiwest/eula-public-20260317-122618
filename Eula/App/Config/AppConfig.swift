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

    static var termsOfUseURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "TERMS_OF_USE_URL") as? String else {
            return nil
        }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            return nil
        }
        return URL(string: value)
    }

    static var privacyPolicyURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "PRIVACY_POLICY_URL") as? String else {
            return nil
        }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            return nil
        }
        return URL(string: value)
    }
}
