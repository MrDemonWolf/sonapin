import SwiftUI

@MainActor
struct OnboardingView: View {
    @Bindable var model: AppModel

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var navigationFeedback = 0

    private var step: OnboardingStep {
        model.snapshot.onboarding.step.primaryStep
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
                            .foregroundStyle(.primary)

                        Text(step.onboardingDetail)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        ProgressView(
                            value: Double(step.number),
                            total: Double(OnboardingStep.allCases.count)
                        )
                        .accessibilityHidden(true)

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
            Button(step == .badgePreview ? "Enter Badge Mode" : "Continue", action: goForward)
                .buttonStyle(.borderedProminent)
                .tint(.sonaNavy)
                .foregroundStyle(.white)
                .disabled(!canContinue)
                .accessibilityHint(canContinue ? "Moves to the next setup step." : "Complete the required fields first.")
                .accessibilityIdentifier(step == .badgePreview ? "onboarding.finish" : "onboarding.next")
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            WelcomeStep()
        case .avatar, .compatibility:
            VStack(alignment: .leading, spacing: 16) {
                AvatarSourcePicker(model: model)
                CompatibilityReportView(record: model.snapshot.avatar)
            }
        case .identity:
            ProfileFields(profile: $model.snapshot.profile)
                .sonaCard()
        case .qrConfiguration, .qrPreview:
            VStack(alignment: .leading, spacing: 16) {
                QRConfigurationFields(
                    configuration: $model.snapshot.qrConfiguration,
                    highContrastPreference: $model.snapshot.preferences.highContrastQR
                )
                .sonaCard()
                QRPreviewStep(configuration: model.snapshot.qrConfiguration)
            }
        case .theme, .badgePreview, .complete:
            VStack(alignment: .leading, spacing: 16) {
                ThemePicker(selection: $model.snapshot.theme)
                BadgePreviewCard(snapshot: model.snapshot)
            }
        }
    }

    private var canContinue: Bool {
        switch step {
        case .identity:
            return (try? ProfileValidator.validate(model.snapshot.profile)) != nil
        case .qrConfiguration, .qrPreview:
            return (try? QRPayloadValidator.validate(model.snapshot.qrConfiguration)) != nil
        case .avatar, .compatibility:
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
        if step == .badgePreview {
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
    var primaryStep: Self {
        switch self {
        case .compatibility: .avatar
        case .qrPreview: .qrConfiguration
        case .theme, .complete: .badgePreview
        default: self
        }
    }

    var onboardingTitle: String {
        switch self {
        case .welcome: "Welcome to SonaPin"
        case .avatar, .compatibility: "Choose an avatar"
        case .identity: "Badge identity"
        case .qrConfiguration, .qrPreview: "QR code"
        case .theme, .badgePreview, .complete: "Review"
        }
    }

    var onboardingDetail: String {
        switch self {
        case .welcome:
            "SonaPin is a private, local-only convention badge with an interactive 3D avatar. No account, ads, analytics, or tracking."
        case .avatar, .compatibility:
            "Choose an avatar, then review what SonaPin can animate and any license details."
        case .identity:
            "Add the details you want another person to see. Nothing leaves this device."
        case .qrConfiguration, .qrPreview:
            "Choose the content and confirm the live preview. Test it with another physical phone before an event."
        case .theme, .badgePreview, .complete:
            "Pick a readable theme and check the finished badge. You can edit everything later."
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
                        Text(point.detail).foregroundStyle(.primary)
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
    @State private var selectedPronounOption: String

    private static let pronounOptions = [
        "he/him",
        "she/her",
        "they/them",
        "he/they",
        "she/they",
        "it/its",
        "any pronouns",
        "ask me",
    ]
    private static let customPronounsOption = "Other…"

    init(profile: Binding<BadgeProfile>) {
        _profile = profile
        let pronouns = profile.wrappedValue.pronouns
        _selectedPronounOption = State(
            initialValue: pronouns.isEmpty || Self.pronounOptions.contains(pronouns)
                ? pronouns
                : Self.customPronounsOption
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            LabeledFormField(
                title: "Display name",
                help: "The name people will notice first on your badge.",
                count: profile.displayName.count,
                limit: 80
            ) {
                TextField("MrDemonWolf", text: $profile.displayName)
                    .textContentType(.name)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .displayName)
                    .onSubmit {
                        focusedField = isEnteringCustomPronouns ? .pronouns : .species
                    }
                    .accessibilityLabel("Display name")
                    .accessibilityHint("Required. Up to 80 characters.")
                    .accessibilityIdentifier("profile.display-name")
            }

            LabeledFormField(
                title: "Pronouns",
                help: "Choose a common option or add your own.",
                count: isEnteringCustomPronouns ? profile.pronouns.count : nil,
                limit: isEnteringCustomPronouns ? 80 : nil
            ) {
                LabeledContent("Selection") {
                    Picker("Pronouns", selection: $selectedPronounOption) {
                        Text("Select pronouns").tag("")
                        Text(Self.customPronounsOption).tag(Self.customPronounsOption)
                        ForEach(Self.pronounOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedPronounOption) { _, selection in
                        updatePronouns(selection)
                    }
                    .accessibilityHint("Choose a common option or Other to enter your own pronouns.")
                    .accessibilityIdentifier("profile.pronouns.picker")
                }
                .frame(minHeight: 44)
            }

            if isEnteringCustomPronouns {
                TextField("Enter your pronouns", text: $profile.pronouns)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .pronouns)
                    .onSubmit { focusedField = .species }
                    .accessibilityHint("Required. Enter pronouns exactly as you want them shown, up to 80 characters.")
                    .accessibilityIdentifier("profile.pronouns.custom")
            }

            LabeledFormField(
                title: "Species or character",
                help: "For example, blue wolf, dragon, or original character.",
                count: profile.species.count,
                limit: 80
            ) {
                TextField("Blue wolf", text: $profile.species)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .species)
                    .onSubmit { focusedField = .tagline }
                    .accessibilityLabel("Species or character")
                    .accessibilityHint("Required. Up to 80 characters.")
                    .accessibilityIdentifier("profile.species")
            }

            LabeledFormField(
                title: "Tagline",
                isRequired: false,
                help: "One short line people can read at a glance.",
                count: profile.tagline.count,
                limit: 140
            ) {
                TextField("Friendly wolf roaming the con floor", text: $profile.tagline, axis: .vertical)
                    .lineLimit(2 ... 4)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .tagline)
                    .onSubmit { focusedField = nil }
                    .accessibilityLabel("Tagline")
                    .accessibilityHint("Optional. Up to 140 characters.")
                    .accessibilityIdentifier("profile.tagline")
            }
        }
        .textFieldStyle(.roundedBorder)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }

    private var isEnteringCustomPronouns: Bool {
        selectedPronounOption == Self.customPronounsOption
    }

    private func updatePronouns(_ selection: String) {
        selectedPronounOption = selection
        if selection == Self.customPronounsOption {
            if Self.pronounOptions.contains(profile.pronouns) {
                profile.pronouns = ""
            }
            Task { @MainActor in focusedField = .pronouns }
        } else {
            profile.pronouns = selection
            if !selection.isEmpty {
                Task { @MainActor in focusedField = .species }
            }
        }
    }
}

private enum ProfileField: Hashable {
    case displayName
    case pronouns
    case species
    case tagline
}

private struct LabeledFormField<Content: View>: View {
    let title: String
    let isRequired: Bool
    let help: String
    let count: Int?
    let limit: Int?
    let content: Content

    init(
        title: String,
        isRequired: Bool = true,
        help: String,
        count: Int? = nil,
        limit: Int? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isRequired = isRequired
        self.help = help
        self.count = count
        self.limit = limit
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("\(title) · \(isRequired ? "Required" : "Optional")")
                .font(.subheadline.weight(.semibold))

            content

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(isOverLimit ? "Shorten this value before continuing." : help)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let count, let limit {
                    Text("\(count)/\(limit)")
                        .monospacedDigit()
                }
            }
            .font(.caption)
            .foregroundStyle(isOverLimit ? Color.red : Color.primary)
        }
    }

    private var isOverLimit: Bool {
        guard let count, let limit else { return false }
        return count > limit
    }
}

