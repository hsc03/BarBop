//
//  EffectSettingsStore.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import Foundation

final class EffectSettingsStore {
    private struct SchemaHeader: Decodable {
        var schemaVersion: Int
    }

    private struct StoredState: Codable, Equatable {
        var schemaVersion: Int
        var settings: EffectSettings
    }

    private struct LegacyStoredState: Decodable {
        var schemaVersion: Int
        var settings: LegacyEffectSettings
    }

    private struct LegacyVersionTwoStoredState: Decodable {
        var schemaVersion: Int
        var settings: LegacyVersionTwoEffectSettings
    }

    private struct LegacyVersionTwoEffectSettings: Decodable {
        var isEnabled: Bool
        var notificationEffectsEnabled: Bool
        var color: CodableColor
        var auroraPalette: AuroraPalette
        var opacity: Double
        var duration: Double
        var style: EffectSettings.Style

        var migrated: EffectSettings {
            EffectSettings(
                isEnabled: isEnabled,
                notificationEffectsEnabled: notificationEffectsEnabled,
                notificationDisplayTarget: .followNotification,
                color: color,
                auroraPalette: auroraPalette,
                opacity: opacity,
                duration: duration,
                style: style
            )
        }
    }

    private struct LegacyEffectSettings: Decodable {
        var isEnabled: Bool
        var color: CodableColor
        var opacity: Double
        var duration: Double
        var style: EffectSettings.Style

        var migrated: EffectSettings {
            EffectSettings(
                isEnabled: isEnabled,
                notificationEffectsEnabled: false,
                notificationDisplayTarget: .followNotification,
                color: color,
                auroraPalette: .defaults,
                opacity: opacity,
                duration: duration,
                style: style
            )
        }
    }

    private static let currentSchemaVersion = 3
    private let userDefaults: UserDefaults
    private let storageKey: String
    private var state: StoredState

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "BarBop.EffectSettingsStore"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.state = Self.loadState(from: userDefaults, key: storageKey)
    }

    var settings: EffectSettings {
        state.settings
    }

    func updateSettings(_ settings: EffectSettings) {
        state.settings = settings.clamped
        save()
    }

    func resetToDefaults() {
        state = Self.defaultState()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(state) else {
            return
        }

        userDefaults.set(data, forKey: storageKey)
    }

    private static func loadState(from userDefaults: UserDefaults, key: String) -> StoredState {
        guard let data = userDefaults.data(forKey: key) else {
            return defaultState()
        }

        let decoder = JSONDecoder()
        guard let header = try? decoder.decode(SchemaHeader.self, from: data) else {
            return defaultState()
        }

        switch header.schemaVersion {
        case currentSchemaVersion:
            guard let state = try? decoder.decode(StoredState.self, from: data) else {
                return defaultState()
            }
            return StoredState(
                schemaVersion: currentSchemaVersion,
                settings: state.settings.clamped
            )
        case 1:
            guard let state = try? decoder.decode(LegacyStoredState.self, from: data) else {
                return defaultState()
            }
            let migratedState = StoredState(
                schemaVersion: currentSchemaVersion,
                settings: state.settings.migrated.clamped
            )
            if let migratedData = try? JSONEncoder().encode(migratedState) {
                userDefaults.set(migratedData, forKey: key)
            }
            return migratedState
        case 2:
            guard let state = try? decoder.decode(LegacyVersionTwoStoredState.self, from: data) else {
                return defaultState()
            }
            let migratedState = StoredState(
                schemaVersion: currentSchemaVersion,
                settings: state.settings.migrated.clamped
            )
            if let migratedData = try? JSONEncoder().encode(migratedState) {
                userDefaults.set(migratedData, forKey: key)
            }
            return migratedState
        default:
            return defaultState()
        }
    }

    private static func defaultState() -> StoredState {
        StoredState(
            schemaVersion: currentSchemaVersion,
            settings: .defaults
        )
    }
}
