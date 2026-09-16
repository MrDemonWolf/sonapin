import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct AvatarSourcePicker: View {
    @Bindable var model: AppModel
    @State private var acknowledgesRights = false
    @State private var presentsImporter = false

    private var vrmType: UTType {
        UTType(filenameExtension: "vrm") ?? .data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                Task { await model.useDemoAvatar() }
            } label: {
                AvatarChoiceLabel(
                    title: "Built-in blue wolf",
                    detail: "Ready now, fully interactive, and safe for testing.",
                    systemImage: "pawprint.fill",
                    isSelected: model.snapshot.avatar.kind == .demo
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Uses the built-in procedural demo avatar.")
            .accessibilityIdentifier("avatar.use-demo")

            VStack(alignment: .leading, spacing: 12) {
                AvatarChoiceLabel(
                    title: "Import a VRM",
                    detail: "SonaPin checks compatibility and keeps the file on this device.",
                    systemImage: "square.and.arrow.down",
                    isSelected: model.snapshot.avatar.kind == .imported
                )

                Toggle(
                    "I have permission to use and display the model I select.",
                    isOn: $acknowledgesRights
                )
                .font(.callout)
                .accessibilityIdentifier("avatar.rights")

                Button("Choose VRM File", systemImage: "folder") {
                    presentsImporter = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(!acknowledgesRights || model.isImportingAvatar)
                .frame(minHeight: 44)
                .accessibilityHint("Opens the system file picker for a dot V R M file.")
                .accessibilityIdentifier("avatar.import")

                if model.isImportingAvatar {
                    ProgressView("Checking model compatibility…")
                        .accessibilityIdentifier("avatar.importing")
                }
            }
            .sonaCard()
        }
        .fileImporter(isPresented: $presentsImporter, allowedContentTypes: [vrmType]) { result in
            switch result {
            case let .success(url):
                Task { await model.importAvatar(from: url) }
            case let .failure(error):
                model.notice = AppNotice(title: "File not selected", message: error.localizedDescription)
            }
        }
    }
}

private struct AvatarChoiceLabel: View {
    let title: String
    let detail: String
    let systemImage: String
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .accessibilityLabel(isSelected ? "Selected" : "Not selected")
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .sonaCard()
        .accessibilityElement(children: .combine)
    }
}

struct CompatibilityReportView: View {
    let record: AvatarRecord

    var body: some View {
        if record.kind == .demo {
            VStack(alignment: .leading, spacing: 14) {
                InlineStatusView(
                    systemImage: "checkmark.seal.fill",
                    text: "Built-in demo is fully supported"
                )
                Text("Expressions, idle animation, look-at, boop reactions, drag rotation, pinch zoom, and reset controls are available.")
                    .foregroundStyle(.secondary)
            }
            .sonaCard()
            .accessibilityIdentifier("compatibility.demo")
        } else if let report = record.compatibility {
            VStack(alignment: .leading, spacing: 16) {
                InlineStatusView(
                    systemImage: report.outcome == .supported ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                    text: outcomeTitle(report.outcome),
                    tint: report.outcome == .supported ? .green : .orange
                )

                LabeledContent("Model", value: report.modelName ?? report.fileName)
                LabeledContent("VRM version", value: report.vrmVersion.rawValue)
                LabeledContent("File size", value: report.fileSize.formatted(.byteCount(style: .file)))
                LabeledContent("Required bones", value: report.bones.hasRequiredHumanoidBones ? "Present" : "Missing")
                LabeledContent("Spring bones", value: report.hasSpringBones ? "Available" : "Not detected")

                if !report.authors.isEmpty {
                    LabeledContent("Author", value: report.authors.joined(separator: ", "))
                }

                DisclosureGroup("License and permissions") {
                    VStack(alignment: .leading, spacing: 8) {
                        ReportLine(label: "License", value: report.license.licenseName)
                        ReportLine(label: "Credit", value: report.license.credit)
                        ReportLine(label: "Commercial use", value: report.license.commercialUse)
                        ReportLine(label: "Redistribution", value: report.license.redistribution)
                    }
                    .padding(.top, 8)
                }

                let warnings = report.parserWarnings + report.rendererWarnings
                if !warnings.isEmpty {
                    DisclosureGroup("Warnings (\(warnings.count))") {
                        ForEach(warnings, id: \.self) { warning in
                            Label(warning, systemImage: "exclamationmark.triangle")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .sonaCard()
            .accessibilityIdentifier("compatibility.imported")
        } else {
            ContentUnavailableView(
                "No compatibility report",
                systemImage: "doc.text.magnifyingglass",
                description: Text("Choose a VRM file to create a report.")
            )
        }
    }

    private func outcomeTitle(_ outcome: AvatarCompatibilityOutcome) -> String {
        switch outcome {
        case .supported: "Model supported"
        case .supportedWithWarnings: "Supported with warnings"
        case .unsupported: "Model unsupported"
        }
    }
}

private struct ReportLine: View {
    let label: String
    let value: String?

    var body: some View {
        if let value, !value.isEmpty {
            LabeledContent(label, value: value)
        } else {
            LabeledContent(label, value: "Not specified")
                .foregroundStyle(.secondary)
        }
    }
}

@MainActor
struct AvatarManagerView: View {
    @Bindable var model: AppModel
    @State private var confirmsRemoval = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AvatarSourcePicker(model: model)
                CompatibilityReportView(record: model.snapshot.avatar)

                if model.snapshot.avatar.kind == .imported {
                    Button("Remove Imported Avatar", systemImage: "trash", role: .destructive) {
                        confirmsRemoval = true
                    }
                    .buttonStyle(.bordered)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("avatar.remove")
                }
            }
            .padding()
        }
        .navigationTitle("Avatar")
        .confirmationDialog(
            "Remove imported avatar?",
            isPresented: $confirmsRemoval,
            titleVisibility: .visible
        ) {
            Button("Remove Avatar", role: .destructive) {
                Task { await model.removeImportedAvatar() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The imported file will be deleted from SonaPin. The built-in demo will become active.")
        }
    }
}
