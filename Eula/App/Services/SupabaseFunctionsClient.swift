import Foundation

struct SupabaseFunctionsClient {
    let supabaseURL: URL
    let anonKey: String

    enum ClientError: LocalizedError {
        case missingConfig(String)
        case invalidResponse
        case httpStatus(Int, String)

        var errorDescription: String? {
            switch self {
            case let .missingConfig(name):
                "\(name) is not configured."
            case .invalidResponse:
                "Invalid response."
            case let .httpStatus(code, body):
                if body.isEmpty { "HTTP \(code)" } else { "HTTP \(code): \(body)" }
            }
        }
    }

    func call<Body: Encodable, Response: Decodable>(
        function name: String,
        body: Body,
        response: Response.Type = Response.self
    ) async throws -> Response {
        var request = try makeRequest(function: name, body: try JSONEncoder().encode(body))
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, rawResponse) = try await URLSession.shared.data(for: request)
        guard let http = rawResponse as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw ClientError.httpStatus(http.statusCode, bodyText)
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    func stream(
        function name: String,
        body: Data,
        accept: String = "text/event-stream"
    ) async throws -> URLSession.AsyncBytes {
        var request = try makeRequest(function: name, body: body)
        request.setValue(accept, forHTTPHeaderField: "Accept")
        let (bytes, rawResponse) = try await URLSession.shared.bytes(for: request)
        guard let http = rawResponse as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            var data = Data()
            for try await byte in bytes {
                data.append(byte)
            }
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw ClientError.httpStatus(http.statusCode, bodyText)
        }
        return bytes
    }

    private func makeRequest(function name: String, body: Data) throws -> URLRequest {
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

        let url = supabaseURL
            .appendingPathComponent("functions")
            .appendingPathComponent("v1")
            .appendingPathComponent(name)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(trimmedKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        return request
    }
}

struct SupabaseRESTClient {
    let supabaseURL: URL
    let anonKey: String

    func get<Response: Decodable>(
        table: String,
        queryItems: [URLQueryItem],
        bearerToken: String? = nil,
        response: Response.Type = Response.self
    ) async throws -> Response {
        var request = try makeRequest(table: table, queryItems: queryItems, bearerToken: bearerToken)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, rawResponse) = try await URLSession.shared.data(for: request)
        guard let http = rawResponse as? HTTPURLResponse else {
            throw SupabaseFunctionsClient.ClientError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseFunctionsClient.ClientError.httpStatus(http.statusCode, bodyText)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Response.self, from: data)
    }

    private func makeRequest(table: String, queryItems: [URLQueryItem], bearerToken: String?) throws -> URLRequest {
        let trimmedKey = anonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw SupabaseFunctionsClient.ClientError.missingConfig("SUPABASE_ANON_KEY")
        }
        if trimmedKey.split(separator: ".").count != 3 {
            throw SupabaseFunctionsClient.ClientError.missingConfig("SUPABASE_ANON_KEY (must be the anon/public JWT from Supabase Settings → API)")
        }
        let base = supabaseURL.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty else {
            throw SupabaseFunctionsClient.ClientError.missingConfig("SUPABASE_URL")
        }

        var components = URLComponents(url: supabaseURL, resolvingAgainstBaseURL: false)
        let path = components?.path ?? ""
        components?.path = path
            .appending("/")
            .appending("rest")
            .appending("/v1")
            .appending("/")
            .appending(table)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw SupabaseFunctionsClient.ClientError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(trimmedKey, forHTTPHeaderField: "apikey")
        if let bearerToken, !bearerToken.isEmpty {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}

enum AgreementKind: String {
    case userAgreement = "user_agreement"
    case privacyPolicy = "privacy_policy"

    var defaultTitle: String {
        switch self {
        case .userAgreement:
            "User Agreement"
        case .privacyPolicy:
            "Privacy Policy"
        }
    }

    var defaultContent: String {
        switch self {
        case .userAgreement:
            """
Welcome to Glame! To make a better place, the following content is not allowed in the app in particular.

1. Any content about child harm, pornography related detrimental to children.

2. Fake and harmful messages about recent or current events.

3. Any violence, bullying content, publicly promotes pornography and other content.

If we find any content including and not limited to the above violations your content will be deleted and account will be banned.
"""
        case .privacyPolicy:
            """
We respect your privacy. This Privacy Policy describes how we collect, use, and protect information when you use the app.

1. Information we collect
We may collect information you provide (such as profile details), content you create, and basic usage data to operate and improve the app.

2. How we use information
We use information to provide core features, maintain safety, personalize your experience, and improve product performance.

3. Sharing
We do not sell your personal information. We may share information with service providers to run the app, or when required by law.

4. Data retention
We keep information only as long as necessary for the purposes described, unless a longer retention period is required by law.

5. Your choices
You can manage certain settings in the app. You may also request deletion of your account where available.

6. Updates
We may update this policy from time to time. Continued use of the app means you accept the updated policy.
"""
        }
    }
}

