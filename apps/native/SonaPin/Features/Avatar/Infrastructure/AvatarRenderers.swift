import Foundation
import RealityKit
import UIKit
import VRMKit
import VRMRealityKit

enum AvatarRendererError: Error, Equatable, LocalizedError, Sendable {
    case unsupportedSource
    case avatarNotLoaded
    case animationUnavailable(String)
    case modelLoadFailed

    var errorDescription: String? {
        switch self {
        case .unsupportedSource:
            "This renderer cannot load the selected avatar source."
        case .avatarNotLoaded:
            "Load an avatar before trying that interaction."
        case let .animationUnavailable(name):
            "The avatar does not include an animation named \(name)."
        case .modelLoadFailed:
            "The avatar could not be rendered. The previous avatar is still available."
        }
    }
}

@MainActor
enum VRMKitRenderValidator {
    /// Builds the complete RealityKit scene while the candidate is still staged.
    static func validate(model: VRM) async throws {
        let loader = VRMEntityLoader(vrm: model)
        _ = try await loader.loadEntity()
        try Task.checkCancellation()
    }
}

struct DemoAvatarMotionComponent: Component {
    var elapsed: TimeInterval = 0
    var idleEnabled = false
    var reactionDuration: TimeInterval = 0
    var reactionRemaining: TimeInterval = 0
    var reactionTilt: Float = 0
    var reactionWiggles: Float = 1
    var baseTransform: Transform = .identity
}

private struct DemoAvatarMotionSystem: System {
    private static let query = EntityQuery(where: .has(DemoAvatarMotionComponent.self))

    init(scene: Scene) {}

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var motion = entity.components[DemoAvatarMotionComponent.self] else { continue }
            motion.elapsed += context.deltaTime

            let idleOffset: Float = motion.idleEnabled ? Float(sin(motion.elapsed * 1.7)) * 0.018 : 0
            let idleTilt: Float = motion.idleEnabled ? Float(sin(motion.elapsed * 0.85)) * 0.018 : 0
            var reactionScale: Float = 1
            var reactionTilt: Float = 0
            if motion.reactionRemaining > 0, motion.reactionDuration > 0 {
                let progress = 1 - (motion.reactionRemaining / motion.reactionDuration)
                reactionScale += Float(sin(progress * .pi)) * 0.08
                reactionTilt = Float(sin(progress * .pi * Double(motion.reactionWiggles))) * motion.reactionTilt
                motion.reactionRemaining = max(0, motion.reactionRemaining - context.deltaTime)
            }

            entity.position = motion.baseTransform.translation + SIMD3<Float>(0, idleOffset, 0)
            entity.orientation = motion.baseTransform.rotation
                * simd_quatf(angle: idleTilt + reactionTilt, axis: SIMD3<Float>(0, 0, 1))
            entity.scale = motion.baseTransform.scale * SIMD3<Float>(repeating: reactionScale)
            entity.components.set(motion)
        }
    }
}

@MainActor private let registerAvatarMotionRuntime: Void = {
    DemoAvatarMotionComponent.registerComponent()
    DemoAvatarMotionSystem.registerSystem()
}()

@MainActor
private func playFallbackMotion(_ animation: AvatarAnimation, on entity: Entity) throws {
    guard var motion = entity.components[DemoAvatarMotionComponent.self] else {
        throw AvatarRendererError.avatarNotLoaded
    }

    switch animation.name.lowercased() {
    case "idle":
        motion.idleEnabled = true
    case "left-paw":
        (motion.reactionDuration, motion.reactionRemaining, motion.reactionTilt, motion.reactionWiggles) = (0.55, 0.55, 0.16, 1)
    case "right-paw":
        (motion.reactionDuration, motion.reactionRemaining, motion.reactionTilt, motion.reactionWiggles) = (0.55, 0.55, -0.16, 1)
    case "wiggle":
        (motion.reactionDuration, motion.reactionRemaining, motion.reactionTilt, motion.reactionWiggles) = (0.7, 0.7, 0.12, 4)
    case "boop", "happy", "reaction", "tap":
        (motion.reactionDuration, motion.reactionRemaining, motion.reactionTilt, motion.reactionWiggles) = (0.65, 0.65, 0, 1)
    default:
        throw AvatarRendererError.animationUnavailable(animation.name)
    }
    entity.components.set(motion)
}