struct QRConfigurationFields: View {
    @Binding var configuration: QRConfiguration
    @Binding var highContrastPreference: Bool
    @FocusState private var isPayloadFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            LabeledFormField(
                title: "QR content type",
                help: "Choose what someone receives after scanning."
            ) {
                LabeledContent("Type") {
                    Picker("QR content type", selection: $configuration.kind) {
                        ForEach(QRPayloadKind.allCases, id: \.rawValue) { kind in
                            Label(kind.title, systemImage: kind.systemImage)
                                .tag(kind)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("qr.kind")
                }
                .frame(minHeight: 44)
            }

            LabeledFormField(
                title: payloadTitle,
                help: payloadHelp
            ) {
                TextField(configuration.kind.prompt, text: $configuration.payload, axis: .vertical)
                    .textInputAutocapitalization(
                        configuration.kind == .customText ? .sentences : .never
                    )
                    .autocorrectionDisabled(configuration.kind != .customText)
                    .keyboardType(configuration.kind == .customText ? .default : .URL)
                    .textContentType(configuration.kind == .customText ? nil : .URL)
                    .lineLimit(2 ... 5)
                    .submitLabel(.done)
                    .focused($isPayloadFocused)
                    .onSubmit { isPayloadFocused = false }
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(payloadTitle)
                    .accessibilityHint("Required. Enter the complete content another person should receive.")
                    .accessibilityIdentifier("qr.payload")
            }

            if let validationStatus {
                Label(validationStatus.message, systemImage: validationStatus.systemImage)
                    .font(.caption)
                    .foregroundStyle(validationStatus.color)
                    .accessibilityIdentifier("qr.validation")
            }

            Toggle("Maximize QR contrast", isOn: $highContrastPreference)
                .accessibilityHint("Keeps the QR code dark on a plain white background.")
                .accessibilityIdentifier("qr.high-contrast")

            Text("Recommended for convention lighting and printed screenshots.")
                .font(.caption)
                .foregroundStyle(.primary)

            InlineStatusView(
                systemImage: "wifi.slash",
                text: "Validation happens on this device. SonaPin does not open or upload this content."
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isPayloadFocused = false }
            }
        }
    }

    private var payloadTitle: String {
        switch configuration.kind {
        case .website: "Website URL"
        case .socialProfile: "Social profile URL"
        case .contact: "Contact link"
        case .customText: "Message"
        }
    }

    private var payloadHelp: String {
        switch configuration.kind {
        case .website, .socialProfile:
            "Include https:// so phones know where to open it."
        case .contact:
            "Use a complete web, mailto:, tel:, or sms: link."
        case .customText:
            "Keep it short so the QR code stays easy to scan."
        }
    }

    private var validationStatus: (message: String, systemImage: String, color: Color)? {
        guard !configuration.payload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        do {
            _ = try QRPayloadValidator.validate(configuration)
            return ("Ready to scan", "checkmark.circle.fill", .green)
        } catch {
            return (error.localizedDescription, "exclamationmark.circle.fill", .red)
        }
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
                            .foregroundStyle(.primary)
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
                .tint(Color(uiColor: .label))
                .accessibilityLabel(theme.title)
                .accessibilityValue(selection == theme ? "Selected" : "Not selected")
                .accessibilityAddTraits(selection == theme ? .isSelected : [])
                .accessibilityIdentifier("theme.\(theme.rawValue)")
            }
        }
        .sonaCard()
    }
}
