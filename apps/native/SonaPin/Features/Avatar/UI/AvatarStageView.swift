import RealityKit
import SwiftUI
import simd

@MainActor
struct AvatarStageHost: View {
    let model: AppModel
    var showsControls = true
    var minimumHeight: CGFloat = 280

    @State private var importedURL: URL?

    var body: some View {
        Group {
            switch model.snapshot.avatar.kind {
            case .demo:
                AvatarStageView(
                    source: .proceduralDemo,
                    model: model,
                    showsControls: showsControls,
                    minimumHeight: minimumHeight
                )
                    .id("demo-avatar")
            case .imported:
                if let importedURL {
                    AvatarStageView(
                        source: .imported(fileURL: importedURL),
                        model: model,
                        showsControls: showsControls,
                        minimumHeight: minimumHeight
                    )
                    .id(model.snapshot.avatar.checksum ?? importedURL.path)
                } else {
                    ProgressView("Loading imported avatar…")
                        .tint(.sonaCyan)
                        .frame(maxWidth: .infinity, minHeight: minimumHeight)
                        .accessibilityIdentifier("avatar.loading")
                }
            }
        }
        .task(id: model.snapshot.avatar.checksum) {
            importedURL = model.snapshot.avatar.kind == .imported
                ? await model.currentImportedAvatarURL()
                : nil
        }
    }
}

@MainActor
struct AvatarStageView: View {
    let source: AvatarSource
    let model: AppModel
    let showsControls: Bool
    let minimumHeight: CGFloat

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var renderer: any AvatarRendering
    @State private var loadError: String?
    @State private var yaw: Float = 0
    @State private var restingYaw: Float = 0
    @State private var zoom: Float = 1
    @State private var restingZoom: Float = 1
    @State private var reactionToken = 0

    init(
        source: AvatarSource,
        model: AppModel,
        showsControls: Bool = true,
        minimumHeight: CGFloat = 280
    ) {
        self.source = source
        self.model = model
        self.showsControls = showsControls
        self.minimumHeight = minimumHeight
        let initialRenderer: any AvatarRendering
        switch source {
        case .proceduralDemo:
            initialRenderer = ProceduralDemoAvatarRenderer()
        case .imported:
            initialRenderer = VRMKitAvatarRenderer()
        }
        _renderer = State(initialValue: initialRenderer)
    }

    private var reducesMotion: Bool {
        systemReduceMotion || model.snapshot.preferences.reduceMotion
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RealityView { content in
                    do {
                        try await renderer.load(source)
                        content.add(renderer.rootEntity)
                        renderer.setExpression(model.snapshot.preferences.defaultExpression, weight: 1)
                        if !reducesMotion {
                            try? renderer.play(AvatarAnimation(name: "idle"), looping: true)
                        }
                        applyTransform()
                        loadError = nil
                    } catch {
                        loadError = error.localizedDescription
                    }
                } update: { _ in
                    applyTransform()
                } placeholder: {
                    ProgressView()
                        .tint(.sonaCyan)
                }

                if let loadError {
                    ContentUnavailableView(
                        "Avatar unavailable",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text(loadError)
                    )
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(.rect(cornerRadius: 16))
                }
            }
            .frame(maxWidth: .infinity, minHeight: minimumHeight)
            .contentShape(.rect)
            .highPriorityGesture(
                TapGesture(count: 2).onEnded {
                    resetView()
                }
            )
            .simultaneousGesture(
                TapGesture().onEnded {
                    react(with: .surprised, animation: "reaction")
                }
            )
            .simultaneousGesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        guard value.entity.name == "SonaPinHeadHitTarget" else { return }
                        react(with: .happy, animation: "boop")
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        let sensitivity = Float(model.snapshot.preferences.interactionSensitivity)
                        yaw = max(
                            -1.5,
                            min(1.5, restingYaw + Float(value.translation.width / 160) * sensitivity)
                        )
                        renderer.look(
                            at: SIMD3<Float>(
                                Float(value.translation.width / 180),
                                -Float(value.translation.height / 180),
                                1
                            )
                        )
                        applyTransform()
                    }
                    .onEnded { _ in
                        restingYaw = yaw
                        renderer.look(at: nil)
                    }
            )
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        zoom = max(0.75, min(1.6, restingZoom * Float(value.magnification)))
                        applyTransform()
                    }
                    .onEnded { _ in
                        restingZoom = zoom
                    }
            )
            .accessibilityLabel("Interactive avatar")
            .accessibilityHint("Double tap for a friendly reaction. Use the buttons below for accessible avatar controls.")
            .accessibilityIdentifier("avatar.stage")

            if showsControls {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        controls
                    }
                    VStack(spacing: 10) {
                        controls
                    }
                }
            }
        }
        .onChange(of: model.cameraResetToken) { _, _ in
            resetView()
        }
        .onChange(of: model.expressionRequestToken) { _, _ in
            react(with: model.requestedExpression, animation: model.requestedExpression == .happy ? "happy" : "reaction")
        }
        .onChange(of: model.snapshot.preferences.defaultExpression) { _, expression in
            renderer.setExpression(expression, weight: 1)
        }
        .onChange(of: reducesMotion) { _, isReduced in
            if isReduced {
                renderer.resetPose()
            } else {
                try? renderer.play(AvatarAnimation(name: "idle"), looping: true)
            }
        }
        .sensoryFeedback(trigger: reactionToken) { _, _ in
            model.snapshot.preferences.hapticsEnabled && !systemReduceMotion ? .selection : nil
        }
    }

    @ViewBuilder
    private var controls: some View {
        Button("React", systemImage: "sparkles") {
            react(with: .surprised, animation: "reaction")
        }
        .buttonStyle(.bordered)
        .frame(minHeight: 44)
        .accessibilityHint("Plays a friendly avatar reaction.")
        .accessibilityIdentifier("avatar.react")

        Button("Happy", systemImage: "face.smiling") {
            react(with: .happy, animation: "happy")
        }
        .buttonStyle(.bordered)
        .frame(minHeight: 44)
        .accessibilityHint("Changes the avatar to a happy expression when supported.")
        .accessibilityIdentifier("avatar.happy")

        Button("Reset", systemImage: "arrow.counterclockwise") {
            resetView()
        }
        .buttonStyle(.bordered)
        .frame(minHeight: 44)
        .accessibilityHint("Restores the avatar pose, rotation, and zoom.")
        .accessibilityIdentifier("avatar.reset")
    }

    private func react(with expression: AvatarExpression, animation: String) {
        renderer.setExpression(expression, weight: 1)
        if !reducesMotion {
            try? renderer.play(AvatarAnimation(name: animation), looping: false)
        }
        reactionToken += 1
    }

    private func resetView() {
        yaw = 0
        restingYaw = 0
        zoom = 1
        restingZoom = 1
        renderer.resetPose()
        renderer.resetCamera()
        applyTransform()
        reactionToken += 1
    }

    private func applyTransform() {
        renderer.rootEntity.transform.rotation = simd_quatf(angle: yaw, axis: [0, 1, 0])
        renderer.rootEntity.scale = SIMD3<Float>(repeating: zoom)
    }
}
