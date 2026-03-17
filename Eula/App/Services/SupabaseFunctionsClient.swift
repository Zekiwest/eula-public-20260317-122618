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
    private static let fractionalISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let standardISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

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
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = SupabaseRESTClient.fractionalISO8601Formatter.date(from: value) {
                return date
            }
            if let date = SupabaseRESTClient.standardISO8601Formatter.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO8601 date: \(value)"
            )
        }
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
            throw SupabaseFunctionsClient.ClientError.httpStatus(404, "Missing legal document: \(kind.rawValue)")
        }
        guard let title = row.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            throw SupabaseFunctionsClient.ClientError.httpStatus(422, "Missing title for legal document: \(kind.rawValue)")
        }
        guard let content = row.content?.trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty else {
            throw SupabaseFunctionsClient.ClientError.httpStatus(422, "Missing content for legal document: \(kind.rawValue)")
        }

        return AgreementDocument(
            title: title,
            content: content,
            updatedAt: row.updated_at
        )
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
