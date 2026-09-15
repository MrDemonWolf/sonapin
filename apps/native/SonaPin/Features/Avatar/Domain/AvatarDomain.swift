import Foundation
import RealityKit
import simd

enum AvatarCompatibilityOutcome: String, Codable, Sendable {
    case supported
    case supportedWithWarnings
    case unsupported
}

enum VRMVersion: String, Codable, Sendable {
    case zeroX = "0.x"
    case one = "1.0"
    case unknown
}

struct AvatarLicenseMetadata: Codable, Equatable, Sendable {
    var licenseName: String?
    var licenseURL: String?
    var commercialUse: String?
    var redistribution: String?
    var credit: String?
    var otherPermissions: [String] = []
}

struct AvatarBonePresence: Codable, Equatable, Sendable {
    var discoveredBones: [String]
    var missingRequiredBones: [String]
    var hasHead: Bool
    var hasNeck: Bool
    var hasEyes: Bool
    var hasHands: Bool
    var tailRelatedNodes: [String]

    var hasRequiredHumanoidBones: Bool { missingRequiredBones.isEmpty }
}

struct AvatarCompatibilityReport: Codable, Equatable, Sendable {
    var fileName: String
    var fileSize: Int64
    var checksum: String
    var vrmVersion: VRMVersion
    var modelName: String?
    var authors: [String]
    var contactInformation: String?
    var references: [String]
    var license: AvatarLicenseMetadata
    var availableExpressions: [String]
    var bones: AvatarBonePresence
    var hasSpringBones: Bool
    var lookAtMode: String?
    var animationClips: [String]
    var supportsVRMA: Bool
    var requiredExtensions: [String]
    var unsupportedRequiredExtensions: [String]
    var parserWarnings: [String]
    var rendererWarnings: [String]
    var outcome: AvatarCompatibilityOutcome
}

enum AvatarKind: String, Codable, Sendable {
    case demo
    case imported
}

struct AvatarRecord: Codable, Equatable, Sendable {
    var kind: AvatarKind
    var storedFileName: String?
    var checksum: String?
    var compatibility: AvatarCompatibilityReport?

    static let demo = AvatarRecord(kind: .demo)
}

enum AvatarSource: Equatable, Sendable {
    case proceduralDemo
    case imported(fileURL: URL)
}

struct AvatarCapabilities: OptionSet, Codable, Hashable, Sendable {
    let rawValue: UInt16

    static let expressions = Self(rawValue: 1 << 0)
    static let animation = Self(rawValue: 1 << 1)
    static let lookAt = Self(rawValue: 1 << 2)
    static let springBones = Self(rawValue: 1 << 3)
    static let headHitTarget = Self(rawValue: 1 << 4)

    static let proceduralDemo: Self = [
        .expressions,
        .animation,
        .lookAt,
        .headHitTarget,
    ]
}

enum AvatarExpression: String, Codable, CaseIterable, Sendable {
    case neutral
    case happy
    case surprised
    case relaxed
    case blink
}

enum AvatarExpressionFallback {
    static func select(
        preferred: AvatarExpression,
        available: some Sequence<String>
    ) -> String? {
        var normalized: [String: String] = [:]
        for expression in available where normalized[normalize(expression)] == nil {
            normalized[normalize(expression)] = expression
        }
        let candidates: [AvatarExpression] = switch preferred {
        case .happy: [.happy, .relaxed, .neutral]
        case .surprised: [.surprised, .happy, .neutral]
        case .relaxed: [.relaxed, .happy, .neutral]
        case .blink: [.blink, .neutral]
        case .neutral: [.neutral, .relaxed]
        }
        return candidates.lazy.compactMap { normalized[normalize($0.rawValue)] }.first
    }

    private static func normalize(_ value: String) -> String {
        value.lowercased().filter(\.isLetter)
    }
}

struct AvatarAnimation: Codable, Equatable, Sendable {
    var name: String
}

@MainActor
protocol AvatarRendering: AnyObject {
    var capabilities: AvatarCapabilities { get }
    /// A stable scene root that a `RealityView` can add once and keep attached.
    var rootEntity: Entity { get }

    func load(_ source: AvatarSource) async throws
    func unload()
    func setExpression(_ expression: AvatarExpression, weight: Float)
    func play(_ animation: AvatarAnimation, looping: Bool) throws
    func look(at target: SIMD3<Float>?)
    func resetPose()
    func resetCamera()
}

struct AvatarImportResult: Equatable, Sendable {
    var record: AvatarRecord
    var fileURL: URL
}
