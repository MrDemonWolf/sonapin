import CoreGraphics
import Foundation
import RealityKit
import Testing
import VRMRealityKit
@testable import SonaPin

@Suite("Profile and QR validation")
struct ValidationTests {
    @Test("New profiles follow the system appearance")
    func defaultThemeFollowsSystem() {
        #expect(AppSnapshot.empty.theme == .system)
    }

    @Test("Profile values are trimmed")
    func profileIsNormalized() throws {
        let result = try ProfileValidator.validate(
            BadgeProfile(
                displayName: "  Nova  ",
                pronouns: " they/them\n",
                species: " Wolf ",
                tagline: " Friendly sona "
            )
        )

        #expect(result.displayName == "Nova")
        #expect(result.pronouns == "they/them")
        #expect(result.species == "Wolf")
        #expect(result.tagline == "Friendly sona")
    }

    @Test("Required profile fields fail", arguments: [
        BadgeProfile(displayName: "", pronouns: "they/them", species: "Wolf"),
        BadgeProfile(displayName: "Nova", pronouns: "", species: "Wolf"),
        BadgeProfile(displayName: "Nova", pronouns: "they/them", species: ""),
    ])
    func requiredProfileFields(_ profile: BadgeProfile) {
        #expect(throws: ValidationError.self) {
            try ProfileValidator.validate(profile)
        }
    }

    @Test("Supported QR payloads pass", arguments: [
        QRConfiguration(kind: .website, payload: "https://example.com"),
        QRConfiguration(kind: .socialProfile, payload: "https://social.example/@nova"),
        QRConfiguration(kind: .contact, payload: "mailto:nova@example.com"),
        QRConfiguration(kind: .contact, payload: "tel:+15555550100"),
        QRConfiguration(kind: .customText, payload: "Boop!"),
    ])
    func supportedQRPayloads(_ configuration: QRConfiguration) throws {
        #expect(try QRPayloadValidator.validate(configuration).payload == configuration.payload)
    }

    @Test("Malformed and unsupported URLs fail", arguments: [
        QRConfiguration(kind: .website, payload: "example.com"),
        QRConfiguration(kind: .website, payload: "ftp://example.com"),
        QRConfiguration(kind: .socialProfile, payload: "https:///missing-host"),
        QRConfiguration(kind: .contact, payload: "mailto:"),
    ])
    func invalidQRPayloads(_ configuration: QRConfiguration) {
        #expect(throws: ValidationError.self) {
            try QRPayloadValidator.validate(configuration)
        }
    }

    @Test("Interaction sensitivity is bounded")
    func sensitivityValidation() {
        #expect(throws: Never.self) {
            try PreferencesValidator.validate(InteractionPreferences(interactionSensitivity: 0.5))
            try PreferencesValidator.validate(InteractionPreferences(interactionSensitivity: 2.0))
        }
        #expect(throws: ValidationError.invalidSensitivity) {
            try PreferencesValidator.validate(InteractionPreferences(interactionSensitivity: 2.1))
        }
    }

    @Test("QR byte capacity follows the selected correction level")
    func correctionLevelCapacity() throws {
        let atHighLimit = QRConfiguration(
            kind: .customText,
            payload: String(repeating: "a", count: 1_273),
            correctionLevel: .high
        )
        #expect(try QRPayloadValidator.validate(atHighLimit) == atHighLimit)

        var overHighLimit = atHighLimit
        overHighLimit.payload.append("a")
        #expect(throws: ValidationError.payloadTooLarge(maximumBytes: 1_273)) {
            try QRPayloadValidator.validate(overHighLimit)
        }
    }
}

@Suite("Versioned local persistence")
struct PersistenceTests {
    @Test("Snapshot round trips and replacement is atomic")
    func roundTripAndReplacement() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = AppPersistenceStore(directoryURL: directory)
        var first = AppSnapshot.empty
        first.profile.displayName = "First"
        first.preferences.defaultExpression = .happy
        try await store.save(first)
        #expect(try await store.load() == first)

