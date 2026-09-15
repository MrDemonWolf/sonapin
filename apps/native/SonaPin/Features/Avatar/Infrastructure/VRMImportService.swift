import CryptoKit
import Darwin
import Foundation
import VRMKit
import VRMRealityKit

enum AvatarDependencyAvailability {
    // Compilation of this file proves both required package products resolve.
    static let vrmKit = true
    static let vrmRealityKit = true
}

enum VRMKitModelValidator {
    static func parse(fileURL: URL) throws -> VRM {
        try VRM(withURL: fileURL)
    }

    /// Exercises the pinned parser without exposing its model graph outside infrastructure.
    static func validate(fileURL: URL) throws {
        _ = try parse(fileURL: fileURL)
    }
}

enum VRMInspectionError: Error, Equatable, LocalizedError, Sendable {
    case invalidContainer
    case unsupportedGLBVersion(UInt32)
    case missingJSONChunk
    case malformedJSON

    var errorDescription: String? {
        switch self {
        case .invalidContainer: "The selected file is not a valid VRM/GLB container."
        case let .unsupportedGLBVersion(version): "GLB version \(version) is not supported."
        case .missingJSONChunk: "The model does not contain readable metadata."
        case .malformedJSON: "The model metadata is malformed."
        }
    }
}

enum AvatarImportError: Error, Equatable, LocalizedError, Sendable {
    case invalidFileType
    case emptyFile
    case invalidModel
    case importAlreadyInProgress
    case unsupported(AvatarCompatibilityReport)
    case fileOperationFailed

    var errorDescription: String? {
        switch self {
        case .invalidFileType: "Choose a .vrm file."
        case .emptyFile: "The selected model is empty."
        case .invalidModel: "The file contains invalid or unsupported VRM data."
        case .importAlreadyInProgress: "Wait for the current avatar import to finish."
        case .unsupported: "This model is not compatible. Review its compatibility report."
        case .fileOperationFailed: "The model could not be copied into the app."
        }
    }
}

enum VRMCompatibilityInspector {
    private static let requiredHumanoidBones: Set<String> = [
        "head", "hips", "spine",
        "leftUpperArm", "leftLowerArm", "leftHand",
        "rightUpperArm", "rightLowerArm", "rightHand",
        "leftUpperLeg", "leftLowerLeg", "leftFoot",
        "rightUpperLeg", "rightLowerLeg", "rightFoot",
    ]

    private static let supportedRequiredExtensions: Set<String> = [
        "VRM", "VRMC_vrm", "VRMC_springBone", "VRMC_node_constraint",
        "VRMC_materials_mtoon", "KHR_materials_unlit", "KHR_texture_transform",
    ]

