import SwiftUI
import CoreLocation
struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager
    var body: some View {
        Group {
            switch appState.onboardingStep {
            case .bikeModel:
                bikeModelScreen
            case .welcome:
                WelcomeView(onNext: { appState.onboardingStep = .permissions })
            case .permissions:
                PermissionsView(onNext: { appState.onboardingStep = .completed })
            case .completed:
                mainScreen
            }
        }
    }
    private var bikeModelScreen: some View {
        BikeModelView(rotationSpeed: 0.35) {
            appState.onboardingStep = .welcome
        }
        .ignoresSafeArea(.container)
    }
    private var mainScreen: some View {
        MainScreenRevealView(
            island: appState.island,
            isRouteActive: appState.isRouteActive,
            isFindMeMode: appState.isFindMeMode,
            onFindMe: {
                appState.isFindMeMode = true
                appState.isRouteActive = true
                appState.focusMapOnUserLocationTrigger += 1
                locationManager.requestWhenInUseAuthorization()
                locationManager.requestLocation()
                locationManager.startUpdatingLocation()
            },
            onCancelFindMe: {
                appState.isRouteActive = false
                appState.activeRoute = nil
                appState.routeProgressAlongLine = 0
            },
            onPokreniNavigaciju: { withNavigation, origin, destination in
                appState.isRouteActive = true
                if withNavigation, !origin.isEmpty, !destination.isEmpty {
                    appState.isNavigationActive = true
                    if appState.isDemoMode {
                        Task { @MainActor in
                            guard let route = await RoutePlanningService.planRoute(
                                origin: DemoRideSimulation.startCoordinate,
                                destination: DemoRideSimulation.endCoordinate
                            ) else { return }
                            appState.activeRoute = route
                            appState.routeProgressAlongLine = 0
                            appState.mapCenter = route.waypoints.first ?? appState.mapCenter
                            DemoRideSimulation.startSimulation(appState: appState, durationMinutes: 20)
                        }
                        return
                    }
                    Task { @MainActor in
                        let start = await RoutePlanningService.coordinate(
                            for: origin,
                            currentLocation: locationManager.currentLocation
                        )
                        let end = await RoutePlanningService.coordinate(
                            for: destination,
                            currentLocation: locationManager.currentLocation
                        )
                        guard let s = start, let e = end else { return }
                        if let route = await RoutePlanningService.planRoute(origin: s, destination: e) {
                            appState.activeRoute = route
                            appState.routeProgressAlongLine = 0
                        }
                    }
                } else {
                    appState.isFindMeMode = true
                    appState.focusMapOnUserLocationTrigger += 1
                    locationManager.requestWhenInUseAuthorization()
                    locationManager.requestLocation()
                    locationManager.startUpdatingLocation()
                }
            },
            onExitRide: {
                appState.demoSimulationTask?.cancel()
                appState.demoSimulationTask = nil
                appState.isRouteActive = false
                appState.activeRoute = nil
                appState.routeProgressAlongLine = 0
                appState.isNavigationActive = false
                appState.isFindMeMode = false
                appState.showMapControlsInIsland = false
                appState.mapHeading = 0
                appState.mapCameraDistance = 500
                appState.mapCenter = CLLocationCoordinate2D(latitude: 45.8129, longitude: 15.9775)
            }
        )
    }
}

private struct MainScreenRevealView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var island: Island
    var isRouteActive: Bool
    var isFindMeMode: Bool
    var onFindMe: () -> Void
    var onCancelFindMe: () -> Void
    var onPokreniNavigaciju: (Bool, String, String) -> Void
    var onExitRide: () -> Void

    @State private var islandRevealed = false
    @State private var barAppeared = false
    @State private var barHidden = false

    private let barEntranceDelay: Double = 0.4
    private let barEntranceDuration: Double = 0.5
    private let barExitDuration: Double = 0.55
    private let holdAtFullDuration: Double = 0.2
    private let islandRevealDuration: Double = 0.6

    var body: some View {
        ZStack(alignment: .bottom) {
            IslandCentralDisplayView()
            if appState.island.isExpanded {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        appState.island.requestClose = true
                    }
            }
            if appState.isAppReady {
                IslandBottomStackView(
                    island: island,
                    isMapVisible: isRouteActive,
                    isFindMeMode: isFindMeMode,
                    onFindMe: onFindMe,
                    onCancelFindMe: onCancelFindMe,
                    onPokreniNavigaciju: onPokreniNavigaciju,
                    onExitRide: onExitRide
                )
                .offset(y: islandRevealed ? 0 : 36)
                .opacity(islandRevealed ? 1 : 0)
                .animation(.easeOut(duration: islandRevealDuration), value: islandRevealed)
            } else {
                loadingProgressOverlay
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + barEntranceDelay) {
                withAnimation(.easeOut(duration: barEntranceDuration)) {
                    barAppeared = true
                }
            }
            if appState.isAppReady || appState.loadingProgress >= 1.0 {
                appState.isAppReady = true
                withAnimation(.easeOut(duration: islandRevealDuration)) {
                    islandRevealed = true
                }
            }
        }
        .onChange(of: appState.loadingProgress) { _, p in
            if p >= 1.0, !appState.isAppReady {
                DispatchQueue.main.asyncAfter(deadline: .now() + holdAtFullDuration) {
                    withAnimation(.easeOut(duration: barExitDuration)) {
                        barHidden = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + barExitDuration + 0.08) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            appState.isAppReady = true
                        }
                        withAnimation(.easeOut(duration: islandRevealDuration)) {
                            islandRevealed = true
                        }
                    }
                }
            }
        }
        .onChange(of: appState.isAppReady) { _, ready in
            if ready, !islandRevealed {
                withAnimation(.easeOut(duration: islandRevealDuration)) {
                    islandRevealed = true
                }
            }
        }
    }

    private var loadingProgressOverlay: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            GeometryReader { geo in
                let width = min(geo.size.width, 240)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.12))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black)
                        .frame(width: max(0, width * appState.loadingProgress), height: 3)
                        .animation(.easeInOut(duration: 0.28), value: appState.loadingProgress)
                }
                .frame(width: width, height: 3, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 3)
            .padding(.horizontal, 60)
            .padding(.bottom, 60)
            .opacity(barAppeared && !barHidden ? 1 : 0)
            .animation(.easeOut(duration: barEntranceDuration), value: barAppeared)
            .animation(.easeOut(duration: barExitDuration), value: barHidden)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(LocationManager())
        .environmentObject(AppDebugLog.shared)
}
