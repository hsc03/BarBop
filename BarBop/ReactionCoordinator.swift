//
//  ReactionCoordinator.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import AppKit
import CoreGraphics

enum ReactionMotionMode: Equatable {
    case fullMotion
    case reducedMotion
}

protocol ReactionRendering: AnyObject {
    func cancelCurrentReaction()
    func playReaction(at location: CGPoint, on screen: ScreenGeometry, motionMode: ReactionMotionMode)
}

final class ReactionCoordinator {
    private let renderer: ReactionRendering
    private let reduceMotionProvider: () -> Bool

    init(
        renderer: ReactionRendering,
        reduceMotionProvider: @escaping () -> Bool = {
            NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        }
    ) {
        self.renderer = renderer
        self.reduceMotionProvider = reduceMotionProvider
    }

    func handleMenuBarClick(_ click: MenuBarClick) {
        renderer.cancelCurrentReaction()
        renderer.playReaction(
            at: click.location,
            on: click.screen,
            motionMode: reduceMotionProvider() ? .reducedMotion : .fullMotion
        )
    }
}
