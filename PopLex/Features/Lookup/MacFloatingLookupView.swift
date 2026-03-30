#if os(macOS)
import SwiftUI

struct MacFloatingLookupView: View {
    @Environment(PopLexAppModel.self) private var model
    @FocusState private var isComposerFocused: Bool

    let layout: MacFloatingPanelLayout
    let toggleLayoutAction: () -> Void
    let reopenAction: () -> Void
    let openNotebookAction: () -> Void

    var body: some View {
        Group {
            if layout == .collapsed {
                collapsedBody
            } else {
                expandedBody
            }
        }
        .frame(width: layout.contentSize.width, height: layout.contentSize.height)
    }

    private var expandedBody: some View {
        ZStack {
            PopLexBackdrop()

            VStack(alignment: .leading, spacing: 14) {
                header
                composer

                if model.isLookingUp {
                    loadingState
                } else if let currentResult = model.currentResult {
                    resultPreview(currentResult)
                } else {
                    idleState
                }
            }
            .padding(14)
        }
    }

    private var collapsedBody: some View {
        ZStack {
            PopLexBackdrop()

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [PopLexTheme.primaryPink, PopLexTheme.primaryOrange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 3) {
                    Text(collapsedTitle)
                        .font(.custom("AvenirNext-Bold", size: 15))
                        .foregroundStyle(PopLexTheme.ink)
                        .lineLimit(1)

                    Text(collapsedSubtitle)
                        .font(.custom("AvenirNext-Regular", size: 12))
                        .foregroundStyle(PopLexTheme.ink.opacity(0.68))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Button(action: toggleLayoutAction) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(PopLexTheme.primaryBlue)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.86), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick PopLex")
                    .font(.custom("AvenirNext-Bold", size: 22))
                    .foregroundStyle(PopLexTheme.ink)

                Text("Main window is minimized. Keep the lookup flow right here.")
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.7))
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button(action: toggleLayoutAction) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(PopLexTheme.primaryPink)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.9), in: Circle())
                }
                .buttonStyle(.plain)

                Button(action: reopenAction) {
                    Text("Open Full App")
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(PopLexTheme.primaryBlue, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField(
                "Type a word, phrase, or sentence",
                text: Binding(
                    get: { model.queryText },
                    set: { model.queryText = $0 }
                ),
                axis: .vertical
            )
            .font(.custom("AvenirNext-Regular", size: 15))
            .foregroundStyle(PopLexTheme.ink)
            .lineLimit(2 ... 4)
            .textFieldStyle(.plain)
            .focused($isComposerFocused)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .onSubmit {
                submitLookup()
            }
            .onChange(of: isComposerFocused) { _, isFocused in
                if isFocused {
                    model.clearLookupFeedback()
                }
            }

            HStack(spacing: 8) {
                quickPill(
                    title: model.selectedNativeLanguage.nativeName,
                    tint: PopLexTheme.chipColor(for: model.selectedNativeLanguageID)
                )
                quickPill(
                    title: model.selectedTargetLanguage.displayName,
                    tint: PopLexTheme.chipColor(for: model.selectedTargetLanguageID)
                )

                Spacer(minLength: 0)

                Button(action: submitLookup) {
                    HStack(spacing: 8) {
                        if model.isLookingUp {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                        }

                        Text(model.isLookingUp ? "Loading" : "Look Up")
                            .font(.custom("AvenirNext-DemiBold", size: 13))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [PopLexTheme.primaryPink, PopLexTheme.primaryOrange],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
                .disabled(model.isLookingUp || model.queryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var loadingState: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text("Building your card")
                    .font(.custom("AvenirNext-DemiBold", size: 18))
                    .foregroundStyle(PopLexTheme.ink)

                HStack(spacing: 10) {
                    FloatingLoadingDots()

                    Text("Still cooking. This one takes a moment.")
                        .font(.custom("AvenirNext-DemiBold", size: 13))
                        .foregroundStyle(PopLexTheme.primaryBlue)
                }

                ProgressView()
                    .controlSize(.regular)
                    .tint(PopLexTheme.primaryPink)

                Text("Definition first. Artwork follows right after.")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.7))
            }
        }
    }

    private var idleState: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text("Ready when you are")
                    .font(.custom("AvenirNext-DemiBold", size: 18))
                    .foregroundStyle(PopLexTheme.ink)

                Text("Minimize the main window, keep this one on top, and do quick lookups without reopening the whole app.")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.72))

                if let statusBanner = model.statusBanner {
                    Text(statusBanner)
                        .font(.custom("AvenirNext-Regular", size: 13))
                        .foregroundStyle(PopLexTheme.primaryBlue)
                        .lineLimit(2)
                }
            }
        }
    }

    private func resultPreview(_ entry: NotebookEntry) -> some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.displayTerm)
                            .font(.custom("AvenirNext-Bold", size: 22))
                            .foregroundStyle(PopLexTheme.ink)
                            .lineLimit(1)

                        Text(entry.definition)
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .foregroundStyle(PopLexTheme.ink.opacity(0.78))
                            .lineLimit(3)
                    }

                    Spacer(minLength: 0)

                    Button {
                        model.pronunciationService.speak(entry.displayTerm, in: entry.targetLanguage)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(PopLexTheme.primaryBlue, in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    Button(action: reopenAction) {
                        Text("See Full Card")
                            .font(.custom("AvenirNext-DemiBold", size: 13))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(PopLexTheme.primaryBlue, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        if model.currentResultIsSaved {
                            openNotebookAction()
                        } else {
                            model.saveCurrentResult()
                        }
                    } label: {
                        Text(model.currentResultIsSaved ? "Open Notebook" : "Save")
                            .font(.custom("AvenirNext-DemiBold", size: 13))
                            .foregroundStyle(model.currentResultIsSaved ? PopLexTheme.primaryPink : PopLexTheme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                model.currentResultIsSaved ? PopLexTheme.primaryPink.opacity(0.12) : .white.opacity(0.82),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func quickPill(title: String, tint: Color) -> some View {
        Text(title)
            .font(.custom("AvenirNext-DemiBold", size: 11))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tint.opacity(0.12), in: Capsule())
    }

    private var collapsedTitle: String {
        if let currentResult = model.currentResult {
            return currentResult.displayTerm
        }

        return "Quick PopLex"
    }

    private var collapsedSubtitle: String {
        if model.isLookingUp {
            return "Building your card..."
        }

        if let currentResult = model.currentResult {
            return currentResult.definition
        }

        return "Click to expand and look up something"
    }

    private func submitLookup() {
        let trimmedText = model.queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !model.isLookingUp else {
            return
        }
        model.performLookup()
    }
}

private struct FloatingLoadingDots: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< 3, id: \.self) { index in
                Circle()
                    .fill(color(for: index))
                    .frame(width: 9, height: 9)
                    .scaleEffect(isAnimating ? 1.0 : 0.55)
                    .offset(y: isAnimating ? -3 : 3)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }

    private func color(for index: Int) -> Color {
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
#endif
