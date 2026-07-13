//
//  BarBopTests.swift
//  BarBopTests
//
//  Created by 황성철 on 7/7/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import BarBop

struct BarBopTests {

    @Test func detectsClickInsidePrimaryMenuBar() {
        let screen = ScreenGeometry(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875)
        )

        let click = MenuBarGeometry.click(at: CGPoint(x: 120, y: 888), screens: [screen])

        #expect(click == MenuBarClick(location: CGPoint(x: 120, y: 888), screen: screen))
    }

    @Test func ignoresClickBelowMenuBar() {
        let screen = ScreenGeometry(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875)
        )

        let click = MenuBarGeometry.click(at: CGPoint(x: 120, y: 860), screens: [screen])

        #expect(click == nil)
    }

    @Test func selectsScreenContainingClick() {
        let primary = ScreenGeometry(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875)
        )
        let external = ScreenGeometry(
            id: 2,
            frame: CGRect(x: 1440, y: -180, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 1440, y: -180, width: 1920, height: 1055)
        )

        let click = MenuBarGeometry.click(at: CGPoint(x: 1800, y: 888), screens: [primary, external])

        #expect(click?.screen == external)
    }

    @Test func usesFallbackHeightWhenMenuBarIsAutoHidden() {
        let screen = ScreenGeometry(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900)
        )

        let menuBarFrame = MenuBarGeometry.menuBarFrame(for: screen)

        #expect(menuBarFrame == CGRect(x: 0, y: 872, width: 1440, height: 28))
    }

    @Test func clampsOverlayInsideScreenBounds() {
        let origin = MenuBarGeometry.clampedOverlayOrigin(
            centeredAt: CGPoint(x: 1435, y: 895),
            overlaySize: CGSize(width: 72, height: 72),
            screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900)
        )

        #expect(origin == CGPoint(x: 1360, y: 820))
    }

    @Test func effectSettingsStoreLoadsDefaults() {
        let store = makeStore()

        #expect(store.settings == EffectSettings.defaults)
    }

    @Test func effectStylesIncludeAurora() {
        #expect(EffectSettings.Style.allCases == [.flash, .pulse, .sweep, .aurora])
    }

    @Test func effectSettingsStorePersistsSettings() {
        let suiteName = uniqueSuiteName()
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        let firstStore = EffectSettingsStore(userDefaults: userDefaults, storageKey: "test-store")
        let settings = EffectSettings(
            isEnabled: false,
            color: CodableColor(red: 1, green: 0.2, blue: 0.1),
            opacity: 0.7,
            duration: 0.5,
            style: .pulse
        )
        firstStore.updateSettings(settings)

        let secondStore = EffectSettingsStore(userDefaults: userDefaults, storageKey: "test-store")

        #expect(secondStore.settings == settings)
    }

    @Test func effectSettingsStoreRecoversFromCorruptedData() {
        let suiteName = uniqueSuiteName()
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults.set(Data("not-json".utf8), forKey: "test-store")

        let store = EffectSettingsStore(userDefaults: userDefaults, storageKey: "test-store")

        #expect(store.settings == EffectSettings.defaults)
    }

    @Test func effectSettingsStoreClampsUnsafeValues() {
        let store = makeStore()
        store.updateSettings(
            EffectSettings(
                isEnabled: true,
                color: CodableColor(red: 0, green: 0, blue: 1),
                opacity: 3,
                duration: -4,
                style: .flash
            )
        )

        #expect(store.settings.opacity == 1)
        #expect(store.settings.duration == 0.1)
    }

    @Test func effectCoordinatorUsesMenuBarFrameAndSettings() {
        let renderer = FakeMenuBarEffectRenderer()
        let store = makeStore()
        let settings = EffectSettings(
            isEnabled: true,
            color: CodableColor(red: 0.2, green: 0.3, blue: 0.4),
            opacity: 0.5,
            duration: 0.4,
            style: .flash
        )
        store.updateSettings(settings)
        let coordinator = EffectCoordinator(
            renderer: renderer,
            settingsStore: store,
            reduceMotionProvider: { true }
        )

        coordinator.handleMenuBarClick(MenuBarClick(location: CGPoint(x: 120, y: 888), screen: sampleScreen))

        #expect(renderer.cancelCount == 1)
        #expect(renderer.playedEffects == [
            FakeMenuBarEffect(
                menuBarFrame: CGRect(x: 0, y: 875, width: 1440, height: 25),
                settings: settings,
                reduceMotion: true
            )
        ])
    }

    @Test func effectCoordinatorCancelsWhenDisabled() {
        let renderer = FakeMenuBarEffectRenderer()
        let store = makeStore()
        store.updateSettings(
            EffectSettings(
                isEnabled: false,
                color: CodableColor(red: 0, green: 0, blue: 1),
                opacity: 0.5,
                duration: 0.3,
                style: .flash
            )
        )
        let coordinator = EffectCoordinator(renderer: renderer, settingsStore: store, reduceMotionProvider: { false })

        coordinator.handleMenuBarClick(MenuBarClick(location: CGPoint(x: 120, y: 888), screen: sampleScreen))

        #expect(renderer.cancelCount == 1)
        #expect(renderer.playedEffects.isEmpty)
    }

    private var sampleScreen: ScreenGeometry {
        ScreenGeometry(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875)
        )
    }

    private func makeStore() -> EffectSettingsStore {
        let suiteName = uniqueSuiteName()
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return EffectSettingsStore(userDefaults: userDefaults, storageKey: "test-store")
    }

    private func uniqueSuiteName() -> String {
        "BarBopTests.\(UUID().uuidString)"
    }
}

private struct FakeMenuBarEffect: Equatable {
    let menuBarFrame: CGRect
    let settings: EffectSettings
    let reduceMotion: Bool
}

private final class FakeMenuBarEffectRenderer: MenuBarEffectRendering {
    var cancelCount = 0
    var playedEffects: [FakeMenuBarEffect] = []

    func cancelCurrentEffect() {
        cancelCount += 1
    }

    func playEffect(in menuBarFrame: CGRect, settings: EffectSettings, reduceMotion: Bool) {
        playedEffects.append(
            FakeMenuBarEffect(
                menuBarFrame: menuBarFrame,
                settings: settings,
                reduceMotion: reduceMotion
            )
        )
    }
}
