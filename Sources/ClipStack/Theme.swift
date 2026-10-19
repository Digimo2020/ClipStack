import SwiftUI
import AppKit

/// The four colour themes. Violet is the ClipStack brand colour.
enum ThemePreset: String, CaseIterable, Identifiable {
    case violet, ocean, emerald, sunset

    var id: String { rawValue }

    var name: String {
        switch self {
        case .violet: return "Violet"
        case .ocean: return "Ocean"
        case .emerald: return "Emerald"
        case .sunset: return "Sunset"
        }
    }

    private var rgb: (accent: [Double], deep: [Double], bgTop: [Double], bgBottom: [Double], tileTop: [Double], tileBottom: [Double]) {
        switch self {
        case .violet:  return ([0.56, 0.38, 0.99], [0.40, 0.26, 0.92], [0.16, 0.09, 0.40], [0.07, 0.05, 0.20], [0.62, 0.45, 1.00], [0.42, 0.28, 0.93])
        case .ocean:   return ([0.25, 0.62, 1.00], [0.12, 0.42, 0.95], [0.06, 0.17, 0.40], [0.03, 0.07, 0.20], [0.35, 0.72, 1.00], [0.13, 0.45, 0.95])
        case .emerald: return ([0.20, 0.78, 0.55], [0.08, 0.58, 0.42], [0.05, 0.24, 0.22], [0.03, 0.10, 0.12], [0.30, 0.85, 0.62], [0.08, 0.60, 0.45])
        case .sunset:  return ([1.00, 0.48, 0.38], [0.92, 0.28, 0.45], [0.36, 0.10, 0.22], [0.16, 0.05, 0.12], [1.00, 0.58, 0.40], [0.90, 0.28, 0.50])
        }
    }

    private func color(_ v: [Double]) -> Color { Color(red: v[0], green: v[1], blue: v[2]) }

    var accent: Color { color(rgb.accent) }
    var deep: Color { color(rgb.deep) }
    var bgTop: Color { color(rgb.bgTop) }
    var bgBottom: Color { color(rgb.bgBottom) }
    var tileTop: Color { color(rgb.tileTop) }
    var tileBottom: Color { color(rgb.tileBottom) }
    var nsAccent: NSColor { NSColor(red: rgb.accent[0], green: rgb.accent[1], blue: rgb.accent[2], alpha: 1) }
    var nsBorder: NSColor { NSColor(red: rgb.tileTop[0], green: rgb.tileTop[1], blue: rgb.tileTop[2], alpha: 0.55) }
}

final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()

    @Published var preset: ThemePreset {
        didSet { if !transient { UserDefaults.standard.set(preset.rawValue, forKey: "theme") } }
    }

    /// Changes the theme for this run only (nothing is saved).
    func setTemporarily(_ t: ThemePreset) { transient = true; preset = t }
    private var transient = false

    private init() {
        preset = ThemePreset(rawValue: UserDefaults.standard.string(forKey: "theme") ?? "") ?? .violet
    }
}

/// Colours used across the panel, settings and menu. They follow the chosen theme.
enum Theme {
    private static var p: ThemePreset { ThemeStore.shared.preset }

    static var accent: Color { p.accent }
    static var accentDeep: Color { p.deep }
    static var bgTop: Color { p.bgTop }
    static var bgBottom: Color { p.bgBottom }
    static var glass: Color { Color.white.opacity(0.06) }
    static var glassBorder: Color { Color.white.opacity(0.10) }
    static var textSecondary: Color { Color.white.opacity(0.55) }
    static var tile: LinearGradient {
        LinearGradient(colors: [p.tileTop, p.tileBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var bar: LinearGradient {
        LinearGradient(colors: [p.deep, p.tileTop], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Tiny helpers for the user preferences read outside SwiftUI.
enum Prefs {
    static func bool(_ key: String, _ fallback: Bool) -> Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? fallback
    }
    static func string(_ key: String, _ fallback: String) -> String {
        UserDefaults.standard.string(forKey: key) ?? fallback
    }
}

/// Re-draws the whole history panel when the theme changes.
struct ThemedHistory: View {
    @ObservedObject var themes = ThemeStore.shared
    let model: PanelModel

    var body: some View {
        HistoryView(model: model).id(themes.preset)
    }
}
