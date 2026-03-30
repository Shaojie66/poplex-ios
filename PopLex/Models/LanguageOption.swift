import Foundation

struct LanguageOption: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let displayName: String
    let nativeName: String
    let localeIdentifier: String
    let speechCode: String
    let promptLabel: String

    var fullLabel: String {
        "\(displayName) · \(nativeName)"
    }

    static let popular: [LanguageOption] = [
        LanguageOption(
            id: "en",
            displayName: "English",
            nativeName: "English",
            localeIdentifier: "en_US",
            speechCode: "en-US",
            promptLabel: "English"
        ),
        LanguageOption(
            id: "zh",
            displayName: "Mandarin Chinese",
            nativeName: "中文",
            localeIdentifier: "zh_Hans_CN",
            speechCode: "zh-CN",
            promptLabel: "Mandarin Chinese"
        ),
        LanguageOption(
            id: "hi",
            displayName: "Hindi",
            nativeName: "हिन्दी",
            localeIdentifier: "hi_IN",
            speechCode: "hi-IN",
            promptLabel: "Hindi"
        ),
        LanguageOption(
            id: "es",
            displayName: "Spanish",
            nativeName: "Español",
            localeIdentifier: "es_ES",
            speechCode: "es-ES",
            promptLabel: "Spanish"
        ),
        LanguageOption(
            id: "fr",
            displayName: "French",
            nativeName: "Français",
            localeIdentifier: "fr_FR",
            speechCode: "fr-FR",
            promptLabel: "French"
        ),
        LanguageOption(
            id: "ar",
            displayName: "Arabic",
            nativeName: "العربية",
            localeIdentifier: "ar_SA",
            speechCode: "ar-SA",
            promptLabel: "Arabic"
        ),
        LanguageOption(
            id: "bn",
            displayName: "Bengali",
            nativeName: "বাংলা",
            localeIdentifier: "bn_BD",
            speechCode: "bn-BD",
            promptLabel: "Bengali"
        ),
        LanguageOption(
            id: "pt",
            displayName: "Portuguese",
            nativeName: "Português",
            localeIdentifier: "pt_BR",
            speechCode: "pt-BR",
            promptLabel: "Portuguese"
        ),
        LanguageOption(
            id: "ru",
            displayName: "Russian",
            nativeName: "Русский",
            localeIdentifier: "ru_RU",
            speechCode: "ru-RU",
            promptLabel: "Russian"
        ),
        LanguageOption(
            id: "ur",
            displayName: "Urdu",
            nativeName: "اردو",
            localeIdentifier: "ur_PK",
            speechCode: "ur-PK",
            promptLabel: "Urdu"
        )
    ]

    static let defaultNative = popular[0]
    static let defaultTarget = popular[3]

    static func option(for id: String) -> LanguageOption {
        popular.first(where: { $0.id == id }) ?? defaultNative
    }

    static let sampleInputs = [
        "serendipity",
        "buen provecho",
        "left on read",
        "saudade",
        "sisu",
        "spill the tea"
    ]
}
