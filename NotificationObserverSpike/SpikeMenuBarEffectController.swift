import AppKit

@MainActor
final class SpikeMenuBarEffectController {
    private var panel: NSPanel?
    private var hideWorkItem: DispatchWorkItem?

    func play(
        on screenID: CGDirectDisplayID,
        uptime: () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) -> TimeInterval? {
        guard let screen = NSScreen.screens.first(where: { $0.displayID == screenID }) else {
            return nil
        }

        hide()
        let menuBarFrame = Self.menuBarFrame(for: screen)
        let panel = panel ?? makePanel(size: menuBarFrame.size)
        self.panel = panel

        let effectView = NSView(frame: CGRect(origin: .zero, size: menuBarFrame.size))
        effectView.wantsLayer = true
        effectView.layer?.backgroundColor = NSColor.systemCyan.withAlphaComponent(0.42).cgColor
        panel.contentView = effectView
        panel.setFrame(menuBarFrame, display: true)
        panel.alphaValue = 1
        panel.orderFrontRegardless()
        let effectStartUptime = uptime()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            panel.animator().alphaValue = 0
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
        return effectStartUptime
    }

    func hide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        panel?.orderOut(nil)
        panel?.alphaValue = 1
    }

    private func makePanel(size: CGSize) -> NSPanel {
        let panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        return panel
    }

    private static func menuBarFrame(for screen: NSScreen) -> CGRect {
        let height = max(screen.frame.maxY - screen.visibleFrame.maxY, 28)
        return CGRect(
            x: screen.frame.minX,
            y: screen.frame.maxY - height,
            width: screen.frame.width,
            height: height
        )
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
