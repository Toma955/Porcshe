import Foundation
import MapKit
import CoreLocation

/// Geokodira adrese i planira rutu između polazišta i odredišta.
enum RoutePlanningService {
    /// Resolves an address string to a coordinate. For "Trenutna lokacija" pass currentLocation.
    static func coordinate(
        for address: String,
        currentLocation: CLLocation?
    ) async -> CLLocationCoordinate2D? {
        if address.isEmpty { return nil }
        if address.lowercased().contains("trenutna lokacija"), let loc = currentLocation {
            return loc.coordinate
        }
        return await withCheckedContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = address
            request.resultTypes = [.address, .pointOfInterest]
            let search = MKLocalSearch(request: request)
            search.start { response, _ in
                let coord = response?.mapItems.first?.placemark.coordinate
                continuation.resume(returning: coord)
            }
        }
    }

    /// Plans a driving/cycling route and returns a RouteModel with polyline waypoints.
    static func planRoute(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D
    ) async -> RouteModel? {
        let originPlacemark = MKPlacemark(coordinate: origin)
        let destPlacemark = MKPlacemark(coordinate: destination)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: originPlacemark)
        request.destination = MKMapItem(placemark: destPlacemark)
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        guard let directions = MKDirections(request: request) as MKDirections? else { return nil }
        return await withCheckedContinuation { continuation in
            directions.calculate { response, _ in
                guard let route = response?.routes.first else {
                    continuation.resume(returning: nil)
                    return
                }
                let points = (0..<route.polyline.pointCount).map { i in
                    route.polyline.points()[i].coordinate
                }
                let model = RouteModel(
                    id: UUID(),
                    name: "Ruta",
                    waypoints: points,
                    elevationProfile: []
                )
                continuation.resume(returning: model)
            }
        }
    }
}
