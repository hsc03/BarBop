import AppKit
import ApplicationServices
import Combine

extension NotificationBannerMonitorState {
    var label: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .permissionRequired:
            return "Accessibility access required"
        case .connecting:
            return "Connecting to Notification Center"
        case .active:
            return "Observing visible notification banners"
        case .unavailable:
            return "Notification Center observer unavailable"
        }
    }
}

struct NotificationBannerEvent: Equatable {
    let date: Date
    let bannerFrame: CGRect
    let screenID: CGDirectDisplayID
}

@MainActor
protocol NotificationBannerMonitoring: AnyObject {
    var state: NotificationBannerMonitorState { get }
    func start()
    func stop()
    func reconnect()
}

@MainActor
final class NotificationBannerDetector: ObservableObject, NotificationBannerMonitoring {
    struct Dependencies {
        var uptime: () -> TimeInterval
        var date: () -> Date
        var screens: () -> [NotificationBannerScreen]

        static let live = Dependencies(
            uptime: { ProcessInfo.processInfo.systemUptime },
            date: Date.init,
            screens: {
                NSScreen.screens.compactMap { screen in
                    guard let id = screen.displayID else { return nil }
                    return NotificationBannerScreen(id: id, frame: CGDisplayBounds(id))
                }
            }
        )
    }

    private struct CandidateMetadata {
        let frame: CGRect
        let screenID: CGDirectDisplayID
        let elementIdentity: NotificationBannerElementIdentity
        let role: String
        let subrole: String?
        let parentDepth: Int
        let structure: NotificationBannerStructureClassifier.Signature
    }

    private struct ElementProbe {
        let candidate: CandidateMetadata?
        let snapshots: [NotificationBannerElementSnapshot]
        let descendantSnapshots: [NotificationBannerElementSnapshot]
    }

    private struct DescendantProbe {
        let candidate: CandidateMetadata?
        let snapshots: [NotificationBannerElementSnapshot]
    }

    nonisolated private static let notificationCenterBundleIdentifier = "com.apple.notificationcenterui"
    private static let maximumTraversalNodeCount = 80

    @Published private(set) var state: NotificationBannerMonitorState = .stopped {
        didSet { onStateChange(state) }
    }
    @Published private(set) var statusDetail = "The observer has not started."
    @Published private(set) var diagnostics = NotificationBannerDiagnostics()
    @Published private(set) var lastEvent: NotificationBannerEvent?

    var lastEventDate: Date? { lastEvent?.date }
    var eventCount: Int { diagnostics.eventCount }
    var duplicateCount: Int { diagnostics.duplicateCount }

    private let onEvent: (NotificationBannerEvent) -> TimeInterval?
    private let onReset: () -> Void
    private let onStateChange: (NotificationBannerMonitorState) -> Void
    private let dependencies: Dependencies
    private let candidateClassifier = NotificationBannerCandidateClassifier()
    private let alertStackCandidateClassifier = NotificationBannerAlertStackCandidateClassifier()
    private let structureClassifier = NotificationBannerStructureClassifier()
    private let eventClassifier = NotificationBannerEventClassifier()
    private let callbackPolicy = NotificationBannerCallbackPolicy()
    private var observer: AXObserver?
    private var observedApplication: AXUIElement?
    private var registeredNotifications: [CFString] = []
    private var lifecycleTokens: [NSObjectProtocol] = []
    private var deduplicator = NotificationBannerDeduplicator(duplicateInterval: 1)
    private var alertStackDeduplicator = NotificationBannerAlertStackDeduplicator()
    private var isStarted = false
    private var pendingRetryCount = 0
    private var observationGeneration = 0

    init(
        dependencies: Dependencies? = nil,
        onEvent: @escaping (NotificationBannerEvent) -> TimeInterval?,
        onReset: @escaping () -> Void = {},
        onStateChange: @escaping (NotificationBannerMonitorState) -> Void = { _ in }
    ) {
        self.dependencies = dependencies ?? .live
        self.onEvent = onEvent
        self.onReset = onReset
        self.onStateChange = onStateChange
    }

    func start() {
        guard !isStarted else {
            reconnect()
            return
        }

        isStarted = true
        installLifecycleObservers()
        reconnect()
    }

    func stop() {
        isStarted = false
        tearDownObserver()
        removeLifecycleObservers()
        onReset()
        state = .stopped
        statusDetail = "The observer is stopped."
    }

