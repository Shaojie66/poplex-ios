import SwiftUI

struct ResultCardView: View {
    let entry: NotebookEntry
    let artwork: PlatformImage?
    let isSaved: Bool
    let saveAction: () -> Void
    let pronunciationService: PronunciationService

    var body: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 18) {
                artworkBlock

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.displayTerm)
                            .font(.custom("AvenirNext-Bold", size: 30))
                            .foregroundStyle(PopLexTheme.ink)

                        HStack(spacing: 8) {
                            InfoPill(
                                title: entry.targetLanguage.displayName,
                                tint: PopLexTheme.chipColor(for: entry.targetLanguageID)
                            )
                            InfoPill(
                                title: "Explained in \(entry.nativeLanguage.nativeName)",
                                tint: PopLexTheme.primaryBlue
                            )
                        }
                    }

                    Spacer()

                    PronunciationButton {
                        pronunciationService.speak(entry.displayTerm, in: entry.targetLanguage)
                    }
                }

                SectionBlock(title: "What it means") {
                    Text(entry.definition)
                        .font(.custom("AvenirNext-Regular", size: 17))
                        .foregroundStyle(PopLexTheme.ink.opacity(0.84))
                }

                SectionBlock(title: "Try it like this") {
                    VStack(spacing: 12) {
                        ForEach(entry.examples) { example in
                            ExampleCard(
                                example: example,
                                language: entry.targetLanguage,
                                pronunciationService: pronunciationService
                            )
                        }
                    }
                }

                SectionBlock(title: "Usage vibe") {
                    Text(entry.usageNote)
                        .font(.custom("AvenirNext-Regular", size: 17))
                        .foregroundStyle(PopLexTheme.ink.opacity(0.84))
                }

                actionButtons

                Button(action: saveAction) {
                    HStack(spacing: 10) {
                        Image(systemName: isSaved ? "checkmark.seal.fill" : "bookmark.fill")
                        Text(isSaved ? "Saved in Notebook" : "Save to Notebook")
                            .font(.custom("AvenirNext-Bold", size: 16))
                    }
                    .foregroundStyle(isSaved ? PopLexTheme.primaryBlue : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        Group {
                            if isSaved {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(PopLexTheme.primaryBlue.opacity(0.12))
                            } else {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [PopLexTheme.primaryPink, PopLexTheme.primaryBlue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
    }

    private var artworkBlock: some View {
        Group {
            if let artwork {
                Image(platformImage: artwork)
                    .resizable()
                    .scaledToFill()
            } else {
                ConceptStickerView(
                    title: entry.displayTerm,
                    tint: PopLexTheme.chipColor(for: entry.targetLanguageID)
                )
            }
        }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 10) {
            ActionButton(label: "听", systemImage: "speaker.wave.2.fill", tint: PopLexTheme.primaryBlue) {
                pronunciationService.speak(entry.displayTerm, in: entry.targetLanguage)
            }

            ActionButton(label: "真题", systemImage: "doc.text.fill", tint: PopLexTheme.primaryPink) {
                // PR2 — exam functionality
            }
            .opacity(0.5)
            .overlay {
                Text("PR2")
                    .font(.custom("AvenirNext-DemiBold", size: 10))
                    .foregroundStyle(PopLexTheme.primaryPink)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(PopLexTheme.primaryPink.opacity(0.12), in: Capsule())
                    .offset(x: 28, y: -20)
            }
        }
    }
}

private struct SectionBlock<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("AvenirNext-DemiBold", size: 20))
                .foregroundStyle(PopLexTheme.ink)

            content
        }
    }
}

private struct ExampleCard: View {
    let example: ExampleLine
    let language: LanguageOption
    let pronunciationService: PronunciationService

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(example.targetText)
                    .font(.custom("AvenirNext-Medium", size: 16))
                    .foregroundStyle(PopLexTheme.ink)

                Spacer()

                PronunciationButton {
                    pronunciationService.speak(example.targetText, in: language)
                }
            }

            Text(example.nativeTranslation)
                .font(.custom("AvenirNext-Regular", size: 15))
                .foregroundStyle(PopLexTheme.ink.opacity(0.72))
        }
        .padding(16)
        .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct PronunciationButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(PopLexTheme.primaryBlue, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

private struct ActionButton: View {
    let label: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .black))
                Text(label)
                    .font(.custom("AvenirNext-DemiBold", size: 14))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(tint.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct InfoPill: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.custom("AvenirNext-DemiBold", size: 13))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(0.12), in: Capsule())
    }
}
