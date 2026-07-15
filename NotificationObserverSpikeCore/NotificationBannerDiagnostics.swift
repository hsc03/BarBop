import CoreGraphics
import Foundation

enum NotificationBannerMonitorState: Equatable {
    case stopped
    case permissionRequired
    case connecting
    case active
    case unavailable
}

struct NotificationBannerScreen: Equatable {
    let id: CGDirectDisplayID
    let frame: CGRect
}

struct NotificationBannerCandidate: Equatable {
    let frame: CGRect
    let screenID: CGDirectDisplayID
}

struct NotificationBannerCandidateClassifier {
    func classify(frame: CGRect, screens: [NotificationBannerScreen]) -> NotificationBannerCandidate? {
        guard let screen = matchingScreen(for: frame, screens: screens) else {
            return nil
        }

        guard
            frame.width >= 180,
            frame.width <= min(700, screen.frame.width * 0.5),
            frame.height >= 40,
            frame.height <= min(450, screen.frame.height * 0.5)
        else {
            return nil
        }

        let topLimit = screen.frame.minY + screen.frame.height * 0.45
        guard frame.minY <= topLimit else {
            return nil
        }

        return NotificationBannerCandidate(frame: frame, screenID: screen.id)
    }

    func screenID(for frame: CGRect, screens: [NotificationBannerScreen]) -> CGDirectDisplayID? {
        matchingScreen(for: frame, screens: screens)?.id
    }

    private func matchingScreen(
        for frame: CGRect,
        screens: [NotificationBannerScreen]
    ) -> NotificationBannerScreen? {
        screens
            .compactMap { screen -> (NotificationBannerScreen, CGFloat)? in
                let intersection = screen.frame.intersection(frame)
                guard !intersection.isNull, !intersection.isEmpty else { return nil }
                return (screen, intersection.width * intersection.height)
            }
            .max(by: { $0.1 < $1.1 })?
            .0
    }
}

struct NotificationBannerStructureClassifier {
    static let bannerRole = "AXGroup"
    static let bannerSubrole = "AXNotificationCenterBanner"

    func isBanner(role: String, subrole: String?, depth: Int) -> Bool {
        role == Self.bannerRole &&
            subrole == Self.bannerSubrole &&
            (0...6).contains(depth)
    }
}

struct NotificationBannerEventClassifier {
    static let layoutChangedNotification = "AXLayoutChanged"

    private let candidateClassifier = NotificationBannerCandidateClassifier()
    private let structureClassifier = NotificationBannerStructureClassifier()

    func classify(
        notificationName: String,
        role: String,
        subrole: String?,
        parentDepth: Int,
        frame: CGRect,
        screens: [NotificationBannerScreen]
    ) -> NotificationBannerCandidate? {
        guard
            notificationName == Self.layoutChangedNotification,
            parentDepth == 0,
            structureClassifier.isBanner(role: role, subrole: subrole, depth: parentDepth)
        else {
            return nil
        }

        return candidateClassifier.classify(frame: frame, screens: screens)
    }
}

struct NotificationBannerElementIdentity: Hashable, Equatable {
    let rawValue: Int
}

struct NotificationBannerDeduplicator {
    private struct FrameKey: Hashable {
        let x: Int
        let y: Int
        let width: Int
        let height: Int

        init(_ frame: CGRect) {
            x = Int(frame.origin.x.rounded())
            y = Int(frame.origin.y.rounded())
            width = Int(frame.width.rounded())
            height = Int(frame.height.rounded())
        }
    }

    private struct Key: Hashable {
        let elementIdentity: NotificationBannerElementIdentity
        let frame: FrameKey
    }

    private let duplicateInterval: TimeInterval
    private var recentEvents: [Key: TimeInterval] = [:]

    init(duplicateInterval: TimeInterval = 1) {
        self.duplicateInterval = duplicateInterval
    }

    mutating func shouldAccept(
        elementIdentity: NotificationBannerElementIdentity,
        frame: CGRect,
        at time: TimeInterval
    ) -> Bool {
        recentEvents = recentEvents.filter { time - $0.value <= duplicateInterval }
        let key = Key(elementIdentity: elementIdentity, frame: FrameKey(frame))

        if let previousTime = recentEvents[key], time - previousTime <= duplicateInterval {
            return false
        }

        recentEvents[key] = time
        return true
    }

    mutating func reset() {
        recentEvents.removeAll()
    }
}

