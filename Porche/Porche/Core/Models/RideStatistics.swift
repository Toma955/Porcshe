import Foundation

// MARK: - 1. Osnovni podaci (Live Dashboard)
struct LiveDashboardStats {
    var speedKmh: Double = 0
    var batteryPercent: Int = 100
    var rangeKm: Double = 99
    var assistModeTitle: String = "Eco"
    var gearCurrent: Int = 1
    var gearMax: Int = 12
    var distanceThisRideKm: Double = 0
    var rideDurationMinutes: Int = 0
}

// MARK: - 2. Performanse (Real-time Telemetry)
struct TelemetryStats {
    var cadenceRpm: Int = 0
    var riderPowerW: Int = 0
    var motorPowerW: Int = 0
    var torqueNm: Double = 0
    var energyConsumptionWhPerKm: Double = 0
    var averageSpeedKmh: Double = 0
    var maxSpeedKmh: Double = 0
}

// MARK: - 3. Topografija i teren (Track Stats)
struct TrackStats {
    var altitudeM: Double = 0
    var gradientPercent: Double = 0
    var totalAscentM: Double = 0
    var totalDescentM: Double = 0
    var maxGradientPercent: Double = 0
    var vamMperHour: Double = 0
}

// MARK: - 4. Zdravlje sustava (Diagnostics & Health)
struct DiagnosticsStats {
    var motorTempC: Double = 0
    var batteryTempC: Double = 0
    var tirePressureFrontBar: Double = 0
    var tirePressureRearBar: Double = 0
    var batterySohPercent: Int = 100
    var chargeCycles: Int = 0
    var kmUntilService: Double = 0
}

// MARK: - 5. Napredna statistika (Weekly/Monthly)
struct HistoryStats {
    var odometerKm: Double = 0
    var weeklyGoalKm: Double = 150
    var weeklyDoneKm: Double = 0
    var co2SavedKg: Double = 0
    var caloriesBurned: Int = 0
    var timeInEcoPercent: Double = 0
    var timeInTurboPercent: Double = 0
}

// MARK: - 6. Pametni podaci (Smart Insights)
struct SmartInsights {
    var recommendedPressureBar: Double = 0
    var batteryWarningMessage: String? = nil
    var timeToFullChargeMinutes: Int? = nil
}

// MARK: - Sve statistike na jednom mjestu
struct RideStatistics {
    var live: LiveDashboardStats = .init()
    var telemetry: TelemetryStats = .init()
    var track: TrackStats = .init()
    var diagnostics: DiagnosticsStats = .init()
    var history: HistoryStats = .init()
    var insights: SmartInsights = .init()

    static var placeholder: RideStatistics {
        var s = RideStatistics()
        s.live.speedKmh = 24
        s.live.batteryPercent = 87
        s.live.rangeKm = 42
        s.live.assistModeTitle = "Eco"
        s.live.gearCurrent = 7
        s.live.gearMax = 12
        s.live.distanceThisRideKm = 12.4
        s.live.rideDurationMinutes = 38
        s.telemetry.cadenceRpm = 72
        s.telemetry.riderPowerW = 85
        s.telemetry.motorPowerW = 120
        s.telemetry.torqueNm = 32
        s.telemetry.energyConsumptionWhPerKm = 8.5
        s.telemetry.averageSpeedKmh = 22
        s.telemetry.maxSpeedKmh = 45
        s.track.altitudeM = 312
        s.track.gradientPercent = 4.2
        s.track.totalAscentM = 180
        s.track.totalDescentM = 95
        s.track.maxGradientPercent = 12
        s.track.vamMperHour = 284
        s.diagnostics.motorTempC = 42
        s.diagnostics.batteryTempC = 28
        s.diagnostics.tirePressureFrontBar = 2.4
        s.diagnostics.tirePressureRearBar = 2.6
        s.diagnostics.batterySohPercent = 98
        s.diagnostics.chargeCycles = 127
        s.diagnostics.kmUntilService = 850
        s.history.odometerKm = 3420
        s.history.weeklyGoalKm = 150
        s.history.weeklyDoneKm = 120
        s.history.co2SavedKg = 48
        s.history.caloriesBurned = 420
        s.history.timeInEcoPercent = 65
        s.history.timeInTurboPercent = 8
        s.insights.recommendedPressureBar = 2.5
        s.insights.batteryWarningMessage = nil
        s.insights.timeToFullChargeMinutes = 95
        return s
    }
}
