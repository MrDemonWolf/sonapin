import SwiftUI
import UIKit

@MainActor
struct BadgeView: View {
    @Bindable var model: AppModel

    @Environment(\.scenePhase) private var scenePhase
    @State private var activeSheet: BadgeSheet?
    @State private var isEditLocked = true
    @State private var displaySession = BadgeDisplaySession()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                model.snapshot.theme.primaryColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    badgeToolbar

                    if proxy.size.width > proxy.size.height {
                        LandscapeBadgePresentation(model: model) {
                            activeSheet = .enlargedQR
                        }
                    } else {
                        PortraitBadgePresentation(model: model) {
                            activeSheet = .enlargedQR
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            displaySession.activate(keepAwake: model.snapshot.preferences.keepScreenAwake)
        }
        .onDisappear {
            displaySession.restore()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                displaySession.activate(keepAwake: model.snapshot.preferences.keepScreenAwake)
            case .inactive, .background:
                displaySession.restore()
            @unknown default:
                displaySession.restore()
            }
        }
        .onChange(of: model.snapshot.preferences.keepScreenAwake) { _, keepAwake in
            displaySession.update(keepAwake: keepAwake)
        }
        .sheet(item: $activeSheet, onDismiss: {
            isEditLocked = true
        }) { sheet in
            switch sheet {
            case .enlargedQR:
                EnlargedQRCodeView(configuration: model.snapshot.qrConfiguration)
            case .settings:
                SettingsView(model: model) {
                    activeSheet = nil
                }
            }
        }
        .sensoryFeedback(.selection, trigger: isEditLocked) { _, _ in
            model.snapshot.preferences.hapticsEnabled
        }
    }

    private var badgeToolbar: some View {
        HStack(spacing: 12) {
            Label("SonaPin Badge", systemImage: "pawprint.fill")
                .font(.headline)
                .foregroundStyle(model.snapshot.theme.foregroundColor)

            Spacer()

            Button {
                isEditLocked.toggle()
            } label: {
                Label(
                    isEditLocked ? "Unlock editing" : "Lock editing",
                    systemImage: isEditLocked ? "lock.fill" : "lock.open.fill"
                )
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
            }
            .foregroundStyle(model.snapshot.theme.foregroundColor)
            .accessibilityLabel(isEditLocked ? "Unlock badge editing" : "Lock badge editing")
            .accessibilityHint("Controls access to badge settings so they cannot open accidentally.")
            .accessibilityIdentifier("badge.edit-lock")

            Button {
                activeSheet = .settings
            } label: {
                Label("Settings", systemImage: "gearshape.fill")
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .foregroundStyle(model.snapshot.theme.foregroundColor)
            .disabled(isEditLocked)
            .accessibilityHint(
                isEditLocked
                    ? "Unlock badge editing first."
                    : "Opens your profile, QR, avatar, and display settings."
            )
            .accessibilityIdentifier("badge.settings")
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }
}

private enum BadgeSheet: String, Identifiable {
    case enlargedQR
    case settings

    var id: String { rawValue }
}

@MainActor
private struct PortraitBadgePresentation: View {
    let model: AppModel
    let showEnlargedQR: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                AvatarStageHost(model: model, showsControls: true, minimumHeight: 300)
                    .frame(maxHeight: 430)

                BadgeIdentityView(profile: model.snapshot.profile, theme: model.snapshot.theme)

                BadgeQRButton(model: model, action: showEnlargedQR)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}

@MainActor
private struct LandscapeBadgePresentation: View {
    let model: AppModel
    let showEnlargedQR: () -> Void

    var body: some View {
        HStack(spacing: 28) {
            VStack(spacing: 10) {
                AvatarStageHost(model: model, showsControls: true, minimumHeight: 150)
                BadgeIdentityView(profile: model.snapshot.profile, theme: model.snapshot.theme)
            }
            .frame(maxWidth: .infinity)

            BadgeQRButton(model: model, maximumDimension: 270, action: showEnlargedQR)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}

struct BadgeIdentityView: View {
    let profile: BadgeProfile
    let theme: BadgeTheme

    var body: some View {
        VStack(spacing: 5) {
            Text(profile.displayName.isEmpty ? "Your name" : profile.displayName)
                .font(.largeTitle.bold())
                .minimumScaleFactor(0.65)
                .lineLimit(2)

            Text(identityLine)
                .font(.title3.weight(.semibold))
                .foregroundStyle(theme.foregroundColor.opacity(0.82))

            if !profile.tagline.isEmpty {
                Text(profile.tagline)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.foregroundColor.opacity(0.82))
            }
        }
        .foregroundStyle(theme.foregroundColor)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityIdentifier("badge.identity")
    }

    private var identityLine: String {
        [profile.pronouns, profile.species]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private var accessibilitySummary: String {
        [profile.displayName, profile.pronouns, profile.species, profile.tagline]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

@MainActor
private struct BadgeQRButton: View {
    let model: AppModel
    var maximumDimension: CGFloat = 300
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            QRCodeView(
                configuration: model.snapshot.qrConfiguration,
                maximumDimension: maximumDimension
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Enlarge QR code")
        .accessibilityHint("Shows a larger code for easier scanning.")
        .accessibilityIdentifier("badge.qr")
    }
}

struct BadgePreviewCard: View {
    let snapshot: AppSnapshot

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 58))
                .foregroundStyle(snapshot.theme.accentColor)
                .accessibilityHidden(true)

            BadgeIdentityView(profile: snapshot.profile, theme: snapshot.theme)
            QRCodeView(configuration: snapshot.qrConfiguration, maximumDimension: 210)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(snapshot.theme.primaryColor)
        .clipShape(.rect(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(snapshot.theme.foregroundColor.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("badge.preview")
    }
}

private struct EnlargedQRCodeView: View {
    let configuration: QRConfiguration
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                QRCodeView(configuration: configuration, maximumDimension: 560, showsPayload: true)
                    .padding(24)
            }
            .background(Color.sonaNavy.ignoresSafeArea())
            .navigationTitle("Scan my badge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("badge.qr.close")
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
    }
}

@MainActor
private final class BadgeDisplaySession {
    private var previousIdleTimerDisabled: Bool?
    private var previousBrightness: CGFloat?

    func activate(keepAwake: Bool) {
        if previousIdleTimerDisabled == nil {
            previousIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
            previousBrightness = UIScreen.main.brightness
        }
        update(keepAwake: keepAwake)
    }

    func update(keepAwake: Bool) {
        guard previousIdleTimerDisabled != nil else { return }
        UIApplication.shared.isIdleTimerDisabled = keepAwake
        if keepAwake {
            UIScreen.main.brightness = max(UIScreen.main.brightness, 0.75)
        } else if let previousBrightness {
            UIScreen.main.brightness = previousBrightness
        }
    }

    func restore() {
        if let previousIdleTimerDisabled {
            UIApplication.shared.isIdleTimerDisabled = previousIdleTimerDisabled
        }
        if let previousBrightness {
            UIScreen.main.brightness = previousBrightness
        }
        previousIdleTimerDisabled = nil
        previousBrightness = nil
    }
}
