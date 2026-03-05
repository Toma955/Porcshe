import SwiftUI
import CoreLocation

@MainActor
final class AppState: ObservableObject {
    var onboardingStep: OnboardingStep = .completed
    let island = Island()
    /// Kad true, u centralnom prikazu se pokazuje mapa + bicikl (ptičja perspektiva).
    @Published var isRouteActive: Bool = false
    /// true = prikaz otvoren preko "Nađi me" (crveni Poništi), false = preko "Početak" (zeleni Pokreni navigaciju).
    var isFindMeMode: Bool = true
    /// Kad se poveća, centralni prikaz (mapa) centrira na trenutnu lokaciju korisnika.
    var focusMapOnUserLocationTrigger: Int = 0
    /// Kad true, navigacija je pokrenuta (ruta aktivna).
    var isNavigationActive: Bool = false
    /// Ruta za navigaciju (poligona za prikaz na karti).
    @Published var activeRoute: RouteModel?
    /// Stanje baterije za gornji trak (nil = placeholder vrijednosti).
    @Published var batteryStatus: BatteryStatus?
    /// Mod rada motora za gornji trak.
    @Published var assistMode: AssistMode = .eco
    /// Tijekom navigacije: trenutna brzina (0–99 km/h).
    @Published var navigationSpeed: Int = 0
    /// Tijekom navigacije: stupanj prijenosa (0–99).
    @Published var navigationGear: Int = 1
    /// Support Level: 0...1 (koliko motor pomaže).
    @Published var supportLevel: Double = 0.5
    /// Maximum Torque: 20–85 Nm.
    @Published var maxTorqueNm: Double = 50
    /// Dynamic Response: 0 = Smooth, 1 = Aggressive.
    @Published var dynamicResponse: Double = 0.3

    // MARK: - Kontrole mape (kad se klikne Mapa u islandu)
    /// Kad true, u islandu se prikazuje panel s 3 stupca: topologija | strelice | light/dark.
    @Published var showMapControlsInIsland: Bool = false
    /// Rotacija pogleda mape (stupnjevi, 0 = sjever gore).
    @Published var mapHeading: Double = 0
    /// Udaljenost kamere (zoom); manje = zoom in.
    @Published var mapCameraDistance: Double = 500
    /// true = tamna tema mape.
    @Published var mapDarkStyle: Bool = false
    /// true = 3D prikaz (nagib), false = 2D (pogled odozgora).
    @Published var mapIs3D: Bool = true
    /// Kad true, korisnik može prstom pomicati kartu (diranje i pomicanje).
    @Published var mapPanningEnabled: Bool = false
    /// Tip karte (topologija): standard, satellite, hybrid, flyover.
    @Published var mapStyle: MapTerrainStyle = .standard
    /// Središte kamere mape (za rotaciju i zoom oko ove točke).
    @Published var mapCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 45.8129, longitude: 15.9775)

    /// Vožnja po noći: cijeli island i aplikacija u narančastoj temi (#FF4B33).
    @Published var isNightRidingMode: Bool = false

    /// Statistika vožnje (live dashboard, telemetrija, staza, dijagnostika, povijest, pametni uvidi). Početno prazno (bez podataka).
    @Published var rideStatistics: RideStatistics = RideStatistics()
    /// Mapa (putanja) za spremanje izvještaja / statistike.
    @Published var saveFolderPath: String = ""
}

enum OnboardingStep {
    case bikeModel
    case welcome
    case permissions
    case completed
}
