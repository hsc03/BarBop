//
//  AppDelegate.swift
//  BarBop
//
//  Created by Codex on 7/7/26.
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let effectController = MenuBarEffectController()
    private lazy var effectCoordinator = EffectCoordinator(renderer: effectController)
    private lazy var eventMonitor = MenuBarEventMonitor { [weak self] click in
        self?.handleMenuBarClick(click)
    }

    private var statusItem: NSStatusItem?
    private var settingsWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        eventMonitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        eventMonitor.stop()
        effectController.hide()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: "BarBop")
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
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()

        return NSWindowController(window: window)
    }

    private func handleMenuBarClick(_ click: MenuBarClick) {
        guard !isOwnStatusItemClick(click.location) else {
            return
        }

        effectCoordinator.handleMenuBarClick(click)
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