@MainActor
private func resetFallbackMotion(on entity: Entity) {
    guard var motion = entity.components[DemoAvatarMotionComponent.self] else { return }
    motion.elapsed = 0
    motion.idleEnabled = false
    motion.reactionDuration = 0
    motion.reactionRemaining = 0
    motion.reactionTilt = 0
    motion.reactionWiggles = 1
    entity.transform = motion.baseTransform
    entity.components.set(motion)
}

@MainActor
private func addHitTarget(
    named name: String,
    shape: ShapeResource,
    position: SIMD3<Float> = .zero,
    to parent: Entity
) {
    let target = Entity()
    target.name = name
    target.position = position
    target.components.set(InputTargetComponent())
    target.components.set(CollisionComponent(shapes: [shape]))
    parent.addChild(target)
}

private struct PreparedVRMModel: Sendable {
    let vrm: VRM
    let report: AvatarCompatibilityReport
}

private actor VRMModelPreparer {
    func prepare(fileURL: URL) throws -> PreparedVRMModel {
        try Task.checkCancellation()
        let model = try VRMKitModelValidator.parse(fileURL: fileURL)
        let report = try VRMCompatibilityInspector.inspect(fileURL: fileURL, checksum: "")
        try Task.checkCancellation()
        return PreparedVRMModel(vrm: model, report: report)
    }
}

/// Original geometric animal avatar used when no user-owned VRM is available.
@MainActor
final class ProceduralDemoAvatarRenderer: AvatarRendering {
    let rootEntity: Entity
    let capabilities: AvatarCapabilities = .proceduralDemo

    private var motionEntity: Entity?
    private var leftEye: ModelEntity?
    private var rightEye: ModelEntity?
    private var leftPupil: ModelEntity?
    private var rightPupil: ModelEntity?
    private var mouth: ModelEntity?
    private var leftEar: ModelEntity?
    private var rightEar: ModelEntity?

    init() {
        _ = registerAvatarMotionRuntime
        let root = Entity()
        root.name = "SonaPinDemoRoot"
        rootEntity = root
    }

    func load(_ source: AvatarSource) async throws {
        guard source == .proceduralDemo else { throw AvatarRendererError.unsupportedSource }
        try Task.checkCancellation()

        let rig = Self.makeRig()
        try Task.checkCancellation()

        removeChildren(from: rootEntity)
        rootEntity.transform = .identity
        rootEntity.addChild(rig.motion)
        motionEntity = rig.motion
        leftEye = rig.leftEye
        rightEye = rig.rightEye
        leftPupil = rig.leftPupil
        rightPupil = rig.rightPupil
        mouth = rig.mouth
        leftEar = rig.leftEar
        rightEar = rig.rightEar
    }

    func unload() {
        removeChildren(from: rootEntity)
        motionEntity = nil
        leftEye = nil
        rightEye = nil
        leftPupil = nil
        rightPupil = nil
        mouth = nil
        leftEar = nil
        rightEar = nil
    }

    func setExpression(_ expression: AvatarExpression, weight: Float) {
        guard let leftEye, let rightEye, let mouth, let leftEar, let rightEar else { return }
        let weight = weight.isFinite ? min(max(weight, 0), 1) : 0

        leftEye.scale = SIMD3<Float>(0.09, 0.12, 0.04)
        rightEye.scale = SIMD3<Float>(0.09, 0.12, 0.04)
        mouth.scale = SIMD3<Float>(0.13, 0.035, 0.025)
        leftEar.orientation = simd_quatf(angle: -0.18, axis: SIMD3<Float>(0, 0, 1))
        rightEar.orientation = simd_quatf(angle: 0.18, axis: SIMD3<Float>(0, 0, 1))

        switch expression {
        case .neutral:
            break
        case .happy:
            mouth.scale.y += 0.045 * weight
            leftEar.orientation *= simd_quatf(angle: -0.18 * weight, axis: SIMD3<Float>(0, 0, 1))
            rightEar.orientation *= simd_quatf(angle: 0.18 * weight, axis: SIMD3<Float>(0, 0, 1))
        case .surprised:
            leftEye.scale *= SIMD3<Float>(repeating: 1 + (0.18 * weight))
            rightEye.scale *= SIMD3<Float>(repeating: 1 + (0.18 * weight))
            mouth.scale = SIMD3<Float>(0.07, 0.07 + (0.035 * weight), 0.025)
        case .relaxed:
            leftEye.scale.y *= 1 - (0.5 * weight)
            rightEye.scale.y *= 1 - (0.5 * weight)
        case .blink:
            leftEye.scale.y *= max(0.08, 1 - (0.92 * weight))
            rightEye.scale.y *= max(0.08, 1 - (0.92 * weight))
        }
    }

