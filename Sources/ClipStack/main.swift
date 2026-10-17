import AppKit
import SwiftUI

/// Branded header at the top of the menu-bar menu: logo, name, status and version.
struct MenuHeader: View {
    let paused: Bool
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 3) {
                Text("ClipStack")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                HStack(spacing: 5) {
                    Circle().fill(paused ? Color.orange : Color.green).frame(width: 6, height: 6)
                    Text(paused ? "Paused" : "Capturing")
                    Text("· \(count) items")
                }
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.72))
            }
            Spacer(minLength: 6)
            Text(SettingsView.version.components(separatedBy: " ").first ?? "")
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(0.18)))
        }
        .padding(.horizontal, 12)
        .frame(width: 270, height: 62)
        .background(
            LinearGradient(colors: [Color(red: 0.42, green: 0.28, blue: 0.93), Color(red: 0.62, green: 0.30, blue: 0.90)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let store = ClipboardStore.shared
    private var panel: PanelController!
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private var pauseItem: NSMenuItem!
    private var accessItem: NSMenuItem!
    private var showItem: NSMenuItem!
    private var headerHost: NSHostingView<MenuHeader>!

    func applicationDidFinishLaunching(_ notification: Notification) {
        panel = PanelController(store: store)
        store.start()

        if CommandLine.arguments.contains("--menu") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.statusItem.button?.performClick(nil) }
        }

        // Developer aid: render the panel off-screen to a PNG (no window is shown). Usage: --snapshot out.png [--images]
        if let i = CommandLine.arguments.firstIndex(of: "--snapshot"), i + 1 < CommandLine.arguments.count {
            let model = PanelModel(store: store)
            if CommandLine.arguments.contains("--images") { model.filter = .images }
            if CommandLine.arguments.contains("--emoji") { model.filter = .emoji }
            if let q = CommandLine.arguments.firstIndex(of: "--query"), q + 1 < CommandLine.arguments.count { model.query = CommandLine.arguments[q + 1] }
            model.selectFirst()
            let size = NSSize(width: 460, height: 600)
            let host = NSHostingView(rootView: HistoryView(model: model).frame(width: size.width, height: size.height).background(Color(red: 0.10, green: 0.06, blue: 0.26)))
            let win = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless, backing: .buffered, defer: false)
            win.contentView = host
            host.frame = NSRect(origin: .zero, size: size)
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.8))
            if let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
                host.cacheDisplay(in: host.bounds, to: rep)
                try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: CommandLine.arguments[i + 1]))
            }
            exit(0)
        }

        if CommandLine.arguments.contains("--show") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.panel.show()
                if CommandLine.arguments.contains("--images") { self.panel.model.filter = .images }
            }
        }

        HotKeyManager.shared.onTrigger = { [weak self] in self?.panel.toggle() }
        HotKeyManager.shared.register(HotkeyPreset.saved)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = Self.menuBarIcon()
        let menu = NSMenu()
        menu.delegate = self
        func add(_ title: String, _ symbol: String, _ action: Selector?, key: String = "") -> NSMenuItem {
            let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key)
            item.image = Self.brandIcon(symbol)
            if action != nil, action != #selector(NSApplication.terminate(_:)) { item.target = self }
            return item
        }
        headerHost = NSHostingView(rootView: MenuHeader(paused: false, count: 0))
        headerHost.frame = NSRect(x: 0, y: 0, width: 270, height: 62)
        let header = NSMenuItem()
        header.view = headerHost
        menu.addItem(header)
        menu.addItem(.separator())
        showItem = add("Show Clipboard History", "doc.on.clipboard", #selector(showPanel))
        _ = add("Emoji Picker", "face.smiling", #selector(showEmoji))
        menu.addItem(.separator())
        pauseItem = add("Pause Capturing", "pause.circle", #selector(togglePause))
        _ = add("Clear History", "trash", #selector(clearHistory))
        menu.addItem(.separator())
        accessItem = add("Enable Auto-Paste…", "exclamationmark.triangle.fill", #selector(showSettings))
        accessItem.isHidden = true
        _ = add("Settings…", "gearshape", #selector(showSettings), key: ",")
        _ = add("GitHub · Digimo2020", "chevron.left.forwardslash.chevron.right", #selector(openGitHub))
        menu.addItem(.separator())
        _ = add("Quit ClipStack", "power", #selector(NSApplication.terminate(_:)), key: "q")
        statusItem.menu = menu
    }

    /// The brand logo (purple clipboard) at menu-bar size, cropped to the squircle so it matches the app icon.
    private static func menuBarIcon() -> NSImage {
        guard let icon = NSApp.applicationIconImage else {
            return NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipStack") ?? NSImage()
        }
        let side = icon.size.width
        let crop = NSRect(x: side * 0.0977, y: side * 0.0977, width: side * 0.8047, height: side * 0.8047)
        let img = NSImage(size: NSSize(width: 19, height: 19), flipped: false) { rect in
            icon.draw(in: rect, from: crop, operation: .sourceOver, fraction: 1)
            return true
        }
        img.isTemplate = false
        img.accessibilityDescription = "ClipStack"
        return img
    }

    /// Purple SF Symbol so the menu carries the brand colour.
    private static func brandIcon(_ symbol: String) -> NSImage? {
        let cfg = NSImage.SymbolConfiguration(paletteColors: [NSColor(red: 0.56, green: 0.38, blue: 0.99, alpha: 1)])
        return NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?.withSymbolConfiguration(cfg)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        accessItem.isHidden = AXIsProcessTrusted()
        pauseItem.title = store.isPaused ? "Resume Capturing" : "Pause Capturing"
        pauseItem.image = Self.brandIcon(store.isPaused ? "play.circle" : "pause.circle")
        headerHost.rootView = MenuHeader(paused: store.isPaused, count: store.items.count)
        // Show the current shortcut next to the item (display only; the global hotkey does the work).
        let preset = HotkeyPreset.saved
        showItem.keyEquivalent = "v"
        showItem.keyEquivalentModifierMask = preset.menuModifiers
    }

    @objc private func showPanel() {
        // Let the menu finish closing so focus returns to the previous app first.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { self.panel.show() }
    }

    @objc private func openGitHub() { NSWorkspace.shared.open(SettingsView.githubURL) }
    @objc private func showEmoji() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.panel.show()
            self.panel.model.filter = .emoji
        }
    }
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
