import Foundation
import CoreLocation

// MARK: - WeatherService

final class WeatherService {
    func fetchWeather(at coordinate: CLLocationCoordinate2D) async throws -> WeatherData {
        try await Task.sleep(nanoseconds: 300_000_000)
        return WeatherData(
            temperature: 18,
            condition: "Oblačno",
            windSpeed: 12,
            precipitation: 0.1
        )
    }
}
