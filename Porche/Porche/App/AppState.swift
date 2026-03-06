import SwiftUI
import CoreLocation

// MARK: - AppState

@MainActor
final class AppState: ObservableObject {
    @Published var isAppReady: Bool = false
    @Published var loadingProgress: Double = 0
    var hasPlayedWelcomeSound: Bool = false
    var onboardingStep: OnboardingStep = .completed
    let island = Island()
    @Published var isRouteActive: Bool = false
    var isFindMeMode: Bool = true
    var focusMapOnUserLocationTrigger: Int = 0
    var focusMapOnBikeTrigger: Int = 0
    var isNavigationActive: Bool = false
    @Published var activeRoute: RouteModel?
    @Published var batteryStatus: BatteryStatus? = BatteryStatus(capacityWh: 0, percent: 0, estimatedRangeKm: 0)
    @Published var assistMode: AssistMode = .eco
    @Published var navigationSpeed: Int = 0
    @Published var navigationGear: Int = 12
    @Published var supportLevel: Double = 0.5
    @Published var maxTorqueNm: Double = 50
    @Published var dynamicResponse: Double = 0.3
    @Published var showMapControlsInIsland: Bool = false
    @Published var mapHeading: Double = 0
    @Published var mapCameraDistance: Double = 500
    @Published var mapDarkStyle: Bool = false
    @Published var mapIs3D: Bool = true
    @Published var mapPanningEnabled: Bool = false
    @Published var mapStyle: MapTerrainStyle = .standard
    @Published var mapCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 45.8129, longitude: 15.9775)
    @Published var routeProgressAlongLine: Double = 0
    @Published var mapPivotProgress: Double = 0
    @Published var routeTotalLengthKm: Double = 0
    @Published var routeStartBatteryRangeKm: Double = 0
    @Published var isNightRidingMode: Bool = false
    @Published var motorTempCelsius: Int? = 0
    @Published var batteryTempCelsius: Int? = 0
    @Published var brakeTempCelsius: Int? = 0
    @Published var isCharging: Bool = false
    @Published var minutesToFullCharge: Int? = nil
    @Published var heartRateBPM: Int? = 0
    @Published var rideStatistics: RideStatistics = RideStatistics()
    @Published var saveFolderPath: String = ""
    @Published var isDemoMode: Bool = false
    @Published var devMessages: [DevMessage] = []
    @Published var hasCompletedAppWelcome: Bool = false
    @Published var isShowingAppWelcomeMessage: Bool = false
    @Published var isAppUnlocked: Bool = false
    @Published var isRideStarted: Bool = false
    @Published var isNavigationInUse: Bool = false
    var demoSimulationTask: Task<Void, Never>?
    private let devMessagesMaxCount = 100

    @Published var gearModeSmallValue: Int = 1
    @Published var isAutoGearOn: Bool = false

    @Published var chargingMotorPercent: Double = 0
    @Published var chargingBatteryPercent: Double = 0

    @Published var tripStartedAt: Date?

    @Published var weatherLocationName: String = "Zagreb"
    @Published var weatherCondition: String = "Oblačno"
    @Published var weatherRainInMinutes: Int? = 15
    @Published var weatherTemperatureCelsius: Int = 15

    @Published var motorConsumptionWatts: Int? = nil

    func addDevMessage(category: DevMessageCategory, _ text: String) {
        let entry = DevMessage(category: category, text: text, date: Date())
        devMessages = Array([entry] + devMessages.prefix(devMessagesMaxCount - 1))
    }

    func clearDevMessages() {
        devMessages = []
    }
}
