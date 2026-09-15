import SwiftUI

extension Color {
    static let sonaNavy = Color(red: 9 / 255, green: 21 / 255, blue: 51 / 255)
    static let sonaCyan = Color(red: 0 / 255, green: 172 / 255, blue: 237 / 255)
    static let sonaCornflower = Color(red: 107 / 255, green: 139 / 255, blue: 245 / 255)
    static let sonaAmber = Color(red: 1, green: 183 / 255, blue: 77 / 255)
}

extension BadgeTheme {
    var title: String {
        switch self {
        case .midnight: "Midnight"
        case .cerulean: "Cerulean"
        case .cornflower: "Cornflower"
        }
    }

    var primaryColor: Color {
        switch self {
        case .midnight: .sonaNavy
        case .cerulean: .sonaCyan
        case .cornflower: .sonaCornflower
        }
    }

    var foregroundColor: Color {
        self == .cerulean ? .sonaNavy : .white
    }

    var accentColor: Color {
        switch self {
        case .midnight: .sonaCyan
        case .cerulean: .sonaNavy
        case .cornflower: .sonaAmber
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
    var body: some View {
        ZStack {
            Color.sonaNavy
            Circle()
                .fill(Color.sonaCyan.opacity(0.08))
                .frame(width: 360, height: 360)
                .offset(x: 190, y: -320)
                .accessibilityHidden(true)
            Circle()
                .fill(Color.sonaCornflower.opacity(0.07))
                .frame(width: 300, height: 300)
                .offset(x: -190, y: 340)
                .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }
}

struct SonaCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(Color.white.opacity(0.08))
            .clipShape(.rect(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    .accessibilityHidden(true)
            }
    }
}

extension View {
    func sonaCard() -> some View {
        modifier(SonaCardModifier())
    }
}

struct SonaPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(Color.sonaNavy)
            .background(Color.sonaCyan.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(.rect(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SonaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(.white)
            .background(Color.white.opacity(configuration.isPressed ? 0.16 : 0.09))
            .clipShape(.rect(cornerRadius: 14))
    }
}

struct InlineStatusView: View {
    let systemImage: String
    let text: String
    var tint: Color = .sonaCyan

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
