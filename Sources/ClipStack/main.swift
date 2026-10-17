import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let store = ClipboardStore.shared
    private var panel: PanelController!
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private var pauseItem: NSMenuItem!
    private var accessItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        panel = PanelController(store: store)
        store.start()

        HotKeyManager.shared.onTrigger = { [weak self] in self?.panel.toggle() }
        HotKeyManager.shared.register(HotkeyPreset.saved)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipStack")
        let menu = NSMenu()
        menu.delegate = self
        func add(_ title: String, _ symbol: String, _ action: Selector?, key: String = "") -> NSMenuItem {
            let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key)
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            if action != nil, action != #selector(NSApplication.terminate(_:)) { item.target = self }
            return item
        }
        _ = add("Show Clipboard History", "doc.on.clipboard", #selector(showPanel))
        menu.addItem(.separator())
        pauseItem = add("Pause Capturing", "pause.circle", #selector(togglePause))
        _ = add("Clear History", "trash", #selector(clearHistory))
        menu.addItem(.separator())
        accessItem = add("Enable Auto-Paste…", "exclamationmark.triangle.fill", #selector(showSettings))
        accessItem.isHidden = true
        _ = add("Settings…", "gearshape", #selector(showSettings), key: ",")
        _ = add("GitHub · Digimo2020", "chevron.left.forwardslash.chevron.right", #selector(openGitHub))
        let ver = add("Version \(SettingsView.version)", "info.circle", nil)
        ver.isEnabled = false
        menu.addItem(.separator())
        _ = add("Quit ClipStack", "power", #selector(NSApplication.terminate(_:)), key: "q")
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        accessItem.isHidden = AXIsProcessTrusted()
        pauseItem.title = store.isPaused ? "Resume Capturing" : "Pause Capturing"
        pauseItem.image = NSImage(systemSymbolName: store.isPaused ? "play.circle" : "pause.circle", accessibilityDescription: nil)
    }

    @objc private func showPanel() {
        // Let the menu finish closing so focus returns to the previous app first.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { self.panel.show() }
    }

    @objc private func openGitHub() { NSWorkspace.shared.open(SettingsView.githubURL) }
    @objc private func togglePause() { store.isPaused.toggle() }
    @objc private func clearHistory() { store.clearUnpinned() }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(store: store)))
            w.title = "ClipStack Settings"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            settingsWindow = w
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}
