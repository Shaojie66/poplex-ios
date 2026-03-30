import SwiftUI

enum AppTab: Hashable {
    case lookup
    case notebook
    case study
    case mistakes
}

struct PopLexRootView: View {
    @Environment(PopLexAppModel.self) private var model

    var body: some View {
        TabView(
            selection: Binding(
                get: { model.selectedTab },
                set: { model.selectedTab = $0 }
            )
        ) {
            LookupTabView()
                .tag(AppTab.lookup)
                .tabItem {
                    Label("Lookup", systemImage: "sparkles.rectangle.stack.fill")
                }

            NotebookTabView()
                .tag(AppTab.notebook)
                .tabItem {
                    Label("Notebook", systemImage: "book.pages.fill")
                }

            StudyTabView()
                .tag(AppTab.study)
                .tabItem {
                    Label("Study", systemImage: "rectangle.on.rectangle.angled.fill")
                }

            MistakeTabView()
                .tag(AppTab.mistakes)
                .tabItem {
                    Label("错题", systemImage: "xmark.circle.fill")
                }
        }
        .tint(PopLexTheme.primaryPink)
    }
}
