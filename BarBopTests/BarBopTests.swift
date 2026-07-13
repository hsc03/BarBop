//
//  BarBopTests.swift
//  BarBopTests
//
//  Created by 황성철 on 7/7/26.
//

import Testing
import CoreGraphics
import Foundation
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

    @Test func identityPrefersBundleAndAccessibilityIdentifier() {
        let id = StatusItemIdentity.makeID(
            from: StatusItemIdentityInput(
                bundleIdentifier: "com.example.MenuApp",
                accessibilityIdentifier: "status.clock",
                title: "Clock",
                processIdentifier: 101
            )
        )

        #expect(id == "bundle:com.example.MenuApp|axid:status.clock")
    }

    @Test func identityFallsBackToBundleAndTitle() {
        let id = StatusItemIdentity.makeID(
            from: StatusItemIdentityInput(
                bundleIdentifier: "com.example.MenuApp",
                accessibilityIdentifier: nil,
                title: "Clock",
                processIdentifier: 101
            )
        )

        #expect(id == "bundle:com.example.MenuApp|title:Clock")
    }

    @Test func identityUsesSystemPidWhenSystemItemHasNoStableText() {
        let id = StatusItemIdentity.makeID(
            from: StatusItemIdentityInput(
                bundleIdentifier: "com.apple.controlcenter",
                accessibilityIdentifier: nil,
                title: nil,
                processIdentifier: 202
            )
        )

        #expect(id == "system:com.apple.controlcenter|pid:202")
    }

    @Test func identityFallsBackToBundleOnly() {
        let id = StatusItemIdentity.makeID(
            from: StatusItemIdentityInput(
                bundleIdentifier: "com.example.MenuApp",
                accessibilityIdentifier: nil,
                title: nil,
                processIdentifier: 101
            )
        )

        #expect(id == "bundle:com.example.MenuApp")
    }

    @Test func identityUsesUnknownWhenNoStableInputsExist() {
        let id = StatusItemIdentity.makeID(
            from: StatusItemIdentityInput(
                bundleIdentifier: nil,
                accessibilityIdentifier: nil,
                title: "   ",
                processIdentifier: 101
            )
        )

        #expect(id == StatusItemIdentity.unknown)
    }

    @Test func reactionCoordinatorUsesFullMotionByDefault() {
        let renderer = FakeReactionRenderer()
        let coordinator = ReactionCoordinator(renderer: renderer, reduceMotionProvider: { false })
        let click = MenuBarClick(location: CGPoint(x: 10, y: 20), screen: sampleScreen)

        coordinator.handleMenuBarClick(click)

        #expect(renderer.cancelCount == 1)
        #expect(renderer.playedReactions == [
            FakeReaction(location: CGPoint(x: 10, y: 20), screen: sampleScreen, motionMode: .fullMotion)
        ])
    }

    @Test func reactionCoordinatorUsesReducedMotionWhenRequested() {
        let renderer = FakeReactionRenderer()
        let coordinator = ReactionCoordinator(renderer: renderer, reduceMotionProvider: { true })
        let click = MenuBarClick(location: CGPoint(x: 12, y: 24), screen: sampleScreen)

        coordinator.handleMenuBarClick(click)

        #expect(renderer.cancelCount == 1)
        #expect(renderer.playedReactions == [
            FakeReaction(location: CGPoint(x: 12, y: 24), screen: sampleScreen, motionMode: .reducedMotion)
        ])
    }

    @Test func reactionCoordinatorCancelsBeforeEveryReaction() {
        let renderer = FakeReactionRenderer()
        let coordinator = ReactionCoordinator(renderer: renderer, reduceMotionProvider: { false })

        coordinator.handleMenuBarClick(MenuBarClick(location: CGPoint(x: 10, y: 20), screen: sampleScreen))
        coordinator.handleMenuBarClick(MenuBarClick(location: CGPoint(x: 30, y: 40), screen: sampleScreen))

        #expect(renderer.cancelCount == 2)
        #expect(renderer.playedReactions.count == 2)
        #expect(renderer.playedReactions.last?.location == CGPoint(x: 30, y: 40))
    }

    @Test func assignmentStoreUpdatesDetectedItemWithoutDuplicating() {
        let store = makeStore()
        let firstDate = Date(timeIntervalSince1970: 100)
        let secondDate = Date(timeIntervalSince1970: 200)

        store.recordDetectedItem(
            DetectedStatusItem(
                id: "bundle:com.example.app|title:Clock",
                bundleIdentifier: "com.example.app",
                applicationName: "Example",
                itemTitle: "Clock",
                accessibilityIdentifier: nil,
                lastDetectedAt: firstDate
            )
        )
        store.recordDetectedItem(
            DetectedStatusItem(
                id: "bundle:com.example.app|title:Clock",
                bundleIdentifier: "com.example.app",
                applicationName: "Example Renamed",
                itemTitle: "Clock",
                accessibilityIdentifier: "clock-item",
                lastDetectedAt: secondDate
            )
        )

        #expect(store.detectedItems.count == 1)
        #expect(store.detectedItems[0].applicationName == "Example Renamed")
        #expect(store.detectedItems[0].accessibilityIdentifier == "clock-item")
        #expect(store.detectedItems[0].lastDetectedAt == secondDate)
    }

    @Test func assignmentStoreFallsBackToDefaultCharacter() {
        let store = makeStore()

        #expect(store.characterID(for: "status-item:unknown") == Character.placeholderID)
    }

    @Test func assignmentStorePersistsAssignments() {
        let suiteName = uniqueSuiteName()
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        let firstStore = AssignmentStore(userDefaults: userDefaults, storageKey: "test-store")
        let characterID = UUID(uuidString: "6F8E2F7C-E280-4F2F-81F7-E09D32A5AC65")!
        firstStore.assign(characterID: characterID, to: "bundle:com.example.app")

        let secondStore = AssignmentStore(userDefaults: userDefaults, storageKey: "test-store")

        #expect(secondStore.characterID(for: "bundle:com.example.app") == characterID)
    }

    @Test func assignmentStoreRecoversFromCorruptedData() {
        let suiteName = uniqueSuiteName()
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults.set(Data("not-json".utf8), forKey: "test-store")

        let store = AssignmentStore(userDefaults: userDefaults, storageKey: "test-store")

        #expect(store.detectedItems.isEmpty)
        #expect(store.assignments.isEmpty)
        #expect(store.settings == ReactionSettings.defaults)
    }

    private var sampleScreen: ScreenGeometry {
        ScreenGeometry(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875)
        )
    }

    private func makeStore() -> AssignmentStore {
        let suiteName = uniqueSuiteName()
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return AssignmentStore(userDefaults: userDefaults, storageKey: "test-store")
    }

    private func uniqueSuiteName() -> String {
        "BarBopTests.\(UUID().uuidString)"
    }

}

private struct FakeReaction: Equatable {
    let location: CGPoint
    let screen: ScreenGeometry
    let motionMode: ReactionMotionMode
}

private final class FakeReactionRenderer: ReactionRendering {
    var cancelCount = 0
    var playedReactions: [FakeReaction] = []

    func cancelCurrentReaction() {
        cancelCount += 1
    }

    func playReaction(at location: CGPoint, on screen: ScreenGeometry, motionMode: ReactionMotionMode) {
        playedReactions.append(FakeReaction(location: location, screen: screen, motionMode: motionMode))
    }
}
