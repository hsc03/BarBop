//
//  EffectSettings.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import AppKit
import Foundation

struct EffectSettings: Codable, Equatable {
    enum Style: String, Codable, CaseIterable, Identifiable {
        case flash
        case pulse
        case sweep

        var id: String { rawValue }
    }

    var isEnabled: Bool
    var color: CodableColor
    var opacity: Double
    var duration: Double
    var style: Style

    var clamped: EffectSettings {
        EffectSettings(
            isEnabled: isEnabled,
            color: color,
            opacity: min(max(opacity, 0.05), 1),
            duration: min(max(duration, 0.1), 1),
            style: style
        )
    }
}

extension EffectSettings {
    static let defaults = EffectSettings(
        isEnabled: true,
        color: CodableColor(nsColor: .controlAccentColor),
        opacity: 0.35,
        duration: 0.28,
        style: .flash
    )
}
