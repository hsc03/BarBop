//
//  EffectCoordinator.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import AppKit

final class EffectCoordinator {
    private let renderer: MenuBarEffectRendering
    private let settingsStore: EffectSettingsStore
    private let reduceMotionProvider: () -> Bool

    init(
        renderer: MenuBarEffectRendering,
        settingsStore: EffectSettingsStore = AppEnvironment.shared.effectSettingsStore,
        reduceMotionProvider: @escaping () -> Bool = {
            NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        }
    ) {
        self.renderer = renderer
        self.settingsStore = settingsStore
        self.reduceMotionProvider = reduceMotionProvider
    }

    func handleMenuBarClick(_ click: MenuBarClick) {
        let settings = settingsStore.settings
        guard settings.isEnabled else {
            renderer.cancelCurrentEffect()
            return
        }

        renderer.cancelCurrentEffect()
        renderer.playEffect(
            in: MenuBarGeometry.menuBarFrame(for: click.screen),
            settings: settings,
            reduceMotion: reduceMotionProvider()
        )
    }
}
