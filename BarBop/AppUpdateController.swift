//
//  AppUpdateController.swift
//  BarBop
//

import AppKit
import Combine
import Foundation
import Sparkle

@MainActor
final class AppUpdateController: ObservableObject {
    struct Dependencies {
        var startUpdater: () -> Void
        var checkForUpdates: () -> Void
        var canCheckForUpdates: () -> Bool
        var observeCanCheckForUpdates: (@escaping (Bool) -> Void) -> () -> Void

        static func live() -> Dependencies {
            let userDriverDelegate = SparkleUserDriverDelegate()
            let controller = SPUStandardUpdaterController(
                startingUpdater: false,
                updaterDelegate: nil,
                userDriverDelegate: userDriverDelegate
            )

            return Dependencies(
                startUpdater: {
                    _ = userDriverDelegate
                    controller.startUpdater()
                },
                checkForUpdates: {
                    controller.checkForUpdates(nil)
                },
                canCheckForUpdates: {
                    controller.updater.canCheckForUpdates
                },
                observeCanCheckForUpdates: { handler in
                    let observation = controller.updater
                        .publisher(for: \.canCheckForUpdates, options: [.initial, .new])
                        .receive(on: RunLoop.main)
                        .sink(receiveValue: handler)
                    return {
                        observation.cancel()
                    }
                }
            )
        }
    }

    @Published private(set) var canCheckForUpdates: Bool

    let versionDescription: String

    private let dependencies: Dependencies
    private var cancelObservation: (() -> Void)?
    private var hasStarted = false

    init(
        dependencies: Dependencies? = nil,
        bundle: Bundle = .main
    ) {
        let dependencies = dependencies ?? .live()
        self.dependencies = dependencies
        self.canCheckForUpdates = dependencies.canCheckForUpdates()
        self.versionDescription = Self.versionDescription(for: bundle)
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        cancelObservation = dependencies.observeCanCheckForUpdates { [weak self] canCheck in
            self?.canCheckForUpdates = canCheck
        }
        dependencies.startUpdater()
        canCheckForUpdates = dependencies.canCheckForUpdates()
    }

    func checkForUpdates() {
        guard canCheckForUpdates else { return }
        NSApp.keyWindow?.close()
        dependencies.checkForUpdates()
    }

    static func versionDescription(for bundle: Bundle) -> String {
        versionDescription(
            version: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            build: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        )
    }

    static func versionDescription(version: String?, build: String?) -> String {
        let version = version ?? "—"
        let build = build ?? "—"
        return "Version \(version) (\(build))"
    }
}

@MainActor
private final class SparkleUserDriverDelegate: NSObject, SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool {
        true
    }

    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        guard handleShowingUpdate else { return }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func standardUserDriverWillFinishUpdateSession() {
        NSApp.setActivationPolicy(.accessory)
    }
}
