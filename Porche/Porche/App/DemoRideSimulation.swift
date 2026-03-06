import Foundation
import CoreLocation
import MapKit

@MainActor
enum DemoRideSimulation {
    static let startName = "Trg bana Jelačića"
    static let destinationName = "Jarun"
    static let routeName = "\(startName) → \(destinationName)"

    static let startCoordinate = CLLocationCoordinate2D(latitude: 45.8132, longitude: 15.9775)
    static let endCoordinate = CLLocationCoordinate2D(latitude: 45.7805, longitude: 15.9234)

    private static let trgBanaJelacica = startCoordinate
    private static let jarun = endCoordinate

    private static var waypoints: [CLLocationCoordinate2D] {
        [
            trgBanaJelacica,
            CLLocationCoordinate2D(latitude: 45.8118, longitude: 15.9740),
            CLLocationCoordinate2D(latitude: 45.8095, longitude: 15.9685),
            CLLocationCoordinate2D(latitude: 45.8065, longitude: 15.9600),
            CLLocationCoordinate2D(latitude: 45.8030, longitude: 15.9500),
            CLLocationCoordinate2D(latitude: 45.7990, longitude: 15.9400),
            CLLocationCoordinate2D(latitude: 45.7940, longitude: 15.9320),
            CLLocationCoordinate2D(latitude: 45.7890, longitude: 15.9280),
            CLLocationCoordinate2D(latitude: 45.7840, longitude: 15.9255),
            jarun
        ]
    }

    private static var steps: [RouteStepModel] {
        [
            RouteStepModel(instructionText: "Krenite prema jugozapadu", distanceMeters: 450),
            RouteStepModel(instructionText: "Nastavite ravno Savskom", distanceMeters: 1200),
            RouteStepModel(instructionText: "Skrenite lijevo prema Jarunu", distanceMeters: 800),
            RouteStepModel(instructionText: "Stigli ste na odredište – Jarun", distanceMeters: 0)
        ]
    }

    static var demoRoute: RouteModel {
        RouteModel(
            id: UUID(),
            name: routeName,
            waypoints: waypoints,
            elevationProfile: (0..<waypoints.count).map { _ in Double.random(in: 118...125) },
            steps: steps
        )
    }

    static func startSimulation(appState: AppState, durationMinutes: Int = 20) {
        appState.demoSimulationTask?.cancel()
        let durationSeconds = Double(durationMinutes) * 60
        let updatesPerSecond = 15.0
        let tickIntervalNanoseconds: UInt64 = 66_666_666
        let totalTicks = Int(durationSeconds * updatesPerSecond)
        let progressPerTick = 1.0 / Double(totalTicks)

        let task = Task { @MainActor in
            appState.routeProgressAlongLine = 0
            appState.navigationSpeed = 18
            appState.navigationGear = 4
            let startBatteryPercent = appState.batteryStatus?.percent ?? 100
            let startRangeKm = appState.batteryStatus?.estimatedRangeKm ?? 50

            for tick in 0..<totalTicks {
                if Task.isCancelled { break }
                let progress = min(1.0, Double(tick) * progressPerTick)
                appState.routeProgressAlongLine = progress
                if tick % 6 == 0 {
                    appState.navigationSpeed = 16 + Int(progress * 10) + (tick % 5) - 2
                    appState.navigationSpeed = min(28, max(12, appState.navigationSpeed))
                    appState.navigationGear = 3 + Int(progress * 4.5)
                    appState.navigationGear = min(8, max(2, appState.navigationGear))
                    let batteryDrop = Int(progress * Double(100 - startBatteryPercent + 8))
                    let percent = max(0, startBatteryPercent - batteryDrop)
                    let rangeKm = max(5, startRangeKm * Double(percent) / Double(max(1, startBatteryPercent)))
                    appState.batteryStatus = BatteryStatus(capacityWh: 500, percent: percent, estimatedRangeKm: rangeKm)
                }
                try? await Task.sleep(nanoseconds: tickIntervalNanoseconds)
            }

            appState.routeProgressAlongLine = 1.0
            appState.demoSimulationTask = nil
        }
        appState.demoSimulationTask = task
    }
}
