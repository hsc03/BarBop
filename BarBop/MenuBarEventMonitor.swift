//
//  MenuBarEventMonitor.swift
//  BarBop
//
//  Created by Codex on 7/7/26.
//

import AppKit

final class MenuBarEventMonitor {
    private let onMenuBarClick: (MenuBarClick) -> Void
    private var globalMonitor: Any?
    private var localMonitor: Any?

    init(onMenuBarClick: @escaping (MenuBarClick) -> Void) {
        self.onMenuBarClick = onMenuBarClick
    }

    func start() {
        guard globalMonitor == nil, localMonitor == nil else {
            return
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.processCurrentMouseLocation()
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.processCurrentMouseLocation()
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }

        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }

        globalMonitor = nil
        localMonitor = nil
    }

    private func processCurrentMouseLocation() {
        let location = NSEvent.mouseLocation
        guard let click = MenuBarGeometry.click(at: location, screens: NSScreen.barBopScreenGeometries) else {
            return
        }

        onMenuBarClick(click)
    }
}

private extension NSScreen {
    static var barBopScreenGeometries: [ScreenGeometry] {
        screens.map { screen in
            let id = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
            return ScreenGeometry(id: id, frame: screen.frame, visibleFrame: screen.visibleFrame)
        }
    }
}
