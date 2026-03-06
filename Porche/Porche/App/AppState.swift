import SwiftUI
import CoreLocation
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
    var isNavigationActive: Bool = false
    @Published var activeRoute: RouteModel?
    @Published var batteryStatus: BatteryStatus?
    @Published var assistMode: AssistMode = .eco
    @Published var navigationSpeed: Int = 0
    @Published var navigationGear: Int = 1
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
    @Published var isNightRidingMode: Bool = false
    @Published var motorTempCelsius: Int? = 42
    @Published var batteryTempCelsius: Int? = 28
    @Published var brakeTempCelsius: Int? = 35
    @Published var isCharging: Bool = false
    @Published var minutesToFullCharge: Int? = nil
    @Published var heartRateBPM: Int? = 72
    @Published var rideStatistics: RideStatistics = RideStatistics()
    @Published var saveFolderPath: String = ""
    @Published var isDemoMode: Bool = false
    @Published var devMessages: [DevMessage] = []
    /// When false, central display shows Porche logo until user completes "App" welcome (message + sound + 3D).
    @Published var hasCompletedAppWelcome: Bool = false
    /// When true, island shows "Porche EBike spojen" during App entry sequence.
    @Published var isShowingAppWelcomeMessage: Bool = false
    var demoSimulationTask: Task<Void, Never>?
    private let devMessagesMaxCount = 100

    func addDevMessage(category: DevMessageCategory, _ text: String) {
        let entry = DevMessage(category: category, text: text, date: Date())
        devMessages = Array([entry] + devMessages.prefix(devMessagesMaxCount - 1))
    }

    func clearDevMessages() {
        devMessages = []
    }
}

struct DevMessage: Identifiable {
    let id = UUID()
    let category: DevMessageCategory
    let text: String
    let date: Date
}

enum DevMessageCategory: String, CaseIterable {
    case general = "Općenito"
    case network = "Mreža"
    case bluetooth = "Bluetooth"
    case navigation = "Navigacija"
    case demo = "Demo"
}

enum OnboardingStep {
    case bikeModel
    case welcome
    case permissions
    case completed
}
