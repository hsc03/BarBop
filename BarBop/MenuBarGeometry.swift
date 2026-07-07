//
//  MenuBarGeometry.swift
//  BarBop
//
//  Created by Codex on 7/7/26.
//

import CoreGraphics

struct ScreenGeometry: Equatable {
    let id: UInt32
    let frame: CGRect
    let visibleFrame: CGRect
}

struct MenuBarClick: Equatable {
    let location: CGPoint
    let screen: ScreenGeometry
}

enum MenuBarGeometry {
    static let fallbackMenuBarHeight: CGFloat = 28

    static func click(
        at location: CGPoint,
        screens: [ScreenGeometry]
    ) -> MenuBarClick? {
        guard let screen = screen(containing: location, in: screens) else {
            return nil
        }

        guard menuBarFrame(for: screen).contains(location) else {
            return nil
        }

        return MenuBarClick(location: location, screen: screen)
    }

    static func screen(
        containing location: CGPoint,
        in screens: [ScreenGeometry]
    ) -> ScreenGeometry? {
        screens.first { screen in
            screen.frame.contains(location)
        }
    }

    static func menuBarFrame(for screen: ScreenGeometry) -> CGRect {
        let visibleTopInset = screen.frame.maxY - screen.visibleFrame.maxY
        let height = max(visibleTopInset, fallbackMenuBarHeight)

        return CGRect(
            x: screen.frame.minX,
            y: screen.frame.maxY - height,
            width: screen.frame.width,
            height: height
        )
    }

    static func clampedOverlayOrigin(
        centeredAt point: CGPoint,
        overlaySize: CGSize,
        screenFrame: CGRect,
        margin: CGFloat = 8
    ) -> CGPoint {
        let proposed = CGPoint(
            x: point.x - overlaySize.width / 2,
            y: point.y - overlaySize.height / 2
        )

        let minimumX = screenFrame.minX + margin
        let maximumX = screenFrame.maxX - overlaySize.width - margin
        let minimumY = screenFrame.minY + margin
        let maximumY = screenFrame.maxY - overlaySize.height - margin

        return CGPoint(
            x: clamp(proposed.x, minimumX, maximumX),
            y: clamp(proposed.y, minimumY, maximumY)
        )
    }

    private static func clamp(_ value: CGFloat, _ lowerBound: CGFloat, _ upperBound: CGFloat) -> CGFloat {
        guard lowerBound <= upperBound else {
            return lowerBound
        }

        return min(max(value, lowerBound), upperBound)
    }
}
