import SwiftUI

@MainActor
struct SettingsView: View {
    @Bindable var model: AppModel
    let leaveBadgeMode: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var confirmsResetOnboarding = false
    @State private var confirmsDeleteAll = false

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                avatarSection
                interactionSection
                appearanceSection
                dataSection
                informationSection
            }
            .navigationDestination(for: SettingsInformationPage.self) { page in
                SettingsInformationView(page: page)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("settings.done")
                }
            }
            .confirmationDialog(
                "Start onboarding again?",
                isPresented: $confirmsResetOnboarding,
                titleVisibility: .visible
            ) {
                Button("Reset Onboarding", role: .destructive) {
                    leaveBadgeMode()
                    Task { await model.resetOnboarding() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your profile, QR code, and avatar stay saved. SonaPin will reopen setup at step one.")
            }
            .confirmationDialog(
                "Delete all local SonaPin data?",
                isPresented: $confirmsDeleteAll,
                titleVisibility: .visible
            ) {
                Button("Delete All Data", role: .destructive) {
                    leaveBadgeMode()
                    Task { await model.deleteAllLocalData() }
                }
                .accessibilityIdentifier("settings.delete-all.confirm")
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes your profile, QR settings, imported avatar, preferences, and onboarding progress from this device. This cannot be undone.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var identitySection: some View {
        Section("Badge") {
            NavigationLink {
                ProfileEditorView(model: model)
            } label: {
                SettingsRow(
                    title: "Profile",
                    detail: model.snapshot.profile.displayName,
                    systemImage: "person.text.rectangle"
                )
            }
            .accessibilityIdentifier("settings.profile")

            NavigationLink {
                QRCodeEditorView(model: model)
            } label: {
                SettingsRow(
                    title: "QR code",
                    detail: model.snapshot.qrConfiguration.kind.title,
                    systemImage: "qrcode"
                )
            }
            .accessibilityIdentifier("settings.qr")
        }
    }

    private var avatarSection: some View {
        Section("Avatar") {
            NavigationLink {
                AvatarManagerView(model: model)
            } label: {
                SettingsRow(
                    title: "Avatar and compatibility",
                    detail: model.snapshot.avatar.kind == .demo ? "Built-in blue wolf" : "Imported VRM",
                    systemImage: "pawprint"
                )
            }
            .accessibilityIdentifier("settings.avatar")

            Picker("Default expression", selection: $model.snapshot.preferences.defaultExpression) {
                ForEach(AvatarExpression.allCases, id: \.rawValue) { expression in
                    Text(expression.settingsTitle).tag(expression)
                }
            }
            .accessibilityHint("Applies this expression when the avatar supports it. Unsupported expressions use a safe fallback.")
            .accessibilityIdentifier("settings.default-expression")

            Button("Reset pose and camera", systemImage: "viewfinder") {
                model.requestExpression(.neutral)
                model.requestCameraReset()
            }
            .accessibilityHint("Restores the neutral pose, expression, rotation, and zoom in Badge Mode.")
            .accessibilityIdentifier("settings.reset-camera")
        }
    }

    private var interactionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Interaction sensitivity")
                    Spacer()
                    Text(model.snapshot.preferences.interactionSensitivity, format: .number.precision(.fractionLength(1)))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: $model.snapshot.preferences.interactionSensitivity,
                    in: 0.5 ... 2,
                    step: 0.1
                ) {
                    Text("Interaction sensitivity")
                } minimumValueLabel: {
                    Image(systemName: "tortoise")
                        .accessibilityLabel("Less sensitive")
                } maximumValueLabel: {
                    Image(systemName: "hare")
                        .accessibilityLabel("More sensitive")
                }
                .accessibilityIdentifier("settings.sensitivity")
            }

            Toggle("Haptic feedback", isOn: $model.snapshot.preferences.hapticsEnabled)
                .accessibilityHint("Controls vibration feedback for avatar and navigation actions.")
                .accessibilityIdentifier("settings.haptics")

            Toggle("Reduce avatar motion", isOn: $model.snapshot.preferences.reduceMotion)
                .accessibilityHint("Stops continuous avatar movement and uses static feedback.")
                .accessibilityIdentifier("settings.reduce-motion")
        } header: {
            Text("Interaction")
        } footer: {
            Text("The system Reduce Motion setting is always respected, even when this switch is off.")
        }
    }

    private var appearanceSection: some View {
        Section("Display") {
            Picker("Badge theme", selection: $model.snapshot.theme) {
                ForEach(BadgeTheme.allCases, id: \.rawValue) { theme in
                    Text(theme.title).tag(theme)
                }
            }
            .accessibilityIdentifier("settings.theme")

            Toggle("Extra-high QR contrast", isOn: $model.snapshot.preferences.highContrastQR)
                .accessibilityHint("Keeps the QR code dark on a plain white background.")
                .accessibilityIdentifier("settings.qr-contrast")
                .onChange(of: model.snapshot.preferences.highContrastQR) { _, value in
                    model.snapshot.qrConfiguration.highContrast = value
                }

            Toggle("Keep screen awake in Badge Mode", isOn: $model.snapshot.preferences.keepScreenAwake)
                .accessibilityHint("Prevents automatic screen locking and raises brightness while the badge is visible.")
                .accessibilityIdentifier("settings.keep-awake")
        }
    }

    private var dataSection: some View {
        Section("Local data") {
            Button("Run Onboarding Again", systemImage: "arrow.triangle.2.circlepath") {
                confirmsResetOnboarding = true
            }
            .accessibilityIdentifier("settings.reset-onboarding")

            Button("Delete All Local Data", systemImage: "trash", role: .destructive) {
                confirmsDeleteAll = true
            }
            .accessibilityIdentifier("settings.delete-all")
        }
    }

    private var informationSection: some View {
        Section("Information") {
            NavigationLink("About SonaPin", value: SettingsInformationPage.about)
                .accessibilityIdentifier("settings.about")
            NavigationLink("Privacy", value: SettingsInformationPage.privacy)
                .accessibilityIdentifier("settings.privacy")
            NavigationLink("Acknowledgments", value: SettingsInformationPage.acknowledgments)
                .accessibilityIdentifier("settings.acknowledgments")
        }
    }
}

