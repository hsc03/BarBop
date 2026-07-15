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
    @ObservedObject private var environment = AppEnvironment.shared
    @ObservedObject private var testNotificationController = AppEnvironment.shared.localTestNotificationController
    @ObservedObject private var notificationEffectController = AppEnvironment.shared.notificationEffectController

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            monitoringStatus
            controls
            Spacer()
            footer
        }
        .frame(minWidth: 560, minHeight: 620, alignment: .topLeading)
        .padding(20)
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

    private var monitoringStatus: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: monitoringStatusSymbol)
                .foregroundStyle(monitoringStatusColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Click Monitoring: \(monitoringStatusLabel)")
                    .fontWeight(.medium)
                Text(monitoringStatusDetail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("BarBop Settings")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Adds a short click-through color effect when you click the macOS menu bar.")
                .foregroundStyle(.secondary)
        }
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

    private var controls: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
            GridRow {
                Text("Click Effects")
                Toggle("Enabled", isOn: settingsBinding(\.isEnabled))
                    .labelsHidden()
            }

            GridRow(alignment: .top) {
                Text("Notifications")
                VStack(alignment: .leading, spacing: 7) {
                    Toggle(
                        "Notification Effects (Experimental)",
                        isOn: notificationEffectsBinding
                    )
                    HStack(alignment: .top, spacing: 7) {
                        Image(systemName: notificationStatusSymbol)
                            .foregroundStyle(notificationStatusColor)
                            .accessibilityHidden(true)
                        Text(notificationEffectController.statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if notificationEffectController.state == .permissionRequired {
                        Button("Open Accessibility Settings") {
                            notificationEffectController.openAccessibilitySettings()
                        }
                    }
                    HStack {
                        Text("Display")
                            .font(.callout)
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
                    HStack {
                        Button(testNotificationController.isSending ? "Sending…" : "Send Test Notification") {
                            Task {
                                await testNotificationController.sendTestNotification()
                            }
                        }
                        .disabled(testNotificationController.isSending)
                        Text(testNotificationPermissionLabel)
                            .font(.caption)
                            .foregroundStyle(testNotificationPermissionColor)
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

            GridRow {
                Text("Style")
                Picker("Style", selection: settingsBinding(\.style)) {
                    ForEach(EffectSettings.Style.allCases) { style in
                        Text(label(for: style)).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }
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
                notificationEffectController.setEnabled(enabled)
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
        case .aurora:
            return "Aurora"
        }
    }

    private var monitoringStatusLabel: String {
        switch environment.clickMonitoringState {
        case .stopped:
            return "Stopped"
        case .active:
            return "Active"
        case .unavailable:
            return "Unavailable"
        }
    }

    private var monitoringStatusDetail: String {
        switch environment.clickMonitoringState {
        case .stopped:
            return "BarBop is not currently observing clicks."
        case .active:
            return "BarBop observes mouse clicks only to detect the menu bar. It does not record click history or keyboard input."
        case .unavailable:
            return "BarBop could not start system-wide mouse click monitoring. Quit and reopen the app, then check macOS privacy settings if the problem continues."
        }
    }

    private var monitoringStatusSymbol: String {
        switch environment.clickMonitoringState {
        case .stopped:
            return "pause.circle"
        case .active:
            return "checkmark.circle.fill"
        case .unavailable:
            return "exclamationmark.triangle.fill"
        }
    }

    private var monitoringStatusColor: Color {
        switch environment.clickMonitoringState {
        case .stopped:
            return .secondary
        case .active:
            return .green
        case .unavailable:
            return .orange
        }
    }

    private var testNotificationPermissionLabel: String {
        switch testNotificationController.authorizationStatus {
        case .notDetermined:
            return "Permission not requested"
        case .authorized:
            return "Permission allowed"
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
        case .denied:
            return .orange
        }
    }

    private var notificationStatusSymbol: String {
        switch notificationEffectController.state {
        case .active:
            return "checkmark.circle.fill"
        case .permissionRequired, .unavailable:
            return "exclamationmark.triangle.fill"
        case .connecting:
            return "arrow.trianglehead.2.clockwise.rotate.90"
        case .stopped:
            return "pause.circle"
        }
    }

    private var notificationStatusColor: Color {
        switch notificationEffectController.state {
        case .active:
            return .green
        case .permissionRequired, .unavailable:
            return .orange
        case .connecting:
            return .blue
        case .stopped:
            return .secondary
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
