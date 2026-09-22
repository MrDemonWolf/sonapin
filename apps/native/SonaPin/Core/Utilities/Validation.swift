import Foundation

enum ValidationError: Error, Equatable, LocalizedError, Sendable {
    case required(field: String)
    case tooLong(field: String, maximum: Int)
    case invalidURL
    case unsupportedURLScheme
    case payloadTooLarge(maximumBytes: Int)
    case invalidSensitivity

    var errorDescription: String? {
        switch self {
        case let .required(field):
            "\(field) is required."
        case let .tooLong(field, maximum):
            "\(field) must be \(maximum) characters or fewer."
        case .invalidURL:
            "Enter a complete, valid URL."
        case .unsupportedURLScheme:
            "That URL type is not supported."
        case let .payloadTooLarge(maximumBytes):
            "QR content must be \(maximumBytes) bytes or fewer."
        case .invalidSensitivity:
            "Interaction sensitivity must be between 0.5 and 2.0."
        }
    }
}

enum ProfileValidator {
    private static let limits = [
        "Display name": 80,
        "Pronouns": 80,
        "Species": 80,
        "Tagline": 140,
    ]

    static func validate(_ profile: BadgeProfile) throws -> BadgeProfile {
        let value = BadgeProfile(
            displayName: profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            pronouns: profile.pronouns.trimmingCharacters(in: .whitespacesAndNewlines),
            species: profile.species.trimmingCharacters(in: .whitespacesAndNewlines),
            tagline: profile.tagline.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        guard !value.displayName.isEmpty else {
            throw ValidationError.required(field: "Display name")
        }

        for (field, text) in [
            ("Display name", value.displayName),
            ("Pronouns", value.pronouns),
            ("Species", value.species),
            ("Tagline", value.tagline),
        ] {
            let maximum = limits[field] ?? 0
            if text.count > maximum {
                throw ValidationError.tooLong(field: field, maximum: maximum)
            }
        }

        return value
    }
}

enum QRPayloadValidator {
    /// QR version 40 byte-mode capacities for each error-correction level.
    static func maximumBytes(for correctionLevel: QRCorrectionLevel) -> Int {
        switch correctionLevel {
        case .low: 2_953
        case .medium: 2_331
        case .quartile: 1_663
        case .high: 1_273
        }
    }

    static func validate(_ configuration: QRConfiguration) throws -> QRConfiguration {
        let payload = configuration.payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !payload.isEmpty else {
            throw ValidationError.required(field: "QR content")
        }
        let maximumBytes = maximumBytes(for: configuration.correctionLevel)
        guard payload.lengthOfBytes(using: .utf8) <= maximumBytes else {
            throw ValidationError.payloadTooLarge(maximumBytes: maximumBytes)
        }

        switch configuration.kind {
        case .customText:
            break
        case .website, .socialProfile:
            try validateURL(payload, allowedSchemes: ["http", "https"], requiresHost: true)
        case .contact:
            try validateURL(
                payload,
                allowedSchemes: ["http", "https", "mailto", "tel", "sms"],
                requiresHost: false
            )
        }

        var validated = configuration
        validated.payload = payload
        return validated
    }

    static func accessibilityDescription(for configuration: QRConfiguration) -> String {
        guard !configuration.payload.isEmpty else {
            return "No QR code configured"
        }
        let label: String = switch configuration.kind {
        case .website: "Website"
        case .socialProfile: "Social profile"
        case .contact: "Contact"
        case .customText: "Text"
        }
        return "\(label) QR code containing \(configuration.payload)"
    }

    private static func validateURL(
        _ value: String,
        allowedSchemes: Set<String>,
        requiresHost: Bool
    ) throws {
        guard let components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              !scheme.isEmpty else {
            throw ValidationError.invalidURL
        }
        guard allowedSchemes.contains(scheme) else {
            throw ValidationError.unsupportedURLScheme
        }
        if requiresHost, components.host?.isEmpty != false {
            throw ValidationError.invalidURL
        }
        if !requiresHost,
           !["http", "https"].contains(scheme),
           components.path.isEmpty {
            throw ValidationError.invalidURL
        }
    }
}

enum PreferencesValidator {
    static func validate(_ preferences: InteractionPreferences) throws {
        guard 0.5 ... 2.0 ~= preferences.interactionSensitivity else {
            throw ValidationError.invalidSensitivity
        }
    }
}
