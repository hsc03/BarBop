//
//  AppEnvironment.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import Combine
import Foundation

enum ClickMonitoringState: Equatable {
    case stopped
    case active
    case unavailable
}

@MainActor
final class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()

    let effectSettingsStore: EffectSettingsStore
    let firstLaunchStore: FirstLaunchStore
    let localTestNotificationController: LocalTestNotificationController
    @Published private(set) var clickMonitoringState: ClickMonitoringState = .stopped

    lazy var menuBarEffectController = MenuBarEffectController()
    lazy var effectCoordinator = EffectCoordinator(
        renderer: menuBarEffectController,
        settingsStore: effectSettingsStore
    )
    lazy var notificationEffectController = NotificationEffectController(
        settingsStore: effectSettingsStore,
        effectCoordinator: effectCoordinator,
        cancelEffect: { [weak self] in self?.menuBarEffectController.hide() }
    )

    init() {
        self.effectSettingsStore = EffectSettingsStore()
        self.firstLaunchStore = FirstLaunchStore()
        self.localTestNotificationController = LocalTestNotificationController()
    }

    init(
        effectSettingsStore: EffectSettingsStore,
        firstLaunchStore: FirstLaunchStore,
        localTestNotificationController: LocalTestNotificationController
    ) {
        self.effectSettingsStore = effectSettingsStore
        self.firstLaunchStore = firstLaunchStore
        self.localTestNotificationController = localTestNotificationController
    }

    func updateClickMonitoringState(_ state: ClickMonitoringState) {
        clickMonitoringState = state
    }
}
