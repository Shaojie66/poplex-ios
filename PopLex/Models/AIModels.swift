import Foundation

struct LookupPayload: Codable, Sendable {
    let correctedTerm: String
    let definition: String
    let usageNote: String
    let imagePrompt: String
    let examples: [LookupExamplePayload]
}

struct LookupExamplePayload: Codable, Sendable {
    let targetSentence: String
    let nativeTranslation: String
}

struct NotebookStoryPayload: Codable, Sendable {
    let title: String
    let story: String
    let memoryHook: String
}