        var replacement = first
        replacement.profile.displayName = "Replacement"
        try await store.save(replacement)
        #expect(try await store.load() == replacement)
        #expect(!FileManager.default.fileExists(atPath: directory.appending(path: "snapshot.json.tmp").path))
    }

    @Test("Corrupt data is archived and clean state is recovered")
    func corruptionRecovery() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("not json".utf8).write(to: directory.appending(path: "snapshot.json"))
        let store = AppPersistenceStore(directoryURL: directory)

        let result = try await store.loadRecovering()

        #expect(result.snapshot == .empty)
        #expect(result.recoveredCorruption)
        #expect(FileManager.default.fileExists(atPath: directory.appending(path: "snapshot.corrupt.json").path))
        #expect(!FileManager.default.fileExists(atPath: directory.appending(path: "snapshot.json").path))
    }

    @Test("Version-zero data enters migration path")
    func legacyMigration() throws {
        var legacy = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(AppSnapshot.empty)) as? [String: Any]
        )
        legacy.removeValue(forKey: "schemaVersion")
        legacy.removeValue(forKey: "theme")
        var profile = try #require(legacy["profile"] as? [String: Any])
        profile["displayName"] = "Migrated"
        legacy["profile"] = profile
        var preferences = try #require(legacy["preferences"] as? [String: Any])
        preferences.removeValue(forKey: "defaultExpression")
        legacy["preferences"] = preferences

        let result = try SnapshotMigrator.decode(JSONSerialization.data(withJSONObject: legacy))

        #expect(result.schemaVersion == AppSnapshot.currentSchemaVersion)
        #expect(result.profile.displayName == "Migrated")
        #expect(result.theme == .system)
        #expect(result.preferences.defaultExpression == .neutral)
    }

    @Test("Future schema is rejected without deleting it")
    func futureSchemaIsPreserved() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data(#"{"schemaVersion":999}"#.utf8).write(to: directory.appending(path: "snapshot.json"))
        let store = AppPersistenceStore(directoryURL: directory)

        await #expect(throws: PersistenceError.unsupportedSchemaVersion(999)) {
            try await store.loadRecovering()
        }
        #expect(FileManager.default.fileExists(atPath: directory.appending(path: "snapshot.json").path))
    }

    @Test("Delete all removes snapshot and imported content")
    func completeDeletion() async throws {
        let directory = try temporaryDirectory()
        let store = AppPersistenceStore(directoryURL: directory)
        try await store.save(.empty)
        let avatarDirectory = directory.appending(path: "Avatars", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: avatarDirectory, withIntermediateDirectories: true)
        try Data("model".utf8).write(to: avatarDirectory.appending(path: "current.vrm"))

        try await store.deleteAll()

        #expect(!FileManager.default.fileExists(atPath: directory.path))
    }
}

@Suite("Deterministic QR image generation")
struct QRCodeTests {
    @Test("Every correction level generates", arguments: QRCorrectionLevel.allCases)
    func correctionLevels(_ level: QRCorrectionLevel) throws {
        let raster = try QRCodeGenerator.generate(
            configuration: QRConfiguration(
                kind: .website,
                payload: "https://mrdemonwolf.com",
                correctionLevel: level
            ),
            targetPixelSize: 512
        )

        #expect(raster.image.width == raster.image.height)
        #expect(raster.moduleScale > 0)
    }

    @Test("Output has four-module quiet zone and integral scaling")
    func dimensionsAndQuietZone() throws {
        let raster = try QRCodeGenerator.generate(
            configuration: QRConfiguration(kind: .customText, payload: "SonaPin"),
            targetPixelSize: 300
        )
        let expectedModules = raster.moduleCount + (raster.quietZoneModules * 2)

        #expect(raster.quietZoneModules == 4)
        #expect(raster.pixelSize == expectedModules * raster.moduleScale)
        #expect(raster.pixelSize <= 300)
        let bytes = try imageBytes(raster.image)
        #expect(bytes.prefix(4).allSatisfy { $0 == 255 })
    }

