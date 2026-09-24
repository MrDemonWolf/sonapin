import SwiftUI
import Sentry

@main
@MainActor
struct SonaPinApp: App {
    @State private var model = AppModel()

    init() {
        SentrySDK.start { options in
            options.dsn = "https://f98f871d959cb512a2c15dcc0a70b563@o4508281688752128.ingest.us.sentry.io/4512140118196224"
            options.sendDefaultPii = false
            options.attachScreenshot = false
            options.attachViewHierarchy = false
            options.enableAutoSessionTracking = false
            options.enableAutoBreadcrumbTracking = false
            options.enableNetworkTracking = false
            options.enableNetworkBreadcrumbs = false
            options.enableCaptureFailedRequests = false
            options.enableMetrics = false
        }
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-SonaPinSentrySmokeTest") {
            SentrySDK.capture(message: "SonaPin Sentry smoke test")
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(model: model)
                .task {
                    await model.start()
                }
        }
    }
}
