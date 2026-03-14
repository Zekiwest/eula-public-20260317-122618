import Foundation
import Security

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String?
    let userId: String
    let email: String?
    let expiresAt: Date?
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() >= expiresAt
    }
}

enum KeychainHelper {
    private static let authService = "com.eula.auth"
    private static let authAccount = "session"
    
    static func saveSession(_ session: AuthSession) -> Bool {
        guard let data = try? JSONEncoder().encode(session) else { return false }
        return writeKeychainData(data, service: authService, account: authAccount)
    }
    
    static func loadSession() -> AuthSession? {
        guard let data = readKeychainData(service: authService, account: authAccount) else { return nil }
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }
    
    static func clearSession() -> Bool {
        deleteKeychainItem(service: authService, account: authAccount)
    }
    
    static func saveGeneric<T: Codable>(_ value: T, service: String, account: String) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        return writeKeychainData(data, service: service, account: account)
    }
    
    static func loadGeneric<T: Codable>(_ type: T.Type, service: String, account: String) -> T? {
        guard let data = readKeychainData(service: service, account: account) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    static func saveString(_ value: String, service: String, account: String) -> Bool {
        writeKeychainString(value, service: service, account: account)
    }
    
    static func loadString(service: String, account: String) -> String? {
        readKeychainString(service: service, account: account)
    }
    
    static func delete(service: String, account: String) -> Bool {
        deleteKeychainItem(service: service, account: account)
    }
    
    private static func readKeychainData(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }
    
    private static func writeKeychainData(_ data: Data, service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess {
            return true
        }
        
        let add: [String: Any] = query.merging(attributes) { _, new in new }
        let addStatus = SecItemAdd(add as CFDictionary, nil)
        return addStatus == errSecSuccess
    }
    
    private static func readKeychainString(service: String, account: String) -> String? {
        guard let data = readKeychainData(service: service, account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    @discardableResult
    private static func writeKeychainString(_ value: String, service: String, account: String) -> Bool {
        let data = Data(value.utf8)
        return writeKeychainData(data, service: service, account: account)
    }
    
    @discardableResult
    private static func deleteKeychainItem(service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

enum DeviceIdentity {
    private static let service = "xcodegame.device"
    private static let account = "device_id"

    static func deviceID() -> String {
        if let existing = KeychainHelper.loadString(service: service, account: account), !existing.isEmpty {
            return existing
        }

        let newID = UUID().uuidString
        _ = KeychainHelper.saveString(newID, service: service, account: account)
        return newID
    }
}

