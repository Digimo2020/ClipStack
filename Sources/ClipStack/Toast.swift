import AppKit
import SwiftUI

/// Small purple pill that appears briefly near the bottom of the screen.
@MainActor
enum Toast {
    private static var panel: NSPanel?

    static func show(_ text: String) {
        panel?.orderOut(nil)
        let view = NSHostingView(rootView:
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18).padding(.vertical, 11)
                .background(Capsule().fill(Theme.bar))
                .padding(10)
        )
        view.frame = NSRect(origin: .zero, size: view.fittingSize)
        let p = NSPanel(contentRect: view.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.contentView = view
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.level = .statusBar
        p.ignoresMouseEvents = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let mouse = NSEvent.mouseLocation
        if let vf = (NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main)?.visibleFrame {
            p.setFrameOrigin(NSPoint(x: vf.midX - view.frame.width / 2, y: vf.minY + 70))
        }
        p.alphaValue = 0
        p.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { $0.duration = 0.15; p.animator().alphaValue = 1 }
        panel = p
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            guard panel === p else { return }
            NSAnimationContext.runAnimationGroup({ $0.duration = 0.3; p.animator().alphaValue = 0 }, completionHandler: { p.orderOut(nil) })
        }
    }
}
