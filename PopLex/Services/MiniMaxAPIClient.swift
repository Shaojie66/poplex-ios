import Foundation

enum MiniMaxAPIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case invalidPayload
    case decodingFailed
    case imageDecodingFailed
    case httpError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "MiniMax isn’t configured yet. Add an API key first."
        case .invalidResponse:
            return "MiniMax returned a response PopLex couldn’t read."
        case .invalidPayload:
            return "MiniMax responded, but the payload shape was missing."
        case .decodingFailed:
            return "MiniMax answered, but PopLex couldn’t decode the JSON card."
        case .imageDecodingFailed:
            return "MiniMax returned image data that couldn’t be decoded."
        case .httpError(_, let message):
            return message
        }
    }
}

private struct MiniMaxChatMessage: Encodable {
    let role: String
    let content: String
}

private struct MiniMaxChatRequest: Encodable {
    let model: String
    let messages: [MiniMaxChatMessage]
    let temperature: Double
    let maxCompletionTokens: Int
    let reasoningSplit: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxCompletionTokens = "max_completion_tokens"
        case reasoningSplit = "reasoning_split"
    }
}

private struct MiniMaxChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String

            enum CodingKeys: String, CodingKey {
                case content
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                if let stringContent = try? container.decode(String.self, forKey: .content) {
                    content = stringContent
                    return
                }

                if let blockContent = try? container.decode([ContentBlock].self, forKey: .content) {
                    content = blockContent.compactMap(\.text).joined(separator: "\n")
                    return
                }

                throw MiniMaxAPIError.invalidResponse
            }
        }

        let message: Message
    }

    struct ContentBlock: Decodable {
        let type: String?
        let text: String?
    }

    let choices: [Choice]
}

private struct MiniMaxImageRequest: Encodable {
    let model: String
    let prompt: String
    let aspectRatio: String
    let responseFormat: String

    enum CodingKeys: String, CodingKey {
        case model
        case prompt
        case aspectRatio = "aspect_ratio"
        case responseFormat = "response_format"
    }
}

private struct MiniMaxImageResponse: Decodable {
    struct DataContainer: Decodable {
        let imageBase64: [String]

        enum CodingKeys: String, CodingKey {
            case imageBase64 = "image_base64"
        }
    }

    let data: DataContainer
}

private struct MiniMaxErrorEnvelope: Decodable {
    struct APIError: Decodable {
        let message: String?
        let type: String?
    }

    struct BaseResponse: Decodable {
        let statusCode: Int?
        let statusMsg: String?

        enum CodingKeys: String, CodingKey {
            case statusCode = "status_code"
            case statusMsg = "status_msg"
        }
    }

    let error: APIError?
    let baseResp: BaseResponse?

    enum CodingKeys: String, CodingKey {
        case error
        case baseResp = "base_resp"
    }
}

