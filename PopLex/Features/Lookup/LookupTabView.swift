import SwiftUI

struct LookupTabView: View {
    @Environment(PopLexAppModel.self) private var model
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    heroCard
                    miniMaxCard
                    languageCard
                    composerCard

                    if let statusBanner = model.statusBanner {
                        BannerBubble(
                            icon: "brain.head.profile",
                            title: "AI status",
                            message: statusBanner
                        )
                    }

                    if model.isLookingUp {
                        loadingCard
                    } else if let currentResult = model.currentResult {
                        ResultCardView(
                            entry: currentResult,
                            artwork: model.currentArtwork,
                            isSaved: model.currentResultIsSaved,
                            saveAction: model.saveCurrentResult,
                            pronunciationService: model.pronunciationService
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
            .popLexNavigationChromeHidden()
        }
    }

    private var miniMaxCard: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MiniMax setup")
                            .font(.custom("AvenirNext-DemiBold", size: 22))
                            .foregroundStyle(PopLexTheme.ink)

                        Text("Live definitions and images run through MiniMax. Pronunciation still stays local for fast playback.")
                            .font(.custom("AvenirNext-Regular", size: 15))
                            .foregroundStyle(PopLexTheme.ink.opacity(0.74))
                    }

                    Spacer(minLength: 0)

                    Text(model.miniMaxSourceLabel)
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                        .foregroundStyle(model.miniMaxIsConfigured ? PopLexTheme.primaryBlue : PopLexTheme.primaryPink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            (model.miniMaxIsConfigured ? PopLexTheme.primaryBlue : PopLexTheme.primaryPink)
                                .opacity(0.12),
                            in: Capsule()
                        )
                }

                Text(model.miniMaxHelperMessage)
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.72))

                if let warningMessage = model.miniMaxWarningMessage {
                    BannerBubble(
                        icon: "exclamationmark.triangle.fill",
                        title: "Heads-up",
                        message: warningMessage
                    )
                }

                SecureField(
                    "Paste a MiniMax API key to save locally",
                    text: Binding(
                        get: { model.miniMaxAPIKeyDraft },
                        set: { model.miniMaxAPIKeyDraft = $0 }
                    )
                )
                .popLexKeyFieldStyle()
                .privacySensitive()
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundStyle(PopLexTheme.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                HStack(spacing: 10) {
                    Button {
                        model.saveMiniMaxAPIKey()
                    } label: {
                        Text("Save key locally")
                            .font(.custom("AvenirNext-DemiBold", size: 15))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(PopLexTheme.primaryBlue, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(model.miniMaxAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if model.miniMaxCanClearSavedKey {
                        Button {
                            model.clearMiniMaxAPIKey()
                        } label: {
                            Text("Clear saved key")
                                .font(.custom("AvenirNext-DemiBold", size: 15))
                                .foregroundStyle(PopLexTheme.primaryPink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(PopLexTheme.primaryPink.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let actionMessage = model.miniMaxActionMessage {
                    Text(actionMessage)
                        .font(.custom("AvenirNext-Regular", size: 13))
                        .foregroundStyle(PopLexTheme.primaryBlue)
                }

                Text("Nothing gets committed. `MINIMAX_API_KEY` also works and takes priority over the saved local key.")
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.58))
            }
        }
    }

    private var heroCard: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 14) {
                Text("PopLex")
                    .font(.custom("AvenirNext-Bold", size: 32))
                    .foregroundStyle(PopLexTheme.ink)

                Text("Bright little AI dictionary cards with explanation, examples, artwork, and tap-to-hear pronunciation.")
                    .font(.custom("AvenirNext-Regular", size: 17))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.82))

                HStack(spacing: 10) {
                    HeroChip(label: "Notebook saves", tint: PopLexTheme.primaryPink)
                    HeroChip(label: "Story mode", tint: PopLexTheme.primaryBlue)
                    HeroChip(label: "Flip cards", tint: PopLexTheme.primaryOrange)
                }
            }
        }
    }

    private var languageCard: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 16) {
                Text("Language setup")
                    .font(.custom("AvenirNext-DemiBold", size: 22))
                    .foregroundStyle(PopLexTheme.ink)

                Text("Pick the language you want explanations in, then the language you’re learning.")
                    .font(.custom("AvenirNext-Regular", size: 15))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.74))

                HStack(alignment: .top, spacing: 12) {
                    LanguageMenu(
                        title: "Native language",
                        selection: model.selectedNativeLanguage,
                        tint: PopLexTheme.chipColor(for: model.selectedNativeLanguageID)
                    ) { option in
                        model.selectedNativeLanguageID = option.id
                    }

                    LanguageMenu(
                        title: "Target language",
                        selection: model.selectedTargetLanguage,
                        tint: PopLexTheme.chipColor(for: model.selectedTargetLanguageID)
                    ) { option in
                        model.selectedTargetLanguageID = option.id
                    }
                }
            }
        }
    }

    private var composerCard: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Look up a word, phrase, or sentence")
                            .font(.custom("AvenirNext-DemiBold", size: 22))
                            .foregroundStyle(PopLexTheme.ink)

                        Text("Keep it short or go full sentence. PopLex handles both.")
                            .font(.custom("AvenirNext-Regular", size: 15))
                            .foregroundStyle(PopLexTheme.ink.opacity(0.74))
                    }

                    Spacer()

                    Button {
                        model.useSampleInput()
                    } label: {
                        Label("Surprise me", systemImage: "dice.fill")
                            .font(.custom("AvenirNext-DemiBold", size: 14))
                            .foregroundStyle(PopLexTheme.primaryBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.9), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.white.opacity(0.82))

                    if model.queryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Type something like “saudade”, “left on read”, or a full sentence you want unpacked.")
                            .font(.custom("AvenirNext-Regular", size: 16))
                            .foregroundStyle(PopLexTheme.ink.opacity(0.42))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 18)
                    }
                    TextEditor(
                        text: Binding(
                            get: { model.queryText },
                            set: { model.queryText = $0 }
                        )
                    )
                        .font(.custom("AvenirNext-Regular", size: 18))
                        .foregroundStyle(PopLexTheme.ink)
                        .scrollContentBackground(.hidden)
                        .focused($isComposerFocused)
                        .frame(minHeight: 118)
                        .padding(12)
                        .background(.clear)
                }
                .onChange(of: isComposerFocused) { _, isFocused in
                    if isFocused {
                        model.clearLookupFeedback()
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        model.performLookup()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if model.isLookingUp {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                                .symbolEffect(.bounce, value: model.currentResult?.id)
                        }

                        Text(model.isLookingUp ? "Cooking up the card..." : "Generate PopLex card")
                            .font(.custom("AvenirNext-Bold", size: 17))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [PopLexTheme.primaryPink, PopLexTheme.primaryOrange],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .disabled(model.queryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isLookingUp)

                if let imageBanner = model.imageBanner {
                    BannerBubble(
                        icon: "photo.artframe",
                        title: "Artwork",
                        message: imageBanner
                    )
                }
            }
        }
    }

    private var loadingCard: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 14) {
                Text("PopLex is building the card")
                    .font(.custom("AvenirNext-DemiBold", size: 22))
                    .foregroundStyle(PopLexTheme.ink)

                Text("Definition first, artwork right after. On supported devices the audio button will use the best available voice for the target language.")
                    .font(.custom("AvenirNext-Regular", size: 15))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.75))

                HStack(spacing: 12) {
                    LoadingPulseRow()

                    Text("Thinking, translating, and dressing the card up.")
                        .font(.custom("AvenirNext-DemiBold", size: 14))
                        .foregroundStyle(PopLexTheme.primaryBlue)
                }

                ProgressView()
                    .controlSize(.large)
                    .tint(PopLexTheme.primaryPink)

                if model.isGeneratingArtwork {
                    Text("Artwork is rendering now.")
                        .font(.custom("AvenirNext-Regular", size: 14))
                        .foregroundStyle(PopLexTheme.primaryBlue)
                }
            }
        }
    }
}

