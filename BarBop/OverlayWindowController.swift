//
//  OverlayWindowController.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import AppKit

final class OverlayWindowController: ReactionRendering {
    private let overlaySize = CGSize(width: 96, height: 96)
    private var panel: NSPanel?
    private var renderer: CharacterRenderer?
    private var hideWorkItem: DispatchWorkItem?

    func playReaction(at location: CGPoint, on screen: ScreenGeometry, motionMode: ReactionMotionMode) {
        cancelCurrentReaction()

        let panel = panel ?? makePanel()
        let renderer = renderer ?? CharacterRenderer(frame: CGRect(origin: .zero, size: overlaySize))
        self.panel = panel
        self.renderer = renderer

        let origin = MenuBarGeometry.clampedOverlayOrigin(
            centeredAt: location,
            overlaySize: overlaySize,
            screenFrame: screen.frame
        )

        renderer.frame = CGRect(origin: .zero, size: overlaySize)
        renderer.resetForPlayback()
        panel.contentView = renderer
        panel.setFrame(CGRect(origin: origin, size: overlaySize), display: true)
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        renderer.play(motionMode: motionMode) { [weak self] in
            self?.hide()
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9, execute: workItem)
    }

    func cancelCurrentReaction() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        renderer?.stop()
        panel?.orderOut(nil)
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

        return panel
    }
}