    @Test("Same payload produces identical pixels")
    func deterministicOutput() throws {
        let configuration = QRConfiguration(kind: .customText, payload: "same input")
        let first = try QRCodeGenerator.generate(configuration: configuration, targetPixelSize: 320)
        let second = try QRCodeGenerator.generate(configuration: configuration, targetPixelSize: 320)

        #expect(try imageBytes(first.image) == imageBytes(second.image))
    }

    @Test("Too-small target fails clearly")
    func targetSizeValidation() {
        #expect(throws: QRCodeGenerationError.self) {
            try QRCodeGenerator.generate(
                configuration: QRConfiguration(kind: .customText, payload: "SonaPin"),
                targetPixelSize: 8
            )
        }
    }
}

@Suite("Avatar compatibility and storage")
struct AvatarTests {
    @Test("VRMKit products resolve")
    func dependenciesResolve() {
        #expect(AvatarDependencyAvailability.vrmKit)
        #expect(AvatarDependencyAvailability.vrmRealityKit)
    }

    @Test("VRM 1 metadata produces a supported report")
    func compatibilityReport() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "avatar.vrm")
        try makeVRM().write(to: url)

        let report = try VRMCompatibilityInspector.inspect(fileURL: url, checksum: "abc123")

        #expect(report.outcome == .supported)
        #expect(report.vrmVersion == .one)
        #expect(report.modelName == "Test Sona")
        #expect(report.authors == ["SonaPin Tests"])
        #expect(report.license.licenseURL == "https://vrm.dev/licenses/1.0/")
        #expect(report.availableExpressions.contains("happy"))
        #expect(report.bones.hasRequiredHumanoidBones)
        #expect(report.bones.hasHead)
        #expect(report.bones.hasHands)
        #expect(report.bones.tailRelatedNodes == ["Tail.001"])
        #expect(report.hasSpringBones)
        #expect(report.lookAtMode == "bone")
        #expect(report.animationClips == ["Idle"])
        #expect(report.checksum == "abc123")
    }

    @Test("Unsupported required extension is reported")
    func unsupportedExtension() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "avatar.vrm")
        try makeVRM(extraRequiredExtension: "VENDOR_unknown").write(to: url)

        let report = try VRMCompatibilityInspector.inspect(fileURL: url, checksum: "checksum")

        #expect(report.outcome == .unsupported)
        #expect(report.unsupportedRequiredExtensions == ["VENDOR_unknown"])
    }

    @Test("VRMA required by a model is reported unsupported by the pinned renderer")
    func unsupportedVRMARequirement() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "avatar.vrm")
        try makeVRM(extraRequiredExtension: "VRMC_vrm_animation").write(to: url)

        let report = try VRMCompatibilityInspector.inspect(fileURL: url, checksum: "checksum")

        #expect(report.outcome == .unsupported)
        #expect(report.unsupportedRequiredExtensions == ["VRMC_vrm_animation"])
    }

    @Test("Expression fallback follows documented order")
    func expressionFallback() {
        #expect(AvatarExpressionFallback.select(preferred: .happy, available: ["relaxed"]) == "relaxed")
        #expect(AvatarExpressionFallback.select(preferred: .surprised, available: ["Happy"]) == "Happy")
        #expect(AvatarExpressionFallback.select(preferred: .blink, available: ["neutral"]) == "neutral")
        #expect(AvatarExpressionFallback.select(preferred: .happy, available: []) == nil)
    }

    @Test("Capabilities expose supported fallbacks")
    func capabilityFallback() {
        let capabilities = AvatarCapabilities.proceduralDemo
        #expect(capabilities.contains(.expressions))
        #expect(capabilities.contains(.animation))
        #expect(capabilities.contains(.lookAt))
        #expect(!capabilities.contains(.springBones))
    }

    @Test("Imported copy survives source access ending")
    func importedCopyPersists() async throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appending(path: "source.vrm")
        let sourceData = try makeVRM(modelName: "First")
        try sourceData.write(to: source)
        let service = AvatarImportService(applicationSupportDirectory: root.appending(path: "Application Support"))

        let result = try await service.importAvatar(from: source)
        try FileManager.default.removeItem(at: source)

        #expect(result.record.kind == .imported)
        #expect(result.record.checksum?.count == 64)
        #expect(FileManager.default.fileExists(atPath: result.fileURL.path))
        #expect(try Data(contentsOf: result.fileURL) == sourceData)
    }

    @Test("Failed candidate preserves current avatar")
    func failedImportPreservesCurrent() async throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appending(path: "first.vrm")
        let broken = root.appending(path: "broken.vrm")
        try makeVRM(modelName: "Working").write(to: first)
        try Data("broken".utf8).write(to: broken)
        let service = AvatarImportService(applicationSupportDirectory: root.appending(path: "Application Support"))
        let imported = try await service.importAvatar(from: first)
        let workingData = try Data(contentsOf: imported.fileURL)

        do {
            _ = try await service.importAvatar(from: broken)
            Issue.record("Malformed candidate unexpectedly imported")
        } catch {
            #expect(error as? AvatarImportError == .invalidModel)
        }

        #expect(try Data(contentsOf: imported.fileURL) == workingData)
    }

    @Test("A render-invalid candidate preserves the current avatar")
    func failedRenderValidationPreservesCurrent() async throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let working = root.appending(path: "working.vrm")
        let renderInvalid = root.appending(path: "render-invalid.vrm")
        try makeVRM(modelName: "Working").write(to: working)
        try makeVRM(modelName: "No Scene", includeScene: false).write(to: renderInvalid)
        let service = AvatarImportService(applicationSupportDirectory: root.appending(path: "Application Support"))
        let imported = try await service.importAvatar(from: working)
        let workingData = try Data(contentsOf: imported.fileURL)

        do {
            _ = try await service.importAvatar(from: renderInvalid)
            Issue.record("Render-invalid candidate unexpectedly replaced the working avatar")
        } catch {
            #expect(error as? AvatarImportError == .invalidModel)
        }

        #expect(try Data(contentsOf: imported.fileURL) == workingData)
    }

    @Test("A second valid import atomically replaces current")
    func atomicModelReplacement() async throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appending(path: "first.vrm")
        let second = root.appending(path: "second.vrm")
        try makeVRM(modelName: "First").write(to: first)
        let secondData = try makeVRM(modelName: "Second")
        try secondData.write(to: second)
        let service = AvatarImportService(applicationSupportDirectory: root.appending(path: "Application Support"))

        _ = try await service.importAvatar(from: first)
        let result = try await service.importAvatar(from: second)

        #expect(try Data(contentsOf: result.fileURL) == secondData)
        #expect(result.record.compatibility?.modelName == "Second")
    }

    @Test("Optional local VRM fixture parses when available")
    func optionalLocalFixture() throws {
        guard let fixture = optionalFixtureURL else {
            print("SKIP: LocalAssets/TestAvatar.vrm is absent; optional VRM integration fixture not run.")
            return
        }

        try VRMKitModelValidator.validate(fileURL: fixture)
        let report = try VRMCompatibilityInspector.inspect(fileURL: fixture, checksum: "local-fixture")
        #expect(report.vrmVersion != .unknown)
    }
}

