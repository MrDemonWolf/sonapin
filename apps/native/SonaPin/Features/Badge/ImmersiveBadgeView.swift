import SwiftUI

@MainActor
struct ImmersiveBadgeView: View {
    let model: AppModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height

            ZStack(alignment: .topTrailing) {
                SonaPinBackground(theme: model.snapshot.theme)

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
                .allowsHitTesting(false)

                closeButton
            }
        }
        .statusBarHidden()
    }

    @ViewBuilder
    private var closeButton: some View {
        if #available(iOS 26.0, *) {
            dismissButton
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .padding()
        } else {
            dismissButton
                .background(.regularMaterial, in: Circle())
                .padding()
        }
    }

    private var dismissButton: some View {
        Button("Close Full Screen", systemImage: "xmark") {
            dismiss()
        }
        .labelStyle(.iconOnly)
        .font(.headline)
        .frame(width: 44, height: 44)
        .foregroundStyle(.primary)
        .accessibilityIdentifier("badge.full-screen.close")
    }
}

private struct ImmersiveBadgeOverlay: View {
    let profile: BadgeProfile
    let configuration: QRConfiguration
    let theme: BadgeTheme
    let size: CGSize
    let isLandscape: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ViewBuilder
    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            ScrollView {
                VStack(spacing: 12) {
                    identityCard
                    qrCard
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, max(size.height * 0.42, 180))
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        } else {
            ZStack(alignment: .bottom) {
                identityCard
                    .frame(maxWidth: isLandscape ? 380 : 300)
                    .frame(
                        maxWidth: .infinity,
                        alignment: isLandscape ? .leading : .center
                    )

                qrCard
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .offset(y: isLandscape ? -size.height * 0.04 : -size.height * 0.10)
            }
            .padding(20)
        }
    }

    private var qrCard: some View {
        PresentedQRCodeCard(
            configuration: configuration,
            theme: theme,
            maximumDimension: isLandscape
                ? min(size.height * 0.40, 220)
                : min(size.width * 0.34, 150)
        )
    }

    private var identityCard: some View {
        BadgeIdentityView(profile: profile, theme: theme)
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
