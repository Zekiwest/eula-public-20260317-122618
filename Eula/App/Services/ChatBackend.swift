import Foundation

struct ChatBackend {
    static let shared = ChatBackend()

    private let client = SupabaseFunctionsClient(
        supabaseURL: AppConfig.supabaseURL,
        anonKey: AppConfig.supabaseAnonKey
    )

    func send(
        conversationID: String,
        personaKey: String,
        messages: [ChatHistoryMessage]
    ) async throws -> ChatReply {
        let req = ChatRequest(
            device_id: DeviceIdentity.deviceID(),
            conversation_id: conversationID,
            persona_key: personaKey,
            message_cost_coins: AppConfig.chatMessageCostCoins,
            messages: messages
        )
        return try await client.call(function: "chat", body: req)
    }

    func stream(
        conversationID: String,
        personaKey: String,
        messageCostCoins: Int,
        messages: [ChatHistoryMessage],
        onDelta: @escaping @MainActor (String) -> Void
    ) async throws {
        let req = ChatRequest(
            device_id: DeviceIdentity.deviceID(),
            conversation_id: conversationID,
            persona_key: personaKey,
            message_cost_coins: messageCostCoins,
            messages: messages,
            stream: true
        )

        let bytes: URLSession.AsyncBytes
        do {
            bytes = try await client.stream(function: "chat", body: try JSONEncoder().encode(req))
        } catch let SupabaseFunctionsClient.ClientError.httpStatus(code, body) {
            if code == 402, let err = try? JSONDecoder().decode(ChatFunctionError.self, from: Data(body.utf8)), err.error == "INSUFFICIENT_COINS" {
                throw InsufficientCoinsError(coinsRemaining: err.coins_remaining)
            }
            throw SupabaseFunctionsClient.ClientError.httpStatus(code, body)
        }

        for try await line in bytes.lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("data:") else { continue }
            let payload = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            if payload == "[DONE]" {
                break
            }
            guard let data = payload.data(using: .utf8) else { continue }
            guard let chunk = try? JSONDecoder().decode(OpenAIStreamChunk.self, from: data) else { continue }
            let delta = chunk.choices.first?.delta?.content ?? ""
            if !delta.isEmpty {
                await onDelta(delta)
            }
        }
    }

    func walletBalance() async throws -> Int {
        let reply: WalletBalanceReply = try await client.call(
            function: "wallet",
            body: WalletBalanceRequest(device_id: DeviceIdentity.deviceID())
        )
        return reply.coins
    }
}

private struct WalletBalanceRequest: Codable {
    let device_id: String
}

private struct WalletBalanceReply: Codable {
    let coins: Int
}

struct ChatHistoryMessage: Codable {
    enum Role: String, Codable {
        case user
        case assistant
    }

    let role: Role
    let content: String
}

struct ChatRequest: Codable {
    let device_id: String
    let conversation_id: String
    let persona_key: String
    let message_cost_coins: Int
    let messages: [ChatHistoryMessage]
    let stream: Bool?

    init(
        device_id: String,
        conversation_id: String,
        persona_key: String,
        message_cost_coins: Int,
        messages: [ChatHistoryMessage],
        stream: Bool? = nil
    ) {
        self.device_id = device_id
        self.conversation_id = conversation_id
        self.persona_key = persona_key
        self.message_cost_coins = message_cost_coins
        self.messages = messages
        self.stream = stream
    }
}

struct ChatReply: Codable {
    let reply: String
    let coins_remaining: Int?
}

struct InsufficientCoinsError: LocalizedError {
    let coinsRemaining: Int?

    var errorDescription: String? {
        "Insufficient coins."
    }
}

private struct ChatFunctionError: Decodable {
    let error: String?
    let coins_remaining: Int?
}

private struct OpenAIStreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }

        let delta: Delta?
    }

    let choices: [Choice]
}
