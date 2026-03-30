import Foundation

enum ExamServiceError: LocalizedError {
    case notEnoughWords
    case generationFailed

    var errorDescription: String? {
        switch self {
        case .notEnoughWords:
            return "Need at least 3 words in your notebook to start an exam."
        case .generationFailed:
            return "Couldn't generate exam questions. Please try again."
        }
    }
}

actor ExamService {
    private let credentials: MiniMaxCredentialStore
    private let apiClient: MiniMaxAPIClient
    private let decoder = JSONDecoder()

    init(credentials: MiniMaxCredentialStore, session: URLSession = .shared) {
        self.credentials = credentials
        self.apiClient = MiniMaxAPIClient(credentials: credentials, session: session)
    }

    func generateExam(
        from words: [NotebookEntry],
        questionCount: Int = 5,
        nativeLanguage: LanguageOption,
        targetLanguage: LanguageOption
    ) async throws -> [ExamQuestion] {
        let trimmedWords = words.prefix(max(3, questionCount + 2))
        guard trimmedWords.count >= 3 else {
            throw ExamServiceError.notEnoughWords
        }

        let credentialState = await credentials.currentState()
        guard credentialState.isConfigured else {
            return generateFallbackExam(from: Array(trimmedWords), questionCount: questionCount)
        }

        do {
            let payload = try await apiClient.examQuestions(
                from: Array(trimmedWords),
                questionCount: questionCount,
                nativeLanguage: nativeLanguage,
                targetLanguage: targetLanguage
            )
            return payload.questions.map { item in
                ExamQuestion(
                    word: item.word,
                    options: item.options,
                    correctAnswer: item.correctAnswer,
                    explanation: item.explanation
                )
            }
        } catch {
            return generateFallbackExam(from: Array(trimmedWords), questionCount: questionCount)
        }
    }

    private func generateFallbackExam(
        from entries: [NotebookEntry],
        questionCount: Int
    ) -> [ExamQuestion] {
        let shuffled = entries.shuffled()
        let count = min(questionCount, shuffled.count)

        return (0..<count).map { index in
            let correctEntry = shuffled[index]
            let wrongEntries = shuffled.filter { $0.id != correctEntry.id }.prefix(3)
            var options = wrongEntries.map { $0.displayTerm }
            options.append(correctEntry.displayTerm)
            let shuffledOptions = options.shuffled()

            return ExamQuestion(
                word: correctEntry.displayTerm,
                options: shuffledOptions,
                correctAnswer: correctEntry.displayTerm,
                explanation: "Definition: \(correctEntry.definition)"
            )
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
