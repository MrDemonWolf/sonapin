import SwiftUI

struct AppRootView: View {
    @Bindable var model: AppModel

    var body: some View {
        Group {
            switch model.bootState {
            case .loading:
                LoadingView()
            case .ready:
                if model.shouldShowOnboarding {
                    OnboardingView(model: model)
                } else {
                    BadgeView(model: model)
                }
            case let .failed(message):
                BootFailureView(message: message) {
                    Task { await model.retryStart() }
                }
            }
        }
        .tint(.sonaCyan)
        .alert(item: $model.notice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

private struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.sonaNavy.ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.sonaCyan)
                Text("Loading your badge…")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("app.loading")
    }
}

private struct BootFailureView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("SonaPin could not start", systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .accessibilityIdentifier("app.load-failed")
    }
}
