import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = CommandStore()

    private var panelController: FloatingPanelController?
    private var hotKeyManager: HotKeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = FloatingPanelController(store: store)
        panelController = controller
        controller.showLauncher()

        let hotKeys = HotKeyManager()
        hotKeys.registerDefaults(
            onToggle: { [weak controller] in
                Task { @MainActor in controller?.toggleCommandPanel() }
            },
            onQuickAdd: { [weak controller] in
                Task { @MainActor in controller?.showQuickAdd() }
            }
        )
        hotKeyManager = hotKeys
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.save()
    }
}