    static func inspect(fileURL: URL, checksum: String) throws -> AvatarCompatibilityReport {
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0
        let root = try GLBJSONReader.read(from: fileURL)
        let extensions = dictionary(root["extensions"]) ?? [:]
        let requiredExtensions = stringArray(root["extensionsRequired"]).sorted()
        let unsupportedExtensions = requiredExtensions
            .filter { !supportedRequiredExtensions.contains($0) }
            .sorted()
        let nodes = array(root["nodes"])
            .compactMap(dictionary)
            .compactMap { string($0["name"]) }
        let animations = array(root["animations"])
            .compactMap(dictionary)
            .compactMap { string($0["name"]) }
            .sorted()

        let extracted: ExtractedMetadata
        if let vrm = dictionary(extensions["VRMC_vrm"]) {
            extracted = extractV1(vrm)
        } else if let vrm = dictionary(extensions["VRM"]) {
            extracted = extractV0(vrm)
        } else {
            extracted = .unknown
        }

        let discoveredBones = extracted.bones.sorted()
        let missingBones = requiredHumanoidBones.subtracting(extracted.bones).sorted()
        let bonePresence = AvatarBonePresence(
            discoveredBones: discoveredBones,
            missingRequiredBones: missingBones,
            hasHead: extracted.bones.contains("head"),
            hasNeck: extracted.bones.contains("neck"),
            hasEyes: extracted.bones.isSuperset(of: ["leftEye", "rightEye"]),
            hasHands: extracted.bones.isSuperset(of: ["leftHand", "rightHand"]),
            tailRelatedNodes: nodes.filter { $0.localizedCaseInsensitiveContains("tail") }.sorted()
        )

        var warnings: [String] = []
        if extracted.version == .unknown {
            warnings.append("No VRM 0.x or VRM 1.0 extension was found.")
        }
        if !missingBones.isEmpty {
            warnings.append("Required humanoid bones are missing: \(missingBones.joined(separator: ", ")).")
        }
        if extracted.authors.isEmpty {
            warnings.append("Model author metadata is missing.")
        }
        if extracted.expressions.isEmpty {
            warnings.append("No avatar expressions were declared.")
        }

        let outcome: AvatarCompatibilityOutcome
        if extracted.version == .unknown || !missingBones.isEmpty || !unsupportedExtensions.isEmpty {
            outcome = .unsupported
        } else if warnings.isEmpty {
            outcome = .supported
        } else {
            outcome = .supportedWithWarnings
        }

        return AvatarCompatibilityReport(
            fileName: fileURL.lastPathComponent,
            fileSize: fileSize,
            checksum: checksum,
            vrmVersion: extracted.version,
            modelName: extracted.name,
            authors: extracted.authors,
            contactInformation: extracted.contact,
            references: extracted.references,
            license: extracted.license,
            availableExpressions: extracted.expressions.sorted(),
            bones: bonePresence,
            hasSpringBones: extensions["VRMC_springBone"] != nil || extracted.hasLegacySpringBones,
            lookAtMode: extracted.lookAtMode,
            animationClips: animations,
            supportsVRMA: extensions["VRMC_vrm_animation"] != nil,
            requiredExtensions: requiredExtensions,
            unsupportedRequiredExtensions: unsupportedExtensions,
            parserWarnings: warnings,
            rendererWarnings: [],
            outcome: outcome
        )
    }

    private static func extractV1(_ vrm: [String: Any]) -> ExtractedMetadata {
        let meta = dictionary(vrm["meta"]) ?? [:]
        let humanoid = dictionary(vrm["humanoid"]) ?? [:]
        let humanBones = dictionary(humanoid["humanBones"]) ?? [:]
        let expressions = dictionary(vrm["expressions"]) ?? [:]
        let presetExpressions = dictionary(expressions["preset"]).map { Array($0.keys) } ?? []
        let customExpressions = dictionary(expressions["custom"]).map { Array($0.keys) } ?? []
        let lookAt = dictionary(vrm["lookAt"])

        var permissions: [String] = []
        for key in [
            "avatarPermission", "allowExcessivelyViolentUsage", "allowExcessivelySexualUsage",
            "allowPoliticalOrReligiousUsage", "allowAntisocialOrHateUsage", "modification",
        ] {
            if let value = scalarDescription(meta[key]) {
                permissions.append("\(key): \(value)")
            }
        }

        return ExtractedMetadata(
            version: .one,
            name: string(meta["name"]),
            authors: stringArray(meta["authors"]),
            contact: string(meta["contactInformation"]),
            references: stringArray(meta["references"]),
            license: AvatarLicenseMetadata(
                licenseName: string(meta["thirdPartyLicenses"]),
                licenseURL: string(meta["licenseUrl"]) ?? string(meta["otherLicenseUrl"]),
                commercialUse: scalarDescription(meta["commercialUsage"]),
                redistribution: scalarDescription(meta["allowRedistribution"]),
                credit: scalarDescription(meta["creditNotation"]),
                otherPermissions: permissions
            ),
            expressions: Array(presetExpressions) + Array(customExpressions),
            bones: Set(humanBones.keys),
            hasLegacySpringBones: false,
            lookAtMode: string(lookAt?["type"])
        )
    }