    func reconnect() {
        tearDownObserver()
        onReset()

        let isTrusted = AXIsProcessTrusted()
        let application = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == Self.notificationCenterBundleIdentifier
        })

        switch NotificationBannerConnectionEvaluator.preflight(
            isTrusted: isTrusted,
            processAvailable: application != nil
        ) {
        case .permissionRequired:
            state = .permissionRequired
            statusDetail = "Grant Accessibility access, then return to the app and choose Reconnect."
            return
        case .processUnavailable:
            state = .unavailable
            statusDetail = "The Notification Center process is not running. The observer will retry when it launches."
            return
        case .ready:
            break
        }

        guard let application else { return }
        state = .connecting
        statusDetail = "Connecting to the Notification Center UI process."
        connect(to: application.processIdentifier)
    }

    func requestAccessibilityAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        state = .permissionRequired
        statusDetail = "Complete the Accessibility approval in System Settings, then choose Reconnect."
    }

    func resetCounters() {
        diagnostics.resetCounters()
        lastEvent = nil
        deduplicator.reset()
        alertStackDeduplicator.reset()
    }

    fileprivate func receiveCreatedElement(
        _ element: AXUIElement,
        notificationName: String,
        callbackDate: Date,
        callbackUptime: TimeInterval,
        retryCount: Int = 0
    ) {
        guard state == .active else {
            return
        }
        guard callbackPolicy.shouldInspect(notificationName: notificationName) else {
            return
        }

        let probe = elementProbe(for: element)
        let acceptedCandidate = probe.candidate.flatMap { candidate -> CandidateMetadata? in
            eventClassifier.classify(
                notificationName: notificationName,
                structure: candidate.structure,
                parentDepth: candidate.parentDepth,
                frame: candidate.frame,
                screens: dependencies.screens()
            ) == nil ? nil : candidate
        }
        let callbackSnapshot = NotificationBannerCallbackSnapshot(
            notificationName: notificationName,
            callbackDate: callbackDate,
            elements: probe.snapshots,
            descendants: probe.descendantSnapshots,
            candidateAccepted: acceptedCandidate != nil
        )
        if retryCount == 0 {
            diagnostics.recordCallback(callbackSnapshot)
        } else {
            diagnostics.updateLastCallback(callbackSnapshot)
        }

        guard let candidate = acceptedCandidate else {
            guard callbackPolicy.shouldScheduleRetry(
                retryCount: retryCount,
                pendingRetryCount: pendingRetryCount
            ) else {
                return
            }
            pendingRetryCount += 1
            let retryGeneration = observationGeneration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self, self.observationGeneration == retryGeneration else {
                    return
                }
                self.pendingRetryCount = max(0, self.pendingRetryCount - 1)
                self.receiveCreatedElement(
                    element,
                    notificationName: notificationName,
                    callbackDate: callbackDate,
                    callbackUptime: callbackUptime,
                    retryCount: retryCount + 1
                )
            }
            return
        }

        diagnostics.recordCandidate()
        let now = dependencies.uptime()
        let shouldAccept: Bool
        switch candidate.structure {
        case .notificationBanner:
            shouldAccept = deduplicator.shouldAccept(
                elementIdentity: candidate.elementIdentity,
                frame: candidate.frame,
                at: now
            )
        case .alertStackContainer:
            shouldAccept = alertStackDeduplicator.shouldAccept(
                screenID: candidate.screenID,
                frame: candidate.frame,
                at: now
            )
        }
        guard shouldAccept else {
            diagnostics.recordDuplicate()
            return
        }

        let event = NotificationBannerEvent(
            date: callbackDate,
            bannerFrame: candidate.frame,
            screenID: candidate.screenID
        )
        let effectStartUptime = onEvent(event) ?? dependencies.uptime()
        let effectStartLatency = max(0, effectStartUptime - callbackUptime)
        lastEvent = event
        diagnostics.recordEvent(
            NotificationBannerStructuralEvent(
                notificationName: notificationName,
                callbackDate: callbackDate,
                elementIdentity: candidate.elementIdentity,
                role: candidate.role,
                subrole: candidate.subrole,
                parentDepth: candidate.parentDepth,
                frame: candidate.frame,
                screenID: candidate.screenID,
                effectStartLatency: effectStartLatency
            )
        )

    }

    private func connect(to processIdentifier: pid_t) {
        var newObserver: AXObserver?
        let createResult = AXObserverCreate(
            processIdentifier,
            { _, element, notification, refcon in
                guard let refcon else { return }
                let callbackDate = Date()
                let callbackUptime = ProcessInfo.processInfo.systemUptime
                let notificationName = notification as String
                let monitor = Unmanaged<NotificationBannerDetector>.fromOpaque(refcon).takeUnretainedValue()
                DispatchQueue.main.async {
                    monitor.receiveCreatedElement(
                        element,
                        notificationName: notificationName,
                        callbackDate: callbackDate,
                        callbackUptime: callbackUptime
                    )
                }
            },
            &newObserver
        )

        guard createResult == .success, let newObserver else {
            state = .unavailable
            statusDetail = "AXObserverCreate failed with error \(createResult.rawValue)."
            return
        }

        let application = AXUIElementCreateApplication(processIdentifier)
        let requestedNotifications: [CFString] = [
            kAXLayoutChangedNotification as CFString,
        ]
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        var successfulNotifications: [CFString] = []

        for notification in requestedNotifications {
            let result = AXObserverAddNotification(newObserver, application, notification, refcon)
            if result == .success || result == .notificationAlreadyRegistered {
                successfulNotifications.append(notification)
            }
        }

        state = NotificationBannerConnectionEvaluator.observerState(
            hasRegisteredNotification: !successfulNotifications.isEmpty
        )
        guard state == .active else {
            statusDetail = "Notification Center does not expose supported creation notifications through Accessibility."
            return
        }

        observer = newObserver
        observedApplication = application
        registeredNotifications = successfulNotifications
        diagnostics.registeredNotificationNames = successfulNotifications
            .map { $0 as String }
            .sorted()
        diagnostics.recordConnectionSuccess()
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(newObserver), .commonModes)
        statusDetail = "Connected to com.apple.notificationcenterui. Only visible structural creation events are inspected."
    }

    private func tearDownObserver() {
        observationGeneration += 1
        pendingRetryCount = 0
        guard let observer else {
            observedApplication = nil
            registeredNotifications = []
            return
        }

        if let observedApplication {
            for notification in registeredNotifications {
                AXObserverRemoveNotification(observer, observedApplication, notification)
            }
        }

        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        self.observer = nil
        observedApplication = nil
        registeredNotifications = []
    }

    private func installLifecycleObservers() {
        guard lifecycleTokens.isEmpty else { return }

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        lifecycleTokens.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.didLaunchApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard
                    let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                    application.bundleIdentifier == Self.notificationCenterBundleIdentifier
                else {
                    return
                }
                Task { @MainActor [weak self] in
                    self?.reconnect()
                }
            }
        )
        lifecycleTokens.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.didTerminateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard
                    let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                    application.bundleIdentifier == Self.notificationCenterBundleIdentifier
                else {
                    return
                }
                Task { @MainActor [weak self] in
                    self?.tearDownObserver()
                    self?.onReset()
                    self?.state = .connecting
                    self?.statusDetail = "Notification Center restarted. Waiting for its process to launch again."
                }
            }
        )
        lifecycleTokens.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, self.isStarted else { return }
                    self.reconnect()
                }
            }
        )
        lifecycleTokens.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, self.isStarted else { return }
                    self.reconnect()
                }
            }
        )
    }

    private func removeLifecycleObservers() {
        for token in lifecycleTokens {
            NSWorkspace.shared.notificationCenter.removeObserver(token)
            NotificationCenter.default.removeObserver(token)
        }
        lifecycleTokens = []
    }

    private func elementProbe(for element: AXUIElement) -> ElementProbe {
        var current: AXUIElement? = element
        var snapshots: [NotificationBannerElementSnapshot] = []
        let descendantProbe = descendantProbe(of: element)

        for parentDepth in 0..<6 {
            guard let candidate = current else { break }
            let role = stringAttribute(kAXRoleAttribute as CFString, from: candidate) ?? "unknown"
            let subrole = stringAttribute(kAXSubroleAttribute as CFString, from: candidate)
            let identity = NotificationBannerElementIdentity(
                rawValue: Int(truncatingIfNeeded: CFHash(candidate))
            )
            let candidateFrame = frame(of: candidate)
            let screens = dependencies.screens()
            snapshots.append(
                NotificationBannerElementSnapshot(
                    elementIdentity: identity,
                    role: role,
                    subrole: subrole,
                    parentDepth: parentDepth,
                    frame: candidateFrame,
                    screenID: candidateFrame.flatMap {
                        candidateClassifier.screenID(for: $0, screens: screens)
                    }
                )
            )

            if
                structureClassifier.isBanner(role: role, subrole: subrole, depth: parentDepth),
                let frame = candidateFrame,
                let classified = candidateClassifier.classify(
                    frame: frame,
                    screens: screens
                )
            {
                return ElementProbe(
                    candidate: CandidateMetadata(
                        frame: classified.frame,
                        screenID: classified.screenID,
                        elementIdentity: identity,
                        role: role,
                        subrole: subrole,
                        parentDepth: parentDepth,
                        structure: .notificationBanner
                    ),
                    snapshots: snapshots,
                    descendantSnapshots: descendantProbe.snapshots
                )
            }

            if
                parentDepth == 0,
                let directAlertStack = descendantProbe.snapshots.first(where: {
                    $0.parentDepth == 1 &&
                        $0.role == NotificationBannerStructureClassifier.bannerRole &&
                        $0.subrole == NotificationBannerStructureClassifier.alertStackSubrole
                }),
                structureClassifier.signature(
                    role: role,
                    subrole: subrole,
                    depth: parentDepth,
                    directChildRole: directAlertStack.role,
                    directChildSubrole: directAlertStack.subrole
                ) == .alertStackContainer,
                let containerFrame = candidateFrame,
                let alertStackFrame = directAlertStack.frame,
                let classified = alertStackCandidateClassifier.classify(
                    containerFrame: containerFrame,
                    alertStackFrame: alertStackFrame,
                    screens: screens
                )
            {
                return ElementProbe(
                    candidate: CandidateMetadata(
                        frame: classified.frame,
                        screenID: classified.screenID,
                        elementIdentity: directAlertStack.elementIdentity,
                        role: role,
                        subrole: subrole,
                        parentDepth: parentDepth,
                        structure: .alertStackContainer
                    ),
                    snapshots: snapshots,
                    descendantSnapshots: descendantProbe.snapshots
                )
            }

            current = elementAttribute(kAXParentAttribute as CFString, from: candidate)
        }

        return ElementProbe(
            candidate: descendantProbe.candidate,
            snapshots: snapshots,
            descendantSnapshots: descendantProbe.snapshots
        )
    }

    private func descendantProbe(of root: AXUIElement) -> DescendantProbe {
        struct PendingElement {
            let element: AXUIElement
            let depth: Int
        }

        var pending = children(of: root).map { PendingElement(element: $0, depth: 1) }
        var snapshots: [NotificationBannerElementSnapshot] = []
        var bannerCandidate: CandidateMetadata?
        var visited: Set<NotificationBannerElementIdentity> = []
        let screens = dependencies.screens()

        var processedNodeCount = 0

        while !pending.isEmpty, processedNodeCount < Self.maximumTraversalNodeCount {
            let current = pending.removeFirst()
            processedNodeCount += 1
            guard current.depth <= 6 else { continue }

            let identity = NotificationBannerElementIdentity(
                rawValue: Int(truncatingIfNeeded: CFHash(current.element))
            )
            guard visited.insert(identity).inserted else { continue }

            let role = stringAttribute(kAXRoleAttribute as CFString, from: current.element) ?? "unknown"
            let subrole = stringAttribute(kAXSubroleAttribute as CFString, from: current.element)
            let elementFrame = frame(of: current.element)

            if shouldRecordDescendant(role: role, frame: elementFrame) {
                snapshots.append(
                    NotificationBannerElementSnapshot(
                        elementIdentity: identity,
                        role: role,
                        subrole: subrole,
                        parentDepth: current.depth,
                        frame: elementFrame,
                        screenID: elementFrame.flatMap {
                            candidateClassifier.screenID(for: $0, screens: screens)
                        }
                    )
                )
            }

            if
                bannerCandidate == nil,
                structureClassifier.isBanner(role: role, subrole: subrole, depth: current.depth),
                let elementFrame,
                let classified = candidateClassifier.classify(frame: elementFrame, screens: screens)
            {
                bannerCandidate = CandidateMetadata(
                    frame: classified.frame,
                    screenID: classified.screenID,
                    elementIdentity: identity,
                    role: role,
                    subrole: subrole,
                    parentDepth: current.depth,
                    structure: .notificationBanner
                )
            }

            if current.depth < 6 {
                pending.append(contentsOf: children(of: current.element).map {
                    PendingElement(element: $0, depth: current.depth + 1)
                })
            }
        }

        return DescendantProbe(candidate: bannerCandidate, snapshots: snapshots)
    }

    private func shouldRecordDescendant(role: String, frame: CGRect?) -> Bool {
        guard let frame else {
            return role == (kAXWindowRole as String) || role == (kAXGroupRole as String)
        }
        return frame.width >= 100 && frame.height >= 20
    }

    private func children(of element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value) == .success,
            let value,
            CFGetTypeID(value) == CFArrayGetTypeID()
        else {
            return []
        }
        return value as? [AXUIElement] ?? []
    }

    private func stringAttribute(_ attribute: CFString, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else { return nil }
        return value as? String
    }

    private func elementAttribute(_ attribute: CFString, from element: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
            let value,
            CFGetTypeID(value) == AXUIElementGetTypeID()
        else {
            return nil
        }
        return unsafeBitCast(value, to: AXUIElement.self)
    }

    private func frame(of element: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue) == .success,
            AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success,
            let positionValue,
            let sizeValue,
            CFGetTypeID(positionValue) == AXValueGetTypeID(),
            CFGetTypeID(sizeValue) == AXValueGetTypeID()
        else {
            return nil
        }

        var position = CGPoint.zero
        var size = CGSize.zero
        guard
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &position),
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        else {
            return nil
        }

        return CGRect(origin: position, size: size)
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
