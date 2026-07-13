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
    private let environment = AppEnvironment.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            controls
            Spacer()
        }
        .frame(minWidth: 520, minHeight: 320, alignment: .topLeading)
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
            Text("Adds a short click-through color effect when you click the macOS menu bar.")
                .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
            GridRow {
                Text("Effect")
                Toggle("Enabled", isOn: settingsBinding(\.isEnabled))
                    .labelsHidden()
            }

            GridRow {
                Text("Color")
                ColorPicker("Effect Color", selection: colorBinding, supportsOpacity: false)
                    .labelsHidden()
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

    private var colorBinding: Binding<Color> {
        Binding(
            get: {
                Color(settings.color.nsColor)
            },
            set: { color in
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                NSColor(color).usingColorSpace(.sRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

                updateSettings { settings in
                    settings.color = CodableColor(
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
}
