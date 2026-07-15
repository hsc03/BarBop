//
//  ContentView.swift
//  BarBop
//
//  Created by 황성철 on 7/7/26.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @State private var settings = AppEnvironment.shared.effectSettingsStore.settings
    @State private var selectedTab: SettingsTab = .effects
    @State private var isTroubleshootingExpanded = false
    @State private var isShowingAccessibilityExplanation = false
    @ObservedObject private var environment = AppEnvironment.shared
    @ObservedObject private var testNotificationController = AppEnvironment.shared.localTestNotificationController
    @ObservedObject private var notificationEffectController = AppEnvironment.shared.notificationEffectController

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            tabPicker
            Divider()
            ScrollView {
                selectedTabContent
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.vertical, 2)
            }
            footer
        }
        .padding(20)
        .frame(width: 520, height: 520, alignment: .topLeading)
        .task {
            reload()
            notificationEffectController.refreshScreens()
            await testNotificationController.refreshAuthorizationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            notificationEffectController.refreshAccessibilityAuthorization()
            reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            notificationEffectController.refreshScreens()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("BarBop")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Menu bar effects for clicks and notifications.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var tabPicker: some View {
        Picker("Settings section", selection: $selectedTab) {
            ForEach(SettingsTab.allCases) { tab in
                Text(tab.label).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Divider()
            HStack {
                Text("Changes are saved automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Quit BarBop") {
                    NSApp.terminate(nil)
                }
            }
        }
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .effects:
            effectsTab
        case .notifications:
            notificationsTab
        }
    }

    private var effectsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Click Effects", isOn: settingsBinding(\.isEnabled))
                .fontWeight(.medium)

            if environment.clickMonitoringState == .unavailable {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)
                    Text("Click monitoring could not start. Quit and reopen BarBop, then check macOS privacy settings if the problem continues.")
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Appearance")
                    .font(.headline)
                Text("These settings are shared by click and notification effects.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
                GridRow {
                    Text("Style")
                    Picker("Style", selection: settingsBinding(\.style)) {
                        ForEach(EffectSettings.Style.allCases) { style in
                            Text(label(for: style)).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                GridRow {
                    if settings.style == .aurora {
                        Text("Aurora Colors")
                        HStack(spacing: 10) {
                            CompactColorWell(
                                selection: colorBinding(\.auroraPalette.leading),
                                accessibilityLabel: "Aurora leading color"
                            )
                            CompactColorWell(
                                selection: colorBinding(\.auroraPalette.middle),
                                accessibilityLabel: "Aurora middle color"
                            )
                            CompactColorWell(
                                selection: colorBinding(\.auroraPalette.trailing),
                                accessibilityLabel: "Aurora trailing color"
                            )
                        }
                    } else {
                        Text("Color")
                        CompactColorWell(
                            selection: colorBinding(\.color),
                            accessibilityLabel: "Effect color"
                        )
                    }
                }

                GridRow {
                    Text("Opacity")
                    HStack {
                        Slider(value: settingsBinding(\.opacity), in: 0.05...1)
                        Text(settings.opacity.formatted(.percent.precision(.fractionLength(0))))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .trailing)
                    }
                }

                GridRow {
                    Text("Duration")
                    HStack {
                        Slider(value: settingsBinding(\.duration), in: 0.1...1)
                        Text("\(settings.duration, specifier: "%.2f")s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .trailing)
                    }
                }
            }
        }
    }

    private var notificationsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(
                "Notification Effects (Experimental)",
                isOn: notificationEffectsBinding
            )
            .fontWeight(.medium)

            Text("Requires Accessibility to detect where visible notification banners appear. Notification contents are not read.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if isShowingAccessibilityExplanation {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Accessibility Access")
                        .fontWeight(.medium)
                    Text("BarBop observes only the structure and position of visible notification banners. It does not read notification contents, app names, keyboard input, or screen pixels.")
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button("Cancel") {
                            isShowingAccessibilityExplanation = false
                        }
                        Button("Continue") {
                            isShowingAccessibilityExplanation = false
                            notificationEffectController.setEnabled(true)
                            reload()
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
            }

            notificationMonitoringStatus

            Divider()

            HStack {
                Text("Display")
                Spacer()
                Picker("Notification display", selection: notificationDisplaySelectionBinding) {
                    Text("Follow Notification").tag(NotificationDisplaySelection.followNotification)
                    Text("Main Display").tag(NotificationDisplaySelection.mainDisplay)
                    Text("All Displays").tag(NotificationDisplaySelection.allDisplays)
                    Divider()
                    if let missing = missingSpecificDisplay {
                        Text("\(missing.name) (Disconnected)")
                            .tag(NotificationDisplaySelection.specificDisplay(missing.identifier))
                    }
                    ForEach(selectableDisplays, id: \.id) { display in
                        if let identifier = display.persistentIdentifier {
                            Text(display.isMain ? "\(display.name) (Main)" : display.name)
                                .tag(NotificationDisplaySelection.specificDisplay(identifier))
                        }
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 300)
            }

            if missingSpecificDisplay != nil {
                Text("The selected display is disconnected. Notification effects will use Main Display until it reconnects.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            DisclosureGroup("Troubleshooting", isExpanded: $isTroubleshootingExpanded) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Local notification permission")
                            .font(.caption)
                        Spacer()
                        Text(testNotificationPermissionLabel)
                            .font(.caption)
                            .foregroundStyle(testNotificationPermissionColor)
                    }
                    Button(testNotificationController.isSending ? "Sending…" : "Send Test Notification") {
                        Task {
                            await testNotificationController.sendTestNotification()
                        }
                    }
                    .disabled(!testNotificationController.canSendTestNotification)
                    if testNotificationController.requiresNotificationSettings {
                        Button("Open Notification Settings") {
                            testNotificationController.openNotificationSettings()
                        }
                    }
                    Text(testNotificationController.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("This sends one local BarBop notification only. It does not enable notification effects.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 10)
            }
        }
    }

    @ViewBuilder
    private var notificationMonitoringStatus: some View {
        switch notificationEffectController.state {
        case .stopped:
            EmptyView()
        case .active:
            compactNotificationStatus(label: "Active", color: .green, symbol: "checkmark.circle.fill")
        case .connecting:
            compactNotificationStatus(label: "Connecting…", color: .blue, symbol: "arrow.trianglehead.2.clockwise.rotate.90")
        case .permissionRequired, .unavailable:
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)
                    Text(notificationEffectController.statusMessage)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if notificationEffectController.state == .permissionRequired {
                    Button("Open Accessibility Settings") {
                        notificationEffectController.openAccessibilitySettings()
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func compactNotificationStatus(label: String, color: Color, symbol: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func colorBinding(_ keyPath: WritableKeyPath<EffectSettings, CodableColor>) -> Binding<NSColor> {
        Binding(
            get: {
                settings[keyPath: keyPath].nsColor
            },
            set: { color in
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                let convertedColor = color.usingColorSpace(.sRGB) ?? .systemBlue
                convertedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

                updateSettings { settings in
                    settings[keyPath: keyPath] = CodableColor(
                        red: Double(red),
                        green: Double(green),
                        blue: Double(blue),
                        alpha: 1
                    )
                }
            }
        )
    }

    private func settingsBinding<Value>(_ keyPath: WritableKeyPath<EffectSettings, Value>) -> Binding<Value> {
        Binding(
            get: {
                settings[keyPath: keyPath]
            },
            set: { value in
                updateSettings { settings in
                    settings[keyPath: keyPath] = value
                }
            }
        )
    }

    private var notificationEffectsBinding: Binding<Bool> {
        Binding(
            get: { environment.effectSettingsStore.settings.notificationEffectsEnabled },
            set: { enabled in
                if enabled, notificationEffectController.requiresAccessibilityAuthorization {
                    isShowingAccessibilityExplanation = true
                } else {
                    notificationEffectController.setEnabled(enabled)
                }
                reload()
            }
        )
    }

    private var notificationDisplaySelectionBinding: Binding<NotificationDisplaySelection> {
        Binding(
            get: {
                let target = settings.notificationDisplayTarget
                switch target.mode {
                case .followNotification:
                    return .followNotification
                case .mainDisplay:
                    return .mainDisplay
                case .allDisplays:
                    return .allDisplays
                case .specificDisplay:
                    return .specificDisplay(target.displayIdentifier ?? "")
                }
            },
            set: { selection in
                updateSettings { settings in
                    switch selection {
                    case .followNotification:
                        settings.notificationDisplayTarget = .followNotification
                    case .mainDisplay:
                        settings.notificationDisplayTarget = .mainDisplay
                    case .allDisplays:
                        settings.notificationDisplayTarget = .allDisplays
                    case let .specificDisplay(identifier):
                        let display = selectableDisplays.first { $0.persistentIdentifier == identifier }
                        settings.notificationDisplayTarget = .specificDisplay(
                            identifier: identifier,
                            name: display?.name ?? settings.notificationDisplayTarget.displayName ?? "Selected Display"
                        )
                    }
                }
            }
        )
    }

    private var selectableDisplays: [ScreenGeometry] {
        notificationEffectController.connectedDisplays.filter { $0.persistentIdentifier != nil }
    }

    private var missingSpecificDisplay: (identifier: String, name: String)? {
        let target = settings.notificationDisplayTarget
        guard
            target.mode == .specificDisplay,
            let identifier = target.displayIdentifier,
            !selectableDisplays.contains(where: { $0.persistentIdentifier == identifier })
        else {
            return nil
        }
        return (identifier, target.displayName ?? "Selected Display")
    }

    private func updateSettings(_ update: (inout EffectSettings) -> Void) {
        var updatedSettings = settings
        update(&updatedSettings)
        environment.effectSettingsStore.updateSettings(updatedSettings)
        reload()
    }

    private func reload() {
        settings = environment.effectSettingsStore.settings
    }

    private func label(for style: EffectSettings.Style) -> String {
        switch style {
        case .flash:
            return "Flash"
        case .pulse:
            return "Pulse"
        case .sweep:
            return "Sweep"
        case .lightning:
            return "Lightning"
        case .shimmer:
            return "Shimmer"
        case .aurora:
            return "Aurora"
        }
    }

    private var testNotificationPermissionLabel: String {
        switch testNotificationController.authorizationStatus {
        case .notDetermined:
            return "Permission not requested"
        case .authorized:
            return "Permission allowed"
        case .alertsDisabled:
            return "Banners disabled"
        case .denied:
            return "Permission denied"
        }
    }

    private var testNotificationPermissionColor: Color {
        switch testNotificationController.authorizationStatus {
        case .notDetermined:
            return .secondary
        case .authorized:
            return .green
        case .alertsDisabled, .denied:
            return .orange
        }
    }

}

private enum SettingsTab: String, CaseIterable, Identifiable {
    case effects
    case notifications

    var id: Self { self }

    var label: String {
        switch self {
        case .effects:
            return "Effects"
        case .notifications:
            return "Notifications"
        }
    }
}

private enum NotificationDisplaySelection: Hashable {
    case followNotification
    case mainDisplay
    case allDisplays
    case specificDisplay(String)
}

private struct CompactColorWell: NSViewRepresentable {
    var selection: Binding<NSColor>
    var accessibilityLabel: String

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSColorWell {
        let colorWell = OpaqueColorWell()
        colorWell.colorWellStyle = .minimal
        colorWell.color = selection.wrappedValue
        colorWell.target = context.coordinator
        colorWell.action = #selector(Coordinator.colorChanged(_:))
        colorWell.setAccessibilityLabel(accessibilityLabel)
        colorWell.setContentHuggingPriority(.required, for: .horizontal)
        colorWell.setContentHuggingPriority(.required, for: .vertical)
        return colorWell
    }

    func updateNSView(_ colorWell: NSColorWell, context: Context) {
        context.coordinator.parent = self
        if !colorWell.color.isEqual(selection.wrappedValue) {
            colorWell.color = selection.wrappedValue
        }
        colorWell.setAccessibilityLabel(accessibilityLabel)
    }

    final class Coordinator: NSObject {
        var parent: CompactColorWell

        init(parent: CompactColorWell) {
            self.parent = parent
        }

        @objc func colorChanged(_ sender: NSColorWell) {
            parent.selection.wrappedValue = sender.color
        }
    }
}

private final class OpaqueColorWell: NSColorWell {
    override func activate(_ exclusive: Bool) {
        NSColorPanel.shared.showsAlpha = false
        super.activate(exclusive)
        NSColorPanel.shared.showsAlpha = false
    }
}
