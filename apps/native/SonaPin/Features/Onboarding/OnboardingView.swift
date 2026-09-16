import SwiftUI

@MainActor
struct OnboardingView: View {
    @Bindable var model: AppModel

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var navigationFeedback = 0

    private var step: OnboardingStep {
        model.snapshot.onboarding.step
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Step \(step.number) of \(OnboardingStep.allCases.count)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)

                        Text(step.onboardingDetail)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        ProgressView(
                            value: Double(step.number),
                            total: Double(OnboardingStep.allCases.count)
                        )
                        .accessibilityLabel("Onboarding progress")
                        .accessibilityValue("Step \(step.number) of \(OnboardingStep.allCases.count)")

                        stepContent
                    }
                    .frame(maxWidth: 720, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(step.onboardingTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar { onboardingToolbar }
        }
        .sensoryFeedback(.selection, trigger: navigationFeedback) { _, _ in
            model.snapshot.preferences.hapticsEnabled && !systemReduceMotion
        }
    }

    @ToolbarContentBuilder
    private var onboardingToolbar: some ToolbarContent {
        if step != .welcome {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back", systemImage: "chevron.left", action: goBack)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Back")
                    .accessibilityIdentifier("onboarding.back")
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button(step == .complete ? "Enter Badge Mode" : "Continue", action: goForward)
                .disabled(!canContinue)
                .accessibilityHint(canContinue ? "Moves to the next setup step." : "Complete the required fields first.")
                .accessibilityIdentifier(step == .complete ? "onboarding.finish" : "onboarding.next")
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            WelcomeStep()
        case .avatar:
            AvatarSourcePicker(model: model)
        case .compatibility:
            CompatibilityReportView(record: model.snapshot.avatar)
        case .identity:
            ProfileFields(profile: $model.snapshot.profile)
        case .qrConfiguration:
            QRConfigurationFields(
                configuration: $model.snapshot.qrConfiguration,
                highContrastPreference: $model.snapshot.preferences.highContrastQR
            )
        case .qrPreview:
            QRPreviewStep(configuration: model.snapshot.qrConfiguration)
        case .theme:
            ThemePicker(selection: $model.snapshot.theme)
        case .badgePreview:
            BadgePreviewCard(snapshot: model.snapshot)
        case .complete:
            CompletionStep()
        }
    }

    private var canContinue: Bool {
        switch step {
        case .identity:
            return !model.snapshot.profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !model.snapshot.profile.pronouns.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !model.snapshot.profile.species.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .qrConfiguration, .qrPreview:
            return (try? QRPayloadValidator.validate(model.snapshot.qrConfiguration)) != nil
        case .compatibility:
            return model.snapshot.avatar.compatibility?.outcome != .unsupported
        default:
            return true
        }
    }

    private func goBack() {
        guard let index = OnboardingStep.allCases.firstIndex(of: step), index > 0 else { return }
        navigationFeedback += 1
        let destination = OnboardingStep.allCases[index - 1]
        Task { await model.setOnboardingStep(destination) }
    }

    private func goForward() {
        do {
            if step == .identity {
                try model.validateCurrentProfile()
            } else if step == .qrConfiguration || step == .qrPreview {
                try model.validateCurrentQR()
            }
        } catch {
            model.notice = AppNotice(title: "Check this step", message: error.localizedDescription)
            return
        }

        navigationFeedback += 1
        if step == .complete {
            Task { await model.completeOnboarding() }
            return
        }

        guard let index = OnboardingStep.allCases.firstIndex(of: step),
              OnboardingStep.allCases.indices.contains(index + 1) else { return }
        let destination = OnboardingStep.allCases[index + 1]
        Task { await model.setOnboardingStep(destination) }
    }
}

private extension OnboardingStep {
    var onboardingTitle: String {
        switch self {
        case .welcome: "Your sona. Your badge. Alive."
        case .avatar: "Choose your avatar"
        case .compatibility: "Check compatibility"
        case .identity: "Build your badge identity"
        case .qrConfiguration: "Choose what people can scan"
        case .qrPreview: "Test your QR preview"
        case .theme: "Pick your colors"
        case .badgePreview: "Review your badge"
        case .complete: "Ready to meet the pack"
        }
    }

    var onboardingDetail: String {
        switch self {
        case .welcome:
            "SonaPin is a private, local-only convention badge with an interactive 3D avatar. No account, ads, analytics, or tracking."
        case .avatar:
            "Start with the built-in blue wolf or choose a VRM model you have permission to display."
        case .compatibility:
            "Review what SonaPin can animate and any license details before continuing."
        case .identity:
            "Add the details you want another person to see. Nothing leaves this device."
        case .qrConfiguration:
            "A QR code can point to your website, social profile, contact link, or plain text."
        case .qrPreview:
            "Keep the code unobstructed and test it with another physical phone before relying on it at an event."
        case .theme:
            "Choose a high-contrast theme for your badge."
        case .badgePreview:
            "Check the name, character details, and scannable code together. You can edit everything later."
        case .complete:
            "Your badge stays on this device and is ready for Badge Mode."
        }
    }
}

