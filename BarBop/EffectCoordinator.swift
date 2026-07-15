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
        settingsStore: EffectSettingsStore,
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
            return
        }

        renderer.cancelCurrentEffect()
        renderer.playEffects(
            in: [MenuBarGeometry.menuBarFrame(for: click.screen)],
            settings: settings,
            reduceMotion: reduceMotionProvider()
        )
    }

    func handleNotificationBanner(on screens: [ScreenGeometry]) {
        let settings = settingsStore.settings
        guard settings.notificationEffectsEnabled else {
            return
        }

        renderer.cancelCurrentEffect()
        renderer.playEffects(
            in: screens.map { MenuBarGeometry.menuBarFrame(for: $0) },
            settings: settings,
            reduceMotion: reduceMotionProvider()
        )
    }
}
