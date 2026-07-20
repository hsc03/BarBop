import AppKit
import ColorSync
import CoreGraphics

struct ScreenGeometry: Equatable {
    let id: UInt32
    let persistentIdentifier: String?
    let name: String
    let isMain: Bool
    let frame: CGRect
    let visibleFrame: CGRect

    init(
        id: UInt32,
        persistentIdentifier: String? = nil,
        name: String = "Display",
        isMain: Bool = false,
        frame: CGRect,
        visibleFrame: CGRect
    ) {
        self.id = id
        self.persistentIdentifier = persistentIdentifier
        self.name = name
        self.isMain = isMain
        self.frame = frame
        self.visibleFrame = visibleFrame
    }
}

enum NotificationDisplayResolver {
    static func resolve(
        target: NotificationDisplayTarget,
        eventScreenID: UInt32,
        screens: [ScreenGeometry]
    ) -> [ScreenGeometry] {
        guard !screens.isEmpty else { return [] }
        let main = screens.first(where: \.isMain) ?? screens.first

        switch target.mode {
        case .followNotification:
            return [screens.first(where: { $0.id == eventScreenID }) ?? main].compactMap { $0 }
        case .mainDisplay:
            return [main].compactMap { $0 }
        case .specificDisplay:
            guard let identifier = target.displayIdentifier else {
                return [main].compactMap { $0 }
            }
            return [screens.first(where: { $0.persistentIdentifier == identifier }) ?? main].compactMap { $0 }
        case .allDisplays:
            return screens
        }
    }
}

struct MenuBarClick: Equatable {
    let location: CGPoint
    let screen: ScreenGeometry
}

extension NSScreen {
    static var barBopScreenGeometries: [ScreenGeometry] {
        screens.map { screen in
            let id = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
            let identifier = CGDisplayCreateUUIDFromDisplayID(id).map {
                CFUUIDCreateString(nil, $0.takeRetainedValue()) as String
            }
            return ScreenGeometry(
                id: id,
                persistentIdentifier: identifier,
                name: screen.localizedName,
                isMain: id == CGMainDisplayID(),
                frame: screen.frame,
                visibleFrame: screen.visibleFrame
            )
        }
    }
}

enum MenuBarGeometry {
    static let fallbackMenuBarHeight: CGFloat = 28

    static func click(
        at location: CGPoint,
        screens: [ScreenGeometry]
    ) -> MenuBarClick? {
        guard let screen = screen(containing: location, in: screens) else {
            return nil
        }

        guard menuBarFrame(for: screen).contains(location) else {
            return nil
        }

        return MenuBarClick(location: location, screen: screen)
    }

    static func screen(
        containing location: CGPoint,
        in screens: [ScreenGeometry]
    ) -> ScreenGeometry? {
        screens.first { screen in
            screen.frame.contains(location)
        }
    }

    static func screen(withID id: UInt32, in screens: [ScreenGeometry]) -> ScreenGeometry? {
        screens.first { $0.id == id }
    }

    static func menuBarFrame(for screen: ScreenGeometry) -> CGRect {
        let visibleTopInset = screen.frame.maxY - screen.visibleFrame.maxY
        let height = max(visibleTopInset, fallbackMenuBarHeight)

        return CGRect(
            x: screen.frame.minX,
            y: screen.frame.maxY - height,
            width: screen.frame.width,
            height: height
        )
    }

    static func clampedOverlayOrigin(
        centeredAt point: CGPoint,
        overlaySize: CGSize,
        screenFrame: CGRect,
        margin: CGFloat = 8
    ) -> CGPoint {
        let proposed = CGPoint(
            x: point.x - overlaySize.width / 2,
            y: point.y - overlaySize.height / 2
        )

        let minimumX = screenFrame.minX + margin
        let maximumX = screenFrame.maxX - overlaySize.width - margin
        let minimumY = screenFrame.minY + margin
        let maximumY = screenFrame.maxY - overlaySize.height - margin

        return CGPoint(
            x: clamp(proposed.x, minimumX, maximumX),
            y: clamp(proposed.y, minimumY, maximumY)
        )
    }

    private static func clamp(_ value: CGFloat, _ lowerBound: CGFloat, _ upperBound: CGFloat) -> CGFloat {
        guard lowerBound <= upperBound else {
            return lowerBound
        }

        return min(max(value, lowerBound), upperBound)
    }
}
