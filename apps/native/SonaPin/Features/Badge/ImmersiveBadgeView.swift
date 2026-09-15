import SwiftUI

@MainActor
struct ImmersiveBadgeView: View {
    let model: AppModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height

            ZStack {
                model.snapshot.theme.primaryColor
                    .ignoresSafeArea()

                AvatarStageHost(
                    model: model,
                    showsControls: false,
                    minimumHeight: max(proxy.size.height, 320)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: isLandscape ? 0 : -min(proxy.size.height * 0.08, 70))

                ImmersiveBadgeOverlay(
                    profile: model.snapshot.profile,
                    configuration: model.snapshot.qrConfiguration,
                    theme: model.snapshot.theme,
                    size: proxy.size,
                    isLandscape: isLandscape
                )

                closeButton
            }
        }
        .statusBarHidden()
        .preferredColorScheme(.dark)
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button("Close Full Screen", systemImage: "xmark") {
                    dismiss()
                }
                .labelStyle(.iconOnly)
                .font(.headline)
                .frame(width: 44, height: 44)
                .foregroundStyle(model.snapshot.theme.foregroundColor)
                .background(model.snapshot.theme.surfaceColor, in: Circle())
                .overlay {
                    Circle()
                        .stroke(model.snapshot.theme.foregroundColor.opacity(0.18), lineWidth: 1)
                }
                .accessibilityIdentifier("badge.full-screen.close")
            }
            Spacer()
        }
        .padding()
    }
}

private struct ImmersiveBadgeOverlay: View {
    let profile: BadgeProfile
    let configuration: QRConfiguration
    let theme: BadgeTheme
    let size: CGSize
    let isLandscape: Bool

    var body: some View {
        VStack {
            Spacer()

            if isLandscape {
                HStack(alignment: .bottom, spacing: 20) {
                    identityCard
                        .frame(maxWidth: 380)
                    Spacer(minLength: 12)
                    PresentedQRCodeCard(
                        configuration: configuration,
                        theme: theme,
                        maximumDimension: min(size.height * 0.42, 220)
                    )
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .bottom, spacing: 12) {
                        identityCard
                            .frame(width: max(min(size.width * 0.46, 220), 170))
                        PresentedQRCodeCard(
                            configuration: configuration,
                            theme: theme,
                            maximumDimension: min(size.width * 0.30, 150)
                        )
                    }

                    VStack(spacing: 12) {
                        identityCard
                        PresentedQRCodeCard(
                            configuration: configuration,
                            theme: theme,
                            maximumDimension: min(size.width * 0.42, 190)
                        )
                    }
                }
            }
        }
        .padding(20)
    }

    private var identityCard: some View {
        BadgeIdentityView(profile: profile, theme: theme)
            .padding(16)
            .background(theme.surfaceColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(theme.foregroundColor.opacity(0.18), lineWidth: 1)
            }
    }
}

private struct PresentedQRCodeCard: View {
    let configuration: QRConfiguration
    let theme: BadgeTheme
    let maximumDimension: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            Text("SCAN ME")
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.black)

            QRCodeView(configuration: configuration, maximumDimension: maximumDimension)
        }
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            Image(systemName: "pawprint.fill")
                .font(.headline)
                .foregroundStyle(theme.primaryColor)
                .frame(width: 42, height: 42)
                .background(theme.accentColor, in: Circle())
                .offset(x: -10, y: 10)
                .accessibilityHidden(true)
        }
        .rotationEffect(.degrees(-2))
        .shadow(color: .black.opacity(0.24), radius: 12, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("QR code")
        .accessibilityValue(QRPayloadValidator.accessibilityDescription(for: configuration))
        .accessibilityHint("Ask another person to scan this code with their camera.")
        .accessibilityIdentifier("badge.full-screen.qr")
    }
}
