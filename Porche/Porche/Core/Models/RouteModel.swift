import Foundation
import CoreLocation

struct RouteModel: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var waypoints: [CLLocationCoordinate2D]
    var elevationProfile: [Double]

    static func == (lhs: RouteModel, rhs: RouteModel) -> Bool {
        lhs.id == rhs.id
    }
}