struct NotificationBannerLatencyMetrics: Equatable {
    private(set) var sampleCount = 0
    private(set) var totalLatency: TimeInterval = 0
    private(set) var maximumLatency: TimeInterval = 0

    var averageLatency: TimeInterval {
        guard sampleCount > 0 else { return 0 }
        return totalLatency / Double(sampleCount)
    }

    mutating func record(_ latency: TimeInterval) {
        let normalizedLatency = max(0, latency)
        sampleCount += 1
        totalLatency += normalizedLatency
        maximumLatency = max(maximumLatency, normalizedLatency)
    }

    mutating func reset() {
        self = NotificationBannerLatencyMetrics()
    }
}

struct NotificationBannerStructuralEvent: Equatable {
    let notificationName: String
    let callbackDate: Date
    let elementIdentity: NotificationBannerElementIdentity
    let role: String
    let subrole: String?
    let parentDepth: Int
    let frame: CGRect
    let screenID: CGDirectDisplayID
    let effectStartLatency: TimeInterval
}

struct NotificationBannerElementSnapshot: Equatable {
    let elementIdentity: NotificationBannerElementIdentity
    let role: String
    let subrole: String?
    let parentDepth: Int
    let frame: CGRect?
    let screenID: CGDirectDisplayID?
}

struct NotificationBannerCallbackSnapshot: Equatable {
    let notificationName: String
    let callbackDate: Date
    let elements: [NotificationBannerElementSnapshot]
    let descendants: [NotificationBannerElementSnapshot]
    let candidateAccepted: Bool
}

struct NotificationBannerDiagnostics: Equatable {
    var registeredNotificationNames: [String] = []
    private(set) var callbackCount = 0
    private(set) var candidateCount = 0
    private(set) var eventCount = 0
    private(set) var duplicateCount = 0
    private(set) var successfulReconnectCount = 0
    private(set) var latency = NotificationBannerLatencyMetrics()
    private(set) var lastCallbackSnapshot: NotificationBannerCallbackSnapshot?
    private(set) var recentCallbackSnapshots: [NotificationBannerCallbackSnapshot] = []
    private(set) var lastStructuralEvent: NotificationBannerStructuralEvent?
    private var hasConnected = false

    mutating func recordCallback(_ snapshot: NotificationBannerCallbackSnapshot) {
        callbackCount += 1
        lastCallbackSnapshot = snapshot
        recentCallbackSnapshots.append(snapshot)
        if recentCallbackSnapshots.count > 20 {
            recentCallbackSnapshots.removeFirst(recentCallbackSnapshots.count - 20)
        }
    }

    mutating func updateLastCallback(_ snapshot: NotificationBannerCallbackSnapshot) {
        lastCallbackSnapshot = snapshot
        if let index = recentCallbackSnapshots.lastIndex(where: {
            $0.callbackDate == snapshot.callbackDate && $0.notificationName == snapshot.notificationName
        }) {
            recentCallbackSnapshots[index] = snapshot
        }
    }

    mutating func recordCandidate() {
        candidateCount += 1
    }

    mutating func recordDuplicate() {
        duplicateCount += 1
    }

    mutating func recordEvent(_ event: NotificationBannerStructuralEvent) {
        eventCount += 1
        lastStructuralEvent = event
        latency.record(event.effectStartLatency)
    }

    mutating func recordConnectionSuccess() {
        if hasConnected {
            successfulReconnectCount += 1
        } else {
            hasConnected = true
        }
    }

    mutating func resetCounters() {
        callbackCount = 0
        candidateCount = 0
        eventCount = 0
        duplicateCount = 0
        successfulReconnectCount = 0
        latency.reset()
        lastCallbackSnapshot = nil
        recentCallbackSnapshots = []
        lastStructuralEvent = nil
    }
}

enum NotificationBannerConnectionPreflight: Equatable {
    case permissionRequired
    case processUnavailable
    case ready
}

enum NotificationBannerConnectionEvaluator {
    static func preflight(isTrusted: Bool, processAvailable: Bool) -> NotificationBannerConnectionPreflight {
        guard isTrusted else { return .permissionRequired }
        guard processAvailable else { return .processUnavailable }
        return .ready
    }

    static func observerState(hasRegisteredNotification: Bool) -> NotificationBannerMonitorState {
        hasRegisteredNotification ? .active : .unavailable
    }
}
