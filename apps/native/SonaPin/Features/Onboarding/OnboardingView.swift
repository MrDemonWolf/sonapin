import SwiftUI
import UIKit

@MainActor
struct OnboardingView: View {
    @Bindable var model: AppModel

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var navigationFeedback = 0
    @State private var isKeyboardVisible = false

    private var step: OnboardingStep {
        model.snapshot.onboarding.step.primaryStep
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !isKeyboardVisible {
                            HStack(spacing: 10) {
                                Text("Step \(step.number) of \(OnboardingStep.allCases.count)")
                                    .font(.subheadline.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(Color(uiColor: .label))
                                    .accessibilityIdentifier("onboarding.progress")
                                ProgressView(value: Double(step.number), total: Double(OnboardingStep.allCases.count))
                                    .tint(.sonaCyan)
                                    .accessibilityHidden(true)
                            }
                        }

                        stepContent
                    }
                    .frame(maxWidth: 720, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(step.onboardingTitle)
            .navigationBarTitleDisplayMode(isKeyboardVisible ? .inline : .large)
            .toolbar { onboardingToolbar }
            .safeAreaInset(edge: .bottom) {
                if !isKeyboardVisible {
                    VStack(spacing: 8) {
                        Button(action: goForward) {
                            Text(primaryActionTitle)
                                .frame(maxWidth: .infinity)
                        }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(.sonaNavy)
                            .frame(maxWidth: .infinity)
                            .accessibilityHint(canContinue ? "Moves to the next setup step." : "Checks this step and shows what needs attention.")
                            .accessibilityIdentifier(step == .badgePreview ? "onboarding.finish" : "onboarding.next")

                        if step == .welcome {
                            VStack(spacing: 2) {
                                Text("By continuing, you agree to the Terms and acknowledge the Privacy Policy.")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)

                                HStack(spacing: 14) {
                                    Link(destination: URL(string: "https://mrdemonwolf.github.io/sonapin/terms/")!) {
                                        Text("Terms")
                                            .frame(minWidth: 44, minHeight: 44)
                                            .contentShape(Rectangle())
                                    }
                                        .accessibilityIdentifier("onboarding.legal.terms")
                                    Link(destination: URL(string: "https://mrdemonwolf.github.io/sonapin/privacy/")!) {
                                        Text("Privacy")
                                            .frame(minWidth: 44, minHeight: 44)
                                            .contentShape(Rectangle())
                                    }
                                        .accessibilityIdentifier("onboarding.legal.privacy")
                                }
                            }
                            .font(.footnote.weight(.semibold))
                            .tint(.primary)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: 720)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(.bar)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                isKeyboardVisible = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardVisible = false
            }
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

    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            WelcomeStep(model: model)
        case .avatar, .compatibility:
            WelcomeStep(model: model)
        case .identity:
            ProfileFields(profile: $model.snapshot.profile)
                .sonaCard()
        case .qrConfiguration, .qrPreview:
            ReadyStep(model: model)
        case .theme, .badgePreview, .complete:
            ReadyStep(model: model)
        }
    }

    private var canContinue: Bool {
        switch step {
        case .identity:
            return (try? ProfileValidator.validate(model.snapshot.profile)) != nil
        default:
            return true
        }
    }

    private var primaryActionTitle: String {
        switch step {
        case .welcome:
            "Make It Mine"
        case .identity:
            "Preview My Badge"
        case .badgePreview:
            "Enter Badge Mode"
        default:
            "Continue"
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
        case .avatar, .compatibility: .welcome
        case .qrConfiguration, .qrPreview, .theme, .complete: .badgePreview
        default: self
        }
    }

    var onboardingTitle: String {
        switch self {
        case .welcome, .avatar, .compatibility: "Try your badge"
        case .identity: "Make it yours"
        case .qrConfiguration, .qrPreview, .theme, .badgePreview, .complete: "Your badge is ready"
        }
    }

}

private struct WelcomeStep: View {
    let model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tap the wolf")
                .font(.title3.weight(.bold))
            Text("It reacts here exactly as it will in Badge Mode.")
                .foregroundStyle(.primary)

            AvatarStageHost(
                model: model,
                showsControls: false,
                minimumHeight: 260,
                stageAccessibilityIdentifier: "onboarding.demo.avatar"
            )
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Demo avatar")
                .accessibilityHint("Double-tap to make the avatar react.")

            Text("Tap to interact • Private • Works offline")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
        }
        .sonaCard()
    }
}

