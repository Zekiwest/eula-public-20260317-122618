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

}
