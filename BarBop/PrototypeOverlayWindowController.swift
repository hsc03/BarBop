//
//  PrototypeOverlayWindowController.swift
//  BarBop
//
//  Created by Codex on 7/7/26.
//

import AppKit

final class PrototypeOverlayWindowController {
    private let overlaySize = CGSize(width: 72, height: 72)
    private var panel: NSPanel?
    private var hideWorkItem: DispatchWorkItem?

    func show(at location: CGPoint, on screen: ScreenGeometry) {
        hideWorkItem?.cancel()

        let panel = panel ?? makePanel()
        self.panel = panel

        let origin = MenuBarGeometry.clampedOverlayOrigin(
            centeredAt: location,
            overlaySize: overlaySize,
            screenFrame: screen.frame
        )

        panel.setFrame(CGRect(origin: origin, size: overlaySize), display: true)
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        let workItem = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: workItem)
    }

    func hide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: overlaySize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        panel.contentView = RedCircleView(frame: CGRect(origin: .zero, size: overlaySize))

        return panel
    }
}

private final class RedCircleView: NSView {
    override var isOpaque: Bool {
        false
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()

        let circleRect = bounds.insetBy(dx: 10, dy: 10)
        NSColor.systemRed.withAlphaComponent(0.9).setFill()
        NSBezierPath(ovalIn: circleRect).fill()
    }
}
