import Foundation

struct AppSnapshot: Codable {
    var nativeLanguageID: String
    var targetLanguageID: String
    var notebook: [NotebookEntry]
}

actor NotebookStore {
    private let snapshotURL: URL
    private let imagesDirectoryURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("PopLex", isDirectory: true)

        self.snapshotURL = supportURL?.appendingPathComponent("snapshot.json") ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("snapshot.json")
        self.imagesDirectoryURL = supportURL?.appendingPathComponent("Images", isDirectory: true) ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Images", isDirectory: true)

        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }

    func loadSnapshot() throws -> AppSnapshot? {
        try prepareDirectoriesIfNeeded()
        guard FileManager.default.fileExists(atPath: snapshotURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: snapshotURL)
        return try decoder.decode(AppSnapshot.self, from: data)
    }

    func saveSnapshot(_ snapshot: AppSnapshot) throws {
        try prepareDirectoriesIfNeeded()
        let data = try encoder.encode(snapshot)
        try data.write(to: snapshotURL, options: .atomic)
    }

    func saveImageData(_ data: Data, for entryID: UUID) throws -> String {
        try prepareDirectoriesIfNeeded()
        let fileName = "\(entryID.uuidString).png"
        let fileURL = imagesDirectoryURL.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
        return fileName
    }

    func loadImageData(named fileName: String) -> Data? {
        let fileURL = imagesDirectoryURL.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }

    func deleteImage(named fileName: String?) {
        guard let fileName else {
            return
        }

        let fileURL = imagesDirectoryURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func prepareDirectoriesIfNeeded() throws {
        try FileManager.default.createDirectory(
            at: imagesDirectoryURL,
            withIntermediateDirectories: true
        )
    }
}
