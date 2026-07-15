import AppKit
import ApplicationServices
import Combine
import Foundation

@MainActor
final class NotificationEffectController: ObservableObject {
    struct Dependencies {
        var isTrusted: () -> Bool
        var requestAccessibilityAccess: () -> Void
        var screens: () -> [ScreenGeometry]
        var uptime: () -> TimeInterval
        var makeDetector: (
            @escaping (NotificationBannerEvent) -> TimeInterval?,
            @escaping () -> Void,
            @escaping (NotificationBannerMonitorState) -> Void
        ) -> NotificationBannerMonitoring

        static let live = Dependencies(
            isTrusted: AXIsProcessTrusted,
            requestAccessibilityAccess: {
                let options = [
                    kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
                ] as CFDictionary
                _ = AXIsProcessTrustedWithOptions(options)
            },
            screens: { NSScreen.barBopScreenGeometries },
            uptime: { ProcessInfo.processInfo.systemUptime },
            makeDetector: { onEvent, onReset, onStateChange in
                NotificationBannerDetector(
                    onEvent: onEvent,
                    onReset: onReset,
                    onStateChange: onStateChange
                )
            }
        )
    }

    @Published private(set) var state: NotificationBannerMonitorState = .stopped
    @Published private(set) var statusMessage = "Notification effects are off."
    @Published private(set) var isAwaitingAccessibilityApproval = false
    @Published private(set) var connectedDisplays: [ScreenGeometry] = []

    private let settingsStore: EffectSettingsStore
    private let effectCoordinator: EffectCoordinator
    private let cancelEffect: () -> Void
    private let dependencies: Dependencies

    private lazy var detector: NotificationBannerMonitoring = dependencies.makeDetector(
        { [weak self] event in self?.handle(event) },
        { [weak self] in self?.cancelEffect() },
        { [weak self] state in self?.receive(state) }
    )

    init(
        settingsStore: EffectSettingsStore,
        effectCoordinator: EffectCoordinator,
        cancelEffect: @escaping () -> Void,
        dependencies: Dependencies? = nil
    ) {
        self.settingsStore = settingsStore
        self.effectCoordinator = effectCoordinator
        self.cancelEffect = cancelEffect
        self.dependencies = dependencies ?? .live
    }

    func restoreSavedState() {
        refreshScreens()
        guard settingsStore.settings.notificationEffectsEnabled else {
            detector.stop()
            return
        }

        guard dependencies.isTrusted() else {
            persistEnabled(false)
            detector.stop()
            state = .permissionRequired
            statusMessage = accessibilityGuidance
            return
        }

        detector.start()
    }

    func refreshScreens() {
        connectedDisplays = dependencies.screens()
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled else {
            isAwaitingAccessibilityApproval = false
            persistEnabled(false)
            detector.stop()
            statusMessage = "Notification effects are off."
            return
        }

        guard dependencies.isTrusted() else {
            isAwaitingAccessibilityApproval = true
            persistEnabled(false)
            detector.stop()
            state = .permissionRequired
            statusMessage = accessibilityGuidance
            dependencies.requestAccessibilityAccess()
            return
        }


        guard !settingsStore.settings.notificationEffectsEnabled else {
            return
        }

        isAwaitingAccessibilityApproval = false
        persistEnabled(true)
        detector.start()
    }

    var requiresAccessibilityAuthorization: Bool {
        !dependencies.isTrusted()
    }

    func refreshAccessibilityAuthorization() {
        let isTrusted = dependencies.isTrusted()

        if settingsStore.settings.notificationEffectsEnabled, !isTrusted {
            isAwaitingAccessibilityApproval = false
            persistEnabled(false)
            detector.stop()
            state = .permissionRequired
            statusMessage = accessibilityGuidance
            return
        }

        guard isAwaitingAccessibilityApproval else { return }
        guard isTrusted else {
            state = .permissionRequired
            statusMessage = accessibilityGuidance
            return
        }

        isAwaitingAccessibilityApproval = false
        persistEnabled(true)
        detector.start()
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func stop() {
        detector.stop()
    }

    private func persistEnabled(_ enabled: Bool) {
        var settings = settingsStore.settings
        settings.notificationEffectsEnabled = enabled
        settingsStore.updateSettings(settings)
    }

    private func handle(_ event: NotificationBannerEvent) -> TimeInterval? {
        let settings = settingsStore.settings
        guard settings.notificationEffectsEnabled else {
            return nil
        }

        let screens = dependencies.screens()
        connectedDisplays = screens
        let targets = NotificationDisplayResolver.resolve(
            target: settings.notificationDisplayTarget,
            eventScreenID: event.screenID,
            screens: screens
        )
        guard !targets.isEmpty else { return nil }

        effectCoordinator.handleNotificationBanner(on: targets)
        return dependencies.uptime()
    }

    private func receive(_ newState: NotificationBannerMonitorState) {
        state = newState
        switch newState {
        case .stopped:
            statusMessage = "Notification effects are off."
        case .permissionRequired:
            if settingsStore.settings.notificationEffectsEnabled {
                persistEnabled(false)
            }
            statusMessage = accessibilityGuidance
        case .connecting:
            statusMessage = "Connecting to Notification Center…"
        case .active:
            statusMessage = "Watching visible notification banners. Notification contents are not read."
        case .unavailable:
            statusMessage = "Notification Center is temporarily unavailable. BarBop will reconnect automatically."
        }
    }

    private var accessibilityGuidance: String {
        "Allow BarBop in System Settings → Privacy & Security → Accessibility. Return to BarBop and notification effects will enable automatically."
    }
}
