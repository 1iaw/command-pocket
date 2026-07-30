import AppKit
import SwiftUI

@MainActor
final class FloatingPanelController: NSObject {
    private let store: CommandStore
    private var launcherPanel: NSPanel?
    private var commandPanel: NSPanel?
    private var isQuickAddPresented = false
    private var moveObserver: NSObjectProtocol?

    init(store: CommandStore) {
        self.store = store
        super.init()
    }

    func showLauncher() {
        if launcherPanel == nil {
            launcherPanel = makeLauncherPanel()
        }
        launcherPanel?.orderFrontRegardless()
    }

    func toggleCommandPanel() {
        if commandPanel?.isVisible == true {
            commandPanel?.orderOut(nil)
        } else {
            showCommandList()
        }
    }

    func showQuickAdd() {
        isQuickAddPresented = true
        showPanel()
        commandPanel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showCommandList() {
        isQuickAddPresented = false
        showPanel()
    }

    private func showPanel() {
        rebuildCommandPanel()
        positionCommandPanel()
        commandPanel?.orderFrontRegardless()
    }

    private func makeLauncherPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: savedLauncherFrame(),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false

        panel.contentView = NSHostingView(
            rootView: FloatingLauncherView { [weak self] in
                self?.toggleCommandPanel()
            }
        )

        moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { notification in
            guard let window = notification.object as? NSWindow else { return }
            UserDefaults.standard.set(window.frame.origin.x, forKey: "launcher.x")
            UserDefaults.standard.set(window.frame.origin.y, forKey: "launcher.y")
        }
        return panel
    }

    private func rebuildCommandPanel() {
        commandPanel?.close()

        let styleMask: NSWindow.StyleMask = isQuickAddPresented
            ? [.titled, .fullSizeContentView]
            : [.titled, .fullSizeContentView, .nonactivatingPanel]

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: isQuickAddPresented ? 430 : 470),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = true
        panel.isReleasedWhenClosed = false

        let root = CommandPanelView(
            quickAddInitiallyPresented: isQuickAddPresented,
            onRequestQuickAdd: { [weak self] in self?.showQuickAdd() },
            onClose: { [weak self] in self?.commandPanel?.orderOut(nil) }
        )
        .environmentObject(store)

        panel.contentView = NSHostingView(rootView: root)
        commandPanel = panel
    }

    private func positionCommandPanel() {
        guard let launcherFrame = launcherPanel?.frame,
              let panel = commandPanel,
              let screen = launcherPanel?.screen ?? NSScreen.main
        else { return }

        let visible = screen.visibleFrame
        var origin = NSPoint(
            x: launcherFrame.maxX - panel.frame.width,
            y: launcherFrame.minY - panel.frame.height - 8
        )

        if origin.y < visible.minY {
            origin.y = launcherFrame.maxY + 8
        }
        origin.x = min(max(origin.x, visible.minX), visible.maxX - panel.frame.width)
        origin.y = min(max(origin.y, visible.minY), visible.maxY - panel.frame.height)
        panel.setFrameOrigin(origin)
    }

    private func savedLauncherFrame() -> NSRect {
        let size = NSSize(width: 48, height: 48)
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "launcher.x") != nil,
           defaults.object(forKey: "launcher.y") != nil {
            return NSRect(
                x: defaults.double(forKey: "launcher.x"),
                y: defaults.double(forKey: "launcher.y"),
                width: size.width,
                height: size.height
            )
        }

        let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        return NSRect(
            x: visible.maxX - size.width - 16,
            y: visible.maxY - size.height - 80,
            width: size.width,
            height: size.height
        )
    }
}
