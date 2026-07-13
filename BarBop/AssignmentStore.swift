//
//  AssignmentStore.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import Foundation

final class AssignmentStore {
    private struct StoredState: Codable, Equatable {
        var schemaVersion: Int
        var detectedItems: [DetectedStatusItem]
        var assignments: [CharacterAssignment]
        var settings: ReactionSettings
    }

    private static let currentSchemaVersion = 1
    private let userDefaults: UserDefaults
    private let storageKey: String
    private var state: StoredState

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "BarBop.AssignmentStore"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.state = Self.loadState(from: userDefaults, key: storageKey)
    }

    var detectedItems: [DetectedStatusItem] {
        state.detectedItems.sorted { $0.lastDetectedAt > $1.lastDetectedAt }
    }

    var assignments: [CharacterAssignment] {
        state.assignments
    }

    var settings: ReactionSettings {
        state.settings
    }

    func recordDetectedItem(_ item: DetectedStatusItem) {
        if let index = state.detectedItems.firstIndex(where: { $0.id == item.id }) {
            state.detectedItems[index].bundleIdentifier = item.bundleIdentifier ?? state.detectedItems[index].bundleIdentifier
            state.detectedItems[index].applicationName = item.applicationName ?? state.detectedItems[index].applicationName
            state.detectedItems[index].itemTitle = item.itemTitle ?? state.detectedItems[index].itemTitle
            state.detectedItems[index].accessibilityIdentifier = item.accessibilityIdentifier ?? state.detectedItems[index].accessibilityIdentifier
            state.detectedItems[index].lastDetectedAt = item.lastDetectedAt
        } else {
            state.detectedItems.append(item)
        }

        save()
    }

    func characterID(for statusItemID: String) -> UUID {
        state.assignments.first { $0.statusItemID == statusItemID }?.characterID ?? state.settings.defaultCharacterID
    }

    func assign(characterID: UUID, to statusItemID: String) {
        if let index = state.assignments.firstIndex(where: { $0.statusItemID == statusItemID }) {
            state.assignments[index].characterID = characterID
        } else {
            state.assignments.append(CharacterAssignment(statusItemID: statusItemID, characterID: characterID))
        }

        save()
    }

    func removeAssignment(for statusItemID: String) {
        state.assignments.removeAll { $0.statusItemID == statusItemID }
        save()
    }

    func resetAssignments() {
        state.assignments.removeAll()
        save()
    }

    func clearDetectedItems() {
        state.detectedItems.removeAll()
        state.assignments.removeAll()
        save()
    }

    func updateSettings(_ settings: ReactionSettings) {
        state.settings = settings
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

        return state
    }

    private static func defaultState() -> StoredState {
        StoredState(
            schemaVersion: currentSchemaVersion,
            detectedItems: [],
            assignments: [],
            settings: .defaults
        )
    }
}
