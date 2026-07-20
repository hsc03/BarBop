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

        if reduceMotion {
            configureBloomLayer(color: settings.color.nsColor, opacity: settings.opacity)
            playFlash(duration: settings.duration, completion: completion)
        } else {
            switch settings.style {
            case .flash:
                configureBloomLayer(color: settings.color.nsColor, opacity: settings.opacity)
                playFlash(duration: settings.duration, completion: completion)
            case .pulse:
                configureBloomLayer(color: settings.color.nsColor, opacity: settings.opacity)
                playPulse(duration: settings.duration, completion: completion)
            case .sweep:
                configureSweepLayer(color: settings.color.nsColor, opacity: settings.opacity)
                playSweep(duration: settings.duration, completion: completion)
            case .lightning:
                configureLightningLayer(color: settings.color.nsColor, opacity: settings.opacity)
                playLightning(duration: settings.duration, completion: completion)
            case .shimmer:
                configureShimmerLayer(
                    color: settings.color.nsColor,
                    opacity: settings.opacity,
                    duration: settings.duration
                )
                playShimmer(duration: settings.duration, completion: completion)
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

        let bloom = CAKeyframeAnimation(keyPath: "transform.scale.y")
        bloom.values = [0.82, 1.04, 1]
        bloom.keyTimes = [0, 0.38, 1]
        bloom.duration = fadeInDuration + fadeOutDuration
        bloom.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        bloom.fillMode = .forwards
        bloom.isRemovedOnCompletion = false

        playGroup(
            animations: [fadeIn, fadeOut, bloom],
            duration: fadeInDuration + fadeOutDuration,
            completion: completion
        )
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

        let breathing = CAKeyframeAnimation(keyPath: "transform.scale.y")
        breathing.values = [0.76, 1, 0.86, 1.03, 0.8]
        breathing.keyTimes = [0, 0.18, 0.45, 0.68, 1]
        breathing.duration = duration
        breathing.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeIn)
        ]
        breathing.fillMode = .forwards
        breathing.isRemovedOnCompletion = false

        playGroup(animations: [opacity, breathing], duration: duration, completion: completion)
    }

    private func playSweep(duration: TimeInterval, completion: @escaping () -> Void) {
        let sweepWidth = max(bounds.width * 0.32, 140)
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

    private func playLightning(duration: TimeInterval, completion: @escaping () -> Void) {
        effectLayer.frame = bounds
        effectLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        effectLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        let strobe = CAKeyframeAnimation(keyPath: "opacity")
        strobe.values = [0, 1, 0.04, 0.76, 0.08, 1, 0.42, 0]
        strobe.keyTimes = [0, 0.05, 0.13, 0.2, 0.3, 0.4, 0.58, 1]
        strobe.duration = duration
        strobe.timingFunctions = [
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .easeIn)
        ]
        strobe.fillMode = .forwards
        strobe.isRemovedOnCompletion = false

        let snap = CAKeyframeAnimation(keyPath: "transform.translation.x")
        snap.values = [-3, 2, -1, 1, 0]
        snap.keyTimes = [0, 0.13, 0.3, 0.58, 1]
        snap.duration = duration
        snap.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        snap.fillMode = .forwards
        snap.isRemovedOnCompletion = false

        playGroup(animations: [strobe, snap], duration: duration, completion: completion)
    }

    private func playShimmer(duration: TimeInterval, completion: @escaping () -> Void) {
        effectLayer.frame = bounds
        effectLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        effectLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        let opacity = CAKeyframeAnimation(keyPath: "opacity")
        opacity.values = [0, 1, 1, 0]
        opacity.keyTimes = [0, 0.12, 0.78, 1]
        opacity.duration = duration
        opacity.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .linear),
            CAMediaTimingFunction(name: .easeIn)
        ]
        opacity.fillMode = .forwards
        opacity.isRemovedOnCompletion = false

        let drift = CABasicAnimation(keyPath: "transform.translation.x")
        drift.fromValue = -bounds.width * 0.025
        drift.toValue = bounds.width * 0.025
        drift.duration = duration
        drift.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        drift.fillMode = .forwards
        drift.isRemovedOnCompletion = false

        playGroup(animations: [opacity, drift], duration: duration, completion: completion)
    }

    private func playAurora(settings: EffectSettings, completion: @escaping () -> Void) {
        let container = CALayer()
        container.frame = bounds.insetBy(dx: -bounds.width * 0.42, dy: 0)
        container.opacity = 0

        let primary = CAGradientLayer()
        primary.frame = container.bounds
        primary.startPoint = CGPoint(x: 0, y: 0.5)
        primary.endPoint = CGPoint(x: 1, y: 0.5)
        primary.colors = Self.auroraColors(
            from: settings.auroraPalette,
            opacity: settings.opacity
        ).map(\.cgColor)
        primary.locations = [0, 0.22, 0.48, 0.74, 1]

        let secondary = CAGradientLayer()
        secondary.frame = container.bounds.offsetBy(dx: container.bounds.width * 0.08, dy: 0)
        secondary.startPoint = CGPoint(x: 0, y: 0.5)
        secondary.endPoint = CGPoint(x: 1, y: 0.5)
        secondary.colors = Self.auroraColors(
            from: AuroraPalette(
                leading: settings.auroraPalette.trailing,
                middle: settings.auroraPalette.leading,
                trailing: settings.auroraPalette.middle
            ),
            opacity: settings.opacity * 0.48
        ).map(\.cgColor)
        secondary.locations = [0, 0.18, 0.5, 0.78, 1]

        let falloffMask = CAGradientLayer()
        falloffMask.frame = container.bounds
        falloffMask.startPoint = CGPoint(x: 0.5, y: 0)
        falloffMask.endPoint = CGPoint(x: 0.5, y: 1)
        falloffMask.colors = [
            NSColor.black.withAlphaComponent(0.38).cgColor,
            NSColor.black.cgColor,
            NSColor.black.withAlphaComponent(0.58).cgColor
        ]
        falloffMask.locations = [0, 0.48, 1]

        container.addSublayer(primary)
        container.addSublayer(secondary)
        container.mask = falloffMask

        replaceEffectLayer(with: container)

        let position = CABasicAnimation(keyPath: "position.x")
        position.fromValue = bounds.midX - bounds.width * 0.18
        position.toValue = bounds.midX + bounds.width * 0.18
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

        let flow = CAKeyframeAnimation(keyPath: "transform.scale.x")
        flow.values = [1, 1.07, 0.98]
        flow.keyTimes = [0, 0.52, 1]
        flow.duration = settings.duration
        flow.timingFunctions = [
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        flow.fillMode = .forwards
        flow.isRemovedOnCompletion = false

        playGroup(
            animations: [position, opacity, flow],
            duration: settings.duration,
            completion: completion
        )
    }

    private func configureBloomLayer(color: NSColor, opacity: Double) {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        gradient.colors = [
            color.withAlphaComponent(opacity * 0.45).cgColor,
            color.withAlphaComponent(opacity).cgColor,
            color.withAlphaComponent(opacity * 0.62).cgColor
        ]
        gradient.locations = [0, 0.46, 1]
        gradient.opacity = 0
        replaceEffectLayer(with: gradient)
    }

    private func configureSweepLayer(color: NSColor, opacity: Double) {
        let gradient = CAGradientLayer()
        let highlight = color.blended(withFraction: 0.46, of: .white) ?? color
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.colors = [
            color.withAlphaComponent(0).cgColor,
            color.withAlphaComponent(opacity * 0.12).cgColor,
            color.withAlphaComponent(opacity * 0.68).cgColor,
            highlight.withAlphaComponent(opacity).cgColor,
            color.withAlphaComponent(opacity * 0.68).cgColor,
            color.withAlphaComponent(opacity * 0.12).cgColor,
            color.withAlphaComponent(0).cgColor
        ]
        gradient.locations = [0, 0.16, 0.36, 0.5, 0.64, 0.84, 1]
        gradient.opacity = 0
        replaceEffectLayer(with: gradient)
    }

    private func configureLightningLayer(color: NSColor, opacity: Double) {
        let container = CALayer()
        container.frame = bounds
        container.opacity = 0

        let flash = CAGradientLayer()
        flash.frame = container.bounds
        flash.startPoint = CGPoint(x: 0, y: 0.5)
        flash.endPoint = CGPoint(x: 1, y: 0.5)
        let highlight = color.blended(withFraction: 0.72, of: .white) ?? .white
        flash.colors = [
            color.withAlphaComponent(opacity * 0.08).cgColor,
            color.withAlphaComponent(opacity * 0.38).cgColor,
            highlight.withAlphaComponent(opacity * 0.78).cgColor,
            color.withAlphaComponent(opacity * 0.24).cgColor,
            highlight.withAlphaComponent(opacity * 0.62).cgColor,
            color.withAlphaComponent(opacity * 0.08).cgColor
        ]
        flash.locations = [0, 0.17, 0.36, 0.56, 0.78, 1]

        let bolt = CAShapeLayer()
        bolt.frame = container.bounds
        bolt.path = Self.lightningPath(in: container.bounds)
        bolt.fillColor = NSColor.clear.cgColor
        bolt.strokeColor = highlight.withAlphaComponent(opacity).cgColor
        bolt.lineWidth = 1.35
        bolt.lineCap = .round
        bolt.lineJoin = .miter
        bolt.shadowColor = color.withAlphaComponent(opacity).cgColor
        bolt.shadowOpacity = 0.95
        bolt.shadowRadius = 5
        bolt.shadowOffset = .zero

        let branch = CAShapeLayer()
        branch.frame = container.bounds
        branch.path = Self.lightningBranchPath(in: container.bounds)
        branch.fillColor = NSColor.clear.cgColor
        branch.strokeColor = color.withAlphaComponent(opacity * 0.72).cgColor
        branch.lineWidth = 0.8
        branch.lineCap = .round
        branch.shadowColor = color.cgColor
        branch.shadowOpacity = 0.65
        branch.shadowRadius = 3
        branch.shadowOffset = .zero

        container.addSublayer(flash)
        container.addSublayer(branch)
        container.addSublayer(bolt)
        replaceEffectLayer(with: container)
    }

    private func configureShimmerLayer(color: NSColor, opacity: Double, duration: TimeInterval) {
        let container = CALayer()
        container.frame = bounds
        container.opacity = 0

        let trail = CAGradientLayer()
        trail.frame = container.bounds
        trail.startPoint = CGPoint(x: 0, y: 0.5)
        trail.endPoint = CGPoint(x: 1, y: 0.5)
        trail.colors = [
            color.withAlphaComponent(0).cgColor,
            color.withAlphaComponent(opacity * 0.1).cgColor,
            color.withAlphaComponent(opacity * 0.2).cgColor,
            color.withAlphaComponent(opacity * 0.1).cgColor,
            color.withAlphaComponent(0).cgColor
        ]
        trail.locations = [0, 0.2, 0.5, 0.8, 1]
        container.addSublayer(trail)

        let sparkleLayout: [(
            x: CGFloat,
            y: CGFloat,
            size: CGFloat,
            delay: Double,
            rotation: CGFloat
        )] = [
            (0.03, 0.3, 3.4, 0, 0.18),
            (0.09, 0.67, 5.2, 0.06, 0),
            (0.15, 0.4, 4.1, 0.14, 0.3),
            (0.21, 0.74, 7.1, 0.19, 0),
            (0.28, 0.28, 3.8, 0.27, 0.22),
            (0.34, 0.58, 5.7, 0.32, 0),
            (0.4, 0.78, 4.3, 0.38, 0.28),
            (0.47, 0.38, 7.6, 0.44, 0),
            (0.53, 0.7, 3.6, 0.5, 0.2),
            (0.59, 0.27, 5, 0.55, 0),
            (0.65, 0.62, 6.9, 0.61, 0.24),
            (0.71, 0.8, 3.5, 0.66, 0),
            (0.77, 0.36, 5.5, 0.72, 0.2),
            (0.83, 0.68, 7.3, 0.76, 0),
            (0.9, 0.25, 3.9, 0.82, 0.28),
            (0.96, 0.55, 5.1, 0.88, 0)
        ]
        let highlight = color.blended(withFraction: 0.74, of: .white) ?? .white

        for item in sparkleLayout {
            let sparkle = CAShapeLayer()
            sparkle.bounds = CGRect(x: 0, y: 0, width: item.size, height: item.size)
            sparkle.position = CGPoint(
                x: container.bounds.width * item.x,
                y: container.bounds.height * item.y
            )
            sparkle.path = Self.sparklePath(size: item.size)
            sparkle.setAffineTransform(CGAffineTransform(rotationAngle: item.rotation))
            sparkle.fillColor = highlight.withAlphaComponent(opacity).cgColor
            sparkle.shadowColor = color.withAlphaComponent(opacity).cgColor
            sparkle.shadowOpacity = 0.85
            sparkle.shadowRadius = item.size * 0.7
            sparkle.shadowOffset = .zero
            sparkle.opacity = 0
            container.addSublayer(sparkle)

            let twinkleDuration = max(0.12, duration * 0.38)
            let twinkle = CAKeyframeAnimation(keyPath: "opacity")
            twinkle.values = [0, 1, 0.45, 0]
            twinkle.keyTimes = [0, 0.32, 0.62, 1]

            let scale = CAKeyframeAnimation(keyPath: "transform.scale")
            scale.values = [0.18, 1.22, 0.78, 0.12]
            scale.keyTimes = [0, 0.32, 0.62, 1]

            let group = CAAnimationGroup()
            group.animations = [twinkle, scale]
            group.beginTime = sparkle.convertTime(CACurrentMediaTime(), from: nil)
                + duration * 0.52 * item.delay
            group.duration = twinkleDuration
            group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            group.fillMode = .forwards
            group.isRemovedOnCompletion = false
            sparkle.add(group, forKey: "twinkle")
        }

        replaceEffectLayer(with: container)
    }

    private static func lightningPath(in bounds: CGRect) -> CGPath {
        let path = CGMutablePath()
        let points: [(CGFloat, CGFloat)] = [
            (0, 0.58), (0.11, 0.43), (0.2, 0.66), (0.31, 0.31),
            (0.43, 0.7), (0.54, 0.38), (0.64, 0.62), (0.74, 0.27),
            (0.85, 0.65), (1, 0.45)
        ]
        guard let first = points.first else { return path }
        path.move(to: CGPoint(x: bounds.width * first.0, y: bounds.height * first.1))
        for point in points.dropFirst() {
            path.addLine(to: CGPoint(x: bounds.width * point.0, y: bounds.height * point.1))
        }
        return path
    }

    private static func lightningBranchPath(in bounds: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: bounds.width * 0.31, y: bounds.height * 0.31))
        path.addLine(to: CGPoint(x: bounds.width * 0.36, y: bounds.height * 0.12))
        path.addLine(to: CGPoint(x: bounds.width * 0.41, y: bounds.height * 0.26))
        path.move(to: CGPoint(x: bounds.width * 0.74, y: bounds.height * 0.27))
        path.addLine(to: CGPoint(x: bounds.width * 0.8, y: bounds.height * 0.08))
        return path
    }

    private static func sparklePath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let center = size / 2
        let inner = size * 0.16
        path.move(to: CGPoint(x: center, y: 0))
        path.addLine(to: CGPoint(x: center + inner, y: center - inner))
        path.addLine(to: CGPoint(x: size, y: center))
        path.addLine(to: CGPoint(x: center + inner, y: center + inner))
        path.addLine(to: CGPoint(x: center, y: size))
        path.addLine(to: CGPoint(x: center - inner, y: center + inner))
        path.addLine(to: CGPoint(x: 0, y: center))
        path.addLine(to: CGPoint(x: center - inner, y: center - inner))
        path.closeSubpath()
        return path
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
