import Foundation

struct ImageGenerationResult {
    let image: PlatformImage?
    let statusMessage: String?
}

actor ImageGenerationService {
    private let credentials: MiniMaxCredentialStore
    private let apiClient: MiniMaxAPIClient

    init(credentials: MiniMaxCredentialStore, session: URLSession = .shared) {
        self.credentials = credentials
        self.apiClient = MiniMaxAPIClient(credentials: credentials, session: session)
    }

    func generateImage(for prompt: String) async -> ImageGenerationResult {
        let cleanedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedPrompt.isEmpty else {
            return ImageGenerationResult(image: nil, statusMessage: nil)
        }

        let credentialState = await credentials.currentState()
        guard credentialState.isConfigured else {
            return ImageGenerationResult(
                image: nil,
                statusMessage: "Add a MiniMax API key to unlock generated artwork. PopLex is using built-in sticker art for now."
            )
        }

        do {
            let data = try await apiClient.imageData(for: cleanedPrompt)
            guard let image = PlatformImage(data: data) else {
                return ImageGenerationResult(
                    image: nil,
                    statusMessage: "MiniMax returned image bytes PopLex couldn’t decode, so it switched to built-in sticker art."
                )
            }

            return ImageGenerationResult(image: image, statusMessage: nil)
        } catch {
            return ImageGenerationResult(
                image: nil,
                statusMessage: "\(error.localizedDescription) PopLex is using built-in sticker art instead."
            )
        }
    }
}
