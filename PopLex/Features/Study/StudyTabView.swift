import SwiftUI

struct StudyTabView: View {
    @Environment(PopLexAppModel.self) private var model
    @State private var selectedIndex = 0

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    studyHeader

                    if model.notebook.isEmpty {
                        emptyState
                    } else {
                        studyDeck

                        controls
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
            .onChange(of: model.notebook.count) { _, newCount in
                selectedIndex = min(selectedIndex, max(0, newCount - 1))
            }
            .popLexNavigationChromeHidden()
        }
    }

    private var safeSelectedIndex: Int {
        min(selectedIndex, max(0, model.notebook.count - 1))
    }

    @ViewBuilder
    private var studyDeck: some View {
        #if os(macOS)
        if let entry = model.notebook[safe: safeSelectedIndex] {
            StudyFlashcardView(
                entry: entry,
                artwork: model.artwork(for: entry),
                pronunciationService: model.pronunciationService
            )
            .frame(maxWidth: 560)
            .padding(.horizontal, 4)
            .onAppear {
                model.requestArtwork(for: entry)
            }
        }
        #else
        TabView(selection: $selectedIndex) {
            ForEach(Array(model.notebook.enumerated()), id: \.element.id) { index, entry in
                StudyFlashcardView(
                    entry: entry,
                    artwork: model.artwork(for: entry),
                    pronunciationService: model.pronunciationService
                )
                .padding(.horizontal, 4)
                .tag(index)
                .onAppear {
                    model.requestArtwork(for: entry)
                }
            }
        }
        .frame(height: 560)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
    }

    private var studyHeader: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("Study mode")
                    .font(.custom("AvenirNext-Bold", size: 30))
                    .foregroundStyle(PopLexTheme.ink)

                Text("Tap a card to flip it. Front side: target-language word plus image. Back side: native-language definition and a usable example.")
                    .font(.custom("AvenirNext-Regular", size: 16))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.76))
            }
        }
    }

    private var emptyState: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("Flashcards wake up after you save cards")
                    .font(.custom("AvenirNext-DemiBold", size: 24))
                    .foregroundStyle(PopLexTheme.ink)

                Text("Save a few lookup results to the notebook, then this tab turns them into flip cards automatically.")
                    .font(.custom("AvenirNext-Regular", size: 16))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.74))
            }
        }
    }

    private var controls: some View {
        PopLexSurface {
            HStack {
                Text("\(safeSelectedIndex + 1) / \(max(model.notebook.count, 1))")
                    .font(.custom("AvenirNext-Bold", size: 18))
                    .foregroundStyle(PopLexTheme.ink)

                Spacer()

                HStack(spacing: 10) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                            selectedIndex = max(0, safeSelectedIndex - 1)
                        }
                    } label: {
                        Image(systemName: "arrow.left")
                            .frame(width: 42, height: 42)
                    }
                    .buttonStyle(StudyControlStyle())
                    .disabled(safeSelectedIndex == 0)

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                            selectedIndex = min(model.notebook.count - 1, safeSelectedIndex + 1)
                        }
                    } label: {
                        Image(systemName: "arrow.right")
                            .frame(width: 42, height: 42)
                    }
                    .buttonStyle(StudyControlStyle())
                    .disabled(safeSelectedIndex >= model.notebook.count - 1)
                }
            }
        }
    }
}

private struct StudyFlashcardView: View {
    let entry: NotebookEntry
    let artwork: PlatformImage?
    let pronunciationService: PronunciationService

    @State private var isFlipped = false

    var body: some View {
        ZStack {
            front
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            back
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .animation(.spring(response: 0.48, dampingFraction: 0.84), value: isFlipped)
        .contentShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .onTapGesture {
            isFlipped.toggle()
        }
    }

    private var front: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 18) {
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
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.displayTerm)
                            .font(.custom("AvenirNext-Bold", size: 34))
                            .foregroundStyle(PopLexTheme.ink)

                        Text("Tap anywhere to flip")
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .foregroundStyle(PopLexTheme.ink.opacity(0.56))
                    }

                    Spacer()

                    Button {
                        pronunciationService.speak(entry.displayTerm, in: entry.targetLanguage)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(PopLexTheme.primaryBlue, in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                Text(entry.targetLanguage.displayName)
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .foregroundStyle(PopLexTheme.primaryPink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(PopLexTheme.primaryPink.opacity(0.12), in: Capsule())
            }
        }
    }

    private var back: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 18) {
                Text(entry.displayTerm)
                    .font(.custom("AvenirNext-Bold", size: 28))
                    .foregroundStyle(PopLexTheme.ink)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Definition")
                        .font(.custom("AvenirNext-DemiBold", size: 18))
                        .foregroundStyle(PopLexTheme.primaryPink)

                    Text(entry.definition)
                        .font(.custom("AvenirNext-Regular", size: 17))
                        .foregroundStyle(PopLexTheme.ink.opacity(0.82))
                }

                if let example = entry.examples.first {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Example")
                                .font(.custom("AvenirNext-DemiBold", size: 18))
                                .foregroundStyle(PopLexTheme.primaryBlue)

                            Spacer()

                            Button {
                                pronunciationService.speak(example.targetText, in: entry.targetLanguage)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 38, height: 38)
                                    .background(PopLexTheme.primaryBlue, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }

                        Text(example.targetText)
                            .font(.custom("AvenirNext-Medium", size: 16))
                            .foregroundStyle(PopLexTheme.ink)

                        Text(example.nativeTranslation)
                            .font(.custom("AvenirNext-Regular", size: 15))
                            .foregroundStyle(PopLexTheme.ink.opacity(0.72))
                    }
                    .padding(18)
                    .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                Spacer(minLength: 0)

                Text("Tap again to flip back")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.56))
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct StudyControlStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .black))
            .foregroundStyle(PopLexTheme.ink)
            .background(PopLexTheme.primaryOrange.opacity(configuration.isPressed ? 0.28 : 0.14), in: Circle())
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
