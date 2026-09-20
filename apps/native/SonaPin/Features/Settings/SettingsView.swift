import SwiftUI

@MainActor
struct SettingsView: View {
    @Bindable var model: AppModel

    @Environment(\.dismiss) private var dismiss
    @State private var confirmsResetOnboarding = false
    @State private var confirmsDeleteAll = false
    @State private var activeEditor: SettingsEditor?

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
                    dismiss()
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
                    dismiss()
                    Task { await model.deleteAllLocalData() }
                }
                .accessibilityIdentifier("settings.delete-all.confirm")
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes your profile, QR settings, imported avatar, preferences, and onboarding progress from this device. This cannot be undone.")
            }
            .sheet(item: $activeEditor) { editor in
                NavigationStack {
                    switch editor {
                    case .profile:
                        ProfileEditorView(model: model)
                    case .qrCode:
                        QRCodeEditorView(model: model)
                    }
                }
            }
        }
    }

    private var identitySection: some View {
        Section("Badge") {
            Button {
                activeEditor = .profile
            } label: {
                SettingsRow(
                    title: "Profile",
                    detail: model.snapshot.profile.displayName,
                    systemImage: "person.text.rectangle"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.profile")

            Button {
                activeEditor = .qrCode
            } label: {
                SettingsRow(
                    title: "QR code",
                    detail: model.snapshot.qrConfiguration.kind.title,
                    systemImage: "qrcode"
                )
            }
            .buttonStyle(.plain)
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
            .pickerStyle(.menu)
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
                    Text("\(sensitivityTitle) · \(model.snapshot.preferences.interactionSensitivity, format: .number.precision(.fractionLength(1)))×")
                        .foregroundStyle(.primary)
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
                .accessibilityValue("\(sensitivityTitle), \(model.snapshot.preferences.interactionSensitivity.formatted(.number.precision(.fractionLength(1)))) times")
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
                    Label(theme.title, systemImage: "circle.fill")
                        .foregroundStyle(theme.accentColor)
                        .tag(theme)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("settings.theme")

            Toggle("Maximize QR contrast", isOn: $model.snapshot.preferences.highContrastQR)
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
            NavigationLink(value: SettingsInformationPage.about) {
                SettingsRow(title: "About SonaPin", detail: "App details and version", systemImage: "info.circle")
            }
                .accessibilityIdentifier("settings.about")
            NavigationLink(value: SettingsInformationPage.privacy) {
                SettingsRow(title: "Privacy", detail: "How local data is handled", systemImage: "hand.raised")
            }
                .accessibilityIdentifier("settings.privacy")
            Link(destination: URL(string: "https://mrdemonwolf.github.io/sonapin/terms/")!) {
                SettingsRow(title: "Terms of Use", detail: "Rules for using SonaPin", systemImage: "doc.text")
            }
                .accessibilityIdentifier("settings.terms")
            Link(destination: URL(string: "https://mrdemonwolf.github.io/sonapin/support/")!) {
                SettingsRow(title: "Support", detail: "Help and contact information", systemImage: "questionmark.circle")
            }
                .accessibilityIdentifier("settings.support")
            NavigationLink(value: SettingsInformationPage.acknowledgments) {
                SettingsRow(title: "Acknowledgments", detail: "Open-source software", systemImage: "heart")
            }
                .accessibilityIdentifier("settings.acknowledgments")
        }
    }

    private var sensitivityTitle: String {
        switch model.snapshot.preferences.interactionSensitivity {
        case ..<0.9: "Gentle"
        case ...1.2: "Standard"
        default: "Lively"
        }
    }
}

private enum SettingsEditor: String, Identifiable {
    case profile
    case qrCode

    var id: Self { self }
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
                        .foregroundStyle(.primary)
                }
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
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
        List {
            if page == .about {
                Section {
                    VStack(spacing: 10) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 88, height: 88)
                            .background(Color.sonaNavy.gradient, in: .rect(cornerRadius: 20))
                            .accessibilityHidden(true)
                        Text("SonaPin")
                            .font(.title2.bold())
                        Text("Your sona. Your badge. Alive.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .accessibilityElement(children: .combine)
                }
            }

            content
        }
        .navigationTitle(page.title)
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color(uiColor: .link))
        .accessibilityIdentifier("settings.information.\(page.rawValue)")
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case .about:
            Section("About") {
                Text("An interactive, local digital convention badge with your VRM avatar, identity, and scannable QR code.")
                LabeledContent("Version", value: appVersion)
                LabeledContent("Developer", value: "MrDemonWolf, Inc.")
            }
            Section("Resources") {
                Link(destination: URL(string: "https://github.com/MrDemonWolf/sonapin")!) {
                    Label("SonaPin on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://mrdemonwolf.github.io/sonapin/support/")!) {
                    Label("Support", systemImage: "questionmark.circle")
                }
                Link(destination: URL(string: "https://mrdemonwolf.com")!) {
                    Label("MrDemonWolf website", systemImage: "safari")
                }
            }
        case .privacy:
            Section("Local by design") {
                Text("Your imported avatar, badge fields, QR settings, and preferences remain on this device. SonaPin version 1 has no account, login, backend, analytics, advertising, or tracking.")
                Text("SonaPin does not open or upload your QR content. Someone receives it only when they scan the QR code you display.")
            }
            Section("Your control") {
                Text("Delete All Local Data in Settings removes the saved profile and imported model from SonaPin.")
            }
            Section("Full policy") {
                Link(destination: URL(string: "https://mrdemonwolf.github.io/sonapin/privacy/")!) {
                    Label("Read Privacy Policy", systemImage: "safari")
                }
                Link(destination: URL(string: "https://mrdemonwolf.github.io/sonapin/terms/")!) {
                    Label("Read Terms of Use", systemImage: "doc.text")
                }
            }
        case .acknowledgments:
            Section("Third-party software") {
                Link(destination: URL(string: "https://github.com/tattn/VRMKit")!) {
                    LabeledContent("VRMKit", value: "0.10.0 · MIT")
                }
                Text("VRM parsing and RealityKit rendering by Tatsuya Tanaka.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section {
                Text("VRM and related names belong to their respective projects and rights holders. Imported model rights remain the user’s responsibility.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
