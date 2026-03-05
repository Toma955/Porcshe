import SwiftUI
import SceneKit
import os

private let logger = Logger(subsystem: "TomaPrivate.Porche", category: "Bike3DSceneView")

/// Cache učitane scene (samo main thread). ~22 MB USDZ se učitava asinkrono da ne blokira UI.
private final class SceneCache {
    static let shared = SceneCache()
    var scene: SCNScene?
    private init() {}
}

struct Bike3DSceneView: UIViewRepresentable {
    var rotationSpeed: Double = 0.3
    /// Kad true: rotacija stane, ptičja perspektiva (sjedalo + volan), volan prema gore.
    var isFindMeMode: Bool = false
    /// Poziva se na main thread kad je scena postavljena (ili odmah ako je iz cachea).
    var onSceneLoaded: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(rotationSpeed: rotationSpeed, isFindMeMode: isFindMeMode, onSceneLoaded: onSceneLoaded)
    }

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
        // .none da izbjegnemo velike Metal buffere; subdivizija iz USDZ već prelazi 256 MB
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

    /// Na main thread: ako imamo cache, postavi scenu odmah; inače kreni asinkrono učitavanje.
    private static func applySceneSync(coordinator: Coordinator, sceneView: SCNView) {
        AppDebugLog.shared.log("Bike3DSceneView makeUIView – provjeravam cache")

        if let cached = SceneCache.shared.scene {
            AppDebugLog.shared.log("3D OK – scena iz cachea")
            sceneView.scene = cached
            coordinator.applyRotation(to: sceneView.scene?.rootNode, speed: coordinator.rotationSpeed)
            if coordinator.isFindMeMode, let view = coordinator.sceneView {
                coordinator.applyFindMeCamera(to: view)
            }
            sceneView.isPlaying = true
            coordinator.onSceneLoaded?()
            return
        }

        sceneView.scene = SCNScene()
        guard let url = Self.bikeSceneURL() else {
            let msg = "3D NIJE PRONAĐEN – nema URL u bundleu (Porche_Ebike.usdz)"
            AppDebugLog.shared.log(msg)
            print("[Porche] GREŠKA: \(msg)")
            coordinator.onSceneLoaded?()
            return
        }

        AppDebugLog.shared.log("3D učitavanje u pozadini...")
        DispatchQueue.global(qos: .userInitiated).async {
            let scene: SCNScene?
            do {
                scene = try SCNScene(url: url, options: nil)
            } catch {
                let errMsg = "Učitavanje USDZ failed: \(error)"
                logger.error("\(errMsg)")
                AppDebugLog.shared.log("3D GREŠKA – \(error.localizedDescription)")
                print("[Porche] GREŠKA 3D: \(errMsg)")
                scene = nil
            }
            DispatchQueue.main.async {
                guard let loaded = scene else {
                    AppDebugLog.shared.log("3D GREŠKA – učitavanje nije uspjelo")
                    print("[Porche] GREŠKA: 3D učitavanje nije uspjelo")
                    coordinator.onSceneLoaded?()
                    return
                }
                // Isključi GPU subdiviziju da Metal buffer ne pređe 256 MB (inace crash)
                Self.disableSubdivision(in: loaded.rootNode)
                SceneCache.shared.scene = loaded
                guard coordinator.sceneView != nil else { return }
                coordinator.sceneView?.scene = loaded
                coordinator.applyRotation(to: coordinator.sceneView?.scene?.rootNode, speed: coordinator.rotationSpeed)
                if coordinator.isFindMeMode, let view = coordinator.sceneView {
                    coordinator.applyFindMeCamera(to: view)
                }
                coordinator.sceneView?.isPlaying = true
                AppDebugLog.shared.log("3D OK – scena učitana u pozadini")
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
        guard let scene = uiView.scene, !scene.rootNode.childNodes.isEmpty else { return }
        if changed {
            context.coordinator.applyRotation(to: uiView.scene?.rootNode, speed: rotationSpeed)
            if isFindMeMode {
                context.coordinator.applyFindMeCamera(to: uiView)
            }
        }
    }

    /// Rekurzivno isključi subdiviziju na svim geometrijama da Metal buffer ne pređe 256 MB.
    private static func disableSubdivision(in node: SCNNode) {
        if let geom = node.geometry {
            geom.subdivisionLevel = 0
        }
        for child in node.childNodes {
            disableSubdivision(in: child)
        }
    }

    /// Vraća URL modela (poziv na main thread, brzo). Putanja: Porche/Resources/3DModels/Porche_Ebike.usdz
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

    /// Euler kuti za ptičju perspektivu: sjedalo i volan vidljivi, volan prema gore.
    /// x: -90° da se vidi odozgora; y: 0 (podesi na Float.pi/2 ili -Float.pi/2 ako volan nije gore).
    private static let findMeEuler = SCNVector3(-Float.pi / 2, 0, 0)

    final class Coordinator {
        var rotationSpeed: Double
        var isFindMeMode: Bool
        weak var sceneView: SCNView?
        var onSceneLoaded: (() -> Void)?
        var findMeCameraNode: SCNNode?

        init(rotationSpeed: Double, isFindMeMode: Bool = false, onSceneLoaded: (() -> Void)?) {
            self.rotationSpeed = rotationSpeed
            self.isFindMeMode = isFindMeMode
            self.onSceneLoaded = onSceneLoaded
        }

        func applyRotation(to node: SCNNode?, speed: Double) {
            guard Thread.isMainThread else {
                DispatchQueue.main.async { [weak self] in
                    self?.applyRotation(to: node, speed: speed)
                }
                return
            }
            guard let node = node else { return }
            node.removeAction(forKey: "rotate")
            if isFindMeMode {
                node.eulerAngles = Bike3DSceneView.findMeEuler
            } else {
                node.eulerAngles = SCNVector3(0, 0, 0)
                let action = SCNAction.repeatForever(
                    SCNAction.rotateBy(x: 0, y: CGFloat(speed), z: 0, duration: 1)
                )
                node.runAction(action, forKey: "rotate")
            }
        }

        /// Kamera iznad bicikla (ptičja perspektiva), gleda prema dolje. pointOfView je na SCNView.
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