struct AgreementDocument: Codable, Equatable {
    var title: String
    var content: String
    var updatedAt: Date?
}

struct AgreementsService {
    static let shared = AgreementsService()

    private let client = SupabaseRESTClient(
        supabaseURL: AppConfig.supabaseURL,
        anonKey: AppConfig.supabaseAnonKey
    )

    private let defaults = UserDefaults.standard

    func loadCached(kind: AgreementKind) -> AgreementDocument? {
        let key = cacheKey(for: kind)
        guard let data = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(AgreementDocument.self, from: data)
    }

    func fetchRemote(kind: AgreementKind) async throws -> AgreementDocument {
        struct Row: Decodable {
            let slug: String
            let title: String?
            let content: String?
            let updated_at: Date?
        }

        let rows: [Row] = try await client.get(
            table: "legal_documents",
            queryItems: [
                URLQueryItem(name: "select", value: "slug,title,content,updated_at"),
                URLQueryItem(name: "slug", value: "eq.\(kind.rawValue)"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )

        guard let row = rows.first else {
            return AgreementDocument(title: kind.defaultTitle, content: kind.defaultContent, updatedAt: nil)
        }

        let doc = AgreementDocument(
            title: (row.title?.isEmpty == false ? row.title : kind.defaultTitle) ?? kind.defaultTitle,
            content: (row.content?.isEmpty == false ? row.content : kind.defaultContent) ?? kind.defaultContent,
            updatedAt: row.updated_at
        )

        saveCache(kind: kind, doc: doc)
        return doc
    }

    private func saveCache(kind: AgreementKind, doc: AgreementDocument) {
        let key = cacheKey(for: kind)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(doc) else { return }
        defaults.set(data, forKey: key)
    }

    private func cacheKey(for kind: AgreementKind) -> String {
        "agreements.cache.\(kind.rawValue)"
    }
}

struct UserRelationsService {
    static let shared = UserRelationsService()
    
    private let restClient = SupabaseRESTClient(
        supabaseURL: AppConfig.supabaseURL,
        anonKey: AppConfig.supabaseAnonKey
    )
    
    private let defaults = UserDefaults.standard
    
    struct FollowRow: Decodable {
        let target_user_id: String
        let created_at: Date?
    }
    
    struct BlockRow: Decodable {
        let target_user_id: String
        let created_at: Date?
    }
    
    func getFollowingList(userId: String, accessToken: String? = nil) async throws -> Set<String> {
        let rows: [FollowRow] = try await restClient.get(
            table: "following",
            queryItems: [
                URLQueryItem(name: "select", value: "target_user_id,created_at"),
                URLQueryItem(name: "user_id", value: "eq.\(userId)")
            ],
            bearerToken: accessToken
        )
        return Set(rows.map { $0.target_user_id })
    }
    
    func getBlockedList(userId: String, accessToken: String? = nil) async throws -> Set<String> {
        let rows: [BlockRow] = try await restClient.get(
            table: "blocked_users",
            queryItems: [
                URLQueryItem(name: "select", value: "target_user_id,created_at"),
                URLQueryItem(name: "user_id", value: "eq.\(userId)")
            ],
            bearerToken: accessToken
        )
        return Set(rows.map { $0.target_user_id })
    }
    
    func addFollow(userId: String, targetUserId: String, accessToken: String? = nil) async throws {
        let body: [String: String] = [
            "user_id": userId,
            "target_user_id": targetUserId
        ]
        guard let bodyData = try? JSONEncoder().encode(body) else { return }
        
        var request = try makePostRequest(table: "following", bearerToken: accessToken)
        request.httpBody = bodyData
        
        let (_, rawResponse) = try await URLSession.shared.data(for: request)
        guard let http = rawResponse as? HTTPURLResponse else {
            throw SupabaseFunctionsClient.ClientError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) || http.statusCode == 409 else {
            throw SupabaseFunctionsClient.ClientError.httpStatus(http.statusCode, "")
        }
    }
    
    func removeFollow(userId: String, targetUserId: String, accessToken: String? = nil) async throws {
        var request = try makeDeleteRequest(
            table: "following",
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(userId)"),
                URLQueryItem(name: "target_user_id", value: "eq.\(targetUserId)")
            ],
            bearerToken: accessToken
        )
        
        let (_, rawResponse) = try await URLSession.shared.data(for: request)
        guard let http = rawResponse as? HTTPURLResponse else {
            throw SupabaseFunctionsClient.ClientError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw SupabaseFunctionsClient.ClientError.httpStatus(http.statusCode, "")
        }
    }
    
    func addBlock(userId: String, targetUserId: String, accessToken: String? = nil) async throws {
        let body: [String: String] = [
            "user_id": userId,
            "target_user_id": targetUserId
        ]
        guard let bodyData = try? JSONEncoder().encode(body) else { return }
        
        var request = try makePostRequest(table: "blocked_users", bearerToken: accessToken)
        request.httpBody = bodyData
        
        let (_, rawResponse) = try await URLSession.shared.data(for: request)
        guard let http = rawResponse as? HTTPURLResponse else {
            throw SupabaseFunctionsClient.ClientError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) || http.statusCode == 409 else {
            throw SupabaseFunctionsClient.ClientError.httpStatus(http.statusCode, "")
        }
    }
    
    func removeBlock(userId: String, targetUserId: String, accessToken: String? = nil) async throws {
        var request = try makeDeleteRequest(
            table: "blocked_users",
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(userId)"),
                URLQueryItem(name: "target_user_id", value: "eq.\(targetUserId)")
            ],
            bearerToken: accessToken
        )
        
        let (_, rawResponse) = try await URLSession.shared.data(for: request)
        guard let http = rawResponse as? HTTPURLResponse else {
            throw SupabaseFunctionsClient.ClientError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw SupabaseFunctionsClient.ClientError.httpStatus(http.statusCode, "")
        }
    }
    
