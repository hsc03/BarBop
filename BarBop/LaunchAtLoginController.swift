import Combine
import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable
}

@MainActor
final class LaunchAtLoginController: ObservableObject {
    struct Dependencies {
        var status: () -> LaunchAtLoginStatus
        var register: () async throws -> Void
        var unregister: () async throws -> Void
        var openLoginItemsSettings: () -> Void

        static let live = Dependencies(
            status: {
                switch SMAppService.mainApp.status {
                case .notRegistered:
                    return .disabled
                case .enabled:
                    return .enabled
                case .requiresApproval:
                    return .requiresApproval
                case .notFound:
                    return .unavailable
                @unknown default:
                    return .unavailable
                }
            },
            register: {
                try SMAppService.mainApp.register()
            },
            unregister: {
                try await SMAppService.mainApp.unregister()
            },
            openLoginItemsSettings: {
                SMAppService.openSystemSettingsLoginItems()
            }
        )
    }

    @Published private(set) var status: LaunchAtLoginStatus
    @Published private(set) var isUpdating = false
    @Published private(set) var errorMessage: String?

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        self.status = dependencies.status()
    }

    var isEnabled: Bool {
        status == .enabled || status == .requiresApproval
    }

    var canChange: Bool {
        !isUpdating
    }

    func refresh() {
        status = dependencies.status()
        if status == .enabled || status == .disabled {
            errorMessage = nil
        }
    }

    func setEnabled(_ enabled: Bool) async {
        guard canChange, enabled != isEnabled else { return }

        isUpdating = true
        errorMessage = nil
        defer {
            isUpdating = false
            status = dependencies.status()
        }

        do {
            if enabled {
                try await dependencies.register()
            } else {
                try await dependencies.unregister()
            }
        } catch {
            errorMessage = enabled
                ? "BarBop could not be added to Login Items. Try again or open Login Items settings."
                : "BarBop could not be removed from Login Items. Try again in System Settings."
        }
    }

    func openLoginItemsSettings() {
        dependencies.openLoginItemsSettings()
    }
}
