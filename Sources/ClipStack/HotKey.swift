import AppKit
import Carbon.HIToolbox

enum HotkeyPreset: String, CaseIterable, Identifiable {
    case cmdShiftV, cmdOptV, ctrlShiftV, ctrlOptV, optV

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cmdShiftV: return "⌘ ⇧ V"
        case .cmdOptV: return "⌘ ⌥ V"
        case .ctrlShiftV: return "⌃ ⇧ V"
        case .ctrlOptV: return "⌃ ⌥ V"
        case .optV: return "⌥ V"
        }
    }

    var modifiers: UInt32 {
        switch self {
        case .cmdShiftV: return UInt32(cmdKey | shiftKey)
        case .cmdOptV: return UInt32(cmdKey | optionKey)
        case .ctrlShiftV: return UInt32(controlKey | shiftKey)
        case .ctrlOptV: return UInt32(controlKey | optionKey)
        case .optV: return UInt32(optionKey)
        }
    }

    static var saved: HotkeyPreset {
        HotkeyPreset(rawValue: UserDefaults.standard.string(forKey: "hotkey") ?? "") ?? .cmdShiftV
    }
}

final class HotKeyManager {
    static let shared = HotKeyManager()

    var onTrigger: (() -> Void)?
    private var ref: EventHotKeyRef?
    private var handlerInstalled = false

    func register(_ preset: HotkeyPreset) {
        if !handlerInstalled {
            var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
                DispatchQueue.main.async { HotKeyManager.shared.onTrigger?() }
                return noErr
            }, 1, &spec, nil, nil)
            handlerInstalled = true
        }
        if let ref { UnregisterEventHotKey(ref) }
        let id = EventHotKeyID(signature: OSType(0x434C4950), id: 1)  // 'CLIP'
        RegisterEventHotKey(UInt32(kVK_ANSI_V), preset.modifiers, id, GetApplicationEventTarget(), 0, &ref)
        UserDefaults.standard.set(preset.rawValue, forKey: "hotkey")
    }
}
