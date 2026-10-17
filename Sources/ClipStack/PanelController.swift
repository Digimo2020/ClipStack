import AppKit
import SwiftUI
import Combine
import Carbon.HIToolbox

enum ClipFilter: String, CaseIterable, Identifiable {
    case all = "All", text = "Text", images = "Images", links = "Links", pinned = "Pinned"
    var id: String { rawValue }
}

@MainActor
final class PanelModel: ObservableObject {
    let store: ClipboardStore
    @Published var query = ""
    @Published var filter: ClipFilter = .all
    @Published var selectedID: UUID?
    @Published var focusTick = 0

    var onActivate: ((ClipItem) -> Void)?
    var onClose: (() -> Void)?

    private var bag = Set<AnyCancellable>()

    init(store: ClipboardStore) {
        self.store = store
        store.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                    self?.normalizeSelection()
                }
            }
            .store(in: &bag)
        $query.dropFirst().sink { [weak self] _ in DispatchQueue.main.async { self?.selectFirst() } }.store(in: &bag)
        $filter.dropFirst().sink { [weak self] _ in DispatchQueue.main.async { self?.selectFirst() } }.store(in: &bag)
    }

    var visible: [ClipItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = store.items.filter { item in
            switch filter {
            case .all: break
            case .text: if item.kind != .text { return false }
            case .images: if item.kind != .image { return false }
            case .links: if !item.isLink { return false }
            case .pinned: if !item.pinned { return false }
            }
            if q.isEmpty { return true }
            return (item.text ?? "").localizedCaseInsensitiveContains(q)
                || (item.sourceName ?? "").localizedCaseInsensitiveContains(q)
        }
        // Pinned first, otherwise most recent first (store order).
        return filtered.filter(\.pinned) + filtered.filter { !$0.pinned }
    }

    func reset() {
        query = ""
        filter = .all
        selectFirst()
        focusTick += 1
    }

    func selectFirst() { selectedID = visible.first?.id }

    func normalizeSelection() {
        let v = visible
        if selectedID == nil || !v.contains(where: { $0.id == selectedID }) { selectedID = v.first?.id }
    }

    func move(_ delta: Int) {
        let v = visible
        guard !v.isEmpty else { return }
        let cur = v.firstIndex(where: { $0.id == selectedID }) ?? 0
        selectedID = v[min(max(cur + delta, 0), v.count - 1)].id
    }

    var selectedItem: ClipItem? {
        let v = visible
        return v.first(where: { $0.id == selectedID }) ?? v.first
    }

    func activateSelected() { if let i = selectedItem { onActivate?(i) } }

    func activate(index: Int) {
        let v = visible
        if index < v.count { onActivate?(v[index]) }
    }

    func deleteSelected() {
        guard let item = selectedItem else { return }
        let v = visible
        let idx = v.firstIndex(where: { $0.id == item.id }) ?? 0
        store.delete(item.id)
        let after = visible
        selectedID = after.isEmpty ? nil : after[min(idx, after.count - 1)].id
    }

    func togglePinSelected() {
        if let item = selectedItem { store.togglePin(item.id) }
    }
}

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class PanelController {
    let model: PanelModel
    private let panel: FloatingPanel
    private var keyMonitor: Any?
    private static var askedForAccessibility = false
    private let size = NSSize(width: 460, height: 600)

    var isVisible: Bool { panel.isVisible }

    init(store: ClipboardStore) {
        model = PanelModel(store: store)
        panel = FloatingPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let effect = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 22
        effect.layer?.cornerCurve = .continuous
        effect.layer?.masksToBounds = true
        effect.layer?.borderWidth = 1
        effect.layer?.borderColor = NSColor(red: 0.62, green: 0.45, blue: 1.0, alpha: 0.55).cgColor

        let host = NSHostingView(rootView: HistoryView(model: model))
        host.frame = effect.bounds
        host.autoresizingMask = [.width, .height]
        effect.addSubview(host)
        panel.contentView = effect

        model.onActivate = { [weak self] item in self?.paste(item) }
        model.onClose = { [weak self] in self?.hide() }

        NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: panel, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.hide() }
        }
    }

    func toggle() { panel.isVisible ? hide() : show() }

    func show() {
        model.reset()
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main
        if let vf = screen?.visibleFrame {
            let origin = NSPoint(x: vf.midX - size.width / 2, y: vf.midY - size.height / 2 + vf.height * 0.06)
            panel.setFrame(NSRect(origin: origin, size: size), display: true)
        }
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            panel.animator().alphaValue = 1
        }
        installKeyMonitor()
    }

    func hide() {
        removeKeyMonitor()
        panel.orderOut(nil)
    }

    private func paste(_ item: ClipItem) {
        model.store.copyToPasteboard(item)
        hide()
        guard AXIsProcessTrusted() else {
            // Copied; the user presses ⌘V until permission is granted. Ask at most once per launch,
            // never on every paste (a stale entry would otherwise nag forever).
            if !Self.askedForAccessibility {
                Self.askedForAccessibility = true
                let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                _ = AXIsProcessTrustedWithOptions(opts)
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            let src = CGEventSource(stateID: .combinedSessionState)
            let down = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
            let up = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
            down?.flags = .maskCommand
            up?.flags = .maskCommand
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
        }
    }

    // MARK: Keyboard

    private static let numberKeys: [Int] = [
        kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5,
        kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9,
    ]

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel.isVisible else { return event }
            let cmd = event.modifierFlags.contains(.command)
            let code = Int(event.keyCode)
            switch code {
            case kVK_DownArrow: self.model.move(1); return nil
            case kVK_UpArrow: self.model.move(-1); return nil
            case kVK_Return, kVK_ANSI_KeypadEnter: self.model.activateSelected(); return nil
            case kVK_Escape: self.hide(); return nil
            case kVK_Delete where cmd: self.model.deleteSelected(); return nil
            case kVK_ANSI_P where cmd: self.model.togglePinSelected(); return nil
            default:
                if cmd, let n = Self.numberKeys.firstIndex(of: code) {
                    self.model.activate(index: n)
                    return nil
                }
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor { NSEvent.removeMonitor(m) }
        keyMonitor = nil
    }
}