actor MiniMaxAPIClient {
    private let credentials: MiniMaxCredentialStore
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(credentials: MiniMaxCredentialStore, session: URLSession = .shared) {
        self.credentials = credentials
        self.session = session
    }

    func lookup(
        query: String,
        nativeLanguage: LanguageOption,
        targetLanguage: LanguageOption
    ) async throws -> LookupPayload {
        let prompt = """
        Return exactly one JSON object and nothing else.
        Required JSON schema:
        {
          "correctedTerm": "string",
          "definition": "string",
          "usageNote": "string",
          "imagePrompt": "string",
          "examples": [
            { "targetSentence": "string", "nativeTranslation": "string" },
            { "targetSentence": "string", "nativeTranslation": "string" }
          ]
        }

        Rules:
        - correctedTerm: keep the user's wording unless a tiny fix makes it more natural.
        - definition: write in \(nativeLanguage.promptLabel), concise, natural, friendly.
        - usageNote: write in \(nativeLanguage.promptLabel), casual and lively, explain nuance, vibe, culture, or a commonly confused neighbor.
        - imagePrompt: write in English, short but vivid, bright and playful, suitable for one illustrated flashcard image.
        - examples: exactly 2 entries.
        - targetSentence fields must be natural \(targetLanguage.promptLabel).
        - nativeTranslation fields must be natural \(nativeLanguage.promptLabel).
        - No markdown. No extra prose. JSON only.

        Target language: \(targetLanguage.promptLabel)
        Native language: \(nativeLanguage.promptLabel)
        User input: \(query)
        """

        let raw = try await chatCompletion(
            systemPrompt: """
            You are PopLex, a playful multilingual dictionary assistant inside a mobile app.
            Sound smart but relaxed. Keep the content compact and highly usable.
            """,
            userPrompt: prompt,
            maxTokens: 900,
            temperature: 0.5
        )

        return try decodeJSONPayload(raw, as: LookupPayload.self)
    }

    func story(
        from entries: [NotebookEntry],
        nativeLanguage: LanguageOption
    ) async throws -> NotebookStoryPayload {
        let phraseList = entries.map(\.displayTerm).joined(separator: ", ")
        let raw = try await chatCompletion(
            systemPrompt: """
            You write short memory stories for language learners.
            Keep them vivid, fun, and easy to picture.
            """,
            userPrompt: """
            Return exactly one JSON object and nothing else.
            Required schema:
            {
              "title": "string",
              "story": "string",
              "memoryHook": "string"
            }

            Rules:
            - Write everything in \(nativeLanguage.promptLabel).
            - Weave these exact target-language words or phrases into the story when possible: \(phraseList)
            - title: punchy and fun.
            - story: 2 short paragraphs max.
            - memoryHook: 1 sentence explaining why the story helps the words stick.
            - No markdown. JSON only.
            """,
            maxTokens: 700,
            temperature: 0.7
        )

        return try decodeJSONPayload(raw, as: NotebookStoryPayload.self)
    }

    func imageData(for prompt: String) async throws -> Data {
        let apiKey = try await apiKeyOrThrow()
        var request = URLRequest(url: URL(string: "https://api.minimax.io/v1/image_generation")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(
            MiniMaxImageRequest(
                model: "image-01",
                prompt: prompt,
                aspectRatio: "1:1",
                responseFormat: "base64"
            )
        )

        let (data, response) = try await session.data(for: request)
        let httpResponse = try validateHTTPResponse(response, data: data, fallbackMessage: "MiniMax image generation failed.")

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw MiniMaxAPIError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage(from: data) ?? "MiniMax image generation failed."
            )
        }

        let payload = try decoder.decode(MiniMaxImageResponse.self, from: data)
        guard
            let first = payload.data.imageBase64.first,
            let imageData = Data(base64Encoded: first)
        else {
            throw MiniMaxAPIError.imageDecodingFailed
        }

        return imageData
    }

    private func chatCompletion(
        systemPrompt: String,
        userPrompt: String,
        maxTokens: Int,
        temperature: Double
    ) async throws -> String {
        let apiKey = try await apiKeyOrThrow()
        var request = URLRequest(url: URL(string: "https://api.minimax.io/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 35
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(
            MiniMaxChatRequest(
                model: "MiniMax-M2.5",
                messages: [
                    MiniMaxChatMessage(role: "system", content: systemPrompt),
                    MiniMaxChatMessage(role: "user", content: userPrompt)
                ],
                temperature: temperature,
                maxCompletionTokens: maxTokens,
                reasoningSplit: true
            )
        )

        let (data, response) = try await session.data(for: request)
        let httpResponse = try validateHTTPResponse(response, data: data, fallbackMessage: "MiniMax text generation failed.")

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw MiniMaxAPIError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage(from: data) ?? "MiniMax text generation failed."
            )
        }

        let payload = try decoder.decode(MiniMaxChatResponse.self, from: data)
        guard let content = payload.choices.first?.message.content, !content.isEmpty else {
            throw MiniMaxAPIError.invalidPayload
        }

        return content
    }

    private func decodeJSONPayload<T: Decodable>(_ raw: String, as type: T.Type) throws -> T {
        let cleaned = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let segments = [
            cleaned.components(separatedBy: "</think>").last?.trimmingCharacters(in: .whitespacesAndNewlines),
            cleaned.nilIfEmpty
        ].compactMap { $0 }

        for segment in segments {
            for candidate in candidateJSONStrings(from: segment) {
                guard let data = candidate.data(using: .utf8) else {
                    continue
                }

                if let payload = try? decoder.decode(type, from: data) {
                    return payload
                }
            }
        }

        throw MiniMaxAPIError.decodingFailed
    }

    private func apiKeyOrThrow() async throws -> String {
        guard let apiKey = await credentials.apiKey(), !apiKey.isEmpty else {
            throw MiniMaxAPIError.missingAPIKey
        }
        return apiKey
    }

    private func validateHTTPResponse(
        _ response: URLResponse,
        data: Data,
        fallbackMessage: String
    ) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MiniMaxAPIError.invalidResponse
        }

        if !(200 ... 299).contains(httpResponse.statusCode) {
            throw MiniMaxAPIError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage(from: data) ?? fallbackMessage
            )
        }

        return httpResponse
    }

    private func errorMessage(from data: Data) -> String? {
        if let envelope = try? decoder.decode(MiniMaxErrorEnvelope.self, from: data) {
            if let message = envelope.error?.message, !message.isEmpty {
                return message
            }
            if let message = envelope.baseResp?.statusMsg, !message.isEmpty {
                return message
            }
        }

        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
    }

    private func candidateJSONStrings(from raw: String) -> [String] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return []
        }

        var candidates = [trimmed]
        if let start = trimmed.firstIndex(of: "{"), let end = trimmed.lastIndex(of: "}") {
            let bracketSlice = String(trimmed[start ... end])
            if bracketSlice != trimmed {
                candidates.append(bracketSlice)
            }
        }

        return candidates
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
