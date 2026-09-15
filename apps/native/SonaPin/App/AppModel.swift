import Foundation
import Observation

enum AppBootState: Equatable {
    case loading
    case ready
    case failed(String)
}

struct AppNotice: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var message: String
}

@MainActor
@Observable
final class AppModel {
    var snapshot = AppSnapshot.empty {
        didSet {
            guard persistenceEnabled, bootState == .ready else { return }
            scheduleSave()
        }
    }

    private(set) var bootState: AppBootState = .loading
    private(set) var isImportingAvatar = false
    var notice: AppNotice?
    var cameraResetToken = 0
    var expressionRequestToken = 0
    var requestedExpression: AvatarExpression = .neutral
    var feedbackToken = 0

    @ObservationIgnored private let persistenceStore: AppPersistenceStore
    @ObservationIgnored private let avatarImportService: AvatarImportService
    @ObservationIgnored private let launchArguments: Set<String>
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var persistenceEnabled = false
    @ObservationIgnored private var hasStarted = false

    init(
        applicationSupportDirectory: URL = AppModel.defaultApplicationSupportDirectory(),
        launchArguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        persistenceStore = AppPersistenceStore(directoryURL: applicationSupportDirectory)
        avatarImportService = AvatarImportService(applicationSupportDirectory: applicationSupportDirectory)
        self.launchArguments = Set(launchArguments)
    }

    var shouldShowOnboarding: Bool {
        !snapshot.onboarding.isComplete
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        bootState = .loading
        persistenceEnabled = false

        do {
            if launchArguments.contains("--reset-app-state") {
                try await persistenceStore.deleteAll()
            }

            let loadResult = try await persistenceStore.loadRecovering()
            var loadedSnapshot = loadResult.snapshot

            if launchArguments.contains("--use-demo-avatar") {
                loadedSnapshot.avatar = .demo
            }
            if launchArguments.contains("--ui-testing") {
                loadedSnapshot.preferences.reduceMotion = true
                loadedSnapshot.preferences.hapticsEnabled = false
                loadedSnapshot.preferences.keepScreenAwake = false
            }

            snapshot = loadedSnapshot
            bootState = .ready
            persistenceEnabled = true

            if loadResult.recoveredCorruption {
                notice = AppNotice(
                    title: "Saved data recovered",
                    message: "SonaPin found unreadable saved data and restored a clean local profile."
                )
            }
        } catch {
            bootState = .failed(error.localizedDescription)
        }
    }

    func retryStart() async {
        hasStarted = false
        await start()
    }

    func setOnboardingStep(_ step: OnboardingStep) async {
        snapshot.onboarding.step = step
        await persistNow()
    }

    func completeOnboarding() async {
        snapshot.onboarding = OnboardingProgress(step: .complete, isComplete: true)
        await persistNow()
    }

    func validateCurrentProfile() throws {
        snapshot.profile = try ProfileValidator.validate(snapshot.profile)
    }

    func validateCurrentQR() throws {
        snapshot.qrConfiguration = try QRPayloadValidator.validate(snapshot.qrConfiguration)
    }

    func importAvatar(from url: URL) async {
        isImportingAvatar = true
        defer { isImportingAvatar = false }

        do {
            let result = try await avatarImportService.importAvatar(from: url)
            snapshot.avatar = result.record
            await persistNow()
            feedbackToken += 1
        } catch is CancellationError {
            return
        } catch {
            notice = AppNotice(title: "Avatar not imported", message: error.localizedDescription)
        }
    }

    func useDemoAvatar() async {
        snapshot.avatar = .demo
        await persistNow()
        feedbackToken += 1
    }

    func removeImportedAvatar() async {
        do {
            var updatedSnapshot = snapshot
            updatedSnapshot.avatar = .demo
            saveTask?.cancel()
            try await persistenceStore.save(updatedSnapshot)
            snapshot = updatedSnapshot
            try await avatarImportService.removeCurrentAvatar()
            feedbackToken += 1
        } catch {
            notice = AppNotice(title: "Avatar not removed", message: error.localizedDescription)
        }
    }

    func currentImportedAvatarURL() async -> URL? {
        await avatarImportService.currentFileURL()
    }

    func requestCameraReset() {
        cameraResetToken += 1
        feedbackToken += 1
    }

    func requestExpression(_ expression: AvatarExpression) {
        requestedExpression = expression
        expressionRequestToken += 1
        feedbackToken += 1
    }

    func resetOnboarding() async {
        snapshot.onboarding = OnboardingProgress()
        await persistNow()
    }

    func deleteAllLocalData() async {
        saveTask?.cancel()
        persistenceEnabled = false

        do {
            try await persistenceStore.deleteAll()
            snapshot = .empty
            persistenceEnabled = true
            feedbackToken += 1
        } catch {
            persistenceEnabled = true
            notice = AppNotice(title: "Data not deleted", message: error.localizedDescription)
        }
    }

    func persistNow() async {
        saveTask?.cancel()
        do {
            try await persistenceStore.save(snapshot)
        } catch {
            notice = AppNotice(title: "Changes not saved", message: error.localizedDescription)
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let value = snapshot
        let store = persistenceStore

        saveTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(250))
                try Task.checkCancellation()
                try await store.save(value)
            } catch is CancellationError {
                return
            } catch {
                self?.notice = AppNotice(title: "Changes not saved", message: error.localizedDescription)
            }
        }
    }

    nonisolated private static func defaultApplicationSupportDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "SonaPin", directoryHint: .isDirectory)
    }
}