    func play(_ animation: AvatarAnimation, looping: Bool) throws {
        guard let motionEntity else { throw AvatarRendererError.avatarNotLoaded }
        try playFallbackMotion(animation, on: motionEntity)
    }

    func look(at target: SIMD3<Float>?) {
        guard let leftPupil, let rightPupil else { return }
        let x = target.map { min(max($0.x * 0.012, -0.026), 0.026) } ?? 0
        let y = target.map { min(max($0.y * 0.008, -0.02), 0.02) } ?? 0
        leftPupil.position = SIMD3<Float>(x, y, 0.055)
        rightPupil.position = SIMD3<Float>(x, y, 0.055)
    }

    func resetPose() {
        guard let motionEntity else { return }
        resetFallbackMotion(on: motionEntity)
        setExpression(.neutral, weight: 1)
        look(at: nil)
    }

    func resetCamera() {
        rootEntity.transform = .identity
    }

    private struct Rig {
        let motion: Entity
        let leftEye: ModelEntity
        let rightEye: ModelEntity
        let leftPupil: ModelEntity
        let rightPupil: ModelEntity
        let mouth: ModelEntity
        let leftEar: ModelEntity
        let rightEar: ModelEntity
    }

    private static func makeRig() -> Rig {
        let navy = material(red: 0.035, green: 0.082, blue: 0.20, roughness: 0.62)
        let cyan = material(red: 0.06, green: 0.68, blue: 0.93, roughness: 0.45)
        let light = material(red: 0.86, green: 0.96, blue: 1, roughness: 0.7)
        let dark = material(red: 0.012, green: 0.025, blue: 0.06, roughness: 0.5)
        let pink = material(red: 0.95, green: 0.34, blue: 0.54, roughness: 0.58)

        let motion = Entity()
        motion.name = "SonaPinDemoMotion"
        motion.components.set(DemoAvatarMotionComponent())

        let body = sphere(
            name: "SonaPinBodyHitTarget",
            radius: 0.5,
            material: navy,
            position: SIMD3<Float>(0, 0.72, 0),
            scale: SIMD3<Float>(0.72, 1.0, 0.56)
        )
        body.components.set(InputTargetComponent())
        body.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.5)]))
        motion.addChild(body)

        let belly = sphere(
            name: "Belly",
            radius: 0.35,
            material: cyan,
            position: SIMD3<Float>(0, 0.70, 0.29),
            scale: SIMD3<Float>(0.68, 0.9, 0.16)
        )
        motion.addChild(belly)

        let head = sphere(
            name: "Head",
            radius: 0.46,
            material: navy,
            position: SIMD3<Float>(0, 1.48, 0),
            scale: SIMD3<Float>(1, 0.92, 0.9)
        )
        motion.addChild(head)

        let leftEar = box(
            name: "LeftEar",
            size: 0.34,
            material: cyan,
            position: SIMD3<Float>(-0.28, 0.34, -0.04),
            scale: SIMD3<Float>(0.7, 1.25, 0.35)
        )
        leftEar.orientation = simd_quatf(angle: -0.18, axis: SIMD3<Float>(0, 0, 1))
        head.addChild(leftEar)

        let rightEar = box(
            name: "RightEar",
            size: 0.34,
            material: cyan,
            position: SIMD3<Float>(0.28, 0.34, -0.04),
            scale: SIMD3<Float>(0.7, 1.25, 0.35)
        )
        rightEar.orientation = simd_quatf(angle: 0.18, axis: SIMD3<Float>(0, 0, 1))
        head.addChild(rightEar)

        let muzzle = sphere(
            name: "Muzzle",
            radius: 0.25,
            material: light,
            position: SIMD3<Float>(0, -0.10, 0.34),
            scale: SIMD3<Float>(1.15, 0.68, 0.7)
        )
        head.addChild(muzzle)

        let leftEye = sphere(
            name: "LeftEye",
            radius: 1,
            material: light,
            position: SIMD3<Float>(-0.16, 0.09, 0.37),
            scale: SIMD3<Float>(0.09, 0.12, 0.04)
        )
        let rightEye = sphere(
            name: "RightEye",
            radius: 1,
            material: light,
            position: SIMD3<Float>(0.16, 0.09, 0.37),
            scale: SIMD3<Float>(0.09, 0.12, 0.04)
        )
        head.addChild(leftEye)
        head.addChild(rightEye)

        let leftPupil = sphere(
            name: "LeftPupil",
            radius: 0.045,
            material: dark,
            position: SIMD3<Float>(0, 0, 0.055)
        )
        let rightPupil = sphere(
            name: "RightPupil",
            radius: 0.045,
            material: dark,
            position: SIMD3<Float>(0, 0, 0.055)
        )
        leftEye.addChild(leftPupil)
        rightEye.addChild(rightPupil)

        let nose = sphere(
            name: "SonaPinHeadHitTarget",
            radius: 0.12,
            material: dark,
            position: SIMD3<Float>(0, -0.05, 0.52),
            scale: SIMD3<Float>(1.1, 0.78, 0.7)
        )
        nose.components.set(InputTargetComponent())
        nose.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.14)]))
        head.addChild(nose)

        let mouth = sphere(
            name: "Mouth",
            radius: 1,
            material: pink,
            position: SIMD3<Float>(0, -0.23, 0.43),
            scale: SIMD3<Float>(0.13, 0.035, 0.025)
        )
        head.addChild(mouth)

        for (name, x) in [("LeftArm", -0.48 as Float), ("RightArm", 0.48 as Float)] {
            let arm = sphere(
                name: name,
                radius: 0.22,
                material: navy,
                position: SIMD3<Float>(x, 0.75, 0),
                scale: SIMD3<Float>(0.62, 1.35, 0.62)
            )
            motion.addChild(arm)
        }
        for (name, x) in [("LeftPaw", -0.23 as Float), ("RightPaw", 0.23 as Float)] {
            let paw = sphere(
                name: name == "LeftPaw" ? "SonaPinLeftPawHitTarget" : "SonaPinRightPawHitTarget",
                radius: 0.25,
                material: cyan,
                position: SIMD3<Float>(x, 0.15, 0.02),
                scale: SIMD3<Float>(0.75, 1.15, 0.9)
            )
            paw.components.set(InputTargetComponent())
            paw.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.25)]))
            motion.addChild(paw)
        }

        let tail = sphere(
            name: "Tail",
            radius: 0.3,
            material: cyan,
            position: SIMD3<Float>(0.48, 0.54, -0.22),
            scale: SIMD3<Float>(0.55, 1.4, 0.55)
        )
        tail.orientation = simd_quatf(angle: -0.58, axis: SIMD3<Float>(0, 0, 1))
        motion.addChild(tail)

        return Rig(
            motion: motion,
            leftEye: leftEye,
            rightEye: rightEye,
            leftPupil: leftPupil,
            rightPupil: rightPupil,
            mouth: mouth,
            leftEar: leftEar,
            rightEar: rightEar
        )
    }

    private static func sphere(
        name: String,
        radius: Float,
        material: SimpleMaterial,
        position: SIMD3<Float>,
        scale: SIMD3<Float> = .one
    ) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateSphere(radius: radius), materials: [material])
        entity.name = name
        entity.position = position
        entity.scale = scale
        return entity
    }

    private static func box(
        name: String,
        size: Float,
        material: SimpleMaterial,
        position: SIMD3<Float>,
        scale: SIMD3<Float>
    ) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateBox(size: size), materials: [material])
        entity.name = name
        entity.position = position
        entity.scale = scale
        return entity
    }

    private static func material(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        roughness: Float
    ) -> SimpleMaterial {
        SimpleMaterial(
            color: UIColor(red: red, green: green, blue: blue, alpha: 1),
            roughness: .float(roughness),
            isMetallic: false
        )
    }
}

