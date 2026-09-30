import SwiftUI

struct QRCodeView: View {
    let configuration: QRConfiguration
    var maximumDimension: CGFloat = 320
    var showsPayload = false

    @State private var raster: QRCodeRaster?
    @State private var errorMessage: String?

    init(
        configuration: QRConfiguration,
        maximumDimension: CGFloat = 320,
        showsPayload: Bool = false
    ) {
        self.configuration = configuration
        self.maximumDimension = maximumDimension
        self.showsPayload = showsPayload

    }

    var body: some View {
        VStack(spacing: 12) {
            if let raster {
                Image(raster.image, scale: 1, label: Text("QR code"))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: maximumDimension, maxHeight: maximumDimension)
                    .padding(8)
                    .background(.white)
                    .clipShape(.rect(cornerRadius: 16))
                    .accessibilityLabel("QR code")
                    .accessibilityValue(QRPayloadValidator.accessibilityDescription(for: configuration))
                    .accessibilityHint("Ask another person to scan this code with their camera.")
            } else if configuration.payload.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 42, weight: .semibold))
                        .accessibilityHidden(true)
                    Text("No QR code yet")
                        .font(.headline)
                    Text("Add one later from Edit Badge.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: maximumDimension, minHeight: 220)
                .accessibilityElement(children: .combine)
            } else if let errorMessage {
                VStack(spacing: 10) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 42, weight: .semibold))
                        .accessibilityHidden(true)
                    Text("QR preview unavailable")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: maximumDimension, minHeight: 220)
                .accessibilityElement(children: .combine)
            } else {
                ProgressView("Preparing QR code")
                    .frame(maxWidth: maximumDimension, minHeight: 220)
            }

            if showsPayload, !configuration.payload.isEmpty {
                Text(configuration.payload)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
            }
        }
        .task(id: configuration) {
            raster = nil
            errorMessage = nil
            guard !configuration.payload.isEmpty else { return }

            do {
                try await Task.sleep(for: .milliseconds(150))
                let generatedRaster = try await Task.detached(priority: .userInitiated) { // concurrency-reviewed: Core Image rendering stays off the main actor.
                    try QRCodeGenerator.generate(configuration: configuration, targetPixelSize: 768)
                }.value
                try Task.checkCancellation()
                raster = generatedRaster
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
