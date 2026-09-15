import Foundation

enum PersistenceError: Error, Equatable, LocalizedError, Sendable {
    case corruptedSnapshot
    case unsupportedSchemaVersion(Int)
    case invalidSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case .corruptedSnapshot:
            "Saved data could not be read. A clean profile was restored."
        case let .unsupportedSchemaVersion(version):
            "Saved data uses unsupported schema version \(version)."
        case let .invalidSchemaVersion(version):
            "Saved data has invalid schema version \(version)."
        }
    }
}

struct PersistenceLoadResult: Equatable, Sendable {
    var snapshot: AppSnapshot
    var recoveredCorruption: Bool
}

enum SnapshotMigrator {
    static func decode(_ data: Data) throws -> AppSnapshot {
        let decoder = JSONDecoder()
        let header: SchemaHeader
        do {
            header = try decoder.decode(SchemaHeader.self, from: data)
        } catch {
            throw PersistenceError.corruptedSnapshot
        }

        switch header.schemaVersion ?? 0 {
        case 0:
            do {
                let legacy = try decoder.decode(LegacySnapshotV0.self, from: data)
                return AppSnapshot(
                    profile: legacy.profile ?? BadgeProfile(),
                    qrConfiguration: legacy.qrConfiguration ?? QRConfiguration(),
                    theme: legacy.theme ?? .midnight,
                    preferences: legacy.preferences ?? InteractionPreferences(),
                    avatar: legacy.avatar ?? .demo,
                    onboarding: legacy.onboarding ?? OnboardingProgress()
                )
            } catch {
                throw PersistenceError.corruptedSnapshot
            }
        case AppSnapshot.currentSchemaVersion:
            do {
                return try decoder.decode(AppSnapshot.self, from: data)
            } catch {
                throw PersistenceError.corruptedSnapshot
            }
        case let version where version < 0:
            throw PersistenceError.invalidSchemaVersion(version)
        case let version:
            throw PersistenceError.unsupportedSchemaVersion(version)
        }
    }

    private struct SchemaHeader: Decodable {
        let schemaVersion: Int?
    }

    private struct LegacySnapshotV0: Decodable {
        var profile: BadgeProfile?
        var qrConfiguration: QRConfiguration?
        var theme: BadgeTheme?
        var preferences: InteractionPreferences?
        var avatar: AvatarRecord?
        var onboarding: OnboardingProgress?
    }
}

actor AppPersistenceStore {
    private let directoryURL: URL
    private let snapshotURL: URL
    private let corruptionBackupURL: URL

    init(directoryURL: URL) {
        self.directoryURL = directoryURL.standardizedFileURL
        snapshotURL = self.directoryURL.appending(path: "snapshot.json", directoryHint: .notDirectory)
        corruptionBackupURL = self.directoryURL.appending(path: "snapshot.corrupt.json", directoryHint: .notDirectory)
    }

    func save(_ snapshot: AppSnapshot) throws {
        guard snapshot.schemaVersion == AppSnapshot.currentSchemaVersion else {
            throw PersistenceError.invalidSchemaVersion(snapshot.schemaVersion)
        }

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: snapshotURL, options: .atomic)
    }

    func load() throws -> AppSnapshot? {
        guard FileManager.default.fileExists(atPath: snapshotURL.path) else {
            return nil
        }
        return try SnapshotMigrator.decode(Data(contentsOf: snapshotURL))
    }

    func loadRecovering(default defaultSnapshot: AppSnapshot = .empty) throws -> PersistenceLoadResult {
        do {
            return PersistenceLoadResult(
                snapshot: try load() ?? defaultSnapshot,
                recoveredCorruption: false
            )
        } catch let error as PersistenceError {
            if case .unsupportedSchemaVersion = error {
                throw error
            }
            try archiveCorruptedSnapshot()
            return PersistenceLoadResult(snapshot: defaultSnapshot, recoveredCorruption: true)
        } catch {
            try archiveCorruptedSnapshot()
            return PersistenceLoadResult(snapshot: defaultSnapshot, recoveredCorruption: true)
        }
    }

    func deleteAll() throws {
        guard FileManager.default.fileExists(atPath: directoryURL.path) else {
            return
        }
        try FileManager.default.removeItem(at: directoryURL)
    }

    private func archiveCorruptedSnapshot() throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: snapshotURL.path) else {
            return
        }
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: corruptionBackupURL.path) {
            try fileManager.removeItem(at: corruptionBackupURL)
        }
        try fileManager.moveItem(at: snapshotURL, to: corruptionBackupURL)
    }
}
