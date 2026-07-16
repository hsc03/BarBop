//
//  BarBopTests.swift
//  BarBopTests
//
//  Created by 황성철 on 7/7/26.
//

import AppKit
import CoreGraphics
import Foundation
import Testing
import UserNotifications
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
        #expect(!store.settings.notificationEffectsEnabled)
        #expect(store.settings.notificationDisplayTarget == .followNotification)
        #expect(store.settings.color == CodableColor(nsColor: .systemBlue))
        #expect(store.settings.auroraPalette == .defaults)
    }

    @Test func effectStylesIncludeAurora() {
        #expect(
            EffectSettings.Style.allCases
                == [.flash, .pulse, .sweep, .lightning, .shimmer, .aurora]
        )
    }

    @Test func effectSettingsStorePersistsSettings() {
        let suiteName = uniqueSuiteName()
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        let firstStore = EffectSettingsStore(userDefaults: userDefaults, storageKey: "test-store")
        let settings = EffectSettings(
            isEnabled: false,
            notificationEffectsEnabled: true,
            notificationDisplayTarget: .specificDisplay(identifier: "display-2", name: "Studio Display"),
            color: CodableColor(red: 1, green: 0.2, blue: 0.1),
            auroraPalette: AuroraPalette(
                leading: CodableColor(red: 0.1, green: 0.2, blue: 0.3),
                middle: CodableColor(red: 0.4, green: 0.5, blue: 0.6),
                trailing: CodableColor(red: 0.7, green: 0.8, blue: 0.9)
            ),
            opacity: 0.7,
            duration: 0.5,
            style: .pulse
        )
        firstStore.updateSettings(settings)

        let secondStore = EffectSettingsStore(userDefaults: userDefaults, storageKey: "test-store")

        #expect(secondStore.settings == settings)
    }

    @Test func effectSettingsStoreMigratesVersionOneWithoutReplacingUserColor() throws {
        let suiteName = uniqueSuiteName()
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        let legacySettings = LegacyEffectSettingsFixture(
            isEnabled: false,
            color: CodableColor(red: 0.9, green: 0.15, blue: 0.25),
            opacity: 0.6,
            duration: 0.45,
            style: .sweep
        )
        let legacyState = LegacyStoredStateFixture(schemaVersion: 1, settings: legacySettings)
        userDefaults.set(try JSONEncoder().encode(legacyState), forKey: "test-store")

        let store = EffectSettingsStore(userDefaults: userDefaults, storageKey: "test-store")

        #expect(store.settings.isEnabled == legacySettings.isEnabled)
        #expect(store.settings.color == legacySettings.color)
        #expect(store.settings.opacity == legacySettings.opacity)
        #expect(store.settings.duration == legacySettings.duration)
        #expect(store.settings.style == legacySettings.style)
        #expect(!store.settings.notificationEffectsEnabled)
        #expect(store.settings.auroraPalette == .defaults)
        #expect(store.settings.notificationDisplayTarget == .followNotification)

        let reloadedStore = EffectSettingsStore(userDefaults: userDefaults, storageKey: "test-store")
        #expect(reloadedStore.settings == store.settings)
    }

    @Test func effectSettingsStoreMigratesVersionTwoWithFollowNotificationDefault() throws {
        let suiteName = uniqueSuiteName()
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        let legacySettings = LegacyVersionTwoEffectSettingsFixture(
            isEnabled: false,
            notificationEffectsEnabled: true,
            color: CodableColor(red: 0.2, green: 0.4, blue: 0.8),
            auroraPalette: .defaults,
            opacity: 0.7,
            duration: 0.6,
            style: .aurora
        )
        userDefaults.set(
            try JSONEncoder().encode(LegacyVersionTwoStoredStateFixture(schemaVersion: 2, settings: legacySettings)),
            forKey: "test-store"
        )

        let store = EffectSettingsStore(userDefaults: userDefaults, storageKey: "test-store")

        #expect(store.settings.isEnabled == legacySettings.isEnabled)
        #expect(store.settings.notificationEffectsEnabled == legacySettings.notificationEffectsEnabled)
        #expect(store.settings.color == legacySettings.color)
        #expect(store.settings.auroraPalette == legacySettings.auroraPalette)
        #expect(store.settings.style == legacySettings.style)
        #expect(store.settings.notificationDisplayTarget == .followNotification)
    }

    @Test func notificationDisplayResolverSupportsAllModesAndFallbacks() {
        let main = ScreenGeometry(
            id: 1,
            persistentIdentifier: "main-uuid",
            name: "Built-in Display",
            isMain: true,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875)
        )
        let external = ScreenGeometry(
            id: 2,
            persistentIdentifier: "external-uuid",
            name: "Studio Display",
            frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 1440, y: 0, width: 1920, height: 1055)
        )
        let screens = [main, external]

        #expect(NotificationDisplayResolver.resolve(
            target: .followNotification,
            eventScreenID: 2,
            screens: screens
        ) == [external])
        #expect(NotificationDisplayResolver.resolve(
            target: .followNotification,
            eventScreenID: 99,
            screens: screens
        ) == [main])
        #expect(NotificationDisplayResolver.resolve(
            target: .mainDisplay,
            eventScreenID: 2,
            screens: screens
        ) == [main])
        #expect(NotificationDisplayResolver.resolve(
            target: .specificDisplay(identifier: "external-uuid", name: "Studio Display"),
            eventScreenID: 1,
            screens: screens
        ) == [external])
        #expect(NotificationDisplayResolver.resolve(
            target: .specificDisplay(identifier: "disconnected", name: "Old Display"),
            eventScreenID: 2,
            screens: screens
        ) == [main])
        #expect(NotificationDisplayResolver.resolve(
            target: .allDisplays,
            eventScreenID: 1,
            screens: screens
        ) == screens)
        #expect(NotificationDisplayResolver.resolve(
            target: .mainDisplay,
            eventScreenID: 1,
            screens: []
        ).isEmpty)
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

    @Test func auroraRendererUsesAllThreePaletteColors() {
        let palette = AuroraPalette(
            leading: CodableColor(red: 0.1, green: 0.2, blue: 0.3),
            middle: CodableColor(red: 0.4, green: 0.5, blue: 0.6),
            trailing: CodableColor(red: 0.7, green: 0.8, blue: 0.9)
        )

        let colors = MenuBarEffectRenderer.auroraColors(from: palette, opacity: 0.4)

        #expect(colors.count == 5)
        expectColor(colors[0], matches: palette.leading, opacity: 0.4)
        expectColor(colors[1], matches: palette.middle, opacity: 0.4)
        expectColor(colors[2], matches: palette.trailing, opacity: 0.4)
        expectColor(colors[3], matches: palette.middle, opacity: 0.4)
        expectColor(colors[4], matches: palette.leading, opacity: 0.4)
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
                menuBarFrames: [CGRect(x: 0, y: 872, width: 1440, height: 28)],
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

        #expect(renderer.cancelCount == 0)
        #expect(renderer.playedEffects.isEmpty)
    }

    @Test func notificationEffectUsesCurrentSettingsWhenClickEffectsAreOff() {
        let renderer = FakeMenuBarEffectRenderer()
        let store = makeStore()
        let settings = EffectSettings(
            isEnabled: false,
            notificationEffectsEnabled: true,
            color: CodableColor(red: 0.8, green: 0.2, blue: 0.4),
            auroraPalette: AuroraPalette(
                leading: CodableColor(red: 0.1, green: 0.2, blue: 0.9),
                middle: CodableColor(red: 0.7, green: 0.2, blue: 0.8),
                trailing: CodableColor(red: 0.1, green: 0.8, blue: 0.7)
            ),
            opacity: 0.65,
            duration: 0.55,
            style: .aurora
        )
        store.updateSettings(settings)
        let coordinator = EffectCoordinator(
            renderer: renderer,
            settingsStore: store,
            reduceMotionProvider: { false }
        )

        coordinator.handleNotificationBanner(on: [sampleScreen])

        #expect(renderer.cancelCount == 1)
        #expect(renderer.playedEffects.first?.settings == settings)
        #expect(renderer.playedEffects.first?.menuBarFrames == [CGRect(x: 0, y: 872, width: 1440, height: 28)])
    }

    @Test @MainActor func notificationToggleWithoutAccessibilityReturnsToOff() {
        let store = makeStore()
        let renderer = FakeMenuBarEffectRenderer()
        let coordinator = EffectCoordinator(renderer: renderer, settingsStore: store)
        let detector = FakeNotificationBannerDetector()
        var promptCount = 0
        let controller = NotificationEffectController(
            settingsStore: store,
            effectCoordinator: coordinator,
            cancelEffect: {},
            dependencies: notificationDependencies(
                detector: detector,
                isTrusted: false,
                requestAccess: { promptCount += 1 }
            )
        )

        controller.setEnabled(true)

        #expect(!store.settings.notificationEffectsEnabled)
        #expect(detector.startCount == 0)
        #expect(detector.stopCount == 1)
        #expect(promptCount == 1)
        #expect(controller.state == .permissionRequired)
    }

    @Test @MainActor func notificationToggleWithAccessibilityStartsOnlyOnce() {
        let store = makeStore()
        let renderer = FakeMenuBarEffectRenderer()
        let coordinator = EffectCoordinator(renderer: renderer, settingsStore: store)
        let detector = FakeNotificationBannerDetector()
        let controller = NotificationEffectController(
            settingsStore: store,
            effectCoordinator: coordinator,
            cancelEffect: {},
            dependencies: notificationDependencies(detector: detector, isTrusted: true)
        )

        controller.setEnabled(true)
        controller.setEnabled(true)

        #expect(store.settings.notificationEffectsEnabled)
        #expect(detector.startCount == 1)
        #expect(controller.state == .active)
    }

    @Test @MainActor func pendingNotificationEnableCompletesAfterAccessibilityApproval() {
        let store = makeStore()
        let renderer = FakeMenuBarEffectRenderer()
        let coordinator = EffectCoordinator(renderer: renderer, settingsStore: store)
        let detector = FakeNotificationBannerDetector()
        var isTrusted = false
        let controller = NotificationEffectController(
            settingsStore: store,
            effectCoordinator: coordinator,
            cancelEffect: {},
            dependencies: NotificationEffectController.Dependencies(
                isTrusted: { isTrusted },
                requestAccessibilityAccess: {},
                screens: { [sampleScreen] },
                uptime: { 20 },
                makeDetector: { onEvent, onReset, onStateChange in
                    detector.onEvent = onEvent
                    detector.onReset = onReset
                    detector.onStateChange = onStateChange
                    return detector
                }
            )
        )

        controller.setEnabled(true)
        #expect(controller.isAwaitingAccessibilityApproval)
        #expect(!store.settings.notificationEffectsEnabled)

        isTrusted = true
        controller.refreshAccessibilityAuthorization()

        #expect(!controller.isAwaitingAccessibilityApproval)
        #expect(store.settings.notificationEffectsEnabled)
        #expect(detector.startCount == 1)
        #expect(controller.state == .active)
    }

    @Test @MainActor func restoredNotificationSettingDisablesWhenPermissionWasRevoked() {
        let store = makeStore()
        var settings = store.settings
        settings.notificationEffectsEnabled = true
        store.updateSettings(settings)
        let renderer = FakeMenuBarEffectRenderer()
        let coordinator = EffectCoordinator(renderer: renderer, settingsStore: store)
        let detector = FakeNotificationBannerDetector()
        let controller = NotificationEffectController(
            settingsStore: store,
            effectCoordinator: coordinator,
            cancelEffect: {},
            dependencies: notificationDependencies(detector: detector, isTrusted: false)
        )

        controller.restoreSavedState()

        #expect(!store.settings.notificationEffectsEnabled)
        #expect(detector.startCount == 0)
        #expect(controller.state == .permissionRequired)
    }

    @Test @MainActor func activeNotificationSettingDisablesWhenPermissionIsRevoked() {
        let store = makeStore()
        let renderer = FakeMenuBarEffectRenderer()
        let coordinator = EffectCoordinator(renderer: renderer, settingsStore: store)
        let detector = FakeNotificationBannerDetector()
        var isTrusted = true
        let controller = NotificationEffectController(
            settingsStore: store,
            effectCoordinator: coordinator,
            cancelEffect: {},
            dependencies: NotificationEffectController.Dependencies(
                isTrusted: { isTrusted },
                requestAccessibilityAccess: {},
                screens: { [sampleScreen] },
                uptime: { 20 },
                makeDetector: { onEvent, onReset, onStateChange in
                    detector.onEvent = onEvent
                    detector.onReset = onReset
                    detector.onStateChange = onStateChange
                    return detector
                }
            )
        )

        controller.setEnabled(true)
        #expect(store.settings.notificationEffectsEnabled)
        #expect(controller.state == .active)

        isTrusted = false
        controller.refreshAccessibilityAuthorization()

        #expect(!store.settings.notificationEffectsEnabled)
        #expect(!controller.isAwaitingAccessibilityApproval)
        #expect(detector.stopCount == 1)
        #expect(controller.state == .permissionRequired)
    }

    @Test @MainActor func notificationDetectorEventTargetsDisplayAndCurrentSettings() {
        let store = makeStore()
        var settings = store.settings
        settings.isEnabled = false
        settings.notificationEffectsEnabled = true
        settings.color = CodableColor(red: 0.9, green: 0.1, blue: 0.3)
        settings.opacity = 0.72
        settings.duration = 0.61
        settings.style = .sweep
        store.updateSettings(settings)
        let renderer = FakeMenuBarEffectRenderer()
        let coordinator = EffectCoordinator(renderer: renderer, settingsStore: store)
        let detector = FakeNotificationBannerDetector()
        let controller = NotificationEffectController(
            settingsStore: store,
            effectCoordinator: coordinator,
            cancelEffect: {},
            dependencies: notificationDependencies(detector: detector, isTrusted: true)
        )
        controller.restoreSavedState()

        detector.emit(NotificationBannerEvent(
            date: Date(timeIntervalSince1970: 1),
            bannerFrame: CGRect(x: 1000, y: 20, width: 344, height: 73),
            screenID: sampleScreen.id
        ))

        #expect(renderer.playedEffects.count == 1)
        #expect(renderer.playedEffects.first?.settings == settings)
    }

    @Test @MainActor func allDisplaysNotificationRendersEveryConnectedMenuBarSimultaneously() {
        let store = makeStore()
        var settings = store.settings
        settings.notificationEffectsEnabled = true
        settings.notificationDisplayTarget = .allDisplays
        store.updateSettings(settings)
        let external = ScreenGeometry(
            id: 2,
            persistentIdentifier: "external-uuid",
            name: "Studio Display",
            frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 1440, y: 0, width: 1920, height: 1055)
        )
        let renderer = FakeMenuBarEffectRenderer()
        let coordinator = EffectCoordinator(renderer: renderer, settingsStore: store)
        let detector = FakeNotificationBannerDetector()
        let controller = NotificationEffectController(
            settingsStore: store,
            effectCoordinator: coordinator,
            cancelEffect: {},
            dependencies: notificationDependencies(
                detector: detector,
                isTrusted: true,
                screens: [sampleScreen, external]
            )
        )
        controller.restoreSavedState()

        detector.emit(NotificationBannerEvent(
            date: Date(timeIntervalSince1970: 1),
            bannerFrame: CGRect(x: 1000, y: 20, width: 344, height: 73),
            screenID: sampleScreen.id
        ))

        #expect(renderer.playedEffects.count == 1)
        #expect(renderer.playedEffects.first?.menuBarFrames == [
            CGRect(x: 0, y: 872, width: 1440, height: 28),
            CGRect(x: 1440, y: 1052, width: 1920, height: 28),
        ])
        #expect(renderer.cancelCount == 1)
    }

    @Test func firstLaunchStoreRequiresInitialPresentationOnlyOnce() {
        let suiteName = uniqueSuiteName()
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        let store = FirstLaunchStore(
            userDefaults: userDefaults,
            presentationKey: "initial-settings"
        )

        #expect(store.shouldPresentInitialSettings)

        store.markInitialSettingsPresented()

        #expect(!store.shouldPresentInitialSettings)
        let reloadedStore = FirstLaunchStore(
            userDefaults: userDefaults,
            presentationKey: "initial-settings"
        )
        #expect(!reloadedStore.shouldPresentInitialSettings)
    }

    @Test func eventMonitorReportsActiveWhenGlobalMonitorInstalls() {
        let globalToken = MonitorToken()
        let localToken = MonitorToken()
        var states: [ClickMonitoringState] = []
        var removedTokens: [MonitorToken] = []
        let monitor = MenuBarEventMonitor(
            onMenuBarClick: { _ in },
            onStateChange: { states.append($0) },
            dependencies: .init(
                addGlobalMonitor: { _ in globalToken },
                addLocalMonitor: { _ in localToken },
                removeMonitor: { token in
                    if let token = token as? MonitorToken {
                        removedTokens.append(token)
                    }
                }
            )
        )

        monitor.start()

        #expect(states == [.active])
        #expect(removedTokens.isEmpty)

        monitor.stop()

        #expect(states == [.active, .stopped])
        #expect(removedTokens.count == 2)
        #expect(removedTokens.contains { $0 === globalToken })
        #expect(removedTokens.contains { $0 === localToken })
    }

    @Test func eventMonitorReportsUnavailableAndCleansPartialInstall() {
        let localToken = MonitorToken()
        var states: [ClickMonitoringState] = []
        var removedTokens: [MonitorToken] = []
        let monitor = MenuBarEventMonitor(
            onMenuBarClick: { _ in },
            onStateChange: { states.append($0) },
            dependencies: .init(
                addGlobalMonitor: { _ in nil },
                addLocalMonitor: { _ in localToken },
                removeMonitor: { token in
                    if let token = token as? MonitorToken {
                        removedTokens.append(token)
                    }
                }
            )
        )

        monitor.start()

        #expect(states == [.unavailable])
        #expect(removedTokens.count == 1)
        #expect(removedTokens.first === localToken)
    }

    @Test @MainActor func testNotificationReportsNotDeterminedAuthorization() async {
        let controller = LocalTestNotificationController(
            dependencies: .init(
                authorizationStatus: { .notDetermined },
                requestAuthorization: { false },
                addRequest: { _ in }
            )
        )

        await controller.refreshAuthorizationStatus()

        #expect(controller.authorizationStatus == .notDetermined)
        #expect(controller.statusMessage.contains("request local notification permission"))
    }

    @Test @MainActor func testNotificationRequestsPermissionAndSchedulesOnce() async {
        var permissionRequestCount = 0
        var requests: [UNNotificationRequest] = []
        let controller = LocalTestNotificationController(
            dependencies: .init(
                authorizationStatus: { .notDetermined },
                requestAuthorization: {
                    permissionRequestCount += 1
                    return true
                },
                addRequest: { request in
                    requests.append(request)
                }
            )
        )

        await controller.sendTestNotification()

        #expect(permissionRequestCount == 1)
        #expect(requests.count == 1)
        #expect(requests.first?.content.title == "BarBop Test Notification")
        #expect(controller.authorizationStatus == .authorized)
        #expect(!controller.isSending)
    }

    @Test @MainActor func testNotificationSchedulesAfterPreparingBannerPresentationWhenAuthorized() async {
        var permissionRequestCount = 0
        var addRequestCount = 0
        var presentationPreparationCount = 0
        let controller = LocalTestNotificationController(
            dependencies: .init(
                authorizationStatus: { .authorized },
                requestAuthorization: {
                    permissionRequestCount += 1
                    return true
                },
                addRequest: { request in
                    addRequestCount += 1
                    let trigger = request.trigger as? UNTimeIntervalNotificationTrigger
                    #expect(trigger?.timeInterval == 1)
                    #expect(trigger?.repeats == false)
                },
                prepareForBannerPresentation: { presentationPreparationCount += 1 }
            )
        )

        await controller.sendTestNotification()

        #expect(permissionRequestCount == 0)
        #expect(addRequestCount == 1)
        #expect(presentationPreparationCount == 1)
        #expect(controller.authorizationStatus == .authorized)
    }

    @Test @MainActor func testNotificationWithDisabledBannersDoesNotScheduleAndOpensSettings() async {
        var addRequestCount = 0
        var openSettingsCount = 0
        let controller = LocalTestNotificationController(
            dependencies: .init(
                authorizationStatus: { .alertsDisabled },
                requestAuthorization: { true },
                addRequest: { _ in addRequestCount += 1 },
                openNotificationSettings: { openSettingsCount += 1 }
            )
        )

        await controller.refreshAuthorizationStatus()
        await controller.sendTestNotification()
        controller.openNotificationSettings()

        #expect(controller.authorizationStatus == .alertsDisabled)
        #expect(controller.requiresNotificationSettings)
        #expect(!controller.canSendTestNotification)
        #expect(controller.statusMessage.contains("banners are disabled"))
        #expect(addRequestCount == 0)
        #expect(openSettingsCount == 1)
    }

    @Test @MainActor func testNotificationDeniedDoesNotScheduleOrChangeEffectSettings() async {
        let store = makeStore()
        let originalSettings = store.settings
        var addRequestCount = 0
        let controller = LocalTestNotificationController(
            dependencies: .init(
                authorizationStatus: { .denied },
                requestAuthorization: { true },
                addRequest: { _ in addRequestCount += 1 }
            )
        )

        await controller.sendTestNotification()

        #expect(controller.authorizationStatus == .denied)
        #expect(controller.statusMessage.contains("System Settings > Notifications > BarBop"))
        #expect(addRequestCount == 0)
        #expect(store.settings == originalSettings)
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

    @MainActor
    private func notificationDependencies(
        detector: FakeNotificationBannerDetector,
        isTrusted: Bool,
        requestAccess: @escaping () -> Void = {},
        screens: [ScreenGeometry]? = nil
    ) -> NotificationEffectController.Dependencies {
        let availableScreens = screens ?? [sampleScreen]
        return NotificationEffectController.Dependencies(
            isTrusted: { isTrusted },
            requestAccessibilityAccess: requestAccess,
            screens: { availableScreens },
            uptime: { 20 },
            makeDetector: { onEvent, onReset, onStateChange in
                detector.onEvent = onEvent
                detector.onReset = onReset
                detector.onStateChange = onStateChange
                return detector
            }
        )
    }

    private func uniqueSuiteName() -> String {
        "BarBopTests.\(UUID().uuidString)"
    }

    private func expectColor(_ color: NSColor, matches expected: CodableColor, opacity: Double) {
        let converted = CodableColor(nsColor: color)
        #expect(abs(converted.red - expected.red) < 0.001)
        #expect(abs(converted.green - expected.green) < 0.001)
        #expect(abs(converted.blue - expected.blue) < 0.001)
        #expect(abs(converted.alpha - opacity) < 0.001)
    }
}