@Suite("Avatar renderers")
@MainActor
struct AvatarRendererTests {
    @Test("Procedural demo loads with interactive regions and fallback motions")
    func proceduralDemoLoads() async throws {
        let renderer = ProceduralDemoAvatarRenderer()
        let stableRoot = renderer.rootEntity

        try await renderer.load(.proceduralDemo)

        #expect(renderer.rootEntity === stableRoot)
        #expect(!renderer.rootEntity.children.isEmpty)
        #expect(renderer.rootEntity.findEntity(named: "SonaPinHeadHitTarget") != nil)
        #expect(renderer.rootEntity.findEntity(named: "SonaPinBodyHitTarget") != nil)
        #expect(renderer.rootEntity.findEntity(named: "SonaPinLeftPawHitTarget") != nil)
        #expect(renderer.rootEntity.findEntity(named: "SonaPinRightPawHitTarget") != nil)
        #expect(renderer.capabilities == .proceduralDemo)

        let motionEntity = try #require(renderer.rootEntity.children.first)
        let restingMotion = try #require(motionEntity.components[DemoAvatarMotionComponent.self])
        #expect(!restingMotion.idleEnabled)

        renderer.setExpression(.happy, weight: 1)
        renderer.look(at: SIMD3<Float>(1, 1, 1))
        for animation in ["idle", "boop", "left-paw", "right-paw", "wiggle"] {
            try renderer.play(AvatarAnimation(name: animation), looping: animation == "idle")
        }
        let activeMotion = try #require(motionEntity.components[DemoAvatarMotionComponent.self])
        #expect(activeMotion.idleEnabled)
        #expect(activeMotion.reactionRemaining > 0)
        motionEntity.position = SIMD3<Float>(1, 1, 1)
        renderer.resetPose()
        #expect(motionEntity.position == .zero)
        let resetMotion = try #require(motionEntity.components[DemoAvatarMotionComponent.self])
        #expect(!resetMotion.idleEnabled)
        #expect(resetMotion.reactionDuration == 0)
        #expect(resetMotion.reactionRemaining == 0)
        #expect(resetMotion.reactionTilt == 0)
        #expect(resetMotion.reactionWiggles == 1)
        renderer.resetCamera()

        renderer.unload()
        #expect(renderer.rootEntity === stableRoot)
        #expect(renderer.rootEntity.children.isEmpty)
    }

