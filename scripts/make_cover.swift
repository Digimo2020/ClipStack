// Generates docs/cover.png. Usage: swift scripts/make_cover.swift <icon.icns> <out.png>
import AppKit

let W: CGFloat = 1600, H: CGFloat = 800
let img = NSImage(size: NSSize(width: W, height: H))
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

NSGradient(colors: [NSColor(red: 0.20, green: 0.17, blue: 0.55, alpha: 1), NSColor(red: 0.50, green: 0.22, blue: 0.85, alpha: 1)])!
    .draw(in: CGRect(x: 0, y: 0, width: W, height: H), angle: -25)
// soft glows
for (x, y, r, a) in [(1250.0, 650.0, 420.0, 0.22), (200.0, 100.0, 360.0, 0.14)] {
    NSGradient(colors: [NSColor.white.withAlphaComponent(a), NSColor.white.withAlphaComponent(0)])!
        .draw(fromCenter: NSPoint(x: x, y: y), radius: 0, toCenter: NSPoint(x: x, y: y), radius: r, options: [])
}

func text(_ s: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat, weight: NSFont.Weight, color: NSColor, mono: Bool = false) {
    let font = mono ? NSFont.monospacedSystemFont(ofSize: size, weight: weight) : NSFont.systemFont(ofSize: size, weight: weight)
    NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color]).draw(at: NSPoint(x: x, y: y))
}

if let icon = NSImage(contentsOfFile: CommandLine.arguments[1]) {
    icon.draw(in: CGRect(x: 90, y: 470, width: 240, height: 240))
}
text("ClipStack", 90, 340, size: 130, weight: .heavy, color: .white)
text("Clipboard history for your Mac.", 94, 280, size: 44, weight: .medium, color: NSColor.white.withAlphaComponent(0.88))
text("Copy anything. Press the shortcut. Paste any of your last 50 copies.", 94, 225, size: 26, weight: .regular, color: NSColor.white.withAlphaComponent(0.7))

// key caps
var kx: CGFloat = 94
for k in ["⌘", "⇧", "V"] {
    let r = CGRect(x: kx, y: 110, width: 84, height: 84)
    let p = NSBezierPath(roundedRect: r, xRadius: 20, yRadius: 20)
    NSColor.white.withAlphaComponent(0.18).setFill(); p.fill()
    NSColor.white.withAlphaComponent(0.45).setStroke(); p.lineWidth = 2; p.stroke()
    text(k, kx + (k == "V" ? 26 : 22), 126, size: 50, weight: .semibold, color: .white)
    kx += 102
}
text("opens your history", kx + 14, 134, size: 30, weight: .medium, color: NSColor.white.withAlphaComponent(0.85))

// mock panel
let panel = CGRect(x: 960, y: 70, width: 540, height: 660)
ctx.saveGState()
let sh = NSShadow(); sh.shadowColor = NSColor.black.withAlphaComponent(0.4); sh.shadowOffset = NSSize(width: 0, height: -20); sh.shadowBlurRadius = 50; sh.set()
NSColor.white.withAlphaComponent(0.94).setFill()
NSBezierPath(roundedRect: panel, xRadius: 34, yRadius: 34).fill()
ctx.restoreGState()
let ink = NSColor(red: 0.12, green: 0.12, blue: 0.2, alpha: 1)
let sub = NSColor(red: 0.45, green: 0.45, blue: 0.55, alpha: 1)
// search
NSColor(red: 0.93, green: 0.93, blue: 0.96, alpha: 1).setFill()
NSBezierPath(roundedRect: CGRect(x: 990, y: 650, width: 480, height: 56), xRadius: 16, yRadius: 16).fill()
text("🔍  Search clipboard history", 1012, 664, size: 24, weight: .regular, color: sub)
// chips
var cx: CGFloat = 990
for (i, c) in ["All", "Text", "Images", "Links"].enumerated() {
    let w = CGFloat(c.count) * 15 + 44
    (i == 0 ? NSColor(red: 0.38, green: 0.33, blue: 0.95, alpha: 1) : NSColor(red: 0.92, green: 0.92, blue: 0.96, alpha: 1)).setFill()
    NSBezierPath(roundedRect: CGRect(x: cx, y: 598, width: w, height: 36), xRadius: 18, yRadius: 18).fill()
    text(c, cx + 20, 603, size: 20, weight: .semibold, color: i == 0 ? .white : sub)
    cx += w + 10
}
// rows
let rows: [(String, String, Bool)] = [
    ("npm run build && npm test", "Terminal · 2m ago", true),
    ("github.com/Digimo2020/ClipStack", "Safari · 14m ago", false),
    ("Meeting moved to 3pm, please confirm", "Messages · 1h ago", false),
    ("Invoice #1042 — €320.00", "Mail · 3h ago", false),
    ("#6D28D9", "Figma · Yesterday", false),
]
var ry: CGFloat = 510
for (t, m, sel) in rows {
    if sel {
        NSColor(red: 0.38, green: 0.33, blue: 0.95, alpha: 0.16).setFill()
        NSBezierPath(roundedRect: CGRect(x: 982, y: ry - 12, width: 496, height: 88), xRadius: 18, yRadius: 18).fill()
    }
    NSColor(red: 0.38, green: 0.33, blue: 0.95, alpha: 0.85).setFill()
    NSBezierPath(roundedRect: CGRect(x: 1004, y: ry + 12, width: 44, height: 44), xRadius: 11, yRadius: 11).fill()
    text(t, 1068, ry + 34, size: 23, weight: .medium, color: ink)
    text(m, 1068, ry + 6, size: 18, weight: .regular, color: sub)
    ry -= 98
}
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
