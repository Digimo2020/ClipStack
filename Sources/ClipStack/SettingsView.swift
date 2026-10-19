import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var store: ClipboardStore
    @ObservedObject var themes = ThemeStore.shared
    @State private var hotkey = HotkeyPreset.saved
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var trusted = AXIsProcessTrusted()
    @AppStorage("autoPaste") private var autoPaste = true
    @AppStorage("captureImages") private var captureImages = true
    @AppStorage("ignorePasswordManagers") private var ignorePasswordManagers = true
    @AppStorage("panelSize") private var panelSize = "regular"
    @AppStorage("panelPosition") private var panelPosition = "center"

    static let githubURL = URL(string: "https://github.com/Digimo2020/ClipStack")!
    static let releasesURL = URL(string: "https://github.com/Digimo2020/ClipStack/releases/latest")!

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

    private var versionShort: String { Self.version.components(separatedBy: " ").first ?? Self.version }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header

                SettingsCard(title: "Appearance", symbol: "paintpalette.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theme").font(.system(size: 13, weight: .medium))
                        HStack(spacing: 18) {
                            ForEach(ThemePreset.allCases) { t in swatch(t) }
                            Spacer()
                        }
                    }
                    .padding(14)
                    divider
                    SettingRow("Panel size", "How big the history window opens") {
                        Pills(options: [("compact", "Compact"), ("regular", "Regular"), ("large", "Large")], selection: $panelSize)
                    }
                    divider
                    SettingRow("Opens at", "Where the window appears") {
                        Pills(options: [("center", "Screen centre"), ("cursor", "Mouse cursor")], selection: $panelPosition)
                    }
                }

                SettingsCard(title: "Shortcut & paste", symbol: "keyboard.fill") {
                    SettingRow("Open clipboard history", "⌘V stays the normal Paste, so history uses its own keys") {
                        Picker("", selection: $hotkey) {
                            ForEach(HotkeyPreset.allCases) { Text($0.label).tag($0) }
                        }
                        .labelsHidden()
                        .frame(width: 110)
                        .onChange(of: hotkey) { _, new in HotKeyManager.shared.register(new) }
                    }
                    divider
                    SettingRow("Paste automatically", "Pick an item and it is pasted for you. Off = copy only") {
                        Toggle("", isOn: $autoPaste).labelsHidden().toggleStyle(.switch).tint(Theme.accent)
                    }
                    divider
                    permissionRow
                }

                SettingsCard(title: "History", symbol: "clock.arrow.circlepath") {
                    SettingRow("Items to keep", "Pinned items are never removed") {
                        MiniStepper(value: $store.maxItems, range: ClipboardStore.minItems...ClipboardStore.maxItemsCap, step: 10)
                    }
                    divider
                    SettingRow("Save images", "Screenshots and copied pictures") {
                        Toggle("", isOn: $captureImages).labelsHidden().toggleStyle(.switch).tint(Theme.accent)
                    }
                    divider
                    SettingRow("Ignore password managers", "Never save what you copy from 1Password, Bitwarden and similar") {
                        Toggle("", isOn: $ignorePasswordManagers).labelsHidden().toggleStyle(.switch).tint(Theme.accent)
                    }
                    divider
                    SettingRow("Pause capturing", "Stop saving new copies for now") {
                        Toggle("", isOn: $store.isPaused).labelsHidden().toggleStyle(.switch).tint(Theme.accent)
                    }
                    divider
                    SettingRow("Clear history", "Removes everything except pinned items") {
                        ActionButton("Clear", role: .destructive) { store.clearUnpinned() }
                    }
                }

                SettingsCard(title: "General", symbol: "gearshape.fill") {
                    SettingRow("Launch at login", "Start ClipStack when you sign in") {
                        Toggle("", isOn: $launchAtLogin).labelsHidden().toggleStyle(.switch).tint(Theme.accent)
                            .onChange(of: launchAtLogin) { _, on in
                                do { on ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister() }
                                catch { launchAtLogin = SMAppService.mainApp.status == .enabled }
                            }
                    }
                }

                SettingsCard(title: "About", symbol: "info.circle.fill") {
                    SettingRow("Version", nil) {
                        Text(Self.version).font(.system(size: 12, design: .monospaced)).foregroundStyle(Theme.textSecondary)
                    }
                    divider
                    SettingRow("Updates", "Download the latest release") {
                        Link(destination: Self.releasesURL) { LinkLabel("Releases", "arrow.down.circle") }
                    }
                    divider
                    SettingRow("Source code", "github.com/Digimo2020/ClipStack") {
                        Link(destination: Self.githubURL) { LinkLabel("GitHub", "chevron.left.forwardslash.chevron.right") }
                    }
                    divider
                    SettingRow("Quit ClipStack", nil) {
                        ActionButton("Quit") { NSApp.terminate(nil) }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 44)
            .padding(.bottom, 24)
        }
        .frame(width: 520, height: 700)
        .background(
            ZStack {
                LinearGradient(colors: [Theme.bgTop, Theme.bgBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [Theme.accent.opacity(0.30), .clear], center: .topTrailing, startRadius: 0, endRadius: 420)
            }
        )
        .environment(\.colorScheme, .dark)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            trusted = AXIsProcessTrusted()
        }
    }

    // MARK: Pieces

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 3) {
                Text("ClipStack").font(.system(size: 24, weight: .heavy))
                Text("Clipboard history for your Mac").font(.system(size: 12.5)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text(versionShort)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(Theme.tile))
        }
    }

    private var divider: some View { Divider().overlay(Color.white.opacity(0.07)).padding(.horizontal, 14) }

    private var permissionRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: trusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(trusted ? Color.green : Color.orange)
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 2) {
                    Text(trusted ? "Auto-paste is allowed" : "Auto-paste needs Accessibility permission").font(.system(size: 13, weight: .medium))
                    Text(trusted ? "macOS lets ClipStack paste into your apps" : "Without it ClipStack only copies, and you press ⌘V")
                        .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if !trusted {
                    ActionButton("Grant") { Self.promptAccessibility() }
                    ActionButton("Repair") {
                        Self.resetAccessibilityEntry()
                        Self.promptAccessibility()
                    }
                }
            }
            if !trusted {
                Text("Already switched on but still asking? Click Repair, then switch ClipStack on again.")
                    .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(14)
    }

    private func swatch(_ t: ThemePreset) -> some View {
        let on = themes.preset == t
        return Button { withAnimation(.easeOut(duration: 0.15)) { themes.preset = t } } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [t.tileTop, t.tileBottom], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 38, height: 38)
                    if on { Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundStyle(.white) }
                }
                .overlay(Circle().stroke(Color.white.opacity(on ? 0.95 : 0.15), lineWidth: on ? 2.5 : 1).frame(width: 46, height: 46))
                .shadow(color: on ? t.accent.opacity(0.6) : .clear, radius: 8)
                Text(t.name).font(.system(size: 11, weight: on ? .bold : .medium)).foregroundStyle(on ? Color.white : Theme.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(t.name) theme")
    }
}