private extension AvatarExpression {
    var settingsTitle: String {
        switch self {
        case .neutral: "Neutral"
        case .happy: "Happy"
        case .surprised: "Surprised"
        case .relaxed: "Relaxed"
        case .blink: "Blink"
        }
    }
}

private struct SettingsRow: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Color.sonaCyan)
        }
    }
}

private enum SettingsInformationPage: String, Hashable {
    case about
    case privacy
    case acknowledgments

    var title: String {
        switch self {
        case .about: "About SonaPin"
        case .privacy: "Privacy"
        case .acknowledgments: "Acknowledgments"
        }
    }
}

private struct SettingsInformationView: View {
    let page: SettingsInformationPage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Label(page.title, systemImage: icon)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.sonaCyan)
                    .accessibilityAddTraits(.isHeader)

                content
            }
            .frame(maxWidth: 680, alignment: .leading)
            .padding(24)
        }
        .navigationTitle(page.title)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.information.\(page.rawValue)")
    }

    private var icon: String {
        switch page {
        case .about: "pawprint.fill"
        case .privacy: "hand.raised.fill"
        case .acknowledgments: "heart.fill"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case .about:
            Text("Your sona. Your badge. Alive.")
                .font(.title2.bold())
            Text("SonaPin is a public native iOS app for an interactive, local digital convention badge. It combines a VRM avatar, badge identity, and scannable QR code without becoming a social network.")
            LabeledContent("Version", value: appVersion)
            Text("Made by MrDemonWolf, Inc. with a little blue-wolf energy.")
                .foregroundStyle(.secondary)
        case .privacy:
            Text("Local by design")
                .font(.title2.bold())
            Text("Your imported avatar, badge fields, QR settings, and preferences remain on this device. SonaPin version 1 has no account, login, backend, analytics, advertising, or tracking.")
            Text("SonaPin does not open your QR link or upload its content. Other people can receive the content only when they scan the QR code you display. A future system share feature would require your explicit action.")
            Text("Deleting all local data in Settings removes the saved profile and imported model from SonaPin.")
        case .acknowledgments:
            Text("Open-source software")
                .font(.title2.bold())
            Text("SonaPin uses VRMKit and Apple system frameworks to import and present compatible VRM avatars.")
            Link("VRMKit source and license", destination: URL(string: "https://github.com/tattn/VRMKit")!)
            Text("VRM and related names are associated with their respective projects and rights holders. Imported model rights remain the user’s responsibility.")
                .foregroundStyle(.secondary)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
