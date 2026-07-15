//
//  MenuBarEffectController.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import AppKit

protocol MenuBarEffectRendering: AnyObject {
    func cancelCurrentEffect()
    func playEffects(in menuBarFrames: [CGRect], settings: EffectSettings, reduceMotion: Bool)
}

final class MenuBarEffectController: MenuBarEffectRendering {
    private struct Presentation {
        let panel: NSPanel
        let renderer: MenuBarEffectRenderer
    }

    private var presentations: [Presentation] = []
    private var hideWorkItem: DispatchWorkItem?

    func playEffects(in menuBarFrames: [CGRect], settings: EffectSettings, reduceMotion: Bool) {
        cancelCurrentEffect()
        guard !menuBarFrames.isEmpty else { return }

        presentations = menuBarFrames.map { menuBarFrame in
            let panel = makePanel(size: menuBarFrame.size)
            let renderer = MenuBarEffectRenderer(frame: CGRect(origin: .zero, size: menuBarFrame.size))

            panel.contentView = renderer
            panel.setFrame(menuBarFrame, display: true)
            panel.alphaValue = 1
            panel.orderFrontRegardless()

            renderer.play(settings: settings, reduceMotion: reduceMotion, completion: {})
            return Presentation(panel: panel, renderer: renderer)
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
        for presentation in presentations {
            presentation.renderer.stop()
            presentation.panel.orderOut(nil)
        }
        presentations = []
    }

    func hide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        for presentation in presentations {
            presentation.renderer.stop()
            presentation.panel.orderOut(nil)
        }
        presentations = []
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
