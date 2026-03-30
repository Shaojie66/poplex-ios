import Foundation

struct ExamQuestion: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let word: String
    let options: [String]
    let correctAnswer: String
    let explanation: String

    init(
        id: UUID = UUID(),
        word: String,
        options: [String],
        correctAnswer: String,
        explanation: String
    ) {
        self.id = id
        self.word = word
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
    }
}

struct ExamAnswer: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let questionID: UUID
    let selectedOption: String
    let isCorrect: Bool

    init(id: UUID = UUID(), questionID: UUID, selectedOption: String, isCorrect: Bool) {
        self.id = id
        self.questionID = questionID
        self.selectedOption = selectedOption
        self.isCorrect = isCorrect
    }
}

struct ExamSession: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var questions: [ExamQuestion]
    var currentIndex: Int
    var answers: [ExamAnswer]
    var score: Int
    let startedAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        questions: [ExamQuestion],
        currentIndex: Int = 0,
        answers: [ExamAnswer] = [],
        score: Int = 0,
        startedAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.questions = questions
        self.currentIndex = currentIndex
        self.answers = answers
        self.score = score
        self.startedAt = startedAt
        self.completedAt = completedAt
    }

    var isComplete: Bool {
        completedAt != nil
    }

    var progress: String {
        "\(currentIndex + 1)/\(questions.count)"
    }

    var currentQuestion: ExamQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
}

struct ExamQuestionPayload: Codable, Sendable {
    let word: String
    let options: [String]
    let correctAnswer: String
    let explanation: String
}

struct ExamGenerationPayload: Codable, Sendable {
    let questions: [ExamQuestionPayload]
}
