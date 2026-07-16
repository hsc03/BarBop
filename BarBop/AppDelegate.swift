//
//  AppDelegate.swift
//  BarBop
//
//  Created by Codex on 7/7/26.
//

import AppKit
import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private let environment = AppEnvironment.shared
    private lazy var eventMonitor = MenuBarEventMonitor(
        onMenuBarClick: { [weak self] click in
            self?.handleMenuBarClick(click)
        },
        onStateChange: { [weak self] state in
            self?.environment.updateClickMonitoringState(state)
        }
    )

    private var statusItem: NSStatusItem?
    private lazy var settingsPopover: NSPopover = makeSettingsPopover()
    private var initialPresentationAttempts = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate = self
        configureStatusItem()
        eventMonitor.start()
        environment.notificationEffectController.restoreSavedState()
        environment.appUpdateController.start()

        DispatchQueue.main.async { [weak self] in
            self?.presentInitialSettingsIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        eventMonitor.stop()
        environment.notificationEffectController.stop()
        environment.menuBarEffectController.hide()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list])
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = makeStatusItemImage()
            button.toolTip = "BarBop Settings"
            button.target = self
            button.action = #selector(toggleSettingsPopover(_:))
            button.sendAction(on: [.leftMouseUp])
        }

        statusItem = item
    }

    private func makeStatusItemImage() -> NSImage? {
        let image = NSImage(named: "MenuBarIcon")
            ?? NSImage(systemSymbolName: "waveform.path", accessibilityDescription: "BarBop")
        image?.isTemplate = true
        image?.size = NSSize(width: 18, height: 18)
        image?.accessibilityDescription = "BarBop"
        return image
    }

    @objc private func toggleSettingsPopover(_ sender: Any?) {
        if settingsPopover.isShown {
            settingsPopover.performClose(sender)
        } else {
            _ = showSettingsPopover()
        }
    }

    private func presentInitialSettingsIfNeeded() {
        guard environment.firstLaunchStore.shouldPresentInitialSettings else {
            return
        }

        initialPresentationAttempts += 1
        guard showSettingsPopover() else {
            guard initialPresentationAttempts < 10 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.presentInitialSettingsIfNeeded()
            }
            return
        }

        environment.firstLaunchStore.markInitialSettingsPresented()
    }

    @discardableResult
    private func showSettingsPopover() -> Bool {
        guard let button = statusItem?.button else { return false }

        NSApp.activate(ignoringOtherApps: true)
        settingsPopover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        return settingsPopover.isShown
    }

    private func makeSettingsPopover() -> NSPopover {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 520, height: 520)
        popover.contentViewController = NSHostingController(rootView: ContentView())
        return popover
    }

    private func handleMenuBarClick(_ click: MenuBarClick) {
        guard !isOwnStatusItemClick(click.location) else {
            return
        }

        environment.effectCoordinator.handleMenuBarClick(click)
    }

    private func isOwnStatusItemClick(_ location: CGPoint) -> Bool {
        guard
            let button = statusItem?.button,
            let window = button.window
        else {
            return false
        }

        let screenFrame = window.convertToScreen(button.frame)
        return screenFrame.insetBy(dx: -6, dy: -6).contains(location)
    }
}