// MARK: - Building blocks

struct SettingsCard<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: symbol).font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.accent)
                Text(title.uppercased()).font(.system(size: 11, weight: .bold)).tracking(0.9).foregroundStyle(Theme.textSecondary)
            }
            .padding(.leading, 4)
            VStack(spacing: 0) { content }
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.glass))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.glassBorder, lineWidth: 1))
        }
    }
}

struct SettingRow<Control: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var control: Control

    init(_ title: String, _ subtitle: String?, @ViewBuilder control: () -> Control) {
        self.title = title
        self.subtitle = subtitle
        self.control = control()
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium))
                if let subtitle { Text(subtitle).font(.system(size: 11)).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true) }
            }
            Spacer(minLength: 10)
            control
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

/// Capsule buttons for choosing one of a few options (same look as the filter pills in the panel).
struct Pills: View {
    let options: [(String, String)]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 5) {
            ForEach(options, id: \.0) { key, label in
                let on = selection == key
                Button { selection = key } label: {
                    Text(label)
                        .font(.system(size: 11.5, weight: .semibold))
                        .padding(.horizontal, 11).padding(.vertical, 5)
                        .background(Capsule().fill(on ? AnyShapeStyle(Theme.tile) : AnyShapeStyle(Color.white.opacity(0.07))))
                        .overlay(Capsule().stroke(on ? Color.white.opacity(0.25) : Color.white.opacity(0.10), lineWidth: 1))
                        .foregroundStyle(on ? Color.white : Color.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct MiniStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        HStack(spacing: 8) {
            stepButton("minus") { value = max(range.lowerBound, value - step) }
            Text("\(value)").font(.system(size: 13, weight: .bold, design: .rounded)).frame(minWidth: 36)
            stepButton("plus") { value = min(range.upperBound, value + step) }
        }
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 11, weight: .bold))
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.white.opacity(0.10)))
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct ActionButton: View {
    let title: String
    var role: ButtonRole? = nil
    let action: () -> Void

    init(_ title: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Capsule().fill(role == .destructive ? AnyShapeStyle(Color.red.opacity(0.28)) : AnyShapeStyle(Theme.tile)))
                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

struct LinkLabel: View {
    let title: String
    let symbol: String
    init(_ title: String, _ symbol: String) { self.title = title; self.symbol = symbol }

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.09)))
            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
            .foregroundStyle(.white)
    }
}
