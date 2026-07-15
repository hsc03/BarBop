//
//  MenuBarEffectRenderer.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import AppKit
import QuartzCore

final class MenuBarEffectRenderer: NSView {
    private var effectLayer = CALayer()
    private var completionWorkItem: DispatchWorkItem?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.addSublayer(effectLayer)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var isOpaque: Bool {
        false
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        effectLayer.frame = bounds
        CATransaction.commit()
    }

    func play(settings: EffectSettings, reduceMotion: Bool, completion: @escaping () -> Void) {
        stop()

        configureSolidLayer(color: settings.color.nsColor.withAlphaComponent(settings.opacity))
        effectLayer.opacity = 0
        effectLayer.frame = bounds

        if reduceMotion {
            playFlash(duration: settings.duration, completion: completion)
        } else {
            switch settings.style {
            case .flash:
                playFlash(duration: settings.duration, completion: completion)
            case .pulse:
                playPulse(duration: settings.duration, completion: completion)
            case .sweep:
                playSweep(duration: settings.duration, completion: completion)
            case .aurora:
                playAurora(settings: settings, completion: completion)
            }
        }
    }

    func stop() {
        completionWorkItem?.cancel()
        completionWorkItem = nil
        effectLayer.removeAllAnimations()
        effectLayer.opacity = 0
    }

    private func playFlash(duration: TimeInterval, completion: @escaping () -> Void) {
        effectLayer.frame = bounds
        effectLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        effectLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        let fadeInDuration = min(0.08, duration * 0.35)
        let fadeOutDuration = max(0.08, duration - fadeInDuration)

        let fadeIn = CABasicAnimation(keyPath: "opacity")
        fadeIn.fromValue = 0
        fadeIn.toValue = 1
        fadeIn.duration = fadeInDuration
        fadeIn.timingFunction = CAMediaTimingFunction(name: .easeOut)
        fadeIn.fillMode = .forwards
        fadeIn.isRemovedOnCompletion = false

        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = 1
        fadeOut.toValue = 0
        fadeOut.beginTime = fadeInDuration
        fadeOut.duration = fadeOutDuration
        fadeOut.timingFunction = CAMediaTimingFunction(name: .easeIn)
        fadeOut.fillMode = .forwards
        fadeOut.isRemovedOnCompletion = false

        playGroup(animations: [fadeIn, fadeOut], duration: fadeInDuration + fadeOutDuration, completion: completion)
    }

    private func playPulse(duration: TimeInterval, completion: @escaping () -> Void) {
        effectLayer.frame = bounds
        effectLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        effectLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        let opacity = CAKeyframeAnimation(keyPath: "opacity")
        opacity.values = [0, 1, 0.18, 0.72, 0]
        opacity.keyTimes = [0, 0.18, 0.45, 0.68, 1]
        opacity.duration = duration
        opacity.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeIn)
        ]
        opacity.fillMode = .forwards
        opacity.isRemovedOnCompletion = false

        playGroup(animations: [opacity], duration: duration, completion: completion)
    }

    private func playSweep(duration: TimeInterval, completion: @escaping () -> Void) {
        let sweepWidth = max(bounds.width * 0.24, 80)
        effectLayer.frame = CGRect(x: -sweepWidth, y: 0, width: sweepWidth, height: bounds.height)
        effectLayer.anchorPoint = CGPoint(x: 0, y: 0.5)
        effectLayer.position = CGPoint(x: -sweepWidth, y: bounds.midY)
        effectLayer.opacity = 1

        let position = CABasicAnimation(keyPath: "position.x")
        position.fromValue = -sweepWidth
        position.toValue = bounds.width + sweepWidth
        position.duration = duration
        position.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        position.fillMode = .forwards
        position.isRemovedOnCompletion = false

        let opacity = CAKeyframeAnimation(keyPath: "opacity")
        opacity.values = [0, 1, 1, 0]
        opacity.keyTimes = [0, 0.16, 0.82, 1]
        opacity.duration = duration
        opacity.fillMode = .forwards
        opacity.isRemovedOnCompletion = false

        playGroup(animations: [position, opacity], duration: duration, completion: completion)
    }

    private func playAurora(settings: EffectSettings, completion: @escaping () -> Void) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds.insetBy(dx: -bounds.width * 0.4, dy: 0)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.colors = Self.auroraColors(
            from: settings.auroraPalette,
            opacity: settings.opacity
        ).map(\.cgColor)
        gradientLayer.locations = [0, 0.22, 0.46, 0.72, 1]
        gradientLayer.opacity = 0

        replaceEffectLayer(with: gradientLayer)

        let position = CABasicAnimation(keyPath: "position.x")
        position.fromValue = bounds.midX - bounds.width * 0.22
        position.toValue = bounds.midX + bounds.width * 0.22
        position.duration = settings.duration
        position.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        position.fillMode = .forwards
        position.isRemovedOnCompletion = false

        let opacity = CAKeyframeAnimation(keyPath: "opacity")
        opacity.values = [0, 1, 0.85, 0]
        opacity.keyTimes = [0, 0.18, 0.72, 1]
        opacity.duration = settings.duration
        opacity.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeIn)
        ]
        opacity.fillMode = .forwards
        opacity.isRemovedOnCompletion = false

        playGroup(animations: [position, opacity], duration: settings.duration, completion: completion)
    }

    private func configureSolidLayer(color: NSColor) {
        if type(of: effectLayer) != CALayer.self {
            replaceEffectLayer(with: CALayer())
        }

        effectLayer.backgroundColor = color.cgColor
    }

    private func replaceEffectLayer(with layer: CALayer) {
        effectLayer.removeAllAnimations()
        effectLayer.removeFromSuperlayer()
        effectLayer = layer
        self.layer?.addSublayer(effectLayer)
    }

    static func auroraColors(from palette: AuroraPalette, opacity: Double) -> [NSColor] {
        [
            palette.leading.nsColor,
            palette.middle.nsColor,
            palette.trailing.nsColor,
            palette.middle.nsColor,
            palette.leading.nsColor
        ].map { color in
            color.withAlphaComponent(opacity)
        }
    }

    private func playGroup(animations: [CAAnimation], duration: TimeInterval, completion: @escaping () -> Void) {
        let group = CAAnimationGroup()
        group.animations = animations
        group.duration = duration
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false

        effectLayer.add(group, forKey: "effect")

        let workItem = DispatchWorkItem {
            completion()
        }
        completionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + group.duration, execute: workItem)
    }
}
