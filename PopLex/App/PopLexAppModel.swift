import Observation
import SwiftUI

@MainActor
@Observable
final class PopLexAppModel {
    let pronunciationService = PronunciationService()

    var selectedNativeLanguageID = LanguageOption.defaultNative.id {
        didSet { persistSnapshot() }
    }
    var selectedTargetLanguageID = LanguageOption.defaultTarget.id {
        didSet { persistSnapshot() }
    }
    var queryText = ""
    var currentResult: NotebookEntry?
    var currentArtwork: PlatformImage?
    var currentStory: NotebookStoryPayload?
    var notebook: [NotebookEntry] = []
    var wrongAnswers: [WrongAnswer] = []
    var masteredWords: [MasteredWord] = []
    var selectedTab: AppTab = .lookup
    var currentExamSession: ExamSession?
    var isExamActive = false
    var isLookingUp = false
    var isGeneratingArtwork = false
    var isGeneratingStory = false
    var statusBanner: String?
    var imageBanner: String?
    var storyBanner: String?
    var miniMaxAPIKeyDraft = ""
    var miniMaxSourceLabel = "Not configured"
    var miniMaxHelperMessage = "Add a MiniMax API key to unlock live definitions and images."
    var miniMaxWarningMessage: String?
    var miniMaxActionMessage: String?
    var miniMaxIsConfigured = false
    var miniMaxCanClearSavedKey = false

    private let miniMaxCredentialStore: MiniMaxCredentialStore
    private let lookupService: DictionaryLookupService
    private let imageService: ImageGenerationService
    private let notebookStore = NotebookStore()
    private let wrongAnswerStore = WrongAnswerStore()
    private var artworkCache: [UUID: PlatformImage] = [:]
    private var lookupRequestID = UUID()
    private var artworkTask: Task<Void, Never>?

    init() {
        let credentialStore = MiniMaxCredentialStore()
        self.miniMaxCredentialStore = credentialStore
        self.lookupService = DictionaryLookupService(credentials: credentialStore)
        self.imageService = ImageGenerationService(credentials: credentialStore)
        pronunciationService.primeVoices(for: LanguageOption.popular)
        Task {
            await bootstrap()
        }
    }

    var selectedNativeLanguage: LanguageOption {
        LanguageOption.option(for: selectedNativeLanguageID)
    }

    var selectedTargetLanguage: LanguageOption {
        LanguageOption.option(for: selectedTargetLanguageID)
    }

    var currentResultIsSaved: Bool {
        guard let currentResult else {
            return false
        }
        return notebook.contains(where: { $0.id == currentResult.id })
    }

    func useSampleInput() {
        queryText = LanguageOption.sampleInputs.randomElement() ?? "serendipity"
    }

    func performLookup() {
        Task {
            await performLookupTask()
        }
    }

    func clearLookupFeedback() {
        statusBanner = nil
        imageBanner = nil
    }

    func saveMiniMaxAPIKey() {
        Task {
            await saveMiniMaxAPIKeyTask()
        }
    }

    func clearMiniMaxAPIKey() {
        Task {
            await clearMiniMaxAPIKeyTask()
        }
    }

    func saveCurrentResult() {
        guard var currentResult, !currentResultIsSaved else {
            selectedTab = .notebook
            return
        }

        Task {
            if let imageData = currentArtwork?.pngDataRepresentation() {
                currentResult.imageFileName = try? await notebookStore.saveImageData(imageData, for: currentResult.id)
            }

            notebook.insert(currentResult, at: 0)
            artworkCache[currentResult.id] = currentArtwork
            self.currentResult = currentResult
            persistSnapshot()
            selectedTab = .notebook
        }
    }

    func remove(_ entry: NotebookEntry) {
        notebook.removeAll(where: { $0.id == entry.id })
        artworkCache.removeValue(forKey: entry.id)

        if currentResult?.id == entry.id {
            currentResult?.imageFileName = nil
        }

        Task {
            await notebookStore.deleteImage(named: entry.imageFileName)
            persistSnapshot()
        }
    }

    func artwork(for entry: NotebookEntry) -> PlatformImage? {
        if currentResult?.id == entry.id, let currentArtwork {
            return currentArtwork
        }
        return artworkCache[entry.id]
    }

    func requestArtwork(for entry: NotebookEntry) {
        guard artworkCache[entry.id] == nil, let imageFileName = entry.imageFileName else {
            return
        }

        Task {
            guard
                let data = await notebookStore.loadImageData(named: imageFileName),
                let image = PlatformImage(data: data)
            else {
                return
            }

            await MainActor.run {
                artworkCache[entry.id] = image
            }
        }
    }

    func generateStory() {
        Task {
            await generateStoryTask()
        }
    }

    func removeWrongAnswer(_ wrongAnswer: WrongAnswer) {
        wrongAnswers.removeAll(where: { $0.id == wrongAnswer.id })
        Task {
            var snapshot = try? await wrongAnswerStore.load()
            snapshot?.wrongAnswers.removeAll(where: { $0.id == wrongAnswer.id })
            if let snapshot {
                try? await wrongAnswerStore.save(snapshot)
            }
        }
    }

    func recordWrongAnswer(questionID: String, word: String, userAnswer: String, correctAnswer: String) {
        let wrongAnswer = WrongAnswer(questionID: questionID, word: word, userAnswer: userAnswer, correctAnswer: correctAnswer)
        wrongAnswers.insert(wrongAnswer, at: 0)
        Task {
            do {
                try await wrongAnswerStore.addWrongAnswer(wrongAnswer)
            } catch {
                // Silent failure acceptable for Phase 1
            }
        }
    }

