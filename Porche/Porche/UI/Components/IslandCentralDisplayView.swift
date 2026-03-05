import SwiftUI
import MapKit
import CoreLocation

private let trgBanaJelacica = CLLocationCoordinate2D(latitude: 45.8129, longitude: 15.9775)
private let defaultCameraDistance: CGFloat = 650
private let userLocationCameraDistance: CGFloat = 500
private let mapBikeWidth: CGFloat = 212
private let mapBikeHeight: CGFloat = 192
private let normalBikeWidth: CGFloat = 220
private let normalBikeHeight: CGFloat = 200
private let routeTransitionDuration: Double = 0.28
private let bikeSpring = Animation.spring(response: 0.32, dampingFraction: 0.84)

struct IslandCentralDisplayView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager
    @State private var isBikeSceneReady = false
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

    @ViewBuilder
    private var bikeOverlayView: some View {
        VStack(spacing: 0) {
            if appState.isRouteActive {
                Spacer(minLength: 0)
                bikeView(width: mapBikeWidth, height: mapBikeHeight, findMeMode: true)
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 16)
                bikeView(width: normalBikeWidth, height: normalBikeHeight, findMeMode: false)
                Spacer(minLength: 220)
            }
        }
        .animation(bikeSpring, value: appState.isRouteActive)
    }

    private func syncMapPositionFromAppState() {
        mapCameraPosition = cameraFromAppState
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
            if let route = appState.activeRoute, !route.waypoints.isEmpty {
                MapPolyline(coordinates: route.waypoints)
                    .stroke(.blue, lineWidth: 5)
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
            Bike3DSceneView(rotationSpeed: findMeMode ? 0 : 0.35, isFindMeMode: findMeMode) {
                isBikeSceneReady = true
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

    /// Traži novu lokaciju; ne koristi cache – centriranje tek kad stigne nova u onChange(currentLocation).
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

// MARK: - Modifier s onChange handlerima; body rastavljen u manje izraze zbog type-checkera
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
                    onFitRoute(route.waypoints)
                }
            }
            .onChange(of: appState.isRouteActive) { _, active in
                if active { onSync() }
            }
    }

    private func addMapSyncHandlers<V: View>(_ view: V) -> some View {
        view
            .onChange(of: appState.mapCenter) { _, _ in onSync() }
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
