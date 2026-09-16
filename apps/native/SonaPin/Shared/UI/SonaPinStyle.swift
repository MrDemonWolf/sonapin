import SwiftUI
import UIKit

extension Color {
    static let sonaNavy = Color(red: 9 / 255, green: 21 / 255, blue: 51 / 255)
    static let sonaCyan = Color(red: 15 / 255, green: 172 / 255, blue: 237 / 255)
    static let sonaCornflower = Color(red: 107 / 255, green: 139 / 255, blue: 245 / 255)
    static let sonaAmber = Color(red: 1, green: 183 / 255, blue: 77 / 255)
}

extension BadgeTheme {
    var title: String {
        switch self {
        case .system: "System"
        case .midnight: "Midnight"
        case .cerulean: "Cerulean"
        case .cornflower: "Cornflower"
        }
    }

    var primaryColor: Color {
        switch self {
        case .system: Color(uiColor: .systemGroupedBackground)
        case .midnight: .sonaNavy
        case .cerulean: .sonaCyan
        case .cornflower: .sonaCornflower
        }
    }

    var foregroundColor: Color {
        switch self {
        case .system: .primary
        case .midnight: .white
        case .cerulean, .cornflower: .sonaNavy
        }
    }

    var accentColor: Color {
        switch self {
        case .system: .accentColor
        case .midnight: .sonaCyan
        case .cerulean: .sonaNavy
        case .cornflower: .sonaAmber
        }
    }

    var surfaceColor: Color {
        switch self {
        case .system:
            Color(uiColor: .secondarySystemGroupedBackground)
        case .midnight:
            Color(red: 19 / 255, green: 36 / 255, blue: 76 / 255)
        case .cerulean, .cornflower:
            .white
        }
    }
}

extension QRPayloadKind {
    var title: String {
        switch self {
        case .website: "Website"
        case .socialProfile: "Social profile"
        case .contact: "Contact link"
        case .customText: "Custom text"
        }
    }

    var systemImage: String {
        switch self {
        case .website: "globe"
        case .socialProfile: "person.crop.circle"
        case .contact: "person.text.rectangle"
        case .customText: "text.quote"
        }
    }

    var prompt: String {
        switch self {
        case .website: "https://example.com"
        case .socialProfile: "https://social.example/@you"
        case .contact: "mailto:you@example.com"
        case .customText: "A short message"
        }
    }
}

extension OnboardingStep {
    var number: Int {
        Self.allCases.firstIndex { $0.rawValue == rawValue }.map { $0 + 1 } ?? 1
    }
}

struct SonaPinBackground: View {
    var theme: BadgeTheme = .system

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [theme.primaryColor, theme.surfaceColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if theme != .system {
                Circle()
                    .fill(theme.accentColor.opacity(0.10))
                    .frame(width: 360, height: 360)
                    .offset(x: 190, y: -320)
                    .accessibilityHidden(true)
                Circle()
                    .fill(Color.sonaCornflower.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .offset(x: -190, y: 340)
                    .accessibilityHidden(true)
            }
        }
        .ignoresSafeArea()
    }
}

struct SonaCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        content
            .padding(20)
            .background(Color(uiColor: .secondarySystemBackground), in: shape)
            .overlay {
                shape
                    .stroke(Color(uiColor: .separator), lineWidth: 0.5)
                    .accessibilityHidden(true)
            }
            .containerShape(shape)
    }
}

extension View {
    func sonaCard() -> some View {
        modifier(SonaCardModifier())
    }
}

struct InlineStatusView: View {
    let systemImage: String
    let text: String
    var tint: Color = .accentColor

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.callout.weight(.semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(tint.opacity(0.12))
            .clipShape(.rect(cornerRadius: 12))
    }
}
