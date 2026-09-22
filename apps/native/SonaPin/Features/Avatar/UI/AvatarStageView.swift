import RealityKit
import SwiftUI
import simd

struct AvatarTouchReaction: Equatable {
    let expression: AvatarExpression
    let animation: String

    static func reaction(tapCount: Int = 0, includesPlacard: Bool = true) -> Self {
        let expressions: [AvatarExpression] = includesPlacard
            ? [.surprised, .blink, .relaxed, .happy, .neutral]
            : [.surprised, .relaxed, .happy]
        return Self(
            expression: expressions[max(0, tapCount) % expressions.count],
            animation: "reaction"
        )
    }
}

enum DemoBadgeReactionPhase: Int, CaseIterable {
    case idle
    case hiding
    case peeking
    case ducking
    case revealing

    static func phase(tapCount: Int) -> Self {
        allCases[max(0, tapCount) % allCases.count]
    }

    var cardXOffset: CGFloat {
        switch self {
        case .idle, .hiding: 0
        case .peeking: -22
        case .ducking: 6
        case .revealing: 26
        }
    }

    var cardYFraction: CGFloat {
        switch self {
        case .idle: 0.66
        case .hiding, .ducking: 0.34
        case .peeking: 0.43
        case .revealing: 0.72
        }
    }

    var cardRotation: Angle {
        switch self {
        case .peeking: .degrees(-10)
        case .ducking: .degrees(5)
        case .revealing: .degrees(9)
        default: .zero
        }
    }

    func avatarOffset(stageHeight: CGFloat) -> CGFloat {
        switch self {
        case .ducking: min(stageHeight * 0.15, 110)
        case .revealing: -min(stageHeight * 0.025, 18)
        default: 0
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .idle: "Wolf ready"
        case .hiding: "Hiding behind the QR card"
        case .peeking: "Peeking over the QR card"
        case .ducking: "Ducking behind the QR card"
        case .revealing: "Pulling the QR card down"
        }
    }
}

@MainActor
struct AvatarStageHost: View {
    let model: AppModel
    var showsControls = true
    var minimumHeight: CGFloat = 280
    var stageAccessibilityIdentifier: String?

    @State private var importedURL: URL?

