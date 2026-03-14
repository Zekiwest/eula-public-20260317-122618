import Foundation
import Combine

struct UserInfo {
    let id: String
    let email: String?
    let name: String?
    let avatarUrl: String?
    
    static let maxNicknameLength = 20
    
    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        if let email = email, !email.isEmpty {
            return defaultNickname(from: email)
        }
        return "User"
    }
    
    var hasCustomAvatar: Bool {
        guard let url = avatarUrl, !url.isEmpty else { return false }
        return true
    }
    
    private func defaultNickname(from email: String) -> String {
        let prefix = email.components(separatedBy: "@").first ?? email
        if prefix.count <= UserInfo.maxNicknameLength {
            return prefix
        }
        let index = prefix.index(prefix.startIndex, offsetBy: UserInfo.maxNicknameLength)
        return String(prefix[..<index])
    }
}

final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published private(set) var isLoggedIn: Bool = false
    @Published private(set) var currentUser: UserInfo?
    @Published private(set) var isLoading: Bool = false
    
    private var session: AuthSession?
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    var currentUserId: String? {
        currentUser?.id ?? session?.userId
    }
    
    var accessToken: String? {
        session?.accessToken
    }
    
    func restoreSession() {
        if isLoading {
            return
        }
        isLoading = true
        
        if let savedSession = KeychainHelper.loadSession() {
            if savedSession.isExpired {
                Task {
                    await refreshSession(savedSession)
                }
            } else {
                session = savedSession
                currentUser = UserInfo(
                    id: savedSession.userId,
                    email: savedSession.email,
                    name: nil,
                    avatarUrl: nil
                )
                isLoggedIn = true
                isLoading = false
            }
        } else {
            isLoading = false
        }
    }
    
    func saveSession(accessToken: String, refreshToken: String?, userId: String, email: String?, expiresIn: TimeInterval? = nil) {
        let expiresAt = expiresIn.map { Date().addingTimeInterval($0) }
        
        let session = AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userId: userId,
            email: email,
            expiresAt: expiresAt
        )
        
        self.session = session
        currentUser = UserInfo(
            id: userId,
            email: email,
            name: nil,
            avatarUrl: nil
        )
        
        KeychainHelper.saveSession(session)
        isLoggedIn = true
        
        saveUserIdToDefaults(userId)
    }
    
    func clearSession() {
        session = nil
        currentUser = nil
        isLoggedIn = false
        KeychainHelper.clearSession()
        defaults.removeObject(forKey: "com.eula.currentUserId")
    }
    
    func signOut() {
        let accessToken = session?.accessToken
        clearSession()
        Task {
            guard let accessToken, !accessToken.isEmpty else { return }
            do {
                let client = SupabaseAuthClient(
                    supabaseURL: AppConfig.supabaseURL,
                    anonKey: AppConfig.supabaseAnonKey
                )
                try await client.signOut(accessToken: accessToken)
            } catch {
            }
        }
    }
    
    func updateUserInfo(name: String?, avatarUrl: String?) {
        if let current = currentUser {
            currentUser = UserInfo(
                id: current.id,
                email: current.email,
                name: name ?? current.name,
                avatarUrl: avatarUrl ?? current.avatarUrl
            )
        }
    }
    
    private func refreshSession(_ session: AuthSession) async {
        guard let refreshToken = session.refreshToken, !refreshToken.isEmpty else {
            await MainActor.run {
                clearSession()
                isLoading = false
            }
            return
        }
        
        do {
            let client = SupabaseAuthClient(
                supabaseURL: AppConfig.supabaseURL,
                anonKey: AppConfig.supabaseAnonKey
            )
            let response = try await client.refreshSession(refreshToken: refreshToken)
            guard let accessToken = response.resolvedAccessToken else {
                await MainActor.run {
                    clearSession()
                    isLoading = false
                }
                return
            }
            
            await MainActor.run {
                saveSession(
                    accessToken: accessToken,
                    refreshToken: response.resolvedRefreshToken ?? session.refreshToken,
                    userId: response.user?.id ?? session.userId,
                    email: response.user?.email ?? session.email,
                    expiresIn: response.resolvedExpiresIn
                )
                isLoading = false
            }
        } catch {
            await MainActor.run {
                clearSession()
                isLoading = false
            }
        }
    }
    
    private func saveUserIdToDefaults(_ userId: String) {
        defaults.set(userId, forKey: "com.eula.currentUserId")
    }
    
    func getLastUserId() -> String? {
        defaults.string(forKey: "com.eula.currentUserId")
    }
}
