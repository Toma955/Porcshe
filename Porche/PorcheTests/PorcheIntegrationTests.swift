import XCTest
import CoreLocation
@testable import Porche

// MARK: - Integration test

final class PorcheIntegrationTests: XCTestCase {

    @MainActor
    func testIntegrationAll() async {
        let statsDefaults = RideStatistics()
        XCTAssertEqual(statsDefaults.live.speedKmh, 0)
        XCTAssertEqual(statsDefaults.live.batteryPercent, 0)
        XCTAssertEqual(statsDefaults.live.rangeKm, 0)
        XCTAssertEqual(statsDefaults.live.assistModeTitle, "")
        XCTAssertEqual(statsDefaults.telemetry.cadenceRpm, 0)
        XCTAssertEqual(statsDefaults.diagnostics.batterySohPercent, 0)

        let statsPlaceholder = RideStatistics.placeholder
        XCTAssertEqual(statsPlaceholder.live.batteryPercent, 87)
        XCTAssertEqual(statsPlaceholder.live.rangeKm, 42)
        XCTAssertEqual(statsPlaceholder.live.assistModeTitle, "Eco")
        XCTAssertEqual(statsPlaceholder.live.gearCurrent, 7)
        XCTAssertEqual(statsPlaceholder.telemetry.cadenceRpm, 72)
        XCTAssertEqual(statsPlaceholder.diagnostics.batterySohPercent, 98)
        XCTAssertEqual(statsPlaceholder.history.caloriesBurned, 420)

        let bat = BatteryStatus(capacityWh: 500, percent: 100, estimatedRangeKm: 99)
        XCTAssertEqual(bat.capacityWh, 500)
        XCTAssertEqual(bat.percent, 100)
        XCTAssertEqual(bat.estimatedRangeKm, 99)

        XCTAssertEqual(AssistMode.eco.displayTitle, "ECO")
        XCTAssertEqual(AssistMode.off.displayTitle, "OFF")

        let step = RouteStepModel(instructionText: "Skrenite lijevo", distanceMeters: 450)
        XCTAssertEqual(step.instructionText, "Skrenite lijevo")
        XCTAssertEqual(step.distanceMeters, 450)

        let id = UUID()
        let waypoints: [CLLocationCoordinate2D] = [
            .init(latitude: 45.81, longitude: 15.97),
            .init(latitude: 45.78, longitude: 15.92)
        ]
        let steps = [RouteStepModel(instructionText: "Krenite", distanceMeters: 1000)]
        let route = RouteModel(id: id, name: "Test", waypoints: waypoints, elevationProfile: [0, 10], steps: steps)
        XCTAssertEqual(route.id, id)
        XCTAssertEqual(route.name, "Test")
        XCTAssertEqual(route.waypoints.count, 2)
        XCTAssertEqual(route.steps.count, 1)

        let waypoints2: [CLLocationCoordinate2D] = [.init(latitude: 0, longitude: 0)]
        let a = RouteModel(id: id, name: "A", waypoints: waypoints2, elevationProfile: [], steps: [])
        let b = RouteModel(id: id, name: "B", waypoints: waypoints2, elevationProfile: [1], steps: [])
        XCTAssertEqual(a, b)

        let demoRoute = DemoRideSimulation.demoRoute
        XCTAssertFalse(demoRoute.waypoints.isEmpty)
        XCTAssertFalse(demoRoute.steps.isEmpty)
        XCTAssertEqual(demoRoute.name, DemoRideSimulation.routeName)
    }
}