    private static func extractV0(_ vrm: [String: Any]) -> ExtractedMetadata {
        let meta = dictionary(vrm["meta"]) ?? [:]
        let humanoid = dictionary(vrm["humanoid"]) ?? [:]
        let humanBones = array(humanoid["humanBones"])
            .compactMap(dictionary)
            .compactMap { string($0["bone"]) }
        let blendShapeMaster = dictionary(vrm["blendShapeMaster"]) ?? [:]
        let expressions = array(blendShapeMaster["blendShapeGroups"])
            .compactMap(dictionary)
            .compactMap { string($0["presetName"]) ?? string($0["name"]) }
        let secondaryAnimation = dictionary(vrm["secondaryAnimation"])
        let firstPerson = dictionary(vrm["firstPerson"])

        var references: [String] = []
        if let reference = string(meta["reference"]), !reference.isEmpty {
            references.append(reference)
        }
        var permissions: [String] = []
        for key in [
            "allowedUserName", "violentUssageName", "sexualUssageName", "otherPermissionUrl",
        ] {
            if let value = scalarDescription(meta[key]) {
                permissions.append("\(key): \(value)")
            }
        }

        return ExtractedMetadata(
            version: .zeroX,
            name: string(meta["title"]),
            authors: string(meta["author"]).map { [$0] } ?? [],
            contact: string(meta["contactInformation"]),
            references: references,
            license: AvatarLicenseMetadata(
                licenseName: string(meta["licenseName"]),
                licenseURL: string(meta["otherLicenseUrl"]),
                commercialUse: scalarDescription(meta["commercialUssageName"]),
                redistribution: nil,
                credit: nil,
                otherPermissions: permissions
            ),
            expressions: expressions,
            bones: Set(humanBones),
            hasLegacySpringBones: !array(secondaryAnimation?["boneGroups"]).isEmpty,
            lookAtMode: string(firstPerson?["lookAtTypeName"])
        )
    }

    private static func dictionary(_ value: Any?) -> [String: Any]? {
        value as? [String: Any]
    }

    private static func array(_ value: Any?) -> [Any] {
        value as? [Any] ?? []
    }

    private static func string(_ value: Any?) -> String? {
        value as? String
    }

    private static func stringArray(_ value: Any?) -> [String] {
        value as? [String] ?? []
    }

    private static func scalarDescription(_ value: Any?) -> String? {
        switch value {
        case let string as String: string
        case let number as NSNumber: number.stringValue
        default: nil
        }
    }

    private struct ExtractedMetadata {
        var version: VRMVersion
        var name: String?
        var authors: [String]
        var contact: String?
        var references: [String]
        var license: AvatarLicenseMetadata
        var expressions: [String]
        var bones: Set<String>
        var hasLegacySpringBones: Bool
        var lookAtMode: String?

        static let unknown = ExtractedMetadata(
            version: .unknown,
            authors: [],
            references: [],
            license: AvatarLicenseMetadata(),
            expressions: [],
            bones: [],
            hasLegacySpringBones: false
        )
    }
}

