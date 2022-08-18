import PocketCastsServer
import PocketCastsUtils

extension AppDelegate {
    func setupAnalytics() {
        Analytics.register(adapters: [TracksAdapter(), AnalyticsLoggingAdapter()])

        Analytics.track(.applicationOpened)

        // After 1 second, the UUID should not be reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Analytics.track(.applicationOpened)

            // After 3 seconds, the UUID should be reset now
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                Analytics.track(.applicationOpened)
            }
        }
        
    }
}
