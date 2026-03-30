import Foundation

struct WrongAnswer: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let questionID: String
    let word: String
    let userAnswer: String
    let correctAnswer: String
    let recordedAt: Date

    init(
        id: UUID = UUID(),
        questionID: String,
        word: String,
        userAnswer: String,
        correctAnswer: String,
        recordedAt: Date = .now
    ) {
        self.id = id
        self.questionID = questionID
        self.word = word
        self.userAnswer = userAnswer
        self.correctAnswer = correctAnswer
        self.recordedAt = recordedAt
    }
}

struct MasteredWord: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let word: String
    let masteredAt: Date

    init(id: UUID = UUID(), word: String, masteredAt: Date = .now) {
        self.id = id
        self.word = word
        self.masteredAt = masteredAt
    }
}

struct MistakesSnapshot: Codable {
    var wrongAnswers: [WrongAnswer]
    var masteredWords: [MasteredWord]
}