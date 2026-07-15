//
//  EffectSettings.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import AppKit
import Foundation

struct AuroraPalette: Codable, Equatable {
    var leading: CodableColor
    var middle: CodableColor
    var trailing: CodableColor

    static let defaults = AuroraPalette(
        leading: CodableColor(nsColor: .systemBlue),
        middle: CodableColor(nsColor: .systemPurple),
        trailing: CodableColor(nsColor: .systemTeal)
    )
}

struct NotificationDisplayTarget: Codable, Equatable {
    enum Mode: String, Codable, CaseIterable {
        case followNotification
        case mainDisplay
        case specificDisplay
        case allDisplays
    }

    var mode: Mode
    var displayIdentifier: String?
    var displayName: String?

    static let followNotification = NotificationDisplayTarget(mode: .followNotification)
    static let mainDisplay = NotificationDisplayTarget(mode: .mainDisplay)
    static let allDisplays = NotificationDisplayTarget(mode: .allDisplays)

    static func specificDisplay(identifier: String, name: String) -> NotificationDisplayTarget {
        NotificationDisplayTarget(
            mode: .specificDisplay,
            displayIdentifier: identifier,
            displayName: name
        )
    }

    private init(
        mode: Mode,
        displayIdentifier: String? = nil,
        displayName: String? = nil
    ) {
        self.mode = mode
        self.displayIdentifier = displayIdentifier
        self.displayName = displayName
    }

    var normalized: NotificationDisplayTarget {
        guard mode == .specificDisplay else {
            return NotificationDisplayTarget(mode: mode)
        }
        guard let displayIdentifier, !displayIdentifier.isEmpty else {
            return .mainDisplay
        }
        let resolvedName = displayName.flatMap { $0.isEmpty ? nil : $0 } ?? "Selected Display"
        return .specificDisplay(identifier: displayIdentifier, name: resolvedName)
    }
}

struct EffectSettings: Codable, Equatable {
    enum Style: String, Codable, CaseIterable, Identifiable {
        case flash
        case pulse
        case sweep
        case aurora

        var id: String { rawValue }
    }

    var isEnabled: Bool
    var notificationEffectsEnabled: Bool
    var notificationDisplayTarget: NotificationDisplayTarget
    var color: CodableColor
    var auroraPalette: AuroraPalette
    var opacity: Double
    var duration: Double
    var style: Style

    init(
        isEnabled: Bool,
        notificationEffectsEnabled: Bool = false,
        notificationDisplayTarget: NotificationDisplayTarget = .followNotification,
        color: CodableColor,
        auroraPalette: AuroraPalette = .defaults,
        opacity: Double,
        duration: Double,
        style: Style
    ) {
        self.isEnabled = isEnabled
        self.notificationEffectsEnabled = notificationEffectsEnabled
        self.notificationDisplayTarget = notificationDisplayTarget
        self.color = color
        self.auroraPalette = auroraPalette
        self.opacity = opacity
        self.duration = duration
        self.style = style
    }

    var clamped: EffectSettings {
        EffectSettings(
            isEnabled: isEnabled,
            notificationEffectsEnabled: notificationEffectsEnabled,
            notificationDisplayTarget: notificationDisplayTarget.normalized,
            color: color,
            auroraPalette: auroraPalette,
            opacity: min(max(opacity, 0.05), 1),
            duration: min(max(duration, 0.1), 1),
            style: style
        )
    }
}

extension EffectSettings {
    static let defaults = EffectSettings(
        isEnabled: true,
        notificationEffectsEnabled: false,
        notificationDisplayTarget: .followNotification,
        color: CodableColor(nsColor: .systemBlue),
        auroraPalette: .defaults,
        opacity: 0.35,
        duration: 0.28,
        style: .flash
    )
}
