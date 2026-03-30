import SwiftUI

@main
struct PopLexApp: App {
    @State private var model = PopLexAppModel()
    #if os(macOS)
    @State private var floatingPanelController = MacFloatingPanelController()
    #endif

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            rootContent
        }
        .defaultSize(width: 1180, height: 860)
        #else
        WindowGroup {
            rootContent
        }
        #endif
    }

    private var rootContent: some View {
        ZStack {
            PopLexBackdrop()
            PopLexRootView()
                .frame(maxWidth: 1100, maxHeight: .infinity)
                .padding(.horizontal, 12)
        }
        .environment(model)
        #if os(macOS)
        .background {
            MainWindowAccessor { window in
                floatingPanelController.attach(mainWindow: window, model: model)
            }
        }
        #endif
    }
}