    @Test("Demo rejects an imported source without losing its current scene")
    func demoPreservesSceneAfterUnsupportedLoad() async throws {
        let renderer = ProceduralDemoAvatarRenderer()
        try await renderer.load(.proceduralDemo)
        let originalChild = try #require(renderer.rootEntity.children.first)

        await #expect(throws: AvatarRendererError.unsupportedSource) {
            try await renderer.load(.imported(fileURL: URL(fileURLWithPath: "/tmp/not-a-demo.vrm")))
        }

        #expect(renderer.rootEntity.children.first === originalChild)
    }

    @Test("Optional local fixture renders through VRMKit when available")
    func optionalLocalFixtureRenders() async throws {
        guard let fixture = optionalFixtureURL else {
            print("SKIP: LocalAssets/TestAvatar.vrm is absent; optional VRM rendering fixture not run.")
            return
        }

        let renderer = VRMKitAvatarRenderer()
        try await renderer.load(.imported(fileURL: fixture))

        let avatar = try #require(renderer.rootEntity.children.first as? VRMEntity)
        let restingMotion = try #require(avatar.components[DemoAvatarMotionComponent.self])
        #expect(!restingMotion.idleEnabled)
        let presentedForward = avatar.orientation(relativeTo: renderer.rootEntity).act(avatar.frontDirection)
        #expect(presentedForward.z > 0.99)

        let leftUpperArm = try #require(avatar.humanoid.node(for: .leftUpperArm))
        let leftLowerArm = try #require(avatar.humanoid.node(for: .leftLowerArm))
        let posedLowerArmY = leftLowerArm.position(relativeTo: avatar).y
        #expect(posedLowerArmY < leftUpperArm.position(relativeTo: avatar).y - 0.05)

        let rightUpperArm = try #require(avatar.humanoid.node(for: .rightUpperArm))
        let rightLowerArm = try #require(avatar.humanoid.node(for: .rightLowerArm))
        let posedRightLowerArmY = rightLowerArm.position(relativeTo: avatar).y
        #expect(posedRightLowerArmY < rightUpperArm.position(relativeTo: avatar).y - 0.05)

        renderer.resetPose()
        #expect(abs(leftLowerArm.position(relativeTo: avatar).y - posedLowerArmY) < 0.001)
        #expect(abs(rightLowerArm.position(relativeTo: avatar).y - posedRightLowerArmY) < 0.001)
        renderer.unload()
        #expect(renderer.rootEntity.children.isEmpty)
    }
}

private let requiredHumanoidBones = [
    "head", "hips", "spine",
    "leftUpperArm", "leftLowerArm", "leftHand",
    "rightUpperArm", "rightLowerArm", "rightHand",
    "leftUpperLeg", "leftLowerLeg", "leftFoot",
    "rightUpperLeg", "rightLowerLeg", "rightFoot",
]