/// The only app boundary that turns VRMKit parser output into RealityKit entities.
@MainActor
final class VRMKitAvatarRenderer: AvatarRendering {
    let rootEntity: Entity
    private(set) var capabilities: AvatarCapabilities = []

    private let modelPreparer = VRMModelPreparer()
    private var avatarEntity: VRMEntity?
    private var restTransforms: [ObjectIdentifier: Transform] = [:]

    init() {
        _ = registerAvatarMotionRuntime
        let root = Entity()
        root.name = "SonaPinImportedAvatarRoot"
        rootEntity = root
    }

    func load(_ source: AvatarSource) async throws {
        guard case let .imported(fileURL) = source else {
            throw AvatarRendererError.unsupportedSource
        }

        do {
            try Task.checkCancellation()
            let prepared = try await modelPreparer.prepare(fileURL: fileURL)
            let loader = VRMEntityLoader(vrm: prepared.vrm)
            let candidate = try await loader.loadEntity()
            try Task.checkCancellation()
            let candidateCapabilities = Self.capabilities(for: candidate, report: prepared.report)

            if candidateCapabilities.contains(.headHitTarget), let head = candidate.humanoid.node(for: .head) {
                addHitTarget(named: "SonaPinHeadHitTarget", shape: .generateSphere(radius: 0.13), to: head)
            }
            if let chest = candidate.humanoid.node(for: .chest) ?? candidate.humanoid.node(for: .upperChest) {
                addHitTarget(named: "SonaPinBodyHitTarget", shape: .generateSphere(radius: 0.2), to: chest)
            }
            if let leftHand = candidate.humanoid.node(for: .leftHand) {
                addHitTarget(named: "SonaPinLeftPawHitTarget", shape: .generateSphere(radius: 0.09), to: leftHand)
            }
            if let rightHand = candidate.humanoid.node(for: .rightHand) {
                addHitTarget(named: "SonaPinRightPawHitTarget", shape: .generateSphere(radius: 0.09), to: rightHand)
            }

            Self.prepareForPresentation(candidate)
            candidate.components.set(DemoAvatarMotionComponent(baseTransform: candidate.transform))
            let candidateRestTransforms = Self.captureTransforms(in: candidate)
            avatarEntity?.stopAnimations()
            removeChildren(from: rootEntity)
            rootEntity.transform = .identity
            rootEntity.addChild(candidate)
            avatarEntity = candidate
            restTransforms = candidateRestTransforms
            capabilities = candidateCapabilities
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as AvatarRendererError {
            throw error
        } catch {
            throw AvatarRendererError.modelLoadFailed
        }
    }

    func unload() {
        avatarEntity?.stopAnimations()
        removeChildren(from: rootEntity)
        avatarEntity = nil
        restTransforms = [:]
        capabilities = []
    }

    func setExpression(_ expression: AvatarExpression, weight: Float) {
        guard let avatarEntity, capabilities.contains(.expressions) else { return }
        let weight = weight.isFinite ? min(max(weight, 0), 1) : 0
        let available = avatarEntity.availableExpressions
        let direct = available.first {
            $0.preset?.rawValue.caseInsensitiveCompare(expression.rawValue) == .orderedSame
        }
        let selected = direct ?? AvatarExpressionFallback
            .select(preferred: expression, available: available.map(\.name))
            .flatMap { fallback in
                available.first { $0.name.caseInsensitiveCompare(fallback) == .orderedSame }
            }
        guard let selected else { return }
        avatarEntity.setExpression(value: CGFloat(weight), for: selected.key)
    }

    func play(_ animation: AvatarAnimation, looping: Bool) throws {
        guard let avatarEntity else { throw AvatarRendererError.avatarNotLoaded }
        if let match = avatarEntity.animations.first(where: {
            $0.name?.caseInsensitiveCompare(animation.name) == .orderedSame
        }) {
            try avatarEntity.playAnimation(at: match.index, loops: looping)
        } else {
            try playFallbackMotion(animation, on: avatarEntity)
        }
    }

    func look(at target: SIMD3<Float>?) {
        guard capabilities.contains(.lookAt) else { return }
        avatarEntity?.lookAtTarget = target.map { .position($0) }
    }

    func resetPose() {
        guard let avatarEntity else { return }
        avatarEntity.stopAnimations()
        Self.restoreTransforms(in: avatarEntity, from: restTransforms)
        resetFallbackMotion(on: avatarEntity)
        avatarEntity.invalidateSkinPose()
        let neutralWeights = Dictionary(
            uniqueKeysWithValues: avatarEntity.availableExpressions.map { ($0.key, CGFloat.zero) }
        )
        avatarEntity.setExpressions(neutralWeights)
        avatarEntity.lookAtTarget = nil
        avatarEntity.resetSpringBones()
    }

    func resetCamera() {
        rootEntity.transform = .identity
    }

    private static func capabilities(
        for entity: VRMEntity,
        report: AvatarCompatibilityReport
    ) -> AvatarCapabilities {
        var capabilities: AvatarCapabilities = []
        if !entity.availableExpressions.isEmpty { capabilities.insert(.expressions) }
        if !entity.animations.isEmpty { capabilities.insert(.animation) }
        if supportsLookAt(entity: entity, mode: report.lookAtMode) { capabilities.insert(.lookAt) }
        if report.hasSpringBones { capabilities.insert(.springBones) }
        if entity.humanoid.node(for: .head) != nil { capabilities.insert(.headHitTarget) }
        return capabilities
    }

    private static func supportsLookAt(entity: VRMEntity, mode: String?) -> Bool {
        switch mode?.lowercased() {
        case "bone":
            return entity.humanoid.node(for: .leftEye) != nil || entity.humanoid.node(for: .rightEye) != nil
        case "expression", "blendshape":
            let gazePresets = Set(["lookup", "lookdown", "lookleft", "lookright"])
            return entity.availableExpressions.contains {
                guard let name = $0.preset?.rawValue.lowercased() else { return false }
                return gazePresets.contains(name)
            }
        default:
            return false
        }
    }

    private static func prepareForPresentation(_ avatar: VRMEntity) {
        if avatar.frontDirection.z < 0 {
            avatar.transform.rotation = simd_quatf(angle: .pi, axis: SIMD3(0, 1, 0))
                * avatar.transform.rotation
        }

        lowerArm(.leftUpperArm, toward: .leftLowerArm, in: avatar)
        lowerArm(.rightUpperArm, toward: .rightLowerArm, in: avatar)
        avatar.invalidateSkinPose()
        avatar.resetSpringBones()
    }

    private static func lowerArm(
        _ upperBone: HumanoidBone,
        toward lowerBone: HumanoidBone,
        in avatar: VRMEntity
    ) {
        guard let upperArm = avatar.humanoid.node(for: upperBone),
              let lowerArm = avatar.humanoid.node(for: lowerBone),
              let parent = upperArm.parent else { return }

        let horizontalDirection = lowerArm.position(relativeTo: avatar).x
            - upperArm.position(relativeTo: avatar).x
        guard abs(horizontalDirection) > 0.001 else { return }

        let angle = copysign(40 * .pi / 180, -horizontalDirection)
        let normalizedDelta = simd_quatf(angle: angle, axis: SIMD3(0, 0, 1))
        let parentRestRotation = parent.orientation(relativeTo: avatar)
        let boneRestRotation = upperArm.orientation(relativeTo: avatar)
        upperArm.transform.rotation = parentRestRotation.inverse * normalizedDelta * boneRestRotation
    }

    private static func captureTransforms(in root: Entity) -> [ObjectIdentifier: Transform] {
        var transforms: [ObjectIdentifier: Transform] = [:]
        visit(root) { transforms[ObjectIdentifier($0)] = $0.transform }
        return transforms
    }

    private static func restoreTransforms(
        in root: Entity,
        from transforms: [ObjectIdentifier: Transform]
    ) {
        visit(root) { entity in
            if let transform = transforms[ObjectIdentifier(entity)] {
                entity.transform = transform
            }
        }
    }

    private static func visit(_ entity: Entity, body: (Entity) -> Void) {
        body(entity)
        for child in entity.children {
            visit(child, body: body)
        }
    }
}

@MainActor
private func removeChildren(from entity: Entity) {
    for child in entity.children {
        child.removeFromParent()
    }
}