    func startExam() {
        isExamActive = true
    }

    func markCurrentResultMastered() {
        guard let result = currentResult else { return }
        let word = result.displayTerm
        guard !masteredWords.contains(where: { $0.word.lowercased() == word.lowercased() }) else { return }
        let mastered = MasteredWord(word: word)
        masteredWords.insert(mastered, at: 0)
        Task {
            do {
                var snapshot = try await wrongAnswerStore.load()
                if !snapshot.masteredWords.contains(where: { $0.word.lowercased() == word.lowercased() }) {
                    snapshot.masteredWords.insert(mastered, at: 0)
                    try await wrongAnswerStore.save(snapshot)
                }
            } catch {
                // Silent failure acceptable for Phase 1
            }
        }
    }

    func isWordMastered(_ word: String) -> Bool {
        masteredWords.contains(where: { $0.word.lowercased() == word.lowercased() })
    }

    var isCurrentResultMastered: Bool {
        guard let result = currentResult else { return false }
        return isWordMastered(result.displayTerm)
    }

    func speakCurrentResult() {
        guard let result = currentResult else { return }
        pronunciationService.speak(result.displayTerm, in: result.targetLanguage)
    }

    private func bootstrap() async {
        if let snapshot = try? await notebookStore.loadSnapshot() {
            selectedNativeLanguageID = snapshot.nativeLanguageID
            selectedTargetLanguageID = snapshot.targetLanguageID
            notebook = snapshot.notebook.sorted(by: { $0.createdAt > $1.createdAt })
            notebook.forEach(requestArtwork(for:))
        }

        if let mistakesSnapshot = try? await wrongAnswerStore.load() {
            wrongAnswers = mistakesSnapshot.wrongAnswers
            masteredWords = mistakesSnapshot.masteredWords
        }

        await refreshMiniMaxCredentialState()
    }

    private func performLookupTask() async {
        let requestID = UUID()
        lookupRequestID = requestID
        artworkTask?.cancel()

        isLookingUp = true
        isGeneratingArtwork = false
        currentArtwork = nil
        imageBanner = nil
        currentStory = nil

        do {
            let lookup = try await lookupService.lookup(
                query: queryText,
                nativeLanguage: selectedNativeLanguage,
                targetLanguage: selectedTargetLanguage
            )
            guard lookupRequestID == requestID else {
                return
            }

            currentResult = lookup.entry
            statusBanner = lookup.statusMessage
            miniMaxActionMessage = nil
            isLookingUp = false

            isGeneratingArtwork = true
            imageBanner = "Artwork is rendering now."
            let entry = lookup.entry
            artworkTask = Task { [weak self] in
                await self?.performArtworkTask(for: entry, requestID: requestID)
            }
        } catch {
            guard lookupRequestID == requestID else {
                return
            }

            statusBanner = error.localizedDescription
            currentResult = nil
            currentArtwork = nil
            imageBanner = nil
            isLookingUp = false
            isGeneratingArtwork = false
        }
    }

    private func performArtworkTask(for entry: NotebookEntry, requestID: UUID) async {
        let imageResult = await imageService.generateImage(for: entry.imagePrompt)
        guard !Task.isCancelled else {
            return
        }

        guard lookupRequestID == requestID, currentResult?.id == entry.id else {
            return
        }

        currentArtwork = imageResult.image
        imageBanner = imageResult.statusMessage
        isGeneratingArtwork = false
        artworkTask = nil
    }

    private func generateStoryTask() async {
        isGeneratingStory = true
        defer {
            isGeneratingStory = false
        }

        let result = await lookupService.makeStory(
            from: notebook,
            nativeLanguage: selectedNativeLanguage
        )
        currentStory = result.payload
        storyBanner = result.statusMessage
    }

    private func saveMiniMaxAPIKeyTask() async {
        do {
            try await miniMaxCredentialStore.saveAPIKey(miniMaxAPIKeyDraft)
            miniMaxAPIKeyDraft = ""
            miniMaxActionMessage = "MiniMax key saved locally to this device keychain."
            await refreshMiniMaxCredentialState()
        } catch {
            miniMaxActionMessage = error.localizedDescription
        }
    }

    private func clearMiniMaxAPIKeyTask() async {
        await miniMaxCredentialStore.clearSavedAPIKey()
        miniMaxAPIKeyDraft = ""
        miniMaxActionMessage = "Saved MiniMax key removed from this device."
        await refreshMiniMaxCredentialState()
    }

    private func refreshMiniMaxCredentialState() async {
        let state = await miniMaxCredentialStore.currentState()
        miniMaxSourceLabel = state.sourceLabel
        miniMaxHelperMessage = state.helperMessage
        miniMaxWarningMessage = state.warningMessage
        miniMaxIsConfigured = state.isConfigured
        miniMaxCanClearSavedKey = state.hasSavedKey
    }

    private func persistSnapshot() {
        let snapshot = AppSnapshot(
            nativeLanguageID: selectedNativeLanguageID,
            targetLanguageID: selectedTargetLanguageID,
            notebook: notebook
        )

        Task {
            try? await notebookStore.saveSnapshot(snapshot)
        }
    }
}
