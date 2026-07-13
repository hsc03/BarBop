//
//  ReactionSettings.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import Foundation

struct ReactionSettings: Codable, Equatable {
    enum Size: String, Codable, CaseIterable, Identifiable {
        case small
        case medium
        case large

        var id: String { rawValue }
    }

    enum MotionIntensity: String, Codable, CaseIterable, Identifiable {
        case subtle
        case normal
        case playful

        var id: String { rawValue }
    }

    var isEnabled: Bool
    var defaultCharacterID: UUID
    var size: Size
    var motionIntensity: MotionIntensity
    var launchAtLogin: Bool
}

extension ReactionSettings {
    static let defaults = ReactionSettings(
        isEnabled: true,
        defaultCharacterID: Character.placeholderID,
        size: .medium,
        motionIntensity: .normal,
        launchAtLogin: false
    )
}
