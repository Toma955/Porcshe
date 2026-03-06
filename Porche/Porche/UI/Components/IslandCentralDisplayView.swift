import SwiftUI
import MapKit
import CoreLocation
private let trgBanaJelacica = CLLocationCoordinate2D(latitude: 45.8129, longitude: 15.9775)
private let defaultCameraDistance: CGFloat = 650
private struct MapCenterValue: Equatable {
    let latitude: Double
    let longitude: Double
    init(_ coordinate: CLLocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }
}
private let userLocationCameraDistance: CGFloat = 500
private let mapBikeWidth: CGFloat = 212
private let mapBikeHeight: CGFloat = 192
private let normalBikeWidth: CGFloat = 520
private let normalBikeHeight: CGFloat = 500
private let routeTransitionDuration: Double = 0.28
private let bikeSpring = Animation.spring(response: 0.32, dampingFraction: 0.84)
private struct GhostBikeItem: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
    let opacity: Double
    let angle: Double
}
private func coordinate(at progress: Double, along waypoints: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
    guard waypoints.count >= 2, progress >= 0, progress <= 1 else { return waypoints.first }
    var total: Double = 0
    var lengths: [Double] = []
    for i in 0..<(waypoints.count - 1) {
        let a = CLLocation(latitude: waypoints[i].latitude, longitude: waypoints[i].longitude)
        let b = CLLocation(latitude: waypoints[i + 1].latitude, longitude: waypoints[i + 1].longitude)
        let d = a.distance(from: b)
        lengths.append(d)
        total += d
    }
    if total == 0 { return waypoints[0] }
    let target = progress * total
    var acc: Double = 0
    for i in 0..<lengths.count {
        if acc + lengths[i] >= target {
            let t = lengths[i] > 0 ? (target - acc) / lengths[i] : 0
            let lat = waypoints[i].latitude + t * (waypoints[i + 1].latitude - waypoints[i].latitude)
            let lon = waypoints[i].longitude + t * (waypoints[i + 1].longitude - waypoints[i].longitude)
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        acc += lengths[i]
    }
    return waypoints.last
}
private func routeBearing(at progress: Double, along waypoints: [CLLocationCoordinate2D]) -> Double {
    guard waypoints.count >= 2 else { return 0 }
    let eps = 0.02
    let p1 = progress - eps
    let p2 = progress + eps
    guard let c1 = coordinate(at: max(0, p1), along: waypoints),
          let c2 = coordinate(at: min(1, p2), along: waypoints) else { return 0 }
    let lat1 = c1.latitude * .pi / 180
    let lon1 = c1.longitude * .pi / 180
    let lat2 = c2.latitude * .pi / 180
    let lon2 = c2.longitude * .pi / 180
    let dLon = lon2 - lon1
    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    var deg = atan2(y, x) * 180 / .pi
    if deg < 0 { deg += 360 }
    return deg
}

private let bikeModelForwardOffset: Double = 0
struct IslandCentralDisplayView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager
    @State private var isBikeSceneReady = false
    @State private var homeBikeKey = 0
    @State private var mapCameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 45.8129, longitude: 15.9775),
            distance: 500,
            heading: 0,
            pitch: 60
        )
    )
    private var cameraFromAppState: MapCameraPosition {
        .camera(
            MapCamera(
                centerCoordinate: appState.mapCenter,
                distance: appState.mapCameraDistance,
                heading: appState.mapHeading,
                pitch: appState.mapIs3D ? 60 : 0
            )
        )
    }

    var body: some View {
        contentWithLayout
            .modifier(IslandCentralMapModifier(
                onSync: syncMapPositionFromAppState,
                onRequestLocation: requestFreshLocationForFindMe,
                onCenter: centerCamera(on:),
                onFitRoute: fitCameraToRoute,
                isLocationValid: isLocationValidForMap
            ))
            .onChange(of: appState.routeProgressAlongLine) { _, progress in
                guard let route = appState.activeRoute, !route.waypoints.isEmpty,
                      let pos = coordinate(at: progress, along: route.waypoints) else { return }
                appState.mapCenter = pos
                syncMapPositionFromAppState()
            }
            .onChange(of: appState.isRouteActive) { _, active in
                if !active { homeBikeKey += 1 }
            }
    }
    private var contentWithLayout: some View {
        mainZStack
            .animation(.easeInOut(duration: routeTransitionDuration), value: appState.isRouteActive)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.primary.opacity(0.25), lineWidth: 1)
            )
    }
    private var mainZStack: some View {
        ZStack {
            mapOrBackgroundView
            bikeOverlayView
        }
        .id(appState.isRouteActive)
    }
    @ViewBuilder
    private var mapOrBackgroundView: some View {
        if appState.isRouteActive {
            ZStack {
                mapView
                if !appState.mapPanningEnabled {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                }
            }
            .preferredColorScheme(appState.mapDarkStyle ? .dark : .light)
            .transition(.opacity.animation(.easeInOut(duration: routeTransitionDuration)))
        } else {
            Color.white
                .transition(.opacity.animation(.easeInOut(duration: routeTransitionDuration)))
        }
    }
    private let welcomeTransitionDuration: Double = 0.5

    @ViewBuilder
    private var bikeOverlayView: some View {
        let routeHasWaypoints = (appState.activeRoute?.waypoints.isEmpty ?? true) == false
        ZStack {
            if appState.isRouteActive {
                VStack(spacing: 0) {
                    if !routeHasWaypoints {
                        Spacer(minLength: 0)
                        bikeView(width: mapBikeWidth, height: mapBikeHeight, findMeMode: true)
                        Spacer(minLength: 0)
                    }
                }
                .animation(bikeSpring, value: appState.isRouteActive)
            } else {
                ZStack {
                    Color.white
                        .ignoresSafeArea()
                    VStack(spacing: 0) {
                        Spacer(minLength: 12)
                        bikeView(width: normalBikeWidth, height: normalBikeHeight, findMeMode: false)
                            .id(homeBikeKey)
                            .opacity(appState.hasCompletedAppWelcome ? 1 : 0)
                        Spacer(minLength: 60)
                    }
                    Image("Porche")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 220, maxHeight: 220)
                        .opacity(appState.hasCompletedAppWelcome ? 0 : 1)
                        .allowsHitTesting(false)
                }
                .animation(.easeOut(duration: welcomeTransitionDuration), value: appState.hasCompletedAppWelcome)
            }
        }
        .allowsHitTesting(!appState.mapPanningEnabled)
    }
    private func syncMapPositionFromAppState() {
        mapCameraPosition = cameraFromAppState
    }
    private func ghostBikeItems(route: RouteModel, progress: Double) -> [GhostBikeItem] {
        let waypoints = route.waypoints
        guard waypoints.count >= 2 else { return [] }
        let heading = appState.mapHeading
        var items: [GhostBikeItem] = []
        if let pos1 = coordinate(at: progress, along: waypoints) {
            let angle1 = routeBearing(at: progress, along: waypoints) - heading + bikeModelForwardOffset
            items.append(GhostBikeItem(id: 0, coordinate: pos1, opacity: 0.7, angle: angle1))
        }
        let progress2 = min(1, progress + 0.08)
        if progress < 1, let pos2 = coordinate(at: progress2, along: waypoints) {
            let angle2 = routeBearing(at: progress2, along: waypoints) - heading + bikeModelForwardOffset
            items.append(GhostBikeItem(id: 1, coordinate: pos2, opacity: 0.4, angle: angle2))
        }
        return items
    }
    @MapContentBuilder
    private func mainBikeOnRoute(route: RouteModel) -> some MapContent {
        let progress = appState.routeProgressAlongLine
        let waypoints = route.waypoints
        if waypoints.count >= 2,
           let pos = coordinate(at: progress, along: waypoints) {
            let bearing = routeBearing(at: progress, along: waypoints)
            let bikeAngle = bearing - appState.mapHeading + bikeModelForwardOffset
            Annotation("", coordinate: pos) {
                routeBike3D(size: 148, opacity: 0.82, angle: bikeAngle)
            }
        }
    }
    private func routeBike3D(size: CGFloat, opacity: Double, angle: Double) -> some View {
        Bike3DSceneView(rotationSpeed: 0, isFindMeMode: true)
            .frame(width: size, height: size)
            .opacity(opacity)
            .rotationEffect(.degrees(angle))
    }

    private func ghostBikeMarker(opacity: Double, angle: Double) -> some View {
        routeBike3D(size: 72, opacity: opacity * 0.88, angle: angle)
    }
    private var mapView: AnyView {
        switch appState.mapStyle {
        case .standard:
            return AnyView(mapWithBinding.mapStyle(.standard(elevation: .realistic)))
        case .satellite:
            return AnyView(mapWithBinding.mapStyle(.imagery(elevation: .realistic)))
        case .hybrid:
            return AnyView(mapWithBinding.mapStyle(.hybrid(elevation: .realistic)))
        case .flyover:
            return AnyView(mapWithBinding.mapStyle(.standard(elevation: .realistic)))
        }
    }
    private var mapWithBinding: some View {
        Map(position: $mapCameraPosition) {
            UserAnnotation()
            if let route = appState.activeRoute, !route.waypoints.isEmpty {
                MapPolyline(coordinates: route.waypoints)
                    .stroke(.blue, lineWidth: 6)
                ForEach(ghostBikeItems(route: route, progress: appState.routeProgressAlongLine)) { item in
                    Annotation("", coordinate: item.coordinate) {
                        ghostBikeMarker(opacity: item.opacity, angle: item.angle)
                    }
                }
                if let bikeCoord = coordinate(at: appState.routeProgressAlongLine, along: route.waypoints) {
                    let bearing = routeBearing(at: appState.routeProgressAlongLine, along: route.waypoints)
                    let angleDegrees = bearing - appState.mapHeading + bikeModelForwardOffset
                    let angleRounded = (angleDegrees / 5).rounded() * 5
                    Annotation("", coordinate: bikeCoord) {
                        routeBike3D(size: 148, opacity: 0.82, angle: angleRounded)
                            .frame(width: 148, height: 148)
                            .allowsHitTesting(false)
                            .id("main-route-bike")
                    }
                }
            }
        }
        .onMapCameraChange(frequency: .onEnd) { context in
                    appState.mapCenter = context.camera.centerCoordinate
                    appState.mapCameraDistance = context.camera.distance
                    appState.mapHeading = context.camera.heading
                }
    }
    private func fitCameraToRoute(_ waypoints: [CLLocationCoordinate2D]) {
        guard waypoints.count >= 2 else { return }
        let lats = waypoints.map(\.latitude)
        let lons = waypoints.map(\.longitude)
        let minLat = lats.min() ?? 0, maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0, maxLon = lons.max() ?? 0
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = max(maxLat - minLat, maxLon - minLon) * 1.4
        let delta = max(span, 0.02)
        let distance = Double( delta * 111_000 * 2.5 )
        withAnimation(.easeInOut(duration: 0.4)) {
            appState.mapCenter = center
            appState.mapCameraDistance = min(2000, max(300, distance))
            appState.mapHeading = 0
        }
    }
    @ViewBuilder
    private func bikeView(width: CGFloat, height: CGFloat, findMeMode: Bool) -> some View {
        ZStack {
            Bike3DSceneView(rotationSpeed: findMeMode ? 0 : 0.5, isFindMeMode: findMeMode) {
                DispatchQueue.main.async { isBikeSceneReady = true }
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            if !isBikeSceneReady {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground).opacity(0.9))
                    .overlay(ProgressView())
                    .frame(width: width, height: height)
            }
        }
        .transition(.opacity.animation(bikeSpring))
    }
    private func requestFreshLocationForFindMe() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
    }
    private func isLocationValidForMap(_ location: CLLocation) -> Bool {
        let coord = location.coordinate
        guard CLLocationCoordinate2DIsValid(coord) else { return false }
        guard abs(coord.latitude) > 0.0001, abs(coord.longitude) > 0.0001 else { return false }
        return true
    }
    private func centerCamera(on coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.35)) {
            appState.mapCenter = coordinate
            appState.mapCameraDistance = userLocationCameraDistance
            appState.mapHeading = 0
        }
    }
}
private struct IslandCentralMapModifier: ViewModifier {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager
    let onSync: () -> Void
    let onRequestLocation: () -> Void
    let onCenter: (CLLocationCoordinate2D) -> Void
    let onFitRoute: ([CLLocationCoordinate2D]) -> Void
    let isLocationValid: (CLLocation) -> Bool
    func body(content: Content) -> some View {
        let withLocation = addLocationHandlers(content)
        let withRoute = addRouteHandlers(withLocation)
        return addMapSyncHandlers(withRoute)
    }
    private func addLocationHandlers<V: View>(_ view: V) -> some View {
        view
            .onChange(of: appState.focusMapOnUserLocationTrigger) { _, _ in
                onRequestLocation()
            }
            .onChange(of: locationManager.currentLocation) { _, newLocation in
                if appState.focusMapOnUserLocationTrigger > 0, let loc = newLocation, isLocationValid(loc) {
                    onCenter(loc.coordinate)
                    locationManager.stopUpdatingLocation()
                }
            }
    }
    private func addRouteHandlers<V: View>(_ view: V) -> some View {
        view
            .onChange(of: appState.activeRoute) { _, newRoute in
                if let route = newRoute, !route.waypoints.isEmpty {
                    appState.mapCenter = route.waypoints[0]
                    appState.mapCameraDistance = 420
                    appState.mapHeading = 0
                    appState.routeProgressAlongLine = 0
                    DispatchQueue.main.async { onSync() }
                }
            }
            .onChange(of: appState.isRouteActive) { _, active in
                if active { onSync() }
            }
    }
    private func addMapSyncHandlers<V: View>(_ view: V) -> some View {
        view
            .onChange(of: MapCenterValue(appState.mapCenter)) { _, _ in onSync() }
            .onChange(of: appState.mapCameraDistance) { _, _ in onSync() }
            .onChange(of: appState.mapHeading) { _, _ in onSync() }
            .onChange(of: appState.mapIs3D) { _, _ in onSync() }
    }
}
#Preview {
    IslandCentralDisplayView()
        .environmentObject(AppState())
        .environmentObject(LocationManager())
}