    var body: some View {
        Group {
            switch model.snapshot.avatar.kind {
            case .demo:
                AvatarStageView(
                    source: .proceduralDemo,
                    model: model,
                    showsControls: showsControls,
                    minimumHeight: minimumHeight,
                    stageAccessibilityIdentifier: stageAccessibilityIdentifier
                )
                    .id("demo-avatar")
            case .imported:
                if let importedURL {
                    AvatarStageView(
                        source: .imported(fileURL: importedURL),
                        model: model,
                        showsControls: showsControls,
                        minimumHeight: minimumHeight,
                        stageAccessibilityIdentifier: stageAccessibilityIdentifier
                    )
                    .id(model.snapshot.avatar.checksum ?? importedURL.path)
                } else {
                    ProgressView("Loading imported avatar…")
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
    let stageAccessibilityIdentifier: String?

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var renderer: any AvatarRendering
    @State private var loadError: String?
    @State private var isLoaded = false
    @State private var yaw: Float = 0
    @State private var restingYaw: Float = 0
    @State private var zoom: Float = 1
    @State private var restingZoom: Float = 1
    @State private var reactionToken = 0
    @State private var touchCount = 0

    init(
        source: AvatarSource,
        model: AppModel,
        showsControls: Bool = true,
        minimumHeight: CGFloat = 280,
        stageAccessibilityIdentifier: String? = nil
    ) {
        self.source = source
        self.model = model
        self.showsControls = showsControls
        self.minimumHeight = minimumHeight
        self.stageAccessibilityIdentifier = stageAccessibilityIdentifier
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

    private var accessibilityStatus: String {
        guard isLoaded else {
            return loadError.map { "Unavailable. \($0)" } ?? "Loading"
        }
        guard source == .proceduralDemo else {
            return reactionToken == 0 ? "Ready" : "Ready. Reaction \(reactionToken)"
        }
        let reaction = reactionToken == 0 ? "Ready" : "Ready. Reaction \(reactionToken)"
        let qrDescription = hasConfiguredQR
            ? QRPayloadValidator.accessibilityDescription(for: model.snapshot.qrConfiguration)
            : "Demo QR opens the SonaPin website"
        let qrDetail = placardIsVisible ? ". \(qrDescription)" : ""
        return "\(reaction). \(demoReactionPhase.accessibilityDescription)\(qrDetail)"
    }

    private var demoReactionPhase: DemoBadgeReactionPhase {
        DemoBadgeReactionPhase.phase(tapCount: touchCount)
    }

    private var isProceduralDemo: Bool {
        if case .proceduralDemo = source { true } else { false }
    }

    private var placardConfiguration: QRConfiguration {
        if hasConfiguredQR {
            return model.snapshot.qrConfiguration
        }
        return QRConfiguration(
            kind: .website,
            payload: "https://mrdemonwolf.github.io/sonapin/",
            correctionLevel: .medium,
            highContrast: true
        )
    }

    private var hasConfiguredQR: Bool {
        (try? QRPayloadValidator.validate(model.snapshot.qrConfiguration)) != nil
    }

    private var placardIsVisible: Bool {
        demoReactionPhase != .idle || (hasConfiguredQR && !showsControls)
    }

    private var interactionHint: String {
        let tapHint = isProceduralDemo
            ? "Tap to change the expression and move the QR card."
            : "Tap to change the expression."
        return showsControls
            ? "\(tapHint) Use the buttons below for more avatar controls."
            : "\(tapHint) More actions include Reset Avatar."
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                avatarRealityView

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

                if isProceduralDemo && isLoaded {
                    GeometryReader { proxy in
                        AvatarQRPlacard(
                            configuration: placardConfiguration,
                            phase: demoReactionPhase,
                            reducesMotion: reducesMotion,
                            showsAtRest: hasConfiguredQR && !showsControls,
                            stageSize: proxy.size
                        )
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: minimumHeight)
            .clipped()
            .contentShape(.rect)
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        performTapReaction()
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Interactive avatar")
            .accessibilityValue(accessibilityStatus)
            .accessibilityHint(interactionHint)
            .accessibilityIdentifier(
                stageAccessibilityIdentifier ?? (showsControls ? "avatar.stage" : "badge.full-screen.avatar")
            )
            .accessibilityAction(.default) {
                performTapReaction()
            }
            .accessibilityAction(named: Text("Boop Nose")) {
                react(with: .happy, animation: "boop")
            }
            .accessibilityAction(named: Text("Touch Paw")) {
                react(with: .happy, animation: "left-paw")
            }
            .accessibilityAction(named: Text("Tickle")) {
                react(with: .surprised, animation: "wiggle")
            }
            .accessibilityAction(named: Text("Reset Avatar")) {
                resetView()
            }
            .accessibilityAction(named: Text("Rotate Left")) {
                adjustView(yawDelta: -0.2)
            }
            .accessibilityAction(named: Text("Rotate Right")) {
                adjustView(yawDelta: 0.2)
            }
            .accessibilityAction(named: Text("Zoom In")) {
                adjustView(zoomDelta: 0.1)
            }
            .accessibilityAction(named: Text("Zoom Out")) {
                adjustView(zoomDelta: -0.1)
            }

            if showsControls {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        controls
                    }
                    VStack(spacing: 10) {
                        controls
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.sonaNavy)
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

    private var avatarRealityView: some View {
        RealityView { content in
            content.camera = .virtual

            let camera = PerspectiveCamera()
            camera.camera = PerspectiveCameraComponent(fieldOfViewInDegrees: 42)
            camera.look(
                at: SIMD3<Float>(0, 0.95, 0),
                from: SIMD3<Float>(0, 0.95, 3.2),
                relativeTo: nil
            )
            content.add(camera)

            let keyLight = DirectionalLight()
            keyLight.light = DirectionalLightComponent(color: .white, intensity: 3_000)
            keyLight.look(
                at: SIMD3<Float>(0, 0.95, 0),
                from: SIMD3<Float>(1.5, 2.5, 3),
                relativeTo: nil
            )
            content.add(keyLight)

            do {
                try await renderer.load(source)
                content.add(renderer.rootEntity)
                renderer.setExpression(model.snapshot.preferences.defaultExpression, weight: 1)
                if !reducesMotion {
                    try? renderer.play(AvatarAnimation(name: "idle"), looping: true)
                }
                applyTransform()
                loadError = nil
                isLoaded = true
            } catch {
                loadError = error.localizedDescription
                isLoaded = false
            }
        } update: { _ in
            applyTransform()
        } placeholder: {
            ProgressView()
                .accessibilityLabel("Rendering avatar")
                .accessibilityIdentifier("avatar.rendering")
        }
        .offset(
            y: isProceduralDemo
                ? demoReactionPhase.avatarOffset(stageHeight: minimumHeight)
                : 0
        )
        .animation(
            reducesMotion ? nil : .spring(duration: 0.45, bounce: 0.2),
            value: demoReactionPhase
        )
    }

    @ViewBuilder
    private var controls: some View {
        Button("React", systemImage: "sparkles") {
            performTapReaction()
        }
        .frame(minHeight: 44)
        .accessibilityHint("Plays a friendly avatar reaction.")
        .accessibilityIdentifier("avatar.react")

        Button("Happy", systemImage: "face.smiling") {
            react(with: .happy, animation: "happy")
        }
        .frame(minHeight: 44)
        .accessibilityHint("Changes the avatar to a happy expression when supported.")
        .accessibilityIdentifier("avatar.happy")

        Button("Reset", systemImage: "arrow.counterclockwise") {
            resetView()
        }
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

    private func performTapReaction() {
        guard isLoaded else { return }
        let reaction = AvatarTouchReaction.reaction(
            tapCount: touchCount,
            includesPlacard: isProceduralDemo
        )
        let phaseCount = isProceduralDemo ? DemoBadgeReactionPhase.allCases.count : 3
        touchCount = (touchCount + 1) % phaseCount
        react(with: reaction.expression, animation: reaction.animation)
    }

    private func resetView() {
        yaw = 0
        restingYaw = 0
        zoom = 1
        restingZoom = 1
        renderer.resetPose()
        renderer.resetCamera()
        touchCount = 0
        applyTransform()
        reactionToken += 1
    }

    private func adjustView(yawDelta: Float = 0, zoomDelta: Float = 0) {
        yaw = max(-1.5, min(1.5, yaw + yawDelta))
        restingYaw = yaw
        zoom = max(0.75, min(1.6, zoom + zoomDelta))
        restingZoom = zoom
        applyTransform()
    }

    private func applyTransform() {
        renderer.rootEntity.transform.rotation = simd_quatf(angle: yaw, axis: [0, 1, 0])
        renderer.rootEntity.scale = SIMD3<Float>(repeating: zoom)
    }
}

private struct AvatarQRPlacard: View {
    let configuration: QRConfiguration
    let phase: DemoBadgeReactionPhase
    let reducesMotion: Bool
    let showsAtRest: Bool
    let stageSize: CGSize

    var body: some View {
        let cardWidth = min(max(stageSize.width * 0.36, 118), 170)
        let isVisible = phase != .idle || showsAtRest

        ZStack(alignment: .bottom) {
            QRCodeView(configuration: configuration, maximumDimension: cardWidth - 46)
            .padding(8)
            .frame(width: cardWidth)
            .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.sonaNavy, lineWidth: 3)
            }
            .shadow(color: .black.opacity(0.22), radius: 6, y: 3)

            HStack {
                paw
                Spacer()
                paw
            }
            .frame(width: cardWidth + 24)
            .offset(y: 9)
        }
        .position(
            x: (stageSize.width / 2) + phase.cardXOffset,
            y: stageSize.height * phase.cardYFraction
        )
        .rotationEffect(phase.cardRotation)
        .scaleEffect(isVisible ? 1 : 0.88)
        .opacity(isVisible ? 1 : 0)
        .animation(
            reducesMotion ? nil : .spring(duration: 0.45, bounce: 0.2),
            value: phase
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var paw: some View {
        Circle()
            .fill(Color.sonaNavy)
            .frame(width: 28, height: 28)
            .overlay {
                Circle()
                    .fill(Color.sonaCyan)
                    .frame(width: 15, height: 15)
            }
    }
}
