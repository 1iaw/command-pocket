import Carbon
import Foundation

final class HotKeyManager {
    private var eventHandler: EventHandlerRef?
    private var toggleHotKey: EventHotKeyRef?
    private var addHotKey: EventHotKeyRef?
    private var onToggle: (() -> Void)?
    private var onQuickAdd: (() -> Void)?

    func registerDefaults(onToggle: @escaping () -> Void, onQuickAdd: @escaping () -> Void) {
        self.onToggle = onToggle
        self.onQuickAdd = onQuickAdd

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                DispatchQueue.main.async {
                    if hotKeyID.id == 1 {
                        manager.onToggle?()
                    } else if hotKeyID.id == 2 {
                        manager.onQuickAdd?()
                    }
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        let signature = OSType(0x434D4450) // CMDP
        var toggleID = EventHotKeyID(signature: signature, id: 1)
        RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(optionKey),
            toggleID,
            GetApplicationEventTarget(),
            0,
            &toggleHotKey
        )

        var addID = EventHotKeyID(signature: signature, id: 2)
        RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(optionKey | shiftKey),
            addID,
            GetApplicationEventTarget(),
            0,
            &addHotKey
        )
    }

    deinit {
        if let toggleHotKey { UnregisterEventHotKey(toggleHotKey) }
        if let addHotKey { UnregisterEventHotKey(addHotKey) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
}

