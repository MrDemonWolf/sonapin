import Foundation
import OSLog

enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.mrdemonwolf.sonapin"

    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    static let avatarImport = Logger(subsystem: subsystem, category: "avatar-import")
    static let avatarValidation = Logger(subsystem: subsystem, category: "avatar-validation")
    static let avatarLoad = Logger(subsystem: subsystem, category: "avatar-load")
    static let rendering = Logger(subsystem: subsystem, category: "rendering")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let qrGeneration = Logger(subsystem: subsystem, category: "qr-generation")
}

enum PerformanceMetric: String, Sendable {
    case importCopy
    case parse
    case entityLoad
    case firstFrame
    case interactionResponse
}

enum AppDiagnostics {
    static func measure<T>(
        _ metric: PerformanceMetric,
        logger: Logger,
        operation: () throws -> T
    ) rethrows -> T {
        let clock = ContinuousClock()
        let start = clock.now
        defer {
            let duration = start.duration(to: clock.now)
            logger.debug("\(metric.rawValue, privacy: .public) completed in \(duration.description, privacy: .public)")
        }
        return try operation()
    }

    static func measure<T: Sendable>(
        _ metric: PerformanceMetric,
        logger: Logger,
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        let clock = ContinuousClock()
        let start = clock.now
        defer {
            let duration = start.duration(to: clock.now)
            logger.debug("\(metric.rawValue, privacy: .public) completed in \(duration.description, privacy: .public)")
        }
        return try await operation()
    }
}
