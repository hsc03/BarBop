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
    private var settingsWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate = self
        configureStatusItem()
        eventMonitor.start()
        environment.notificationEffectController.restoreSavedState()

        if environment.firstLaunchStore.shouldPresentInitialSettings {
            openSettings()
            environment.firstLaunchStore.markInitialSettingsPresented()
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
        item.button?.image = makeStatusItemImage()
        item.button?.toolTip = "BarBop"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "BarBop", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit BarBop", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu

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

    @objc private func openSettings() {
        let controller = settingsWindowController ?? makeSettingsWindowController()
        settingsWindowController = controller

        NSApp.activate(ignoringOtherApps: true)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    private func makeSettingsWindowController() -> NSWindowController {
        let hostingController = NSHostingController(rootView: ContentView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "BarBop Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 700, height: 700))
        window.minSize = NSSize(width: 640, height: 600)
        window.isReleasedWhenClosed = false
        window.center()

        return NSWindowController(window: window)
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
