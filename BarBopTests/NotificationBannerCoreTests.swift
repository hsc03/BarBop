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

    @Test func elementDeduplicatorCollapsesLongAnimationsButAllowsDistinctBanners() {
        var deduplicator = NotificationBannerElementDeduplicator(duplicateInterval: 30)
        let firstIdentity = NotificationBannerElementIdentity(rawValue: 10)
        let secondIdentity = NotificationBannerElementIdentity(rawValue: 11)

        let firstAccepted = deduplicator.shouldAccept(elementIdentity: firstIdentity, at: 10)
        let sameElementAccepted = deduplicator.shouldAccept(elementIdentity: firstIdentity, at: 10.5)
        let differentElementAccepted = deduplicator.shouldAccept(elementIdentity: secondIdentity, at: 10.5)
        let longAnimationAccepted = deduplicator.shouldAccept(elementIdentity: firstIdentity, at: 17)
        let expiredAccepted = deduplicator.shouldAccept(elementIdentity: firstIdentity, at: 40.6)

        #expect(firstAccepted)
        #expect(!sameElementAccepted)
        #expect(differentElementAccepted)
        #expect(!longAnimationAccepted)
        #expect(expiredAccepted)
    }

    @Test func alertStackDeduplicatorCollapsesHorizontalAnimationOnly() {
        var deduplicator = NotificationBannerAlertStackDeduplicator(duplicateInterval: 0.4)
        let enteringFrame = CGRect(x: 1450, y: 49, width: 344, height: 57)
        let settledFrame = CGRect(x: 1175, y: 49, width: 344, height: 57)

        let firstAccepted = deduplicator.shouldAccept(screenID: 1, frame: enteringFrame, at: 10)
        let animationDuplicateAccepted = deduplicator.shouldAccept(screenID: 1, frame: settledFrame, at: 10.1)
        let resizedAnimationDuplicateAccepted = deduplicator.shouldAccept(
            screenID: 1,
            frame: CGRect(x: 1175, y: 49, width: 350, height: 62),
            at: 10.2
        )
        let otherScreenAccepted = deduplicator.shouldAccept(screenID: 2, frame: settledFrame, at: 10.1)
        let otherVerticalPositionAccepted = deduplicator.shouldAccept(
            screenID: 1,
            frame: CGRect(x: 1175, y: 130, width: 344, height: 57),
            at: 10.1
        )
        let afterIntervalAccepted = deduplicator.shouldAccept(screenID: 1, frame: settledFrame, at: 10.5)

        #expect(firstAccepted)
        #expect(!animationDuplicateAccepted)
        #expect(!resizedAnimationDuplicateAccepted)
        #expect(otherScreenAccepted)
        #expect(otherVerticalPositionAccepted)
        #expect(afterIntervalAccepted)
    }

    @Test func structuralDeduplicatorMergesAlertAndStackButAllowsNextBanner() {
        var deduplicator = NotificationBannerStructuralDeduplicator(
            elementDuplicateInterval: 30,
            geometryDuplicateInterval: 0.4
        )
        let frame = CGRect(x: 1200, y: 49, width: 344, height: 57)

        let alertAccepted = deduplicator.shouldAccept(
            elementIdentity: NotificationBannerElementIdentity(rawValue: 1),
            screenID: primary.id,
            frame: frame,
            at: 10
        )
        let pairedStackAccepted = deduplicator.shouldAccept(
            elementIdentity: NotificationBannerElementIdentity(rawValue: 2),
            screenID: primary.id,
            frame: frame.offsetBy(dx: -50, dy: 0),
            at: 10.1
        )
        let nextBannerAccepted = deduplicator.shouldAccept(
            elementIdentity: NotificationBannerElementIdentity(rawValue: 3),
            screenID: primary.id,
            frame: frame,
            at: 10.5
        )
        let longAnimationAccepted = deduplicator.shouldAccept(
            elementIdentity: NotificationBannerElementIdentity(rawValue: 1),
            screenID: primary.id,
            frame: frame,
            at: 17
        )

        #expect(alertAccepted)
        #expect(!pairedStackAccepted)
        #expect(nextBannerAccepted)
        #expect(!longAnimationAccepted)
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

    @Test func diagnosticsRetainAndResetRecentDetectedEventsInMemory() {
        var diagnostics = NotificationBannerDiagnostics()
        let event = NotificationBannerStructuralEvent(
            notificationName: "AXLayoutChanged",
            callbackDate: Date(timeIntervalSince1970: 100),
            elementIdentity: NotificationBannerElementIdentity(rawValue: 42),
            role: "AXGroup",
            subrole: "AXNotificationCenterAlertStack",
            parentDepth: 0,
            frame: CGRect(x: 100, y: 20, width: 344, height: 57),
            screenID: primary.id,
            effectStartLatency: 0.01
        )

        diagnostics.recordEvent(event)

        #expect(diagnostics.recentStructuralEvents == [event])
        diagnostics.resetCounters()
        #expect(diagnostics.recentStructuralEvents.isEmpty)
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

    @Test func structureClassifierAcceptsOnlyConfirmedAlertStackContainerSignature() {
        let structureClassifier = NotificationBannerStructureClassifier()

        #expect(structureClassifier.signature(
            role: "AXGroup",
            subrole: nil,
            depth: 0,
            directChildRole: "AXGroup",
            directChildSubrole: "AXNotificationCenterAlertStack"
        ) == .alertStackContainer)
        #expect(structureClassifier.signature(
            role: "AXGroup",
            subrole: nil,
            depth: 1,
            directChildRole: "AXGroup",
            directChildSubrole: "AXNotificationCenterAlertStack"
        ) == nil)
        #expect(structureClassifier.signature(
            role: "AXGroup",
            subrole: "AXNotificationCenterAlertStack",
            depth: 0,
            directChildRole: nil,
            directChildSubrole: nil
        ) == .alertStack)
        #expect(structureClassifier.signature(
            role: "AXGroup",
            subrole: "AXNotificationCenterAlertStack",
            depth: 1,
            directChildRole: nil,
            directChildSubrole: nil
        ) == nil)
        #expect(structureClassifier.signature(
            role: "AXGroup",
            subrole: "AXNotificationCenterAlert",
            depth: 0,
            directChildRole: nil,
            directChildSubrole: nil
        ) == .alert)
        #expect(structureClassifier.signature(
            role: "AXGroup",
            subrole: "AXNotificationCenterAlert",
            depth: 1,
            directChildRole: nil,
            directChildSubrole: nil
        ) == nil)
        #expect(structureClassifier.signature(
            role: "AXScrollArea",
            subrole: nil,
            depth: 0,
            directChildRole: "AXGroup",
            directChildSubrole: "AXNotificationCenterAlertStack"
        ) == nil)
    }

    @Test func alertStackCandidateUsesStableChildFrameAndRejectsLooseGeometry() {
        let classifier = NotificationBannerAlertStackCandidateClassifier()
        let container = CGRect(x: 1100, y: 49, width: 620, height: 73)
        let alertStack = CGRect(x: 1100, y: 49, width: 344, height: 57)

        #expect(classifier.classify(
            containerFrame: container,
            alertStackFrame: alertStack,
            screens: [primary]
        ) == NotificationBannerCandidate(frame: alertStack, screenID: primary.id))
        #expect(classifier.classify(
            alertStackFrame: alertStack,
            screens: [primary]
        ) == NotificationBannerCandidate(frame: alertStack, screenID: primary.id))
        #expect(classifier.classify(
            containerFrame: CGRect(x: 900, y: 0, width: 752, height: 962),
            alertStackFrame: alertStack,
            screens: [primary]
        ) == nil)
        #expect(classifier.classify(
            containerFrame: container,
            alertStackFrame: CGRect(x: 100, y: 500, width: 344, height: 57),
            screens: [primary]
        ) == nil)
    }

    @Test func alertCandidateAcceptsOnlyBannerSizedTopElements() {
        let classifier = NotificationBannerAlertCandidateClassifier()
        let alert = CGRect(x: 1000, y: 49, width: 465, height: 93)

        #expect(classifier.classify(
            alertFrame: alert,
            screens: [primary]
        ) == NotificationBannerCandidate(frame: alert, screenID: primary.id))
        #expect(classifier.classify(
            alertFrame: CGRect(x: 900, y: 0, width: 752, height: 962),
            screens: [primary]
        ) == nil)
        #expect(classifier.classify(
            alertFrame: CGRect(x: 1000, y: 500, width: 344, height: 57),
            screens: [primary]
        ) == nil)
    }

    @Test func presentationClassifierDistinguishesExpandedNotificationCenter() {
        let classifier = NotificationCenterPresentationClassifier()
        let alert = NotificationBannerElementSnapshot(
            elementIdentity: NotificationBannerElementIdentity(rawValue: 1),
            role: "AXGroup",
            subrole: "AXNotificationCenterAlertStack",
            parentDepth: 0,
            frame: CGRect(x: 1100, y: 49, width: 344, height: 57),
            screenID: primary.id
        )
        let scrollArea = NotificationBannerElementSnapshot(
            elementIdentity: NotificationBannerElementIdentity(rawValue: 2),
            role: "AXScrollArea",
            subrole: nil,
            parentDepth: 2,
            frame: CGRect(x: 760, y: 0, width: 752, height: 962),
            screenID: primary.id
        )
        let collapsedContainer = NotificationBannerElementSnapshot(
            elementIdentity: NotificationBannerElementIdentity(rawValue: 3),
            role: "AXGroup",
            subrole: nil,
            parentDepth: 3,
            frame: CGRect(x: 760, y: 0, width: 792, height: 962),
            screenID: primary.id
        )
        let expandedContainer = NotificationBannerElementSnapshot(
            elementIdentity: NotificationBannerElementIdentity(rawValue: 4),
            role: "AXGroup",
            subrole: nil,
            parentDepth: 3,
            frame: CGRect(x: 760, y: 0, width: 1_040, height: 962),
            screenID: primary.id
        )
        let largeCollapsedContainer = NotificationBannerElementSnapshot(
            elementIdentity: NotificationBannerElementIdentity(rawValue: 5),
            role: "AXGroup",
            subrole: nil,
            parentDepth: 3,
            frame: CGRect(x: 579, y: 0, width: 933, height: 962),
            screenID: primary.id
        )
        let widgetGrid = NotificationBannerElementSnapshot(
            elementIdentity: NotificationBannerElementIdentity(rawValue: 6),
            role: "AXOpaqueProviderGroup",
            subrole: "AXOpaqueProviderGrid",
            parentDepth: 1,
            frame: CGRect(x: 1_168, y: 300, width: 344, height: 344),
            screenID: primary.id
        )

        #expect(!classifier.isExpanded(
            ancestors: [alert, scrollArea, collapsedContainer],
            screen: primary
        ))
        #expect(!classifier.isExpanded(
            ancestors: [alert, scrollArea, largeCollapsedContainer],
            screen: primary
        ))
        #expect(classifier.isExpanded(
            ancestors: [alert, scrollArea, expandedContainer],
            screen: primary
        ))
        #expect(classifier.isExpanded(
            ancestors: [alert, scrollArea, collapsedContainer],
            surroundingElements: [widgetGrid],
            screen: primary
        ))
        #expect(classifier.containsExpandedStructure(in: [widgetGrid]))
        #expect(!classifier.containsExpandedStructure(in: [alert, scrollArea]))
    }

    @Test func presentationStateSuppressesNotificationCenterCollapseOnlyBriefly() {
        var state = NotificationCenterPresentationState(
            collapseSuppressionInterval: 0.75
        )

        #expect(!state.shouldSuppressStructuralCandidate(at: 9))
        state.observeExpandedStructure(at: 10)
        #expect(state.shouldSuppressStructuralCandidate(at: 10.74))
        #expect(!state.shouldSuppressStructuralCandidate(at: 10.76))
        state.reset()
        #expect(!state.shouldSuppressStructuralCandidate(at: 10.1))
    }

    @Test func eventClassifierAcceptsOnlyConfirmedRootLayoutChange() {
        let eventClassifier = NotificationBannerEventClassifier()
        let frame = CGRect(x: 1000, y: 40, width: 344, height: 73)

        #expect(eventClassifier.classify(
            notificationName: "AXLayoutChanged",
            structure: .notificationBanner,
            parentDepth: 0,
            frame: frame,
            screens: [primary]
        )?.screenID == primary.id)
        #expect(eventClassifier.classify(
            notificationName: "AXCreated",
            structure: .notificationBanner,
            parentDepth: 0,
            frame: frame,
            screens: [primary]
        ) == nil)
        #expect(eventClassifier.classify(
            notificationName: "AXLayoutChanged",
            structure: .notificationBanner,
            parentDepth: 1,
            frame: frame,
            screens: [primary]
        ) == nil)
        #expect(eventClassifier.classify(
            notificationName: "AXLayoutChanged",
            structure: .alertStackContainer,
            parentDepth: 0,
            frame: frame,
            screens: [primary]
        ) == nil)
        #expect(eventClassifier.classify(
            notificationName: "AXLayoutChanged",
            structure: .alertStack,
            parentDepth: 0,
            frame: frame,
            screens: [primary]
        )?.screenID == primary.id)
        #expect(eventClassifier.classify(
            notificationName: "AXLayoutChanged",
            structure: .alert,
            parentDepth: 0,
            frame: frame,
            screens: [primary]
        )?.screenID == primary.id)
    }

    @Test func callbackPolicyInspectsOnlyLayoutChanges() {
        let policy = NotificationBannerCallbackPolicy()

        #expect(policy.presentationValidationDelay == 0.25)

        #expect(policy.shouldInspect(notificationName: "AXLayoutChanged"))
        #expect(!policy.shouldInspect(notificationName: "AXCreated"))
        #expect(!policy.shouldInspect(notificationName: "AXValueChanged"))
    }

    @Test func callbackPolicyBoundsRetriesAndPendingWork() {
        let policy = NotificationBannerCallbackPolicy(
            maximumRetryCount: 2,
            maximumPendingRetries: 8
        )

        #expect(policy.shouldScheduleRetry(retryCount: 0, pendingRetryCount: 0))
        #expect(policy.shouldScheduleRetry(retryCount: 1, pendingRetryCount: 7))
        #expect(!policy.shouldScheduleRetry(retryCount: 2, pendingRetryCount: 0))
        #expect(!policy.shouldScheduleRetry(retryCount: 0, pendingRetryCount: 8))
    }

    @Test func callbackPolicyDelaysOnlyInitialAlertPresentationValidation() {
        let policy = NotificationBannerCallbackPolicy()

        #expect(policy.shouldDelayPresentationValidation(
            structure: .alert,
            retryCount: 0
        ))
        #expect(policy.shouldDelayPresentationValidation(
            structure: .alertStack,
            retryCount: 0
        ))
        #expect(!policy.shouldDelayPresentationValidation(
            structure: .notificationBanner,
            retryCount: 0
        ))
        #expect(!policy.shouldDelayPresentationValidation(
            structure: .alert,
            retryCount: 1
        ))
    }

    @Test func structuralDeduplicatorSuppressesElementsPresentAtConnection() {
        var deduplicator = NotificationBannerStructuralDeduplicator()
        let existing = NotificationBannerElementIdentity(rawValue: 51)
        let newBanner = NotificationBannerElementIdentity(rawValue: 52)
        let frame = CGRect(x: 1_100, y: 49, width: 344, height: 57)

        deduplicator.ignoreExistingElement(existing)

        let acceptsExisting = deduplicator.shouldAccept(
            elementIdentity: existing,
            screenID: primary.id,
            frame: frame,
            at: 50
        )
        let acceptsNewBanner = deduplicator.shouldAccept(
            elementIdentity: newBanner,
            screenID: primary.id,
            frame: frame,
            at: 50
        )

        #expect(!acceptsExisting)
        #expect(acceptsNewBanner)
    }
}
