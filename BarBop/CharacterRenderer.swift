//
//  CharacterRenderer.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import AppKit
import QuartzCore

final class CharacterRenderer: NSView {
    private let characterView = PlaceholderCharacterView(frame: CGRect(x: 20, y: 22, width: 56, height: 56))
    private var completionWorkItem: DispatchWorkItem?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        addSubview(characterView)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var isOpaque: Bool {
        false
    }

    func resetForPlayback() {
        stop()
        alphaValue = 1
        characterView.alphaValue = 1
        characterView.frame = restingFrame
        characterView.needsDisplay = true
    }

    func play(motionMode: ReactionMotionMode, completion: @escaping () -> Void) {
        switch motionMode {
        case .fullMotion:
            playDropInReaction(completion: completion)
        case .reducedMotion:
            playReducedMotionReaction(completion: completion)
        }
    }

    func stop() {
        completionWorkItem?.cancel()
        completionWorkItem = nil
        characterView.layer?.removeAllAnimations()
        layer?.removeAllAnimations()
        animator().alphaValue = 1
    }

    private var restingFrame: CGRect {
        CGRect(x: 20, y: 22, width: 56, height: 56)
    }

    private var aboveFrame: CGRect {
        CGRect(x: 20, y: 96, width: 56, height: 56)
    }

    private func playDropInReaction(completion: @escaping () -> Void) {
        characterView.frame = aboveFrame
        characterView.alphaValue = 1

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.24
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            characterView.animator().frame = restingFrame
        }, completionHandler: {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.characterView.animator().frame = self.restingFrame.offsetBy(dx: 0, dy: -5)
            }, completionHandler: {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.38
                    context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                    self.characterView.animator().frame = self.aboveFrame
                    self.characterView.animator().alphaValue = 0
                }, completionHandler: completion)
            })
        })
    }

    private func playReducedMotionReaction(completion: @escaping () -> Void) {
        characterView.frame = restingFrame
        characterView.alphaValue = 0

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            characterView.animator().alphaValue = 1
        }, completionHandler: {
            let workItem = DispatchWorkItem {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.2
                    context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                    self.characterView.animator().alphaValue = 0
                }, completionHandler: completion)
            }
            self.completionWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28, execute: workItem)
        })
    }
}

private final class PlaceholderCharacterView: NSView {
    override var isOpaque: Bool {
        false
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()

        let bodyRect = bounds.insetBy(dx: 7, dy: 6)
        NSColor.systemTeal.withAlphaComponent(0.95).setFill()
        NSBezierPath(roundedRect: bodyRect, xRadius: 14, yRadius: 14).fill()

        NSColor.white.withAlphaComponent(0.95).setFill()
        NSBezierPath(ovalIn: CGRect(x: bodyRect.minX + 12, y: bodyRect.midY + 2, width: 7, height: 7)).fill()
        NSBezierPath(ovalIn: CGRect(x: bodyRect.maxX - 19, y: bodyRect.midY + 2, width: 7, height: 7)).fill()

        NSColor.black.withAlphaComponent(0.72).setStroke()
        let smile = NSBezierPath()
        smile.lineWidth = 2
        smile.move(to: CGPoint(x: bodyRect.midX - 8, y: bodyRect.midY - 7))
        smile.curve(
            to: CGPoint(x: bodyRect.midX + 8, y: bodyRect.midY - 7),
            controlPoint1: CGPoint(x: bodyRect.midX - 4, y: bodyRect.midY - 12),
            controlPoint2: CGPoint(x: bodyRect.midX + 4, y: bodyRect.midY - 12)
        )
        smile.stroke()
    }
}