private var optionalFixtureURL: URL? {
    let testFile = URL(fileURLWithPath: #filePath)
    let nativeRoot = testFile.deletingLastPathComponent().deletingLastPathComponent()
    let repositoryRoot = nativeRoot.deletingLastPathComponent().deletingLastPathComponent()
    return [
        nativeRoot.appending(path: "LocalAssets/TestAvatar.vrm"),
        repositoryRoot.appending(path: "LocalAssets/TestAvatar.vrm"),
    ].first { FileManager.default.fileExists(atPath: $0.path) }
}

private func temporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appending(
        path: "SonaPinTests-\(UUID().uuidString)",
        directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func makeVRM(
    modelName: String = "Test Sona",
    extraRequiredExtension: String? = nil,
    includeScene: Bool = true
) throws -> Data {
    let bones = Dictionary(uniqueKeysWithValues: requiredHumanoidBones.map { ($0, ["node": 0]) })
    var requiredExtensions = ["VRMC_vrm"]
    if let extraRequiredExtension {
        requiredExtensions.append(extraRequiredExtension)
    }
    var object: [String: Any] = [
        "asset": ["version": "2.0"],
        "extensionsRequired": requiredExtensions,
        "extensions": [
            "VRMC_vrm": [
                "specVersion": "1.0",
                "meta": [
                    "name": modelName,
                    "authors": ["SonaPin Tests"],
                    "contactInformation": "https://example.com",
                    "references": ["https://example.com/model"],
                    "thirdPartyLicenses": "None",
                    "licenseUrl": "https://vrm.dev/licenses/1.0/",
                    "commercialUsage": "personalNonProfit",
                    "allowRedistribution": false,
                    "creditNotation": "required",
                ],
                "humanoid": ["humanBones": bones],
                "expressions": ["preset": ["happy": [:]], "custom": [:]],
                "lookAt": ["type": "bone"],
            ],
            "VRMC_springBone": ["specVersion": "1.0"],
        ],
        "nodes": [["name": "Tail.001"]],
        "animations": [["name": "Idle", "channels": [], "samplers": []]],
    ]
    if includeScene {
        object["scene"] = 0
        object["scenes"] = [["nodes": [0]]]
    }
    var json = try JSONSerialization.data(withJSONObject: object, options: .sortedKeys)
    while !json.count.isMultiple(of: 4) {
        json.append(0x20)
    }

    var data = Data([0x67, 0x6C, 0x54, 0x46])
    data.appendLittleEndian(2)
    data.appendLittleEndian(UInt32(20 + json.count))
    data.appendLittleEndian(UInt32(json.count))
    data.appendLittleEndian(0x4E4F534A)
    data.append(json)
    return data
}

@Suite("Avatar touch reactions")
struct AvatarTouchReactionTests {
    @Test("Named avatar regions choose distinct reactions", arguments: [
        ("SonaPinHeadHitTarget", AvatarExpression.happy, "boop"),
        ("SonaPinLeftPawHitTarget", AvatarExpression.happy, "left-paw"),
        ("SonaPinRightPawHitTarget", AvatarExpression.happy, "right-paw"),
        ("SonaPinBodyHitTarget", AvatarExpression.surprised, "wiggle"),
    ])
    func touchReaction(name: String, expression: AvatarExpression, animation: String) throws {
        let reaction = try #require(AvatarTouchReaction.reaction(for: name))
        #expect(reaction.expression == expression)
        #expect(reaction.animation == animation)
    }

    @Test("Unknown scene entities do not react")
    func ignoresUnknownEntity() {
        #expect(AvatarTouchReaction.reaction(for: "Background") == nil)
    }
}

private func imageBytes(_ image: CGImage) throws -> Data {
    let source = try #require(image.dataProvider?.data)
    guard let bytes = CFDataGetBytePtr(source) else { return Data() }
    return Data(bytes: bytes, count: CFDataGetLength(source))
}

private extension Data {
    mutating func appendLittleEndian(_ value: UInt32) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }
}
