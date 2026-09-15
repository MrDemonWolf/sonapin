import SwiftUI

@MainActor
struct ProfileEditorView: View {
    @Bindable var model: AppModel

    @Environment(\.dismiss) private var dismiss
    @State private var draft: BadgeProfile

    init(model: AppModel) {
        self.model = model
        _draft = State(initialValue: model.snapshot.profile)
    }

    var body: some View {
        Form {
            Section {
                ProfileFields(profile: $draft)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } header: {
                Text("Badge identity")
            } footer: {
                Text("Display name, pronouns, and species are required. Your tagline is optional.")
            }

            Section("Preview") {
                BadgeIdentityView(profile: draft, theme: model.snapshot.theme)
                    .padding(.vertical, 14)
                    .listRowBackground(model.snapshot.theme.primaryColor)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .accessibilityIdentifier("profile.save")
            }
        }
    }

    private func save() {
        do {
            model.snapshot.profile = try ProfileValidator.validate(draft)
            Task { await model.persistNow() }
            model.feedbackToken += 1
            dismiss()
        } catch {
            model.notice = AppNotice(title: "Profile not saved", message: error.localizedDescription)
        }
    }
}

@MainActor
struct QRCodeEditorView: View {
    @Bindable var model: AppModel

    @Environment(\.dismiss) private var dismiss
    @State private var draft: QRConfiguration
    @State private var highContrast: Bool

    init(model: AppModel) {
        self.model = model
        _draft = State(initialValue: model.snapshot.qrConfiguration)
        _highContrast = State(initialValue: model.snapshot.preferences.highContrastQR)
    }

    var body: some View {
        Form {
            Section("QR content") {
                QRConfigurationFields(
                    configuration: $draft,
                    highContrastPreference: $highContrast
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Preview") {
                QRCodeView(configuration: draft, maximumDimension: 340, showsPayload: true)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }

            Section {
                Text("Test the finished code with a separate physical phone before an event. SonaPin validates its format without making a network request.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Edit QR Code")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .accessibilityIdentifier("qr.save")
            }
        }
    }

    private func save() {
        do {
            model.snapshot.qrConfiguration = try QRPayloadValidator.validate(draft)
            model.snapshot.qrConfiguration.highContrast = highContrast
            model.snapshot.preferences.highContrastQR = highContrast
            Task { await model.persistNow() }
            model.feedbackToken += 1
            dismiss()
        } catch {
            model.notice = AppNotice(title: "QR code not saved", message: error.localizedDescription)
        }
    }
}
