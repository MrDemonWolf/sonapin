import Foundation

struct BadgeProfile: Codable, Equatable, Sendable {
    var displayName = ""
    var pronouns = ""
    var species = ""
    var tagline = ""
}

enum QRPayloadKind: String, Codable, CaseIterable, Sendable {
    case website
    case socialProfile
    case contact
    case customText
}

enum QRCorrectionLevel: String, Codable, CaseIterable, Sendable {
    case low = "L"
    case medium = "M"
    case quartile = "Q"
    case high = "H"
}

struct QRConfiguration: Codable, Equatable, Sendable {
    var kind: QRPayloadKind = .website
    var payload = ""
    var correctionLevel: QRCorrectionLevel = .medium
    var highContrast = true
}

enum BadgeTheme: String, Codable, CaseIterable, Sendable {
    case midnight
    case cerulean
    case cornflower
}

struct InteractionPreferences: Codable, Equatable, Sendable {
    var hapticsEnabled = true
    var reduceMotion = false
    var highContrastQR = true
    var keepScreenAwake = false
    var interactionSensitivity = 1.0
    var defaultExpression: AvatarExpression = .neutral
}

extension InteractionPreferences {
    private enum CodingKeys: String, CodingKey {
        case hapticsEnabled
        case reduceMotion
        case highContrastQR
        case keepScreenAwake
        case interactionSensitivity
        case defaultExpression
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        reduceMotion = try container.decodeIfPresent(Bool.self, forKey: .reduceMotion) ?? false
        highContrastQR = try container.decodeIfPresent(Bool.self, forKey: .highContrastQR) ?? true
        keepScreenAwake = try container.decodeIfPresent(Bool.self, forKey: .keepScreenAwake) ?? false
        interactionSensitivity = try container.decodeIfPresent(Double.self, forKey: .interactionSensitivity) ?? 1
        defaultExpression = (try? container.decode(AvatarExpression.self, forKey: .defaultExpression)) ?? .neutral
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hapticsEnabled, forKey: .hapticsEnabled)
        try container.encode(reduceMotion, forKey: .reduceMotion)
        try container.encode(highContrastQR, forKey: .highContrastQR)
        try container.encode(keepScreenAwake, forKey: .keepScreenAwake)
        try container.encode(interactionSensitivity, forKey: .interactionSensitivity)
        try container.encode(defaultExpression, forKey: .defaultExpression)
    }
}

enum OnboardingStep: String, Codable, CaseIterable, Sendable {
    case welcome
    case avatar
    case compatibility
    case identity
    case qrConfiguration
    case qrPreview
    case theme
    case badgePreview
    case complete
}

struct OnboardingProgress: Codable, Equatable, Sendable {
    var step: OnboardingStep = .welcome
    var isComplete = false
}

struct AppSnapshot: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int = Self.currentSchemaVersion
    var profile = BadgeProfile()
    var qrConfiguration = QRConfiguration()
    var theme: BadgeTheme = .midnight
    var preferences = InteractionPreferences()
    var avatar: AvatarRecord = .demo
    var onboarding = OnboardingProgress()

    static let empty = AppSnapshot()
}
