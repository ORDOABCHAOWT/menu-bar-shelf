import AppKit
import Carbon

@MainActor
final class HotKeyController {
    enum InstallationState: Equatable {
        case available
        case unavailable(OSStatus)
    }

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let onPressed: @MainActor () -> Void
    private(set) var installationState: InstallationState = .unavailable(OSStatus(eventNotHandledErr))

    init(onPressed: @escaping @MainActor () -> Void) {
        self.onPressed = onPressed
        install()
    }

    isolated deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    private func install() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )
        guard handlerStatus == noErr else {
            installationState = .unavailable(handlerStatus)
            return
        }

        let hotKeyID = EventHotKeyID(signature: fourCharacterCode("MBSH"), id: 1)
        let modifiers = UInt32(cmdKey | optionKey | controlKey)
        let hotKeyStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_M),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard hotKeyStatus == noErr else {
            if let eventHandlerRef {
                RemoveEventHandler(eventHandlerRef)
                self.eventHandlerRef = nil
            }
            installationState = .unavailable(hotKeyStatus)
            return
        }

        installationState = .available
    }

    fileprivate func handlePress() {
        onPressed()
    }
}

private let hotKeyEventHandler: EventHandlerUPP = { _, event, userData in
    guard let event, let userData else {
        return noErr
    }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    guard status == noErr, hotKeyID.signature == fourCharacterCode("MBSH"), hotKeyID.id == 1 else {
        return noErr
    }

    let controller = Unmanaged<HotKeyController>.fromOpaque(userData).takeUnretainedValue()
    Task { @MainActor in
        controller.handlePress()
    }
    return noErr
}

private func fourCharacterCode(_ string: String) -> OSType {
    var result: OSType = 0
    for scalar in string.unicodeScalars.prefix(4) {
        result = (result << 8) + OSType(scalar.value)
    }
    return result
}
