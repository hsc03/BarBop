import CoreGraphics
import Foundation
import Testing
@testable import BarBop

struct NotificationBannerCoreTests {
    private let classifier = NotificationBannerCandidateClassifier()
    private let primary = NotificationBannerScreen(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900)
    )

    @Test func candidateClassifierAcceptsBoundarySizedTopElement() {
        let frame = CGRect(x: 1200, y: 0, width: 180, height: 40)

        let candidate = classifier.classify(frame: frame, screens: [primary])

        #expect(candidate == NotificationBannerCandidate(frame: frame, screenID: primary.id))
    }

    @Test func candidateClassifierRejectsElementsOutsideSizeAndTopBounds() {
        #expect(classifier.classify(
            frame: CGRect(x: 1200, y: 0, width: 179, height: 40),
            screens: [primary]
        ) == nil)
        #expect(classifier.classify(
            frame: CGRect(x: 1200, y: 0, width: 180, height: 39),
            screens: [primary]
        ) == nil)
        #expect(classifier.classify(
            frame: CGRect(x: 1200, y: 500, width: 180, height: 80),
            screens: [primary]
        ) == nil)
    }

    @Test func candidateClassifierSelectsDisplayWithLargestIntersection() {
        let secondary = NotificationBannerScreen(
            id: 2,
            frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        )
        let frame = CGRect(x: 1400, y: 40, width: 300, height: 100)

        let candidate = classifier.classify(frame: frame, screens: [primary, secondary])

        #expect(candidate?.screenID == secondary.id)
    }

    @Test func deduplicatorRejectsSameElementAndFrameWithinInterval() {
        var deduplicator = NotificationBannerDeduplicator(duplicateInterval: 1)
        let identity = NotificationBannerElementIdentity(rawValue: 10)
        let frame = CGRect(x: 100, y: 20, width: 300, height: 80)

        let firstAccepted = deduplicator.shouldAccept(elementIdentity: identity, frame: frame, at: 10)
        let duplicateAccepted = deduplicator.shouldAccept(elementIdentity: identity, frame: frame, at: 10.5)
        let expiredAccepted = deduplicator.shouldAccept(elementIdentity: identity, frame: frame, at: 11.1)

        #expect(firstAccepted)
        #expect(!duplicateAccepted)
        #expect(expiredAccepted)
    }

    @Test func deduplicatorAcceptsDifferentElementsAtSameFrame() {
        var deduplicator = NotificationBannerDeduplicator(duplicateInterval: 1)
        let frame = CGRect(x: 100, y: 20, width: 300, height: 80)

        let firstAccepted = deduplicator.shouldAccept(
            elementIdentity: NotificationBannerElementIdentity(rawValue: 10),
            frame: frame,
            at: 10
        )
        let secondAccepted = deduplicator.shouldAccept(
            elementIdentity: NotificationBannerElementIdentity(rawValue: 11),
            frame: frame,
            at: 10.1
        )

        #expect(firstAccepted)
        #expect(secondAccepted)
    }

    @Test func latencyMetricsTrackAverageMaximumAndClampNegativeValues() {
        var metrics = NotificationBannerLatencyMetrics()

        metrics.record(0.1)
        metrics.record(0.3)
        metrics.record(-2)

        #expect(metrics.sampleCount == 3)
        #expect(abs(metrics.averageLatency - (0.4 / 3)) < 0.0001)
        #expect(metrics.maximumLatency == 0.3)
    }

    @Test func diagnosticsCountReconnectsOnlyAfterInitialConnection() {
        var diagnostics = NotificationBannerDiagnostics()

        diagnostics.recordConnectionSuccess()
        #expect(diagnostics.successfulReconnectCount == 0)

        diagnostics.recordConnectionSuccess()
        diagnostics.recordConnectionSuccess()
        #expect(diagnostics.successfulReconnectCount == 2)
    }

    @Test func connectionEvaluatorCoversPermissionProcessAndObserverStates() {
        #expect(NotificationBannerConnectionEvaluator.preflight(
            isTrusted: false,
            processAvailable: true
        ) == .permissionRequired)
        #expect(NotificationBannerConnectionEvaluator.preflight(
            isTrusted: true,
            processAvailable: false
        ) == .processUnavailable)
        #expect(NotificationBannerConnectionEvaluator.preflight(
            isTrusted: true,
            processAvailable: true
        ) == .ready)
        #expect(NotificationBannerConnectionEvaluator.observerState(
            hasRegisteredNotification: true
        ) == .active)
        #expect(NotificationBannerConnectionEvaluator.observerState(
            hasRegisteredNotification: false
        ) == .unavailable)
    }

    @Test func diagnosticsRetainRejectedCallbackStructureInMemory() {
        var diagnostics = NotificationBannerDiagnostics()
        let callback = NotificationBannerCallbackSnapshot(
            notificationName: "AXCreated",
            callbackDate: Date(timeIntervalSince1970: 10),
            elements: [
                NotificationBannerElementSnapshot(
                    elementIdentity: NotificationBannerElementIdentity(rawValue: 99),
                    role: "AXGroup",
                    subrole: nil,
                    parentDepth: 0,
                    frame: nil,
                    screenID: nil
                )
            ],
            descendants: [],
            candidateAccepted: false
        )

        diagnostics.recordCallback(callback)

        #expect(diagnostics.callbackCount == 1)
        #expect(diagnostics.candidateCount == 0)
        #expect(diagnostics.lastCallbackSnapshot == callback)
        #expect(diagnostics.recentCallbackSnapshots == [callback])
    }

    @Test func classifierMapsFrameToScreenBeforeCandidateSizeFiltering() {
        let undersizedFrame = CGRect(x: 100, y: 10, width: 20, height: 20)

        let screenID = classifier.screenID(for: undersizedFrame, screens: [primary])

        #expect(screenID == primary.id)
        #expect(classifier.classify(frame: undersizedFrame, screens: [primary]) == nil)
    }

    @Test func structureClassifierAcceptsOnlyConfirmedNotificationBannerSignature() {
        let structureClassifier = NotificationBannerStructureClassifier()

        #expect(structureClassifier.isBanner(
            role: "AXGroup",
            subrole: "AXNotificationCenterBanner",
            depth: 0
        ))
        #expect(structureClassifier.isBanner(
            role: "AXGroup",
            subrole: "AXNotificationCenterBanner",
            depth: 4
        ))
        #expect(!structureClassifier.isBanner(
            role: "AXGroup",
            subrole: nil,
            depth: 4
        ))
        #expect(!structureClassifier.isBanner(
            role: "AXStaticText",
            subrole: "AXNotificationCenterBanner",
            depth: 4
        ))
        #expect(!structureClassifier.isBanner(
            role: "AXGroup",
            subrole: "AXNotificationCenterBanner",
            depth: 7
        ))
    }

    @Test func eventClassifierAcceptsOnlyConfirmedRootLayoutChange() {
        let eventClassifier = NotificationBannerEventClassifier()
        let frame = CGRect(x: 1000, y: 40, width: 344, height: 73)

        #expect(eventClassifier.classify(
            notificationName: "AXLayoutChanged",
            role: "AXGroup",
            subrole: "AXNotificationCenterBanner",
            parentDepth: 0,
            frame: frame,
            screens: [primary]
        )?.screenID == primary.id)
        #expect(eventClassifier.classify(
            notificationName: "AXCreated",
            role: "AXGroup",
            subrole: "AXNotificationCenterBanner",
            parentDepth: 0,
            frame: frame,
            screens: [primary]
        ) == nil)
        #expect(eventClassifier.classify(
            notificationName: "AXLayoutChanged",
            role: "AXGroup",
            subrole: "AXNotificationCenterBanner",
            parentDepth: 1,
            frame: frame,
            screens: [primary]
        ) == nil)
    }
}
