import Foundation

struct SupabaseAuthClient {
    let supabaseURL: URL
    let anonKey: String
    
    enum ClientError: LocalizedError {
        case missingConfig(String)
        case invalidResponse
        case httpStatus(Int, String)
        case missingSession
        
        var errorDescription: String? {
            switch self {
            case let .missingConfig(name):
                "\(name) is not configured. Please contact support."
            case .invalidResponse:
                "We received an invalid server response. Please try again."
            case let .httpStatus(code, message):
                if message.isEmpty {
                    "Request failed (\(code)). Please try again."
                } else {
                    "Request failed: \(message)"
                }
            case .missingSession:
                "We couldn’t create a session. Please sign in again."
            }
        }
    }
    
    struct AuthUser: Decodable {
        let id: String
        let email: String?
    }
    
    struct AuthResponse: Decodable {
        struct SessionPayload: Decodable {
            let access_token: String?
            let refresh_token: String?
            let expires_in: TimeInterval?
        }
        
        let access_token: String?
        let refresh_token: String?
        let expires_in: TimeInterval?
        let user: AuthUser?
        let session: SessionPayload?
        
        var resolvedAccessToken: String? {
            access_token ?? session?.access_token
        }
        
        var resolvedRefreshToken: String? {
            refresh_token ?? session?.refresh_token
        }
        
        var resolvedExpiresIn: TimeInterval? {
            expires_in ?? session?.expires_in
        }
    }
    
    func signInWithPassword(email: String, password: String) async throws -> AuthResponse {
        struct Body: Encodable {
            let email: String
            let password: String
        }
        
        return try await post(
            path: "/auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            body: Body(email: email, password: password),
            response: AuthResponse.self
        )
    }
    
    func signUp(email: String, password: String) async throws -> AuthResponse {
        struct Body: Encodable {
            let email: String
            let password: String
        }
        
        return try await post(
            path: "/auth/v1/signup",
            body: Body(email: email, password: password),
            response: AuthResponse.self
        )
    }
    
    func verifySignUp(email: String, token: String) async throws -> AuthResponse {
        struct Body: Encodable {
            let type: String
            let token: String
            let email: String
        }
        
        return try await post(
            path: "/auth/v1/verify",
            body: Body(type: "signup", token: token, email: email),
            response: AuthResponse.self
        )
    }
    
    func refreshSession(refreshToken: String) async throws -> AuthResponse {
        struct Body: Encodable {
            let refresh_token: String
        }
        
        return try await post(
            path: "/auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: Body(refresh_token: refreshToken),
            response: AuthResponse.self
        )
    }
    
    func signOut(accessToken: String) async throws {
        struct Empty: Encodable {}
        _ = try await post(
            path: "/auth/v1/logout",
            bearerToken: accessToken,
            body: Empty(),
            response: EmptyResponse.self
        )
    }
    
    private struct EmptyResponse: Decodable {}
    
    private struct ErrorResponse: Decodable {
        let error: String?
        let error_description: String?
        let message: String?
        let msg: String?
    }
    
    private func post<Body: Encodable, Response: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        bearerToken: String? = nil,
        body: Body,
        response: Response.Type
    ) async throws -> Response {
        var request = try makeRequest(path: path, queryItems: queryItems, bearerToken: bearerToken)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, rawResponse) = try await URLSession.shared.data(for: request)
        guard let http = rawResponse as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        
        guard (200...299).contains(http.statusCode) else {
            let message = decodeErrorMessage(from: data) ?? (String(data: data, encoding: .utf8) ?? "")
            throw ClientError.httpStatus(http.statusCode, message)
        }
        
        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }
        
        return try JSONDecoder().decode(Response.self, from: data)
    }
    
    private func makeRequest(path: String, queryItems: [URLQueryItem], bearerToken: String?) throws -> URLRequest {
        let trimmedKey = anonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw ClientError.missingConfig("SUPABASE_ANON_KEY")
        }
        if trimmedKey.split(separator: ".").count != 3 {
            throw ClientError.missingConfig("SUPABASE_ANON_KEY (must be the anon/public JWT from Supabase Settings → API)")
        }
        
        let base = supabaseURL.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty else {
            throw ClientError.missingConfig("SUPABASE_URL")
        }
        
        var components = URLComponents(url: supabaseURL, resolvingAgainstBaseURL: false)
        let basePath = components?.path ?? ""
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        components?.path = basePath.appending(normalizedPath)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components?.url else {
            throw ClientError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.setValue(trimmedKey, forHTTPHeaderField: "apikey")
        if let bearerToken, !bearerToken.isEmpty {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
    
    private func decodeErrorMessage(from data: Data) -> String? {
        guard let parsed = try? JSONDecoder().decode(ErrorResponse.self, from: data) else { return nil }
        return parsed.error_description ?? parsed.message ?? parsed.msg ?? parsed.error
    }
}