private struct WelcomeStep: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 76))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            ForEach(welcomePoints, id: \.title) { point in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: point.icon)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 34)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(point.title).font(.headline)
                        Text(point.detail).foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .sonaCard()
        .accessibilityIdentifier("onboarding.welcome")
    }

    private var welcomePoints: [(icon: String, title: String, detail: String)] {
        [
            ("person.crop.square", "A living badge", "Show your avatar and identity in one friendly, full-screen view."),
            ("qrcode", "Easy connections", "Let someone scan the link or message you choose."),
            ("lock.shield", "Yours alone", "SonaPin works without an account, network service, or tracker."),
        ]
    }
}

struct ProfileFields: View {
    @Binding var profile: BadgeProfile
    @FocusState private var focusedField: ProfileField?

    var body: some View {
        VStack(spacing: 16) {
            TextField("Display name", text: $profile.displayName)
                .textContentType(.name)
                .submitLabel(.next)
                .focused($focusedField, equals: .displayName)
                .onSubmit { focusedField = .pronouns }
                .accessibilityHint("Required. Up to 80 characters.")
                .accessibilityIdentifier("profile.display-name")

            TextField("Pronouns", text: $profile.pronouns)
                .textInputAutocapitalization(.never)
                .submitLabel(.next)
                .focused($focusedField, equals: .pronouns)
                .onSubmit { focusedField = .species }
                .accessibilityHint("Required. For example, they slash them.")
                .accessibilityIdentifier("profile.pronouns")

            TextField("Species or character type", text: $profile.species)
                .submitLabel(.next)
                .focused($focusedField, equals: .species)
                .onSubmit { focusedField = .tagline }
                .accessibilityHint("Required. For example, blue wolf.")
                .accessibilityIdentifier("profile.species")

            TextField("Short tagline (optional)", text: $profile.tagline, axis: .vertical)
                .lineLimit(2 ... 4)
                .submitLabel(.done)
                .focused($focusedField, equals: .tagline)
                .onSubmit { focusedField = nil }
                .accessibilityHint("Optional. Up to 140 characters.")
                .accessibilityIdentifier("profile.tagline")
        }
        .textFieldStyle(.roundedBorder)
        .sonaCard()
    }
}

private enum ProfileField: Hashable {
    case displayName
    case pronouns
    case species
    case tagline
}

struct QRConfigurationFields: View {
    @Binding var configuration: QRConfiguration
    @Binding var highContrastPreference: Bool
    @FocusState private var isPayloadFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("QR content type", selection: $configuration.kind) {
                ForEach(QRPayloadKind.allCases, id: \.rawValue) { kind in
                    Label(kind.title, systemImage: kind.systemImage)
                        .tag(kind)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("qr.kind")

            TextField(configuration.kind.prompt, text: $configuration.payload, axis: .vertical)
                .textInputAutocapitalization(
                    configuration.kind == .customText ? .sentences : .never
                )
                .autocorrectionDisabled(configuration.kind != .customText)
                .keyboardType(configuration.kind == .customText ? .default : .URL)
                .lineLimit(2 ... 5)
                .submitLabel(.done)
                .focused($isPayloadFocused)
                .onSubmit { isPayloadFocused = false }
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("QR content")
                .accessibilityHint("Required. Enter the complete content another person should receive.")
                .accessibilityIdentifier("qr.payload")

            Toggle("Extra-high QR contrast", isOn: $highContrastPreference)
                .accessibilityHint("Keeps the QR code dark on a plain white background.")
                .accessibilityIdentifier("qr.high-contrast")

            InlineStatusView(
                systemImage: "wifi.slash",
                text: "Validation happens on this device. SonaPin does not open or upload this content."
            )
        }
        .sonaCard()
    }
}

private struct QRPreviewStep: View {
    let configuration: QRConfiguration

    var body: some View {
        VStack(spacing: 18) {
            QRCodeView(configuration: configuration, maximumDimension: 360, showsPayload: true)
            InlineStatusView(
                systemImage: "iphone.gen3",
                text: "Before an event, scan this preview with a different physical phone. A Simulator screenshot cannot prove camera scanning works."
            )
        }
        .frame(maxWidth: .infinity)
        .sonaCard()
        .accessibilityIdentifier("qr.preview")
    }
}

struct ThemePicker: View {
    @Binding var selection: BadgeTheme

    var body: some View {
        VStack(spacing: 12) {
            ForEach(BadgeTheme.allCases, id: \.rawValue) { theme in
                Button {
                    selection = theme
                } label: {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.primaryColor)
                            .frame(width: 54, height: 44)
                            .overlay {
                                Circle()
                                    .fill(theme.accentColor)
                                    .frame(width: 16, height: 16)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.white.opacity(0.25), lineWidth: 1)
                            }
                            .accessibilityHidden(true)

                        Text(theme.title)
                            .font(.headline)
                        Spacer()
                        Image(systemName: selection == theme ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(selection == theme ? Color.accentColor : .secondary)
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(theme.title)
                .accessibilityValue(selection == theme ? "Selected" : "Not selected")
                .accessibilityIdentifier("theme.\(theme.rawValue)")
            }
        }
        .sonaCard()
    }
}

private struct CompletionStep: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 78))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text("Badge setup complete")
                .font(.title2.bold())
            Text("Tap Enter Badge Mode below. Unlock the edit control when you need settings; it starts locked to prevent accidental changes.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .sonaCard()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("onboarding.complete")
    }
}
