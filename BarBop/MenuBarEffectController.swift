//
//  MenuBarEffectController.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import AppKit

protocol MenuBarEffectRendering: AnyObject {
    func cancelCurrentEffect()
    func playEffect(in menuBarFrame: CGRect, settings: EffectSettings, reduceMotion: Bool)
}

final class MenuBarEffectController: MenuBarEffectRendering {
    private var panel: NSPanel?
    private var renderer: MenuBarEffectRenderer?
    private var hideWorkItem: DispatchWorkItem?

    func playEffect(in menuBarFrame: CGRect, settings: EffectSettings, reduceMotion: Bool) {
        cancelCurrentEffect()

        let panel = panel ?? makePanel(size: menuBarFrame.size)
        let renderer = renderer ?? MenuBarEffectRenderer(frame: CGRect(origin: .zero, size: menuBarFrame.size))
        self.panel = panel
        self.renderer = renderer

        renderer.frame = CGRect(origin: .zero, size: menuBarFrame.size)
        panel.contentView = renderer
        panel.setFrame(menuBarFrame, display: true)
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        renderer.play(settings: settings, reduceMotion: reduceMotion) { [weak self] in
            self?.hide()
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + settings.duration + 0.1, execute: workItem)
    }

    func cancelCurrentEffect() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        renderer?.stop()
        panel?.orderOut(nil)
    }

    func hide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        renderer?.stop()
        panel?.orderOut(nil)
    }

    private func makePanel(size: CGSize) -> NSPanel {
        let panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: size),
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
