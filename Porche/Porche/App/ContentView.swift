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
        .onAppear { AppDebugLog.shared.log("ContentView body – step: \(String(describing: appState.onboardingStep))") }
    }

    private var bikeModelScreen: some View {
        BikeModelView(rotationSpeed: 0.35) {
            appState.onboardingStep = .welcome
        }
        .ignoresSafeArea(.container)
    }

    private var mainScreen: some View {
        ZStack(alignment: .bottom) {
            IslandCentralDisplayView()
            if appState.island.isExpanded {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        appState.island.requestClose = true
                    }
            }
            IslandBottomStackView(
                island: appState.island,
                isMapVisible: appState.isRouteActive,
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
                },
                onPokreniNavigaciju: { withNavigation, origin, destination in
                    appState.isRouteActive = true
                    if withNavigation, !origin.isEmpty, !destination.isEmpty {
                        appState.isNavigationActive = true
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
                    appState.isRouteActive = false
                    appState.activeRoute = nil
                    appState.isNavigationActive = false
                    appState.isFindMeMode = false
                    appState.showMapControlsInIsland = false
                    appState.mapHeading = 0
                    appState.mapCameraDistance = 500
                    appState.mapCenter = CLLocationCoordinate2D(latitude: 45.8129, longitude: 15.9775)
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
        .onAppear { AppDebugLog.shared.log("Main screen vidljiv") }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(LocationManager())
        .environmentObject(AppDebugLog.shared)
}
