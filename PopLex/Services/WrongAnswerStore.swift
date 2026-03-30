import Foundation

actor WrongAnswerStore {
    private let snapshotURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("PopLex", isDirectory: true)

        self.snapshotURL = supportURL?.appendingPathComponent("mistakes.json")
            ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("mistakes.json")

        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }

    func load() throws -> MistakesSnapshot {
        guard FileManager.default.fileExists(atPath: snapshotURL.path) else {
            return MistakesSnapshot(wrongAnswers: [], masteredWords: [])
        }

        let data = try Data(contentsOf: snapshotURL)
        return try decoder.decode(MistakesSnapshot.self, from: data)
    }

    func save(_ snapshot: MistakesSnapshot) throws {
        let data = try encoder.encode(snapshot)
        try data.write(to: snapshotURL, options: .atomic)
    }

    func addWrongAnswer(_ wrongAnswer: WrongAnswer, to existing: inout MistakesSnapshot) throws {
        existing.wrongAnswers.insert(wrongAnswer, at: 0)
        try save(existing)
    }

    func markWordMastered(_ word: String, to existing: inout MistakesSnapshot) throws {
        guard !existing.masteredWords.contains(where: { $0.word.lowercased() == word.lowercased() }) else {
            return
        }
        let mastered = MasteredWord(word: word)
        existing.masteredWords.insert(mastered, at: 0)
        try save(existing)
    }

    func removeWrongAnswer(id: UUID, from existing: inout MistakesSnapshot) throws {
        existing.wrongAnswers.removeAll(where: { $0.id == id })
        try save(existing)
    }
}