//
//  MenuBarEventMonitor.swift
//  BarBop
//
//  Created by Codex on 7/7/26.
//

import AppKit

final class MenuBarEventMonitor {
    struct Dependencies {
        var addGlobalMonitor: (@escaping () -> Void) -> Any?
        var addLocalMonitor: (@escaping () -> Void) -> Any?
        var removeMonitor: (Any) -> Void

        static let live = Dependencies(
            addGlobalMonitor: { handler in
                NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
                    handler()
                }
            },
            addLocalMonitor: { handler in
                NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
                    handler()
                    return event
                }
            },
            removeMonitor: { monitor in
                NSEvent.removeMonitor(monitor)
            }
        )
    }

    private let onMenuBarClick: (MenuBarClick) -> Void
    private let onStateChange: (ClickMonitoringState) -> Void
    private let dependencies: Dependencies
    private var globalMonitor: Any?
    private var localMonitor: Any?

    init(
        onMenuBarClick: @escaping (MenuBarClick) -> Void,
        onStateChange: @escaping (ClickMonitoringState) -> Void = { _ in },
        dependencies: Dependencies = .live
    ) {
        self.onMenuBarClick = onMenuBarClick
        self.onStateChange = onStateChange
        self.dependencies = dependencies
    }

    func start() {
        guard globalMonitor == nil else {
            return
        }

        localMonitor = dependencies.addLocalMonitor { [weak self] in
            self?.processCurrentMouseLocation()
        }

        globalMonitor = dependencies.addGlobalMonitor { [weak self] in
            DispatchQueue.main.async {
                self?.processCurrentMouseLocation()
            }
        }

        guard globalMonitor != nil else {
            if let localMonitor {
                dependencies.removeMonitor(localMonitor)
            }
            localMonitor = nil
            onStateChange(.unavailable)
            return
        }

        onStateChange(.active)
    }

    func stop() {
        if let globalMonitor {
            dependencies.removeMonitor(globalMonitor)
        }

        if let localMonitor {
            dependencies.removeMonitor(localMonitor)
        }

        globalMonitor = nil
        localMonitor = nil
        onStateChange(.stopped)
    }

    private func processCurrentMouseLocation() {
        let location = NSEvent.mouseLocation
        guard let click = MenuBarGeometry.click(at: location, screens: NSScreen.barBopScreenGeometries) else {
            return
        }

        onMenuBarClick(click)
    }
}
