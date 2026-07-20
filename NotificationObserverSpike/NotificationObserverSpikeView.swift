import SwiftUI

struct NotificationObserverSpikeView: View {
    @ObservedObject var monitor: NotificationBannerMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            statusCard
            metrics
            privacyNotice
            Spacer()
            controls
        }
        .padding(24)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notification Observer Spike")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Tests whether visible macOS notification banners can trigger a menu bar effect.")
                .foregroundStyle(.secondary)
        }
    }

    private var statusCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: statusSymbol)
                .foregroundStyle(statusColor)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(monitor.state.label)
                    .fontWeight(.semibold)
                Text(monitor.statusDetail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var metrics: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
            metricRow(
                "Registered AX events",
                value: monitor.diagnostics.registeredNotificationNames.joined(separator: ", ").nilIfEmpty ?? "None"
            )
            metricRow("AX callbacks", value: "\(monitor.diagnostics.callbackCount)")
            metricRow("Banner candidates", value: "\(monitor.diagnostics.candidateCount)")
            metricRow("Detected banners", value: "\(monitor.eventCount)")
            metricRow("Duplicates removed", value: "\(monitor.duplicateCount)")
            metricRow("Successful reconnects", value: "\(monitor.diagnostics.successfulReconnectCount)")
            metricRow("Average effect latency", value: formatLatency(monitor.diagnostics.latency.averageLatency))
            metricRow("Maximum effect latency", value: formatLatency(monitor.diagnostics.latency.maximumLatency))
            metricRow("Last event", value: monitor.lastEventDate?.formatted(date: .omitted, time: .standard) ?? "None")
            metricRow("Last frame", value: monitor.lastEvent.map { format($0.bannerFrame) } ?? "None")
            metricRow("Last display ID", value: monitor.lastEvent.map { String($0.screenID) } ?? "None")
            metricRow("Last AX event", value: monitor.diagnostics.lastStructuralEvent?.notificationName ?? "None")
            metricRow("Last element ID", value: monitor.diagnostics.lastStructuralEvent.map { String($0.elementIdentity.rawValue) } ?? "None")
            metricRow("Last role / subrole", value: lastRoleDescription)
            metricRow("Last parent depth", value: monitor.diagnostics.lastStructuralEvent.map { String($0.parentDepth) } ?? "None")
            metricRow("Last callback accepted", value: lastCallbackAcceptedDescription)
            metricRow("Last callback structure", value: lastCallbackStructureDescription)
            metricRow("Recent detected events", value: recentDetectedEventsDescription)
            metricRow("Recent structural signatures", value: recentStructuralSignaturesDescription)
        }
    }

    private var privacyNotice: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("Structural metadata only", systemImage: "hand.raised.fill")
                .fontWeight(.medium)
            Text("This spike reads only accessibility event type, element identity, role, subrole, parent depth, position, size, timing, and display ID. It does not read notification titles, bodies, app names, button labels, screenshots, or Notification Center databases. Nothing is stored or sent.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack {
            Button("Request Accessibility Access") {
                monitor.requestAccessibilityAccess()
            }
            Button("Reconnect") {
                monitor.reconnect()
            }
            Button("Reset Counters") {
                monitor.resetCounters()
            }
            Spacer()
            Button("Stop") {
                monitor.stop()
            }
            .disabled(monitor.state == .stopped)
        }
    }

    private func metricRow(_ label: String, value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .monospacedDigit()
                .textSelection(.enabled)
        }
    }

    private func format(_ frame: CGRect) -> String {
        "x \(Int(frame.origin.x)), y \(Int(frame.origin.y)), w \(Int(frame.width)), h \(Int(frame.height))"
    }

    private func formatLatency(_ latency: TimeInterval) -> String {
        "\(Int((latency * 1_000).rounded())) ms"
    }

    private var lastRoleDescription: String {
        guard let event = monitor.diagnostics.lastStructuralEvent else { return "None" }
        return "\(event.role) / \(event.subrole ?? "none")"
    }

    private var lastCallbackAcceptedDescription: String {
        guard let snapshot = monitor.diagnostics.lastCallbackSnapshot else { return "None" }
        return snapshot.candidateAccepted ? "Yes" : "No"
    }

    private var lastCallbackStructureDescription: String {
        guard let snapshot = monitor.diagnostics.lastCallbackSnapshot else { return "None" }
        guard !snapshot.elements.isEmpty else {
            return "\(snapshot.notificationName): no readable structural elements"
        }

        let ancestors = snapshot.elements.map { element in
            let frame = element.frame.map(format) ?? "no frame"
            let display = element.screenID.map(String.init) ?? "none"
            return "parent d\(element.parentDepth) id \(element.elementIdentity.rawValue) \(element.role)/\(element.subrole ?? "none") \(frame) display \(display)"
        }
        let descendants = snapshot.descendants.prefix(20).map { element in
            let frame = element.frame.map(format) ?? "no frame"
            let display = element.screenID.map(String.init) ?? "none"
            return "child d\(element.parentDepth) id \(element.elementIdentity.rawValue) \(element.role)/\(element.subrole ?? "none") \(frame) display \(display)"
        }
        return (ancestors + descendants).joined(separator: "\n")
    }

    private var recentStructuralSignaturesDescription: String {
        let grouped = Dictionary(grouping: monitor.diagnostics.recentCallbackSnapshots) {
            structuralSignature(for: $0)
        }
        guard !grouped.isEmpty else { return "None" }
        return grouped
            .map { signature, snapshots in "\(snapshots.count)× \(signature)" }
            .sorted()
            .joined(separator: "\n")
    }

    private var recentDetectedEventsDescription: String {
        guard !monitor.diagnostics.recentStructuralEvents.isEmpty else { return "None" }
        return monitor.diagnostics.recentStructuralEvents.map { event in
            let time = event.callbackDate.formatted(date: .omitted, time: .standard)
            return "\(time) id=\(event.elementIdentity.rawValue) \(event.role)/\(event.subrole ?? "none") \(format(event.frame)) display \(event.screenID)"
        }
        .joined(separator: "\n")
    }

    private func structuralSignature(for snapshot: NotificationBannerCallbackSnapshot) -> String {
        let root = snapshot.elements.first.map { element in
            "id=\(element.elementIdentity.rawValue) \(element.role)/\(element.subrole ?? "none") \(sizeDescription(element.frame))"
        } ?? "no root"
        let children = snapshot.descendants.prefix(20).map { element in
            "d\(element.parentDepth) id=\(element.elementIdentity.rawValue) \(element.role)/\(element.subrole ?? "none") \(sizeDescription(element.frame))"
        }
        return "\(snapshot.notificationName) accepted=\(snapshot.candidateAccepted) root=[\(root)] children=[\(children.joined(separator: "; "))]"
    }

    private func sizeDescription(_ frame: CGRect?) -> String {
        guard let frame else { return "no-frame" }
        return "\(Int(frame.width))x\(Int(frame.height))"
    }

    private var statusSymbol: String {
        switch monitor.state {
        case .stopped:
            return "pause.circle"
        case .permissionRequired:
            return "lock.trianglebadge.exclamationmark"
        case .connecting:
            return "arrow.trianglehead.2.clockwise.rotate.90"
        case .active:
            return "checkmark.circle.fill"
        case .unavailable:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch monitor.state {
        case .stopped:
            return .secondary
        case .permissionRequired, .unavailable:
            return .orange
        case .connecting:
            return .blue
        case .active:
            return .green
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
