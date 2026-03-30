import AVFAudio
import Foundation

@MainActor
final class PronunciationService: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
        #if canImport(UIKit)
        synthesizer.usesApplicationAudioSession = false
        #endif
    }

    func primeVoices(for languages: [LanguageOption]) {
        _ = languages.map(preferredVoice(for:))
    }

    func speak(_ text: String, in language: LanguageOption) {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else {
            return
        }

        let utterance = AVSpeechUtterance(string: cleanedText)
        utterance.voice = preferredVoice(for: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 1.03
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        synthesizer.speak(utterance)
    }

    private func preferredVoice(for language: LanguageOption) -> AVSpeechSynthesisVoice? {
        let matches = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(language.id) || $0.language.hasPrefix(language.speechCode.prefix(2)) }
            .sorted { lhs, rhs in
                if lhs.quality == rhs.quality {
                    return lhs.language < rhs.language
                }
                return lhs.quality.rawValue > rhs.quality.rawValue
            }

        if let premiumOrEnhanced = matches.first(where: { voice in
            voice.quality == .premium || voice.quality == .enhanced
        }) {
            return premiumOrEnhanced
        }

        if let exact = AVSpeechSynthesisVoice(language: language.speechCode) {
            return exact
        }

        return matches.first
    }
}
