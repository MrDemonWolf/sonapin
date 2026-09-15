import CoreImage
import Foundation

enum QRCodeGenerationError: Error, Equatable, LocalizedError, Sendable {
    case invalidPayload(ValidationError)
    case filterUnavailable
    case generationFailed
    case targetTooSmall(minimumPixels: Int)

    var errorDescription: String? {
        switch self {
        case let .invalidPayload(error): error.localizedDescription
        case .filterUnavailable: "QR generation is unavailable on this device."
        case .generationFailed: "The QR code could not be generated."
        case let .targetTooSmall(minimumPixels):
            "QR output must be at least \(minimumPixels) pixels wide."
        }
    }
}

struct QRCodeRaster {
    let image: CGImage
    let moduleCount: Int
    let moduleScale: Int
    let quietZoneModules: Int

    var pixelSize: Int { image.width }
}

enum QRCodeGenerator {
    static let minimumQuietZoneModules = 4

    static func generate(
        configuration: QRConfiguration,
        targetPixelSize: Int,
        quietZoneModules: Int = minimumQuietZoneModules
    ) throws -> QRCodeRaster {
        let validated: QRConfiguration
        do {
            validated = try QRPayloadValidator.validate(configuration)
        } catch let error as ValidationError {
            throw QRCodeGenerationError.invalidPayload(error)
        }

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw QRCodeGenerationError.filterUnavailable
        }
        filter.setValue(Data(validated.payload.utf8), forKey: "inputMessage")
        filter.setValue(validated.correctionLevel.rawValue, forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else {
            throw QRCodeGenerationError.generationFailed
        }

        let moduleCount = Int(output.extent.width.rounded())
        let quietZone = max(minimumQuietZoneModules, quietZoneModules)
        let totalModules = moduleCount + (quietZone * 2)
        let scale = targetPixelSize / totalModules
        guard scale >= 1 else {
            throw QRCodeGenerationError.targetTooSmall(minimumPixels: totalModules)
        }

        let paddedExtent = CGRect(x: 0, y: 0, width: totalModules, height: totalModules)
        let background = CIImage(color: .white).cropped(to: paddedExtent)
        let translated = output.transformed(
            by: CGAffineTransform(translationX: CGFloat(quietZone), y: CGFloat(quietZone))
        )
        let padded = translated.composited(over: background)
        let scaled = padded.transformed(
            by: CGAffineTransform(scaleX: CGFloat(scale), y: CGFloat(scale))
        )
        let extent = scaled.extent.integral
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        let context = CIContext(options: [.cacheIntermediates: false])
        guard let image = context.createCGImage(
            scaled,
            from: extent,
            format: .RGBA8,
            colorSpace: colorSpace
        ) else {
            throw QRCodeGenerationError.generationFailed
        }

        return QRCodeRaster(
            image: image,
            moduleCount: moduleCount,
            moduleScale: scale,
            quietZoneModules: quietZone
        )
    }
}
