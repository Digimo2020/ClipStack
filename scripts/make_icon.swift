// Generates Resources/AppIcon.icns. Usage: swift scripts/make_icon.swift <iconset-dir>
import AppKit

func render(_ px: Int) -> Data {
    let s = CGFloat(px)
    let img = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext
    let u = s / 1024  // unit scale

    // Background squircle (macOS icon grid: 824pt inside 1024 canvas)
    let bg = CGRect(x: 100 * u, y: 100 * u, width: 824 * u, height: 824 * u)
    let bgPath = NSBezierPath(roundedRect: bg, xRadius: 185 * u, yRadius: 185 * u)
    ctx.saveGState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowOffset = NSSize(width: 0, height: -12 * u)
    shadow.shadowBlurRadius = 24 * u
    shadow.set()
    NSColor.black.setFill()
    bgPath.fill()
    ctx.restoreGState()
    ctx.saveGState()
    bgPath.addClip()
    NSGradient(colors: [NSColor(red: 0.38, green: 0.36, blue: 0.98, alpha: 1),
                        NSColor(red: 0.62, green: 0.28, blue: 0.95, alpha: 1)])!
        .draw(in: bg, angle: -60)
    // soft top highlight
    NSGradient(colors: [NSColor.white.withAlphaComponent(0.22), NSColor.white.withAlphaComponent(0)])!
        .draw(in: CGRect(x: bg.minX, y: bg.midY, width: bg.width, height: bg.height / 2), angle: -90)
    ctx.restoreGState()

    // Stacked cards (history)
    func card(_ rect: CGRect, alpha: CGFloat, shadowed: Bool) {
        let p = NSBezierPath(roundedRect: rect, xRadius: 54 * u, yRadius: 54 * u)
        ctx.saveGState()
        if shadowed {
            let sh = NSShadow()
            sh.shadowColor = NSColor.black.withAlphaComponent(0.25)
            sh.shadowOffset = NSSize(width: 0, height: -10 * u)
            sh.shadowBlurRadius = 22 * u
            sh.set()
        }
        NSColor.white.withAlphaComponent(alpha).setFill()
        p.fill()
        ctx.restoreGState()
    }
    card(CGRect(x: 292 * u, y: 262 * u, width: 440 * u, height: 500 * u), alpha: 0.35, shadowed: false)
    card(CGRect(x: 262 * u, y: 232 * u, width: 500 * u, height: 500 * u), alpha: 0.6, shadowed: false)
    let front = CGRect(x: 232 * u, y: 202 * u, width: 560 * u, height: 580 * u)
    card(front, alpha: 1, shadowed: true)

    // Clip at top of front card
    let clip = CGRect(x: 392 * u, y: front.maxY - 56 * u, width: 240 * u, height: 100 * u)
    let clipPath = NSBezierPath(roundedRect: clip, xRadius: 34 * u, yRadius: 34 * u)
    NSColor(red: 0.30, green: 0.27, blue: 0.85, alpha: 1).setFill()
    clipPath.fill()
    let hole = CGRect(x: clip.midX - 36 * u, y: clip.midY - 10 * u, width: 72 * u, height: 22 * u)
    NSColor.white.withAlphaComponent(0.9).setFill()
    NSBezierPath(roundedRect: hole, xRadius: 11 * u, yRadius: 11 * u).fill()

    // Text lines
    NSColor(red: 0.45, green: 0.40, blue: 0.95, alpha: 0.85).setFill()
    for (i, w) in [400.0, 400.0, 270.0].enumerated() {
        let r = CGRect(x: 292 * u, y: (560 - Double(i) * 104) * u, width: w * u, height: 38 * u)
        NSBezierPath(roundedRect: r, xRadius: 19 * u, yRadius: 19 * u).fill()
    }
    img.unlockFocus()
    let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
    return rep.representation(using: .png, properties: [:])!
}

let dir = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try render(base).write(to: URL(fileURLWithPath: "\(dir)/icon_\(base)x\(base).png"))
    try render(base * 2).write(to: URL(fileURLWithPath: "\(dir)/icon_\(base)x\(base)@2x.png"))
}
