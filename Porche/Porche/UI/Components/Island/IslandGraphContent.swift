import SwiftUI

// MARK: - IslandGraphContent

struct IslandGraphContent: View {
    @ObservedObject var appState: AppState
    @Environment(\.islandColors) private var islandColors
    var onDismiss: () -> Void

    private var batteryPercent: Int { appState.batteryStatus?.percent ?? 0 }
    private var batteryRangeKm: Double { appState.batteryStatus?.estimatedRangeKm ?? 0 }
    private var navGear: Int { min(12, max(0, appState.navigationGear)) }
    private var gearRatioText: String { "\(navGear)/12" }
    private var tripCaloriesForDisplay: Int {
        let start = appState.tripStartedAt ?? Date()
        let sec = appState.isRouteActive ? Date().timeIntervalSince(start) : 0
        return Int((sec / 60) * 6)
    }

    private var graphLiveSpeed: String {
        if appState.isRouteActive { return "\(appState.navigationSpeed) km/h" }
        let v = appState.rideStatistics.live.speedKmh
        return v > 0 ? String(format: "%.0f km/h", v) : "—"
    }
    private var graphLiveBattery: String {
        if appState.isRouteActive { return "\(batteryPercent) %" }
        let p = appState.rideStatistics.live.batteryPercent
        return p > 0 ? "\(p) %" : "—"
    }
    private var graphLiveRange: String {
        if appState.isRouteActive { return String(format: "%.0f km", batteryRangeKm) }
        let r = appState.rideStatistics.live.rangeKm
        return r > 0 ? String(format: "%.0f km", r) : "—"
    }
    private var graphLiveMod: String {
        if appState.isRouteActive { return appState.assistMode.displayTitle }
        let m = appState.rideStatistics.live.assistModeTitle
        return !m.isEmpty ? m : "—"
    }
    private var graphLiveGear: String {
        if appState.isRouteActive { return gearRatioText }
        let g = appState.rideStatistics.live.gearCurrent
        return g > 0 ? "\(g)/\(appState.rideStatistics.live.gearMax)" : "—"
    }
    private var graphLiveDistance: String {
        let d = appState.rideStatistics.live.distanceThisRideKm
        if d > 0 { return String(format: "%.1f km", d) }
        if let route = appState.activeRoute, !route.waypoints.isEmpty {
            let totalM = route.steps.reduce(0.0) { $0 + Double($1.distanceMeters) }
            let km = (totalM / 1000) * appState.routeProgressAlongLine
            return String(format: "%.1f km", km)
        }
        return "—"
    }
    private var graphLiveDuration: String {
        let m = appState.rideStatistics.live.rideDurationMinutes
        if m > 0 { return "\(m) min" }
        guard let start = appState.tripStartedAt, appState.isRouteActive else { return "—" }
        let sec = Date().timeIntervalSince(start)
        let min = Int(sec / 60)
        return "\(min) min"
    }
    private var graphTelemetryCadence: String { appState.rideStatistics.telemetry.cadenceRpm > 0 ? "\(appState.rideStatistics.telemetry.cadenceRpm) o/min" : "—" }
    private var graphTelemetryRiderPower: String { appState.rideStatistics.telemetry.riderPowerW > 0 ? "\(appState.rideStatistics.telemetry.riderPowerW) W" : "—" }
    private var graphTelemetryMotorPower: String { appState.rideStatistics.telemetry.motorPowerW > 0 ? "\(appState.rideStatistics.telemetry.motorPowerW) W" : "—" }
    private var graphTelemetryTorque: String { appState.rideStatistics.telemetry.torqueNm > 0 ? String(format: "%.1f Nm", appState.rideStatistics.telemetry.torqueNm) : "—" }
    private var graphTelemetryConsumption: String {
        if let w = appState.motorConsumptionWatts, w != 0 { return "\(w) W" }
        let c = appState.rideStatistics.telemetry.energyConsumptionWhPerKm
        return c > 0 ? String(format: "%.1f Wh/km", c) : "—"
    }
    private var graphTelemetryAvgSpeed: String { appState.rideStatistics.telemetry.averageSpeedKmh > 0 ? String(format: "%.0f km/h", appState.rideStatistics.telemetry.averageSpeedKmh) : "—" }
    private var graphTelemetryMaxSpeed: String { appState.rideStatistics.telemetry.maxSpeedKmh > 0 ? String(format: "%.0f km/h", appState.rideStatistics.telemetry.maxSpeedKmh) : "—" }
    private var graphTrackAltitude: String { appState.rideStatistics.track.altitudeM != 0 ? String(format: "%.0f m", appState.rideStatistics.track.altitudeM) : "—" }
    private var graphTrackGradient: String { appState.rideStatistics.track.gradientPercent != 0 ? String(format: "%.1f %%", appState.rideStatistics.track.gradientPercent) : "—" }
    private var graphTrackAscent: String { appState.rideStatistics.track.totalAscentM > 0 ? String(format: "%.0f m", appState.rideStatistics.track.totalAscentM) : "—" }
    private var graphTrackDescent: String { appState.rideStatistics.track.totalDescentM > 0 ? String(format: "%.0f m", appState.rideStatistics.track.totalDescentM) : "—" }
    private var graphTrackMaxGradient: String { appState.rideStatistics.track.maxGradientPercent != 0 ? String(format: "%.1f %%", appState.rideStatistics.track.maxGradientPercent) : "—" }
    private var graphTrackVam: String { appState.rideStatistics.track.vamMperHour > 0 ? String(format: "%.0f m/h", appState.rideStatistics.track.vamMperHour) : "—" }
    private var graphDiagnosticsMotorTemp: String {
        if let t = appState.motorTempCelsius { return "\(t) °C" }
        return appState.rideStatistics.diagnostics.motorTempC != 0 ? String(format: "%.0f °C", appState.rideStatistics.diagnostics.motorTempC) : "—"
    }
    private var graphDiagnosticsBatteryTemp: String {
        if let t = appState.batteryTempCelsius { return "\(t) °C" }
        return appState.rideStatistics.diagnostics.batteryTempC != 0 ? String(format: "%.0f °C", appState.rideStatistics.diagnostics.batteryTempC) : "—"
    }
    private var graphDiagnosticsTirePressure: String {
        let f = appState.rideStatistics.diagnostics.tirePressureFrontBar
        let r = appState.rideStatistics.diagnostics.tirePressureRearBar
        if f > 0 || r > 0 { return String(format: "%.1f / %.1f bar", f, r) }
        return "—"
    }
    private var graphDiagnosticsSoh: String { appState.rideStatistics.diagnostics.batterySohPercent > 0 ? "\(appState.rideStatistics.diagnostics.batterySohPercent) %" : "—" }
    private var graphDiagnosticsCycles: String { appState.rideStatistics.diagnostics.chargeCycles > 0 ? "\(appState.rideStatistics.diagnostics.chargeCycles)" : "—" }
    private var graphDiagnosticsService: String { appState.rideStatistics.diagnostics.kmUntilService > 0 ? String(format: "%.0f km", appState.rideStatistics.diagnostics.kmUntilService) : "—" }
    private var graphHistoryOdometer: String { appState.rideStatistics.history.odometerKm > 0 ? String(format: "%.0f km", appState.rideStatistics.history.odometerKm) : "—" }
    private var graphHistoryWeeklyGoal: String { appState.rideStatistics.history.weeklyGoalKm > 0 ? String(format: "%.0f / %.0f km", appState.rideStatistics.history.weeklyDoneKm, appState.rideStatistics.history.weeklyGoalKm) : "—" }
    private var graphHistoryCo2: String { appState.rideStatistics.history.co2SavedKg > 0 ? String(format: "%.1f kg", appState.rideStatistics.history.co2SavedKg) : "—" }
    private var graphHistoryCalories: String { appState.rideStatistics.history.caloriesBurned > 0 ? "\(appState.rideStatistics.history.caloriesBurned) kcal" : (appState.isRouteActive ? "\(tripCaloriesForDisplay) kcal" : "—") }
    private var graphHistoryEco: String { appState.rideStatistics.history.timeInEcoPercent > 0 ? String(format: "%.0f %%", appState.rideStatistics.history.timeInEcoPercent) : "—" }
    private var graphHistoryTurbo: String { appState.rideStatistics.history.timeInTurboPercent > 0 ? String(format: "%.0f %%", appState.rideStatistics.history.timeInTurboPercent) : "—" }
    private var graphInsightPressure: String { appState.rideStatistics.insights.recommendedPressureBar > 0 ? String(format: "%.1f bar", appState.rideStatistics.insights.recommendedPressureBar) : "—" }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    statsSectionTitle("1. Live Dashboard")
                    statsRow("Brzina", graphLiveSpeed)
                    statsRow("Baterija", graphLiveBattery)
                    statsRow("Doseg", graphLiveRange)
                    statsRow("Mod", graphLiveMod)
                    statsRow("Prijenos", graphLiveGear)
                    statsRow("Prijeđeno (vožnja)", graphLiveDistance)
                    statsRow("Vrijeme vožnje", graphLiveDuration)
                    statsSectionTitle("2. Performanse (Telemetrija)")
                    statsRow("Kadenca", graphTelemetryCadence)
                    statsRow("Snaga vozača", graphTelemetryRiderPower)
                    statsRow("Snaga motora", graphTelemetryMotorPower)
                    statsRow("Okretni moment", graphTelemetryTorque)
                    statsRow("Potrošnja", graphTelemetryConsumption)
                    statsRow("Prosječna brzina", graphTelemetryAvgSpeed)
                    statsRow("Maks. brzina", graphTelemetryMaxSpeed)
                    statsSectionTitle("3. Topografija i teren")
                    statsRow("Nadmorska visina", graphTrackAltitude)
                    statsRow("Nagib", graphTrackGradient)
                    statsRow("Ukupni uspon", graphTrackAscent)
                    statsRow("Ukupni spust", graphTrackDescent)
                    statsRow("Maks. nagib", graphTrackMaxGradient)
                    statsRow("VAM", graphTrackVam)
                    if !(appState.activeRoute?.elevationProfile.isEmpty ?? true) {
                        ElevationChartView(elevationData: appState.activeRoute?.elevationProfile ?? [])
                            .frame(height: 100)
                            .padding(.vertical, 8)
                    }
                    statsSectionTitle("4. Zdravlje sustava")
                    statsRow("Temperatura motora", graphDiagnosticsMotorTemp)
                    statsRow("Temperatura baterije", graphDiagnosticsBatteryTemp)
                    statsRow("Tlak guma", graphDiagnosticsTirePressure)
                    statsRow("Zdravlje baterije (SOH)", graphDiagnosticsSoh)
                    statsRow("Ciklusi punjenja", graphDiagnosticsCycles)
                    statsRow("Do servisa", graphDiagnosticsService)
                    statsSectionTitle("5. Povijest (tjedan / mjesec)")
                    statsRow("Kilometraža (odometar)", graphHistoryOdometer)
                    statsRow("Tjedni cilj", graphHistoryWeeklyGoal)
                    statsRow("Ušteda CO2", graphHistoryCo2)
                    statsRow("Kalorije", graphHistoryCalories)
                    statsRow("Vrijeme u Eco", graphHistoryEco)
                    statsRow("Vrijeme u Turbo", graphHistoryTurbo)
                    statsSectionTitle("6. Pametni uvidi")
                    statsRow("Preporučeni tlak", graphInsightPressure)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Spacer(minLength: 0)
            VStack(spacing: 8) {
                HStack {
                    Text("Mapa za spremanje")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(islandColors.secondary)
                    Spacer(minLength: 8)
                    Text(appState.saveFolderPath.isEmpty ? "Nije odabrano" : appState.saveFolderPath)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(islandColors.title)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(islandColors.buttonBg.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Button {
                    onDismiss()
                } label: {
                    Text("Spremi")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(islandColors.accentGreen, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func statsSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(islandColors.accentGreen)
            .padding(.top, 4)
    }

    private func statsRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(islandColors.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(islandColors.title)
        }
        .padding(.vertical, 4)
        .foregroundStyle(islandColors.title)
    }
}