private struct LegacyStoredStateFixture: Codable {
    var schemaVersion: Int
    var settings: LegacyEffectSettingsFixture
}

private struct LegacyEffectSettingsFixture: Codable {
    var isEnabled: Bool
    var color: CodableColor
    var opacity: Double
    var duration: Double
    var style: EffectSettings.Style
}

private struct LegacyVersionTwoStoredStateFixture: Codable {
    var schemaVersion: Int
    var settings: LegacyVersionTwoEffectSettingsFixture
}

private struct LegacyVersionTwoEffectSettingsFixture: Codable {
    var isEnabled: Bool
    var notificationEffectsEnabled: Bool
    var color: CodableColor
    var auroraPalette: AuroraPalette
    var opacity: Double
    var duration: Double
    var style: EffectSettings.Style
}

private final class MonitorToken {}

private struct FakeMenuBarEffect: Equatable {
    let menuBarFrames: [CGRect]
    let settings: EffectSettings
    let reduceMotion: Bool
}

private final class FakeMenuBarEffectRenderer: MenuBarEffectRendering {
    var cancelCount = 0
    var playedEffects: [FakeMenuBarEffect] = []

    func cancelCurrentEffect() {
        cancelCount += 1
    }

    func playEffects(in menuBarFrames: [CGRect], settings: EffectSettings, reduceMotion: Bool) {
        playedEffects.append(
            FakeMenuBarEffect(
                menuBarFrames: menuBarFrames,
                settings: settings,
                reduceMotion: reduceMotion
            )
        )
    }
}

@MainActor
private final class FakeNotificationBannerDetector: NotificationBannerMonitoring {
    private(set) var state: NotificationBannerMonitorState = .stopped
    var startCount = 0
    var stopCount = 0
    var reconnectCount = 0
    var onEvent: ((NotificationBannerEvent) -> TimeInterval?)?
    var onReset: (() -> Void)?
    var onStateChange: ((NotificationBannerMonitorState) -> Void)?

    func start() {
        startCount += 1
        state = .active
        onStateChange?(.active)
    }

    func stop() {
        stopCount += 1
        state = .stopped
        onReset?()
        onStateChange?(.stopped)
    }

    func reconnect() {
        reconnectCount += 1
    }

    func emit(_ event: NotificationBannerEvent) {
        _ = onEvent?(event)
    }
}
