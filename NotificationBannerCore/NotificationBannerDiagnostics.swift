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

struct NotificationBannerAlertStackCandidateClassifier {
    private let candidateClassifier = NotificationBannerCandidateClassifier()

    func classify(
        alertStackFrame: CGRect,
        screens: [NotificationBannerScreen]
    ) -> NotificationBannerCandidate? {
        guard
            alertStackFrame.width >= 300,
            alertStackFrame.width <= 380,
            alertStackFrame.height >= 40,
            alertStackFrame.height <= 80
        else {
            return nil
        }

        return candidateClassifier.classify(frame: alertStackFrame, screens: screens)
    }

    func classify(
        containerFrame: CGRect,
        alertStackFrame: CGRect,
        screens: [NotificationBannerScreen]
    ) -> NotificationBannerCandidate? {
        guard
            containerFrame.width >= 300,
            containerFrame.width <= 700,
            containerFrame.height >= 60,
            containerFrame.height <= 100,
            containerFrame.insetBy(dx: -1, dy: -1).contains(
                CGPoint(x: alertStackFrame.midX, y: alertStackFrame.midY)
            )
        else {
            return nil
        }

        return classify(alertStackFrame: alertStackFrame, screens: screens)
    }
}

struct NotificationBannerAlertCandidateClassifier {
    private let candidateClassifier = NotificationBannerCandidateClassifier()

    func classify(
        alertFrame: CGRect,
        screens: [NotificationBannerScreen]
    ) -> NotificationBannerCandidate? {
        guard
            alertFrame.width >= 300,
            alertFrame.width <= 700,
            alertFrame.height >= 40,
            alertFrame.height <= 180
        else {
            return nil
        }

        return candidateClassifier.classify(frame: alertFrame, screens: screens)
    }
}

struct NotificationCenterPresentationClassifier {
    private let minimumExpandedWidthExcess: CGFloat

    init(minimumExpandedWidthExcess: CGFloat = 240) {
        self.minimumExpandedWidthExcess = minimumExpandedWidthExcess
    }

    func isExpanded(
        ancestors: [NotificationBannerElementSnapshot],
        surroundingElements: [NotificationBannerElementSnapshot] = [],
        screen: NotificationBannerScreen
    ) -> Bool {
        if containsExpandedStructure(in: surroundingElements) {
            return true
        }

        guard
            let scrollArea = ancestors.first(where: { $0.role == "AXScrollArea" }),
            let scrollAreaFrame = scrollArea.frame,
            let containerFrame = ancestors.first(where: {
                $0.parentDepth == scrollArea.parentDepth + 1 &&
                    $0.role == "AXGroup" &&
                    $0.subrole == nil
            })?.frame
        else {
            return false
        }

        return containerFrame.width - scrollAreaFrame.width >= minimumExpandedWidthExcess
    }

    func containsExpandedStructure(
        in elements: [NotificationBannerElementSnapshot]
    ) -> Bool {
        elements.contains(where: {
            $0.role == "AXOpaqueProviderGroup" &&
                $0.subrole == "AXOpaqueProviderGrid"
        })
    }
}

struct NotificationCenterPresentationState {
    private let collapseSuppressionInterval: TimeInterval
    private var suppressionUntil: TimeInterval = 0

    init(collapseSuppressionInterval: TimeInterval = 0.75) {
        self.collapseSuppressionInterval = collapseSuppressionInterval
    }

    mutating func observeExpandedStructure(at time: TimeInterval) {
        suppressionUntil = max(
            suppressionUntil,
            time + collapseSuppressionInterval
        )
    }

    func shouldSuppressStructuralCandidate(at time: TimeInterval) -> Bool {
        time <= suppressionUntil
    }

    mutating func reset() {
        suppressionUntil = 0
    }
}

struct NotificationBannerStructureClassifier {
    static let bannerRole = "AXGroup"
    static let bannerSubrole = "AXNotificationCenterBanner"
    static let alertStackSubrole = "AXNotificationCenterAlertStack"
    static let alertSubrole = "AXNotificationCenterAlert"

    enum Signature: Equatable {
        case notificationBanner
        case alert
        case alertStack
        case alertStackContainer
    }

    func isBanner(role: String, subrole: String?, depth: Int) -> Bool {
        signature(
            role: role,
            subrole: subrole,
            depth: depth,
            directChildRole: nil,
            directChildSubrole: nil
        ) == .notificationBanner
    }

    func signature(
        role: String,
        subrole: String?,
        depth: Int,
        directChildRole: String?,
        directChildSubrole: String?
    ) -> Signature? {
        guard (0...6).contains(depth), role == Self.bannerRole else {
            return nil
        }

        if subrole == Self.bannerSubrole {
            return .notificationBanner
        }

        if depth == 0, subrole == Self.alertStackSubrole {
            return .alertStack
        }

        if depth == 0, subrole == Self.alertSubrole {
            return .alert
        }

        if
            depth == 0,
            subrole == nil,
            directChildRole == Self.bannerRole,
            directChildSubrole == Self.alertStackSubrole
        {
            return .alertStackContainer
        }

        return nil
    }
}

struct NotificationBannerEventClassifier {
    static let layoutChangedNotification = NotificationBannerCallbackPolicy.layoutChangedNotification