private struct ReadyStep: View {
    let model: AppModel

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .top) {
                AvatarStageHost(
                    model: model,
                    showsControls: false,
                    minimumHeight: 300,
                    stageAccessibilityIdentifier: "onboarding.ready.avatar"
                )
                    .accessibilityLabel("Your interactive badge avatar")
                    .accessibilityHint("Double-tap to make the avatar react.")

                Label("Tap to try it", systemImage: "hand.tap.fill")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, 12)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            BadgeIdentityView(profile: model.snapshot.profile, theme: model.snapshot.theme)

            Text("Avatar, QR code, colors, and interactions can all be changed later.")
                .font(.footnote)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .sonaCard()
    }
}

struct ProfileFields: View {
    @Binding var profile: BadgeProfile
    @FocusState private var focusedField: ProfileField?
    @State private var selectedPronounOption: String
    @State private var showsMoreDetails: Bool

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
        _showsMoreDetails = State(
            initialValue: !profile.wrappedValue.species.isEmpty || !profile.wrappedValue.tagline.isEmpty
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Start with a name. Everything else can wait.")
                .font(.subheadline)
                .foregroundStyle(.primary)

            LabeledFormField(
                title: "Badge name",
                help: "Shown in the largest type on your badge.",
                count: profile.displayName.count,
                limit: 80
            ) {
                HStack(spacing: 10) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    TextField("JayU", text: $profile.displayName)
                        .textContentType(.name)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .displayName)
                        .onSubmit { focusedField = nil }
                        .accessibilityLabel("Display name")
                        .accessibilityHint("Required. Up to 80 characters.")
                        .accessibilityIdentifier("profile.display-name")
                }
            }

            LabeledFormField(
                title: "Pronouns",
                isRequired: false,
                help: "Choose a common option or add your own.",
                count: isEnteringCustomPronouns ? profile.pronouns.count : nil,
                limit: isEnteringCustomPronouns ? 80 : nil
            ) {
                HStack {
                    Image(systemName: "text.bubble.fill")
                        .foregroundStyle(.secondary)
                    Picker("Pronouns", selection: $selectedPronounOption) {
                        Text("Choose pronouns").tag("")
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
                    Spacer()
                }
                .frame(minHeight: 44)
            }

            if isEnteringCustomPronouns {
                TextField("Enter your pronouns", text: $profile.pronouns)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .pronouns)
                    .onSubmit { focusedField = nil }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHint("Optional. Enter pronouns exactly as you want them shown, up to 80 characters.")
                    .accessibilityIdentifier("profile.pronouns.custom")
            }

            DisclosureGroup("Add more badge details", isExpanded: $showsMoreDetails) {
                VStack(alignment: .leading, spacing: 16) {
                    LabeledFormField(
                        title: "Species or character",
                        isRequired: false,
                        help: "For example, blue wolf, dragon, or original character.",
                        count: profile.species.count,
                        limit: 80
                    ) {
                        TextField("Blue wolf", text: $profile.species)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .species)
                            .onSubmit { focusedField = .tagline }
                            .accessibilityLabel("Species or character")
                            .accessibilityHint("Optional. Up to 80 characters.")
                            .accessibilityIdentifier("profile.species")
                    }

                    LabeledFormField(
                        title: "Tagline",
                        isRequired: false,
                        help: "One short line people can read at a glance.",
                        count: profile.tagline.count,
                        limit: 140
                    ) {
                        TextField("Say hi if you spot me!", text: $profile.tagline, axis: .vertical)
                            .lineLimit(2 ... 3)
                            .submitLabel(.done)
                            .focused($focusedField, equals: .tagline)
                            .onSubmit { focusedField = nil }
                            .accessibilityLabel("Tagline")
                            .accessibilityHint("Optional. Up to 140 characters.")
                            .accessibilityIdentifier("profile.tagline")
                    }
                }
                .padding(.top, 12)
            }
            .fontWeight(.semibold)

            Label("Saved only on this iPhone", systemImage: "lock.fill")
                .font(.footnote)
                .foregroundStyle(.primary)
        }
        .textFieldStyle(.plain)
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
            if !selection.isEmpty { focusedField = nil }
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(isRequired ? "Required" : "Optional")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            content
                .frame(minHeight: 28)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(isOverLimit ? "Shorten this value before continuing." : help)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if shouldShowCount, let count, let limit {
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

    private var shouldShowCount: Bool {
        guard let count, let limit else { return false }
        return count >= limit - 20
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
                TextField("", text: $configuration.payload, axis: .vertical)
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
                    .overlay(alignment: .topLeading) {
                        if configuration.payload.isEmpty {
                            Text(configuration.kind.prompt)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
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
