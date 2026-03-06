import SwiftUI
import SceneKit
private final class SceneCache {
    static let shared = SceneCache()
    var scene: SCNScene?
    private init() {}
}
struct Bike3DSceneView: UIViewRepresentable {
    var rotationSpeed: Double = 0.3
    var isFindMeMode: Bool = false
    var onSceneLoaded: (() -> Void)?
    func makeCoordinator() -> Coordinator {
        Coordinator(rotationSpeed: rotationSpeed, isFindMeMode: isFindMeMode, onSceneLoaded: onSceneLoaded)
    }
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
        sceneView.antialiasingMode = .none
        sceneView.isPlaying = false
        let coordinator = context.coordinator
        coordinator.sceneView = sceneView
        if Thread.isMainThread {
            Self.applySceneSync(coordinator: coordinator, sceneView: sceneView)
        } else {
            DispatchQueue.main.async {
                Self.applySceneSync(coordinator: coordinator, sceneView: sceneView)
            }
        }
        return sceneView
    }
    private static func applySceneSync(coordinator: Coordinator, sceneView: SCNView) {
        if let cached = SceneCache.shared.scene {
            sceneView.scene = cached
            coordinator.applyRotation(to: sceneView.scene?.rootNode, speed: coordinator.rotationSpeed)
            if coordinator.isFindMeMode {
                coordinator.applyFindMeCamera(to: sceneView)
            } else {
                coordinator.applyDefaultCamera(to: sceneView)
            }
            sceneView.isPlaying = true
            coordinator.onSceneLoaded?()
            return
        }
        sceneView.scene = SCNScene()
        guard let url = Self.bikeSceneURL() else {
            coordinator.onSceneLoaded?()
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let scene: SCNScene?
            do {
                scene = try SCNScene(url: url, options: nil)
            } catch {
                scene = nil
            }
            DispatchQueue.main.async {
                guard let loaded = scene else {
                    coordinator.onSceneLoaded?()
                    return
                }
                Self.disableSubdivision(in: loaded.rootNode)
                SceneCache.shared.scene = loaded
                guard coordinator.sceneView != nil else { return }
                coordinator.sceneView?.scene = loaded
                coordinator.applyRotation(to: coordinator.sceneView?.scene?.rootNode, speed: coordinator.rotationSpeed)
                if let view = coordinator.sceneView {
                    if coordinator.isFindMeMode {
                        coordinator.applyFindMeCamera(to: view)
                    } else {
                        coordinator.applyDefaultCamera(to: view)
                    }
                }
                coordinator.sceneView?.isPlaying = true
                coordinator.onSceneLoaded?()
            }
        }
    }
    func updateUIView(_ uiView: SCNView, context: Context) {
        let changed = context.coordinator.rotationSpeed != rotationSpeed
            || context.coordinator.isFindMeMode != isFindMeMode
        context.coordinator.rotationSpeed = rotationSpeed
        context.coordinator.isFindMeMode = isFindMeMode
        context.coordinator.onSceneLoaded = onSceneLoaded
        let sceneValid = uiView.scene != nil && !(uiView.scene?.rootNode.childNodes.isEmpty ?? true)
        if !sceneValid {
            Self.applySceneSync(coordinator: context.coordinator, sceneView: uiView)
            return
        }
        if changed {
            context.coordinator.applyRotation(to: uiView.scene?.rootNode, speed: rotationSpeed)
            if isFindMeMode {
                context.coordinator.applyFindMeCamera(to: uiView)
            } else {
                context.coordinator.applyDefaultCamera(to: uiView)
                uiView.isPlaying = true
            }
        }
    }
    private static func disableSubdivision(in node: SCNNode) {
        if let geom = node.geometry {
            geom.subdivisionLevel = 0
        }
        for child in node.childNodes {
            disableSubdivision(in: child)
        }
    }
    private static func bikeSceneURL() -> URL? {
        let candidates: [(subdir: String?, name: String)] = [
            ("Resources/3DModels", "Porche_Ebike"),
            ("Porche/Resources/3DModels", "Porche_Ebike"),
            ("3DModels", "Porche_Ebike"),
            (nil, "Porche_Ebike"),
        ]
        for (subdir, name) in candidates {
            if let url = Bundle.main.url(forResource: name, withExtension: "usdz", subdirectory: subdir) {
                return url
            }
        }
        return nil
    }

    static func preloadScene(completion: @escaping () -> Void) {
        if SceneCache.shared.scene != nil {
            DispatchQueue.main.async { completion() }
            return
        }
        guard let url = bikeSceneURL() else {
            DispatchQueue.main.async { completion() }
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let scene: SCNScene?
            do {
                scene = try SCNScene(url: url, options: nil)
            } catch {
                scene = nil
            }
            DispatchQueue.main.async {
                if let loaded = scene {
                    disableSubdivision(in: loaded.rootNode)
                    SceneCache.shared.scene = loaded
                }
                completion()
            }
        }
    }
    private static let defaultCameraPosition = SCNVector3(0, 1.2, 3.2)
    final class Coordinator {
        var rotationSpeed: Double
        var isFindMeMode: Bool
        weak var sceneView: SCNView?
        var onSceneLoaded: (() -> Void)?
        var findMeCameraNode: SCNNode?
        var defaultCameraNode: SCNNode?
        init(rotationSpeed: Double, isFindMeMode: Bool = false, onSceneLoaded: (() -> Void)?) {
            self.rotationSpeed = rotationSpeed
            self.isFindMeMode = isFindMeMode
            self.onSceneLoaded = onSceneLoaded
        }
        func nodesToRotate(from root: SCNNode?) -> [SCNNode] {
            guard let root = root else { return [] }
            if root.geometry != nil { return [root] }
            if !root.childNodes.isEmpty { return root.childNodes }
            return [root]
        }
        func applyRotation(to node: SCNNode?, speed: Double) {
            guard Thread.isMainThread else {
                DispatchQueue.main.async { [weak self] in
                    self?.applyRotation(to: node, speed: speed)
                }
                return
            }
            guard let root = node else { return }
            let targets = nodesToRotate(from: root)
            guard !targets.isEmpty else { return }
            let action: SCNAction? = isFindMeMode ? nil : SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: CGFloat(speed), z: 0, duration: 1)
            )
            for target in targets {
                target.removeAction(forKey: "rotate")
                if isFindMeMode {
                    target.eulerAngles = SCNVector3(0, 0, 0)
                } else {
                    target.eulerAngles = SCNVector3(0, 0, 0)
                    if let action = action { target.runAction(action, forKey: "rotate") }
                }
            }
        }
        func applyDefaultCamera(to view: SCNView) {
            guard let scene = view.scene else { return }
            let pos = Bike3DSceneView.defaultCameraPosition
            if let existing = defaultCameraNode, existing.parent != nil {
                existing.position = pos
                existing.camera?.fieldOfView = 42
                view.pointOfView = existing
                return
            }
            let cam = SCNNode()
            cam.camera = SCNCamera()
            cam.position = pos
            cam.look(at: SCNVector3(0, 0, 0))
            cam.camera?.usesOrthographicProjection = false
            cam.camera?.fieldOfView = 42
            scene.rootNode.addChildNode(cam)
            view.pointOfView = cam
            defaultCameraNode = cam
        }
        func applyFindMeCamera(to view: SCNView) {
            guard let scene = view.scene else { return }
            if findMeCameraNode?.parent != nil {
                view.pointOfView = findMeCameraNode
                return
            }
            let cam = SCNNode()
            cam.camera = SCNCamera()
            cam.position = SCNVector3(0, 8, 0)
            cam.look(at: SCNVector3(0, 0, 0))
            cam.camera?.usesOrthographicProjection = false
            cam.camera?.fieldOfView = 50
            scene.rootNode.addChildNode(cam)
            view.pointOfView = cam
            findMeCameraNode = cam
        }
    }
}
