//
//  BarBopTests.swift
//  BarBopTests
//
//  Created by 황성철 on 7/7/26.
//

import Testing
import CoreGraphics
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

}
