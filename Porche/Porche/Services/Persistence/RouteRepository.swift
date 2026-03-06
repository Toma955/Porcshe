import Foundation

// MARK: - RouteRepository

final class RouteRepository {
    private let key = "saved_routes"
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func save(_ route: RouteModel) async throws {
        var routes = try await fetchAll()
        if let i = routes.firstIndex(where: { $0.id == route.id }) {
            routes[i] = route
        } else {
            routes.append(route)
        }
        let data = try encoder.encode(routes)
        defaults.set(data, forKey: key)
    }

    func fetchAll() async throws -> [RouteModel] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? decoder.decode([RouteModel].self, from: data)) ?? []
    }
}
