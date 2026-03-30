#if os(macOS)
import AppKit
import SwiftUI

enum MacFloatingPanelLayout {
    case expanded
    case collapsed

    var contentSize: CGSize {
        switch self {
        case .expanded:
            return CGSize(width: 430, height: 320)
        case .collapsed:
            return CGSize(width: 280, height: 92)
        }
    }
}

@MainActor
final class MacFloatingPanelController: NSObject {
    private weak var mainWindow: NSWindow?
    private weak var model: PopLexAppModel?
    private var floatingPanel: PopLexFloatingPanel?
    private var layout: MacFloatingPanelLayout = .expanded

    func attach(mainWindow: NSWindow, model: PopLexAppModel) {
        if self.mainWindow !== mainWindow {
            NotificationCenter.default.removeObserver(self)
            self.mainWindow = mainWindow

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleMainWindowMiniaturized),
                name: NSWindow.didMiniaturizeNotification,
                object: mainWindow
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleMainWindowRestored),
                name: NSWindow.didDeminiaturizeNotification,
                object: mainWindow
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleMainWindowClosing),
                name: NSWindow.willCloseNotification,
                object: mainWindow
            )
        }

        self.model = model
        updateFloatingPanelContent()
    }

    func reopenMainWindow(select tab: AppTab = .lookup) {
        model?.selectedTab = tab

        if let mainWindow, mainWindow.isMiniaturized {
            mainWindow.deminiaturize(nil)
        }

        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        hideFloatingPanel()
    }

    func toggleLayout() {
        layout = layout == .expanded ? .collapsed : .expanded
        applyPanelLayout()
        updateFloatingPanelContent()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func handleMainWindowMiniaturized() {
        showFloatingPanel()
    }

    @objc
    private func handleMainWindowRestored() {
        hideFloatingPanel()
    }

    @objc
    private func handleMainWindowClosing() {
        hideFloatingPanel()
    }

    private func showFloatingPanel() {
        guard let model else {
            return
        }

        let panel = ensureFloatingPanel(for: model)
        applyPanelLayout()
        panel.orderFrontRegardless()
    }

    private func hideFloatingPanel() {
        floatingPanel?.orderOut(nil)
    }

    private func ensureFloatingPanel(for model: PopLexAppModel) -> PopLexFloatingPanel {
        if let floatingPanel {
            updateFloatingPanelContent()
            return floatingPanel
        }

        let panel = PopLexFloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 430, height: 320),
            styleMask: [.titled, .closable, .fullSizeContentView, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        floatingPanel = panel
        applyPanelLayout()
        updateFloatingPanelContent()
        return panel
    }

    private func updateFloatingPanelContent() {
        guard let floatingPanel, let model else {
            return
        }

        floatingPanel.contentViewController = NSHostingController(
            rootView: MacFloatingLookupView(
                layout: layout,
                toggleLayoutAction: { [weak self] in
                    self?.toggleLayout()
                },
                reopenAction: { [weak self] in
                    self?.reopenMainWindow()
                },
                openNotebookAction: { [weak self] in
                    self?.reopenMainWindow(select: .notebook)
                }
            )
            .environment(model)
        )
    }

    private func applyPanelLayout() {
        guard let floatingPanel else {
            return
        }

        floatingPanel.setContentSize(layout.contentSize)
        align(panel: floatingPanel)
    }

    private func align(panel: NSPanel) {
        let visibleFrame = mainWindow?.screen?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = CGPoint(
            x: visibleFrame.maxX - panel.frame.width - 24,
            y: visibleFrame.maxY - panel.frame.height - 28
        )
        panel.setFrameOrigin(origin)
    }
}

private final class PopLexFloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

struct MainWindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            resolve(from: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            resolve(from: nsView)
        }
    }

    private func resolve(from view: NSView) {
        guard let window = view.window else {
            return
        }
        onResolve(window)
    }
}
#endif
