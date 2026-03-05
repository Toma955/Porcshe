import SwiftUI
import UIKit

/// Ikone iz Assets.xcassets/Icons. Ako PNG nije u bundleu, koristi se SF Symbol.
enum AppIcons {
    static let route = "Route"
    static let graph = "Graph"
    static let bike = "Bike"
    static let settings = "Settings"
    static let backArrow = "BackArrow"
    static let start = "Start"
    static let island = "Island"
    static let moon = "Moon"
    static let paths = "Paths"

    /// Navigacijske strelice (Resources/Icons/Navigation → Assets).
    static let turnLeft = "TurnLeft"
    static let turnRight = "TurnRight"
    static let forward = "Forward"
    static let turnBack = "TurnBack"
    static let compass = "Compass"

    /// Dijelovi bicikla (Resources/Icons/parts) – za prikaz kad korisnik klikne na Bike.
    enum Part: String, CaseIterable {
        case oil
        case brake
        case service
        case wheels
        case gears
        case suspension
        case batery
        case engine
        case link
        var displayName: String {
            switch self {
            case .oil: return "Ulje"
            case .brake: return "Kočnice"
            case .service: return "Servis"
            case .wheels: return "Kotači"
            case .gears: return "Mjenjač"
            case .suspension: return "Ovjes"
            case .batery: return "Baterija"
            case .engine: return "Elektromotor"
            case .link: return "Lanac"
            }
        }
    }

    /// Točna imena u folderu: oil, brake, service, wheels, gears, suspension, batery, engine, link (.png)
    private static let partsRelPaths = [
        "Resources/Icons/parts",
        "Porche/Resources/Icons/parts",
        "Icons/parts",
        "parts",
    ]

    /// Ikona dijela (template) – učitava iz bundlea; nikad UIImage(named:) da ne ide u asset catalog i ne logira grešku.
    static func imagePart(_ part: Part) -> Image {
        let name = part.rawValue
        let bundle = Bundle.main
        let base = bundle.bundlePath as NSString
        for rel in partsRelPaths {
            let path = base.appendingPathComponent("\(rel)/\(name).png")
            if FileManager.default.fileExists(atPath: path), let ui = UIImage(contentsOfFile: path) {
                return Image(uiImage: ui).renderingMode(.template)
            }
        }
        let subdirs: [String?] = ["Resources/Icons/parts", "Icons/parts", "parts", nil]
        for subdir in subdirs {
            if let p = bundle.path(forResource: name, ofType: "png", inDirectory: subdir),
               let ui = UIImage(contentsOfFile: p) {
                return Image(uiImage: ui).renderingMode(.template)
            }
        }
        return Image(systemName: "wrench.and.screwdriver").renderingMode(.template)
    }

    /// SF Symbol fallback kad asset ne postoji.
    enum Symbol {
        static let route = "map"
        static let graph = "chart.bar"
        static let bike = "bicycle"
        static let settings = "gearshape"
        static let backArrow = "chevron.left"
        static let start = "flag.fill"
        static let island = "square.roundedbottomhalf.filled"
        static let moon = "moon.fill"
        static let paths = "point.topleft.down.curvedto.point.bottomright.up"
        static let turnLeft = "arrow.turn.up.left"
        static let turnRight = "arrow.turn.up.right"
        static let forward = "arrow.up"
        static let turnBack = "arrow.uturn.backward"
        static let compass = "location.north.fill"
    }

    /// Vraća sliku iz Assets ili SF Symbol ako asset ne postoji (nazivi točno: Route, Graph, Bike, Settings, BackArrow).
    /// Asset ikone se vraćaju kao template da primaju boju iz .foregroundStyle() (npr. bijelu na crnom islandu).
    static func image(route: String = route, symbol: String) -> Image {
        if UIImage(named: route) != nil {
            return Image(route).renderingMode(.template)
        }
        return Image(systemName: symbol)
    }

    static var imageRoute: Image { image(route: route, symbol: Symbol.route) }
    static var imageGraph: Image { image(route: graph, symbol: Symbol.graph) }
    static var imageBike: Image { image(route: bike, symbol: Symbol.bike) }
    static var imageSettings: Image { image(route: settings, symbol: Symbol.settings) }
    static var imageBackArrow: Image { image(route: backArrow, symbol: Symbol.backArrow) }
    static var imageStart: Image { image(route: start, symbol: Symbol.start) }
    static var imageIsland: Image { image(route: island, symbol: Symbol.island) }
    static var imageMoon: Image { image(route: moon, symbol: Symbol.moon) }
    static var imagePaths: Image { image(route: paths, symbol: Symbol.paths) }
    static var imageTurnLeft: Image { image(route: turnLeft, symbol: Symbol.turnLeft) }
    static var imageTurnRight: Image { image(route: turnRight, symbol: Symbol.turnRight) }
    static var imageForward: Image { image(route: forward, symbol: Symbol.forward) }
    static var imageTurnBack: Image { image(route: turnBack, symbol: Symbol.turnBack) }
    static var imageCompass: Image { image(route: compass, symbol: Symbol.compass) }
}

extension Image {
    static let iconRoute = AppIcons.imageRoute
    static let iconGraph = AppIcons.imageGraph
    static let iconBike = AppIcons.imageBike
    static let iconSettings = AppIcons.imageSettings
    static let iconBackArrow = AppIcons.imageBackArrow
}
