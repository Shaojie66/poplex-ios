import Foundation

struct LookupServiceResult: Sendable {
    let entry: NotebookEntry
    let statusMessage: String?
}

struct StoryServiceResult: Sendable {
    let payload: NotebookStoryPayload
    let statusMessage: String?
}

enum LookupServiceError: LocalizedError {
    case emptyQuery

    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "Type a word, phrase, or sentence first."
        }
    }
}

actor DictionaryLookupService {
    private let credentials: MiniMaxCredentialStore
    private let apiClient: MiniMaxAPIClient

    init(credentials: MiniMaxCredentialStore, session: URLSession = .shared) {
        self.credentials = credentials
        self.apiClient = MiniMaxAPIClient(credentials: credentials, session: session)
    }

    func lookup(
        query: String,
        nativeLanguage: LanguageOption,
        targetLanguage: LanguageOption
    ) async throws -> LookupServiceResult {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw LookupServiceError.emptyQuery
        }

        let credentialState = await credentials.currentState()
        guard credentialState.isConfigured else {
            return fallbackLookup(
                query: trimmedQuery,
                nativeLanguage: nativeLanguage,
                targetLanguage: targetLanguage,
                reason: credentialState.helperMessage
            )
        }

        do {
            let payload = try await apiClient.lookup(
                query: trimmedQuery,
                nativeLanguage: nativeLanguage,
                targetLanguage: targetLanguage
            )

            let entry = NotebookEntry(
                query: trimmedQuery,
                displayTerm: payload.correctedTerm,
                nativeLanguageID: nativeLanguage.id,
                targetLanguageID: targetLanguage.id,
                definition: payload.definition,
                usageNote: payload.usageNote,
                imagePrompt: payload.imagePrompt,
                examples: normalizeExamples(payload.examples)
            )
            return LookupServiceResult(entry: entry, statusMessage: nil)
        } catch {
            return fallbackLookup(
                query: trimmedQuery,
                nativeLanguage: nativeLanguage,
                targetLanguage: targetLanguage,
                reason: fallbackReason(for: error, fallback: "MiniMax didn’t answer in time, so PopLex switched to a preview card.")
            )
        }
    }

    func makeStory(
        from entries: [NotebookEntry],
        nativeLanguage: LanguageOption
    ) async -> StoryServiceResult {
        guard !entries.isEmpty else {
            return StoryServiceResult(
                payload: NotebookStoryPayload(
                    title: "Empty notebook",
                    story: "Save a few words first, then PopLex can spin them into a mini story that actually helps them stick.",
                    memoryHook: "Three to six saved cards is the sweet spot."
                ),
                statusMessage: nil
            )
        }

        let credentialState = await credentials.currentState()
        guard credentialState.isConfigured else {
            return fallbackStory(
                from: entries,
                nativeLanguage: nativeLanguage,
                reason: credentialState.helperMessage
            )
        }

        do {
            let payload = try await apiClient.story(from: entries, nativeLanguage: nativeLanguage)
            return StoryServiceResult(payload: payload, statusMessage: nil)
        } catch {
            return fallbackStory(
                from: entries,
                nativeLanguage: nativeLanguage,
                reason: fallbackReason(for: error, fallback: "Story mode fell back to a quick mnemonic because MiniMax didn’t answer in time.")
            )
        }
    }

    private func normalizeExamples(_ payloads: [LookupExamplePayload]) -> [ExampleLine] {
        let trimmed = payloads
            .prefix(2)
            .map {
                ExampleLine(
                    targetText: $0.targetSentence.trimmingCharacters(in: .whitespacesAndNewlines),
                    nativeTranslation: $0.nativeTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }

        if trimmed.count == 2 {
            return trimmed
        }

        return [
            ExampleLine(
                targetText: "“\(trimmed.first?.targetText ?? "term")” in a quick everyday moment.",
                nativeTranslation: trimmed.first?.nativeTranslation ?? "A short example would show how the term lands in real life."
            ),
            ExampleLine(
                targetText: "A second natural example with “\(trimmed.first?.targetText ?? "term")” in context.",
                nativeTranslation: "A second example helps you hear the tone instead of memorizing it like a robot."
            )
        ]
    }

    private func fallbackLookup(
        query: String,
        nativeLanguage: LanguageOption,
        targetLanguage: LanguageOption,
        reason: String?
    ) -> LookupServiceResult {
        let entry = NotebookEntry(
            query: query,
            displayTerm: query,
            nativeLanguageID: nativeLanguage.id,
            targetLanguageID: targetLanguage.id,
            definition: "Preview mode: this slot will show a natural explanation in \(nativeLanguage.promptLabel) once MiniMax is connected.",
            usageNote: "Think of this as the shape of the answer, not the final spicy version. When MiniMax is live, this part will unpack tone, nuance, culture, or sneaky lookalikes without sounding like homework.",
            imagePrompt: "A bright playful illustration for the concept of \(query), bold colors, friendly shapes, mobile app card art",
            examples: [
                ExampleLine(
                    targetText: "Preview example for “\(query)” in \(targetLanguage.promptLabel).",
                    nativeTranslation: "A native-language translation lands here in the full version."
                ),
                ExampleLine(
                    targetText: "Second preview example showing how “\(query)” could appear naturally.",
                    nativeTranslation: "This second line is where the quick, friendly translation would go."
                )
            ]
        )
        return LookupServiceResult(entry: entry, statusMessage: reason)
    }

    private func fallbackStory(
        from entries: [NotebookEntry],
        nativeLanguage: LanguageOption,
        reason: String?
    ) -> StoryServiceResult {
        let terms = entries.map(\.displayTerm)
        let joinedTerms = terms.joined(separator: ", ")
        let payload = NotebookStoryPayload(
            title: "Pocket story remix",
            story: "Picture a neon street corner where \(joinedTerms) all show up in one ridiculous scene. The weirder the movie in your head, the faster the words stick.\n\nNow replay it once, but say each saved term out loud when it appears. That little bit of sound plus image is the cheat code.",
            memoryHook: "In \(nativeLanguage.promptLabel), the trick is simple: one silly scene beats ten dry repetitions."
        )
        return StoryServiceResult(payload: payload, statusMessage: reason)
    }

    private func fallbackReason(for error: Error, fallback: String) -> String {
        guard let description = error.localizedDescription.nilIfEmpty else {
            return fallback
        }

        return "\(description) PopLex switched to preview mode for this card."
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
