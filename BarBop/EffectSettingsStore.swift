//
//  EffectSettingsStore.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import Foundation

final class EffectSettingsStore {
    private struct StoredState: Codable, Equatable {
        var schemaVersion: Int
        var settings: EffectSettings
    }

    private static let currentSchemaVersion = 1
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
        guard
            let data = userDefaults.data(forKey: key),
            let state = try? JSONDecoder().decode(StoredState.self, from: data),
            state.schemaVersion == currentSchemaVersion
        else {
            return defaultState()
        }

        return StoredState(
            schemaVersion: currentSchemaVersion,
            settings: state.settings.clamped
        )
    }

    private static func defaultState() -> StoredState {
        StoredState(
            schemaVersion: currentSchemaVersion,
            settings: .defaults
        )
    }
}
