import Foundation

struct ExampleLine: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let targetText: String
    let nativeTranslation: String

    init(id: UUID = UUID(), targetText: String, nativeTranslation: String) {
        self.id = id
        self.targetText = targetText
        self.nativeTranslation = nativeTranslation
    }
}

struct NotebookEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let query: String
    let displayTerm: String
    let nativeLanguageID: String
    let targetLanguageID: String
    let definition: String
    let usageNote: String
    let imagePrompt: String
    let examples: [ExampleLine]
    let createdAt: Date
    var imageFileName: String?

    init(
        id: UUID = UUID(),
        query: String,
        displayTerm: String,
        nativeLanguageID: String,
        targetLanguageID: String,
        definition: String,
        usageNote: String,
        imagePrompt: String,
        examples: [ExampleLine],
        createdAt: Date = .now,
        imageFileName: String? = nil
    ) {
        self.id = id
        self.query = query
        self.displayTerm = displayTerm
        self.nativeLanguageID = nativeLanguageID
        self.targetLanguageID = targetLanguageID
        self.definition = definition
        self.usageNote = usageNote
        self.imagePrompt = imagePrompt
        self.examples = examples
        self.createdAt = createdAt
        self.imageFileName = imageFileName
    }

    var nativeLanguage: LanguageOption {
        LanguageOption.option(for: nativeLanguageID)
    }

    var targetLanguage: LanguageOption {
        LanguageOption.option(for: targetLanguageID)
    }
}
