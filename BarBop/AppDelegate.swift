//
//  AppDelegate.swift
//  BarBop
//
//  Created by Codex on 7/7/26.
//

import AppKit
import OSLog

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "io.github.hsc03.BarBop", category: "StatusItemResolver")
    private let statusItemResolver = StatusItemResolver()
    private let overlayWindowController = OverlayWindowController()
    private lazy var reactionCoordinator = ReactionCoordinator(renderer: overlayWindowController)
    private lazy var eventMonitor = MenuBarEventMonitor { [weak self] click in
        self?.handleMenuBarClick(click)
    }

    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        eventMonitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        eventMonitor.stop()
        overlayWindowController.hide()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: "BarBop")
        item.button?.toolTip = "BarBop"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "BarBop Prototype", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit BarBop", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu

        statusItem = item
    }

    private func handleMenuBarClick(_ click: MenuBarClick) {
        guard !isOwnStatusItemClick(click.location) else {
            return
        }

        logStatusItemResolution(statusItemResolver.resolve(at: click.location))
        reactionCoordinator.handleMenuBarClick(click)
    }

    private func logStatusItemResolution(_ resolution: StatusItemResolution) {
        logger.debug(
            """
            status item resolved identity=\(resolution.identity, privacy: .public) \
            app=\(resolution.applicationName ?? "nil", privacy: .public) \
            bundle=\(resolution.bundleIdentifier ?? "nil", privacy: .public) \
            pid=\(resolution.processIdentifier.map(String.init) ?? "nil", privacy: .public) \
            role=\(resolution.role ?? "nil", privacy: .public) \
            title=\(resolution.title ?? "nil", privacy: .public) \
            axid=\(resolution.accessibilityIdentifier ?? "nil", privacy: .public) \
            error=\(resolution.errorDescription ?? "nil", privacy: .public)
            """
        )
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
