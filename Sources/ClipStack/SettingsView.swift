import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var store: ClipboardStore
    @State private var hotkey = HotkeyPreset.saved
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var trusted = AXIsProcessTrusted()

    static let githubURL = URL(string: "https://github.com/Digimo2020")!

    static func promptAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    /// Clears a stale Accessibility entry (it goes out of date when the app binary is replaced).
    static func resetAccessibilityEntry() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        p.arguments = ["reset", "Accessibility", Bundle.main.bundleIdentifier ?? "com.fahim.clipstack"]
        try? p.run()
        p.waitUntilExit()
    }

    static var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }

    var body: some View {
        Form {
            Section("Shortcut") {
                Picker("Open clipboard history", selection: $hotkey) {
                    ForEach(HotkeyPreset.allCases) { Text($0.label).tag($0) }
                }
                .onChange(of: hotkey) { _, new in HotKeyManager.shared.register(new) }
                Text("⌘V is reserved for the system Paste, so history uses its own shortcut.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("History") {
                Stepper(value: $store.maxItems, in: ClipboardStore.minItems...ClipboardStore.maxItemsCap, step: 10) {
                    Text("Keep last \(store.maxItems) items")
                }
                Toggle("Pause capturing", isOn: $store.isPaused)
                Button("Clear history (keeps pinned)", role: .destructive) { store.clearUnpinned() }
            }
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in
                        do { on ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister() }
                        catch { launchAtLogin = SMAppService.mainApp.status == .enabled }
                    }
                HStack {
                    Image(systemName: trusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(trusted ? .green : .orange)
                    Text(trusted ? "Auto-paste enabled" : "Auto-paste needs Accessibility permission")
                    Spacer()
                    if !trusted {
                        Button("Grant…") { Self.promptAccessibility() }
                        Button("Repair…") {
                            Self.resetAccessibilityEntry()
                            Self.promptAccessibility()
                        }
                        .help("Use this if ClipStack is already switched on in Accessibility but still not working.")
                    }
                }
                if !trusted {
                    Text("Already switched on but still asking? Click Repair, then switch ClipStack on again.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                Text("ClipStack \(Self.version)")
                Text("·")
                Link(destination: Self.githubURL) {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .help("github.com/Digimo2020")
            }
            .font(.caption).foregroundStyle(.secondary)
            .padding(.bottom, 8)
        }
        .frame(width: 420, height: 430)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            trusted = AXIsProcessTrusted()
        }
    }
}