actor AvatarImportService {
    private let directoryURL: URL
    private let currentAvatarURL: URL
    private var isImporting = false

    init(applicationSupportDirectory: URL) {
        directoryURL = applicationSupportDirectory
            .standardizedFileURL
            .appending(path: "Avatars", directoryHint: .isDirectory)
        currentAvatarURL = directoryURL.appending(path: "current.vrm", directoryHint: .notDirectory)
    }

    func importAvatar(from sourceURL: URL) async throws -> AvatarImportResult {
        guard !isImporting else { throw AvatarImportError.importAlreadyInProgress }
        isImporting = true
        defer { isImporting = false }

        guard sourceURL.pathExtension.lowercased() == "vrm" else {
            throw AvatarImportError.invalidFileType
        }
        try Task.checkCancellation()

        let hasSecurityScope = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScope {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let stagedURL = directoryURL.appending(
            path: "candidate-\(UUID().uuidString).vrm",
            directoryHint: .notDirectory
        )
        defer { try? fileManager.removeItem(at: stagedURL) }

        do {
            try AppDiagnostics.measure(.importCopy, logger: AppLog.avatarImport) {
                try fileManager.copyItem(at: sourceURL, to: stagedURL)
            }
        } catch {
            throw AvatarImportError.fileOperationFailed
        }

        try Task.checkCancellation()
        let attributes = try fileManager.attributesOfItem(atPath: stagedURL.path)
        guard (attributes[.size] as? NSNumber)?.int64Value ?? 0 > 0 else {
            throw AvatarImportError.emptyFile
        }

        let checksum: String
        let parsedModel: VRM
        do {
            checksum = try SHA256FileHasher.hash(fileURL: stagedURL)
            parsedModel = try VRMKitModelValidator.parse(fileURL: stagedURL)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw AvatarImportError.invalidModel
        }
        let report = try AppDiagnostics.measure(.parse, logger: AppLog.avatarValidation) {
            try VRMCompatibilityInspector.inspect(fileURL: stagedURL, checksum: checksum)
        }
        guard report.outcome != .unsupported else {
            throw AvatarImportError.unsupported(report)
        }

        do {
            try await AppDiagnostics.measure(.entityLoad, logger: AppLog.avatarLoad) {
                try await VRMKitRenderValidator.validate(model: parsedModel)
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw AvatarImportError.invalidModel
        }

        try Task.checkCancellation()
        do {
            try atomicReplace(stagedURL, with: currentAvatarURL)
        } catch {
            throw AvatarImportError.fileOperationFailed
        }

        return AvatarImportResult(
            record: AvatarRecord(
                kind: .imported,
                storedFileName: currentAvatarURL.lastPathComponent,
                checksum: checksum,
                compatibility: report
            ),
            fileURL: currentAvatarURL
        )
    }

    func currentFileURL() -> URL? {
        FileManager.default.fileExists(atPath: currentAvatarURL.path) ? currentAvatarURL : nil
    }

    func removeCurrentAvatar() throws {
        guard FileManager.default.fileExists(atPath: currentAvatarURL.path) else {
            return
        }
        try FileManager.default.removeItem(at: currentAvatarURL)
    }

    private func atomicReplace(_ sourceURL: URL, with destinationURL: URL) throws {
        let result = sourceURL.withUnsafeFileSystemRepresentation { sourcePath in
            destinationURL.withUnsafeFileSystemRepresentation { destinationPath in
                guard let sourcePath, let destinationPath else { return -1 }
                return Int(Darwin.rename(sourcePath, destinationPath))
            }
        }
        guard result == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
    }
}

private enum SHA256FileHasher {
    static func hash(fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        var hasher = SHA256()

        while let chunk = try handle.read(upToCount: 1_048_576), !chunk.isEmpty {
            try Task.checkCancellation()
            hasher.update(data: chunk)
        }

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

private enum GLBJSONReader {
    private static let glTFMagic = Data([0x67, 0x6C, 0x54, 0x46])
    private static let jsonChunkType: UInt32 = 0x4E4F534A

    static func read(from fileURL: URL) throws -> [String: Any] {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        let header = try readExactly(12, from: handle)
        guard header.prefix(4) == glTFMagic else {
            throw VRMInspectionError.invalidContainer
        }
        let version = header.littleEndianUInt32(at: 4)
        guard version == 2 else {
            throw VRMInspectionError.unsupportedGLBVersion(version)
        }
        let declaredLength = Int(header.littleEndianUInt32(at: 8))
        let actualLength = try handle.seekToEnd()
        guard declaredLength >= 20, UInt64(declaredLength) <= actualLength else {
            throw VRMInspectionError.invalidContainer
        }
        try handle.seek(toOffset: 12)

        let chunkHeader = try readExactly(8, from: handle)
        let chunkLength = Int(chunkHeader.littleEndianUInt32(at: 0))
        let chunkType = chunkHeader.littleEndianUInt32(at: 4)
        guard chunkType == jsonChunkType, chunkLength > 0, 20 + chunkLength <= declaredLength else {
            throw VRMInspectionError.missingJSONChunk
        }
        var jsonData = try readExactly(chunkLength, from: handle)
        while jsonData.last == 0 || jsonData.last == 0x20 {
            jsonData.removeLast()
        }
        guard let root = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw VRMInspectionError.malformedJSON
        }
        return root
    }

    private static func readExactly(_ count: Int, from handle: FileHandle) throws -> Data {
        guard let data = try handle.read(upToCount: count), data.count == count else {
            throw VRMInspectionError.invalidContainer
        }
        return data
    }
}

private extension Data {
    func littleEndianUInt32(at offset: Int) -> UInt32 {
        UInt32(self[index(startIndex, offsetBy: offset)])
            | UInt32(self[index(startIndex, offsetBy: offset + 1)]) << 8
            | UInt32(self[index(startIndex, offsetBy: offset + 2)]) << 16
            | UInt32(self[index(startIndex, offsetBy: offset + 3)]) << 24
    }
}
