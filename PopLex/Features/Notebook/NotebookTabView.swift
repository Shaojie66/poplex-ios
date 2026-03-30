import SwiftUI

struct NotebookTabView: View {
    @Environment(PopLexAppModel.self) private var model
    @State private var selectedEntry: NotebookEntry?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    notebookHeader

                    if let storyBanner = model.storyBanner {
                        notebookBanner(title: "Story mode", icon: "theatermasks.fill", message: storyBanner)
                    }

                    if let story = model.currentStory {
                        NotebookStoryCard(story: story)
                    }

                    if model.notebook.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(model.notebook) { entry in
                                NotebookEntryCard(
                                    entry: entry,
                                    artwork: model.artwork(for: entry),
                                    openAction: {
                                        selectedEntry = entry
                                    },
                                    deleteAction: {
                                        model.remove(entry)
                                    },
                                    pronunciationService: model.pronunciationService
                                )
                                .onAppear {
                                    model.requestArtwork(for: entry)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
            .popLexNavigationChromeHidden()
            .sheet(item: $selectedEntry) { entry in
                NavigationStack {
                    ScrollView(showsIndicators: false) {
                        ResultCardView(
                            entry: entry,
                            artwork: model.artwork(for: entry),
                            isSaved: true,
                            saveAction: {},
                            onExamTap: model.startExam,
                            pronunciationService: model.pronunciationService
                        )
                        .padding(18)
                    }
                    .background(PopLexBackdrop())
                    .navigationTitle("Saved card")
                    .popLexSheetTitleStyle()
                    .onAppear {
                        model.requestArtwork(for: entry)
                    }
                }
                #if os(iOS)
                .presentationDetents([.large])
                #endif
            }
        }
    }

    private var notebookHeader: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 16) {
                Text("Notebook")
                    .font(.custom("AvenirNext-Bold", size: 30))
                    .foregroundStyle(PopLexTheme.ink)

                Text("Save any card, then ask PopLex to mash the notebook terms into one memorable little story.")
                    .font(.custom("AvenirNext-Regular", size: 16))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.78))

                Button {
                    model.generateStory()
                } label: {
                    HStack(spacing: 10) {
                        if model.isGeneratingStory {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "wand.and.stars")
                        }

                        Text(model.isGeneratingStory ? "Writing your story..." : "Make up a story")
                            .font(.custom("AvenirNext-Bold", size: 16))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            colors: [PopLexTheme.primaryBlue, PopLexTheme.primaryPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .disabled(model.notebook.isEmpty || model.isGeneratingStory)
            }
        }
    }

    private var emptyState: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("Nothing saved yet")
                    .font(.custom("AvenirNext-DemiBold", size: 24))
                    .foregroundStyle(PopLexTheme.ink)

                Text("When you hit “Save to Notebook” on a lookup card, it lands here for later review, story mode, and flashcards.")
                    .font(.custom("AvenirNext-Regular", size: 16))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.74))
            }
        }
    }

    private func notebookBanner(title: String, icon: String, message: String) -> some View {
        PopLexSurface {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(PopLexTheme.primaryPink)

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

private struct NotebookStoryCard: View {
    let story: NotebookStoryPayload

    var body: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 14) {
                Text(story.title)
                    .font(.custom("AvenirNext-Bold", size: 24))
                    .foregroundStyle(PopLexTheme.ink)

                Text(story.story)
                    .font(.custom("AvenirNext-Regular", size: 16))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.82))

                Text(story.memoryHook)
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .foregroundStyle(PopLexTheme.primaryPink)
            }
        }
    }
}

private struct NotebookEntryCard: View {
    let entry: NotebookEntry
    let artwork: PlatformImage?
    let openAction: () -> Void
    let deleteAction: () -> Void
    let pronunciationService: PronunciationService

    var body: some View {
        PopLexSurface {
            HStack(alignment: .top, spacing: 16) {
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
                .frame(width: 96, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.displayTerm)
                                .font(.custom("AvenirNext-Bold", size: 22))
                                .foregroundStyle(PopLexTheme.ink)

                            Text(entry.definition)
                                .font(.custom("AvenirNext-Regular", size: 14))
                                .foregroundStyle(PopLexTheme.ink.opacity(0.72))
                                .lineLimit(3)
                        }

                        Spacer()

                        VStack(spacing: 8) {
                            Button {
                                pronunciationService.speak(entry.displayTerm, in: entry.targetLanguage)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(.white)
                                    .frame(width: 34, height: 34)
                                    .background(PopLexTheme.primaryBlue, in: Circle())
                            }
                            .buttonStyle(.plain)

                            Button(role: .destructive, action: deleteAction) {
                                Image(systemName: "trash.fill")
                                    .foregroundStyle(PopLexTheme.primaryPink)
                                    .frame(width: 34, height: 34)
                                    .background(PopLexTheme.primaryPink.opacity(0.12), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(entry.targetLanguage.nativeName)
                            .font(.custom("AvenirNext-DemiBold", size: 13))
                            .foregroundStyle(PopLexTheme.chipColor(for: entry.targetLanguageID))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(PopLexTheme.chipColor(for: entry.targetLanguageID).opacity(0.12), in: Capsule())

                        Text(entry.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.custom("AvenirNext-Regular", size: 12))
                            .foregroundStyle(PopLexTheme.ink.opacity(0.54))
                    }
                }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture(perform: openAction)
    }
}