    func cacheFollowingList(_ userIds: Set<String>, forUserId userId: String) {
        let key = cacheKeyFollowing(userId: userId)
        let data = Array(userIds)
        defaults.set(data, forKey: key)
    }
    
    func loadCachedFollowingList(userId: String) -> Set<String>? {
        let key = cacheKeyFollowing(userId: userId)
        guard let data = defaults.stringArray(forKey: key) else { return nil }
        return Set(data)
    }
    
    func cacheBlockedList(_ userIds: Set<String>, forUserId userId: String) {
        let key = cacheKeyBlocked(userId: userId)
        let data = Array(userIds)
        defaults.set(data, forKey: key)
    }
    
    func loadCachedBlockedList(userId: String) -> Set<String>? {
        let key = cacheKeyBlocked(userId: userId)
        guard let data = defaults.stringArray(forKey: key) else { return nil }
        return Set(data)
    }
    
    private func cacheKeyFollowing(userId: String) -> String {
        "user.following.\(userId)"
    }
    
    private func cacheKeyBlocked(userId: String) -> String {
        "user.blocked.\(userId)"
    }
    
    private func makePostRequest(table: String, bearerToken: String?) throws -> URLRequest {
        let trimmedKey = AppConfig.supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw SupabaseFunctionsClient.ClientError.missingConfig("SUPABASE_ANON_KEY")
        }
        
        var components = URLComponents(url: AppConfig.supabaseURL, resolvingAgainstBaseURL: false)
        let path = components?.path ?? ""
        components?.path = path
            .appending("/")
            .appending("rest")
            .appending("/v1")
            .appending("/")
            .appending(table)
        
        guard let url = components?.url else {
            throw SupabaseFunctionsClient.ClientError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(trimmedKey, forHTTPHeaderField: "apikey")
        if let bearerToken, !bearerToken.isEmpty {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        return request
    }
    
    private func makeDeleteRequest(table: String, queryItems: [URLQueryItem], bearerToken: String?) throws -> URLRequest {
        let trimmedKey = AppConfig.supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw SupabaseFunctionsClient.ClientError.missingConfig("SUPABASE_ANON_KEY")
        }
        
        var components = URLComponents(url: AppConfig.supabaseURL, resolvingAgainstBaseURL: false)
        let path = components?.path ?? ""
        components?.path = path
            .appending("/")
            .appending("rest")
            .appending("/v1")
            .appending("/")
            .appending(table)
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw SupabaseFunctionsClient.ClientError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(trimmedKey, forHTTPHeaderField: "apikey")
        if let bearerToken, !bearerToken.isEmpty {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
