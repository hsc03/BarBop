import SwiftUI

@main
struct NotificationObserverSpikeApp: App {
    @StateObject private var monitor = NotificationBannerMonitor()

    var body: some Scene {
        WindowGroup("Notification Observer Spike") {
            NotificationObserverSpikeView(monitor: monitor)
                .frame(minWidth: 780, minHeight: 780)
                .onAppear {
                    monitor.start()
                }
                .onDisappear {
                    monitor.stop()
                }
        }
        .windowResizability(.contentMinSize)
    }
}