private struct HeroChip: View {
    let label: String
    let tint: Color

    var body: some View {
        Text(label)
            .font(.custom("AvenirNext-DemiBold", size: 13))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(0.14), in: Capsule())
    }
}

private struct LanguageMenu: View {
    let title: String
    let selection: LanguageOption
    let tint: Color
    let onSelect: (LanguageOption) -> Void

    var body: some View {
        Menu {
            ForEach(LanguageOption.popular) { option in
                Button {
                    onSelect(option)
                } label: {
                    HStack {
                        Text(option.fullLabel)
                        if option.id == selection.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(title.uppercased())
                    .font(.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.52))

                HStack(spacing: 10) {
                    Circle()
                        .fill(tint)
                        .frame(width: 12, height: 12)

                    Text(selection.fullLabel)
                        .font(.custom("AvenirNext-Medium", size: 16))
                        .foregroundStyle(PopLexTheme.ink)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(PopLexTheme.ink.opacity(0.6))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct BannerBubble: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        PopLexSurface {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(PopLexTheme.primaryBlue)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("AvenirNext-DemiBold", size: 17))
                        .foregroundStyle(PopLexTheme.ink)

                    Text(message)
                        .font(.custom("AvenirNext-Regular", size: 14))
                        .foregroundStyle(PopLexTheme.ink.opacity(0.74))
                }
            }
        }
    }
}

private struct LoadingPulseRow: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< 3, id: \.self) { index in
                Circle()
                    .fill(tint(for: index))
                    .frame(width: 12, height: 12)
                    .scaleEffect(isAnimating ? 1.0 : 0.6)
                    .offset(y: isAnimating ? -4 : 4)
                    .animation(
                        .easeInOut(duration: 0.55)
                            .repeatForever()
                            .delay(Double(index) * 0.12),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }

    private func tint(for index: Int) -> Color {
        switch index {
        case 0:
            return PopLexTheme.primaryPink
        case 1:
            return PopLexTheme.primaryOrange
        default:
            return PopLexTheme.primaryBlue
        }
    }
}