    private let candidateClassifier = NotificationBannerCandidateClassifier()
    func classify(
        notificationName: String,
        structure: NotificationBannerStructureClassifier.Signature,
        parentDepth: Int,
        frame: CGRect,
        screens: [NotificationBannerScreen]
    ) -> NotificationBannerCandidate? {
        guard
            notificationName == Self.layoutChangedNotification,
            parentDepth == 0
        else {
            return nil
        }

        switch structure {
        case .notificationBanner, .alert, .alertStack:
            return candidateClassifier.classify(frame: frame, screens: screens)
        case .alertStackContainer:
            return nil
        }
    }
}

struct NotificationBannerCallbackPolicy {
    static let layoutChangedNotification = "AXLayoutChanged"

    let maximumRetryCount: Int
    let maximumPendingRetries: Int
    let presentationValidationDelay: TimeInterval

    init(
        maximumRetryCount: Int = 2,
        maximumPendingRetries: Int = 8,
        presentationValidationDelay: TimeInterval = 0.25
    ) {
        self.maximumRetryCount = maximumRetryCount
        self.maximumPendingRetries = maximumPendingRetries
        self.presentationValidationDelay = presentationValidationDelay
    }

    func shouldInspect(notificationName: String) -> Bool {
        notificationName == Self.layoutChangedNotification
    }

    func shouldScheduleRetry(retryCount: Int, pendingRetryCount: Int) -> Bool {
        retryCount < maximumRetryCount && pendingRetryCount < maximumPendingRetries
    }

    func shouldDelayPresentationValidation(
        structure: NotificationBannerStructureClassifier.Signature,
        retryCount: Int
    ) -> Bool {
        guard retryCount == 0 else { return false }
        return structure == .alert || structure == .alertStack
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

struct NotificationBannerElementDeduplicator {
    private let duplicateInterval: TimeInterval
    private var recentEvents: [NotificationBannerElementIdentity: TimeInterval] = [:]

    init(duplicateInterval: TimeInterval = 2) {
        self.duplicateInterval = duplicateInterval
    }

    mutating func shouldAccept(
        elementIdentity: NotificationBannerElementIdentity,
        at time: TimeInterval
    ) -> Bool {
        recentEvents = recentEvents.filter { time - $0.value <= duplicateInterval }

        if let previousTime = recentEvents[elementIdentity], time - previousTime <= duplicateInterval {
            return false
        }

        recentEvents[elementIdentity] = time
        return true
    }

    mutating func reset() {
        recentEvents.removeAll()
    }
}

struct NotificationBannerAlertStackDeduplicator {
    private struct Key: Hashable {
        let screenID: CGDirectDisplayID
        let y: Int

        init(screenID: CGDirectDisplayID, frame: CGRect) {
            self.screenID = screenID
            y = Int(frame.origin.y.rounded())
        }
    }

    private let duplicateInterval: TimeInterval
    private var recentEvents: [Key: TimeInterval] = [:]

    init(duplicateInterval: TimeInterval = 0.4) {
        self.duplicateInterval = duplicateInterval
    }

    mutating func shouldAccept(
        screenID: CGDirectDisplayID,
        frame: CGRect,
        at time: TimeInterval
    ) -> Bool {
        recentEvents = recentEvents.filter { time - $0.value <= duplicateInterval }
        let key = Key(screenID: screenID, frame: frame)

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

struct NotificationBannerStructuralDeduplicator {
    private var elementDeduplicator: NotificationBannerElementDeduplicator
    private var geometryDeduplicator: NotificationBannerAlertStackDeduplicator
    private var ignoredElementIdentities: Set<NotificationBannerElementIdentity> = []

    init(
        elementDuplicateInterval: TimeInterval = 30,
        geometryDuplicateInterval: TimeInterval = 0.4
    ) {
        elementDeduplicator = NotificationBannerElementDeduplicator(
            duplicateInterval: elementDuplicateInterval
        )
        geometryDeduplicator = NotificationBannerAlertStackDeduplicator(
            duplicateInterval: geometryDuplicateInterval
        )
    }

    mutating func shouldAccept(
        elementIdentity: NotificationBannerElementIdentity,
        screenID: CGDirectDisplayID,
        frame: CGRect,
        at time: TimeInterval
    ) -> Bool {
        guard !ignoredElementIdentities.contains(elementIdentity) else {
            return false
        }
        let isNewElement = elementDeduplicator.shouldAccept(
            elementIdentity: elementIdentity,
            at: time
        )
        let isNewGeometry = geometryDeduplicator.shouldAccept(
            screenID: screenID,
            frame: frame,
            at: time
        )
        return isNewElement && isNewGeometry
    }

    mutating func ignoreExistingElement(
        _ elementIdentity: NotificationBannerElementIdentity
    ) {
        ignoredElementIdentities.insert(elementIdentity)
    }

    mutating func reset() {
        elementDeduplicator.reset()
        geometryDeduplicator.reset()
        ignoredElementIdentities.removeAll()
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
    private(set) var recentStructuralEvents: [NotificationBannerStructuralEvent] = []
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
        recentStructuralEvents.append(event)
        if recentStructuralEvents.count > 20 {
            recentStructuralEvents.removeFirst(recentStructuralEvents.count - 20)
        }
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
        recentStructuralEvents = []
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
