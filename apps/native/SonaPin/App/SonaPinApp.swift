import SwiftUI

@main
@MainActor
struct SonaPinApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            AppRootView(model: model)
                .task {
                    await model.start()
                }
        }
    }
}
