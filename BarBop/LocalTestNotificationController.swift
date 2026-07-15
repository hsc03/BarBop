import Combine
import Foundation
import UserNotifications

enum LocalNotificationAuthorizationStatus: Equatable {
    case notDetermined
    case authorized
    case denied
}

@MainActor
final class LocalTestNotificationController: ObservableObject {
    struct Dependencies {
        var authorizationStatus: () async -> LocalNotificationAuthorizationStatus
        var requestAuthorization: () async throws -> Bool
        var addRequest: (UNNotificationRequest) async throws -> Void

        static let live = Dependencies(
            authorizationStatus: {
                await withCheckedContinuation { continuation in
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        let status: LocalNotificationAuthorizationStatus
                        switch settings.authorizationStatus {
                        case .notDetermined:
                            status = .notDetermined
                        case .denied:
                            status = .denied
                        case .authorized, .provisional, .ephemeral:
                            status = .authorized
                        @unknown default:
                            status = .denied
                        }
                        continuation.resume(returning: status)
                    }
                }
            },
            requestAuthorization: {
                try await withCheckedThrowingContinuation { continuation in
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: granted)
                        }
                    }
                }
            },
            addRequest: { request in
                try await withCheckedThrowingContinuation { continuation in
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                }
            }
        )
    }

    @Published private(set) var authorizationStatus: LocalNotificationAuthorizationStatus = .notDetermined
    @Published private(set) var isSending = false
    @Published private(set) var statusMessage = "Notification permission has not been checked yet."

    private let dependencies: Dependencies

    init() {
        self.dependencies = .live
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func refreshAuthorizationStatus() async {
        apply(await dependencies.authorizationStatus())
    }

    func sendTestNotification() async {
        guard !isSending else { return }
        isSending = true
        let status = await dependencies.authorizationStatus()
        apply(status)

        switch status {
        case .notDetermined:
            do {
                if try await dependencies.requestAuthorization() {
                    apply(.authorized)
                    await scheduleTestNotification()
                } else {
                    apply(.denied)
                    isSending = false
                }
            } catch {
                statusMessage = "Could not request notification permission: \(error.localizedDescription)"
                isSending = false
            }
        case .authorized:
            await scheduleTestNotification()
        case .denied:
            isSending = false
        }
    }

    private func scheduleTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "BarBop Test Notification"
        content.body = "This local notification checks whether visible banners can trigger a menu bar effect."

        let request = UNNotificationRequest(
            identifier: "BarBop.TestNotification.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        do {
            try await dependencies.addRequest(request)
            statusMessage = "Test notification sent. Look for a visible macOS banner."
        } catch {
            statusMessage = "Could not send the test notification: \(error.localizedDescription)"
        }
        isSending = false
    }

    private func apply(_ status: LocalNotificationAuthorizationStatus) {
        authorizationStatus = status
        switch status {
        case .notDetermined:
            statusMessage = "Click Send Test Notification to request local notification permission."
        case .authorized:
            statusMessage = "BarBop can send local test notifications."
        case .denied:
            statusMessage = "Notifications are disabled for BarBop. Enable them in System Settings > Notifications > BarBop."
        }
    }
}
