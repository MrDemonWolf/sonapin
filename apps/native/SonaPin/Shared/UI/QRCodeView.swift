import SwiftUI

struct QRCodeView: View {
    let configuration: QRConfiguration
    var maximumDimension: CGFloat = 320
    var showsPayload = false

    private let raster: QRCodeRaster?
    private let errorMessage: String?

    init(
        configuration: QRConfiguration,
        maximumDimension: CGFloat = 320,
        showsPayload: Bool = false
    ) {
        self.configuration = configuration
        self.maximumDimension = maximumDimension
        self.showsPayload = showsPayload

        do {
            raster = try QRCodeGenerator.generate(configuration: configuration, targetPixelSize: 768)
            errorMessage = nil
        } catch {
            raster = nil
            errorMessage = error.localizedDescription
        }
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
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 42, weight: .semibold))
                        .accessibilityHidden(true)
                    Text(configuration.payload.isEmpty ? "No QR code yet" : "QR preview unavailable")
                        .font(.headline)
                    Text(configuration.payload.isEmpty
                         ? "Add one later from Edit Badge."
                         : (errorMessage ?? "Enter valid QR content to make a preview."))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: maximumDimension, minHeight: 220)
                .accessibilityElement(children: .combine)
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
    }
}
