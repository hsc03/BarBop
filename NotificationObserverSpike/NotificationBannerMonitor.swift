import Foundation

typealias NotificationBannerMonitor = NotificationBannerDetector

extension NotificationBannerDetector {
    convenience init() {
        let effectController = SpikeMenuBarEffectController()
        self.init(
            onEvent: { event in
                effectController.play(
                    on: event.screenID,
                    uptime: { ProcessInfo.processInfo.systemUptime }
                )
            },
            onReset: {
                effectController.hide()
            }
        )
    }
}
