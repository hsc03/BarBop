//
//  ContentView.swift
//  BarBop
//
//  Created by 황성철 on 7/7/26.
//

import SwiftUI

struct ContentView: View {
    @State private var snapshot = SettingsSnapshot(environment: .shared)
    private let environment = AppEnvironment.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            controls
            Divider()
            detectedItemsList
            actions
        }
        .frame(minWidth: 620, minHeight: 480, alignment: .topLeading)
        .padding(20)
        .onAppear {
            reload()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("BarBop Settings")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Detected menu bar items and prototype character assignments are stored locally.")
                .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
            GridRow {
                Text("Reactions")
                Toggle("Enabled", isOn: settingsBinding(\.isEnabled))
                    .labelsHidden()
            }

            GridRow {
                Text("Default Character")
                characterPicker(selection: settingsBinding(\.defaultCharacterID))
            }

            GridRow {
                Text("Size")
                Picker("Size", selection: settingsBinding(\.size)) {
                    ForEach(ReactionSettings.Size.allCases) { size in
                        Text(label(for: size)).tag(size)
                    }
                }
                .pickerStyle(.segmented)
            }

            GridRow {
                Text("Motion")
                Picker("Motion", selection: settingsBinding(\.motionIntensity)) {
                    ForEach(ReactionSettings.MotionIntensity.allCases) { intensity in
                        Text(label(for: intensity)).tag(intensity)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var detectedItemsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Detected Menu Bar Items")
                .font(.headline)

            if snapshot.detectedItems.isEmpty {
                ContentUnavailableView(
                    "No Items Detected",
                    systemImage: "menubar.rectangle",
                    description: Text("Click menu bar items while BarBop is running to populate this list.")
                )
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                List(snapshot.detectedItems) { item in
                    detectedItemRow(item)
                }
                .frame(minHeight: 220)
            }
        }
    }

    private func detectedItemRow(_ item: DetectedStatusItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(displayName(for: item))
                    .font(.body)
                Text(detailText(for: item))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Last detected \(item.lastDetectedAt.formatted(date: .abbreviated, time: .standard))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            characterPicker(
                selection: Binding(
                    get: {
                        snapshot.assignmentMap[item.id] ?? snapshot.settings.defaultCharacterID
                    },
                    set: { characterID in
                        environment.assignmentStore.assign(characterID: characterID, to: item.id)
                        reload()
                    }
                )
            )
            .frame(width: 180)

            Button("Default") {
                environment.assignmentStore.removeAssignment(for: item.id)
                reload()
            }
            .disabled(snapshot.assignmentMap[item.id] == nil)
        }
        .padding(.vertical, 4)
    }

    private var actions: some View {
        HStack {
            Button("Reset Mappings") {
                environment.assignmentStore.resetAssignments()
                reload()
            }
            .disabled(snapshot.assignments.isEmpty)

            Button("Clear Detected Items") {
                environment.assignmentStore.clearDetectedItems()
                reload()
            }
            .disabled(snapshot.detectedItems.isEmpty)

            Spacer()

            Button("Reload") {
                reload()
            }
        }
    }

    private func characterPicker(selection: Binding<UUID>) -> some View {
        Picker("Character", selection: selection) {
            ForEach(snapshot.characters) { character in
                Text(character.name).tag(character.id)
            }
        }
    }

    private func settingsBinding<Value>(_ keyPath: WritableKeyPath<ReactionSettings, Value>) -> Binding<Value> {
        Binding(
            get: {
                snapshot.settings[keyPath: keyPath]
            },
            set: { value in
                var settings = snapshot.settings
                settings[keyPath: keyPath] = value
                environment.assignmentStore.updateSettings(settings)
                reload()
            }
        )
    }

    private func reload() {
        snapshot = SettingsSnapshot(environment: environment)
    }

    private func displayName(for item: DetectedStatusItem) -> String {
        if let itemTitle = item.itemTitle, !itemTitle.isEmpty {
            return itemTitle
        }

        if let applicationName = item.applicationName, !applicationName.isEmpty {
            return applicationName
        }

        return "Unidentified Item"
    }

    private func detailText(for item: DetectedStatusItem) -> String {
        [item.applicationName, item.bundleIdentifier, item.accessibilityIdentifier]
            .compactMap { value in
                guard let value, !value.isEmpty else {
                    return nil
                }

                return value
            }
            .joined(separator: " / ")
    }

    private func label(for size: ReactionSettings.Size) -> String {
        switch size {
        case .small:
            return "Small"
        case .medium:
            return "Medium"
        case .large:
            return "Large"
        }
    }

    private func label(for intensity: ReactionSettings.MotionIntensity) -> String {
        switch intensity {
        case .subtle:
            return "Subtle"
        case .normal:
            return "Normal"
        case .playful:
            return "Playful"
        }
    }
}

private struct SettingsSnapshot {
    var characters: [Character]
    var detectedItems: [DetectedStatusItem]
    var assignments: [CharacterAssignment]
    var assignmentMap: [String: UUID]
    var settings: ReactionSettings

    init(environment: AppEnvironment) {
        characters = environment.characterStore.characters
        detectedItems = environment.assignmentStore.detectedItems
        assignments = environment.assignmentStore.assignments
        assignmentMap = Dictionary(uniqueKeysWithValues: assignments.map { ($0.statusItemID, $0.characterID) })
        settings = environment.assignmentStore.settings
    }
}
