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
            let questions = payload.questions.compactMap { item -> ExamQuestion? in
                guard item.options.count == 4,
                      item.options.allSatisfy({ !$0.trimmingCharacters(in: .whitespaces).isEmpty }),
                      item.options.contains(item.correctAnswer) else {
                    return nil
                }
                return ExamQuestion(
                    word: item.word,
                    options: item.options,
                    correctAnswer: item.correctAnswer,
                    explanation: item.explanation
                )
            }
            guard questions.count >= 1 else {
                return generateFallbackExam(from: Array(trimmedWords), questionCount: questionCount)
            }
            return questions
        } catch {
            return generateFallbackExam(from: Array(trimmedWords), questionCount: questionCount)
        }
    }

    private func generateFallbackExam(
        from entries: [NotebookEntry],
        questionCount: Int
    ) -> [ExamQuestion] {
        // Need at least 4 entries to create 4-option questions (3 distractors + 1 correct)
        // With fewer than 4, fall back to API even if unconfigured, or return empty
        guard entries.count >= 4 else {
            return []
        }

        let shuffled = entries.shuffled()
        let count = min(questionCount, shuffled.count)

        return (0..<count).map { index in
            let correctEntry = shuffled[index]
            let wrongEntries = shuffled.filter { $0.id != correctEntry.id }.prefix(3)
            var options = wrongEntries.map { $0.displayTerm }
            options.append(correctEntry.displayTerm)

            // Ensure unique options (no duplicate displayTerms)
            var uniqueOptions = [String]()
            for opt in options {
                if !uniqueOptions.contains(opt) {
                    uniqueOptions.append(opt)
                }
            }
            // If deduplication left us with < 4, pad with placeholder markers
            while uniqueOptions.count < 4 {
                uniqueOptions.append("选项\(uniqueOptions.count + 1)")
            }
            let shuffledOptions = Array(uniqueOptions.shuffled().prefix(4))

            return ExamQuestion(
                word: correctEntry.displayTerm,
                options: shuffledOptions,
                correctAnswer: correctEntry.displayTerm,
                explanation: "Definition: \(correctEntry.definition)"
            )
        }
    }
}
