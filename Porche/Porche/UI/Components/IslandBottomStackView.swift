import SwiftUI

struct IslandBottomStackView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var island: Island
    var isMapVisible: Bool = false
    var isFindMeMode: Bool = true
    var onFindMe: (() -> Void)? = nil
    var onCancelFindMe: (() -> Void)? = nil
    var onPokreniNavigaciju: ((Bool, String, String) -> Void)? = nil
    /// Poziva se kad korisnik u vožnji stisne Island (povratak na početak) – reset vožnje i prikaza bicikla.
    var onExitRide: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            PorcheIslandView(
                island: island,
                isMapVisible: isMapVisible,
                isFindMeMode: isFindMeMode,
                onFindMe: onFindMe,
                onCancelFindMe: onCancelFindMe,
                onPokreniNavigaciju: onPokreniNavigaciju,
                onExitRide: onExitRide
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

private enum IslandTopBarColors {
    static let background = Color.black.opacity(0.85)
    static let nightBackground = AppColors.nightRidingOrange.opacity(0.95)
    static let text = Color.white
    static let secondary = Color.white.opacity(0.8)
}

/// Gornji trak: baterija (%), domet (km), mod rada, mali kompas.
struct IslandTopBarView: View {
    @EnvironmentObject private var appState: AppState

    private var batteryPercent: Int {
        appState.batteryStatus?.percent ?? 87
    }
    private var rangeKm: Double {
        appState.batteryStatus?.estimatedRangeKm ?? 42
    }
    private var modeLabel: String {
        appState.assistMode.displayTitle
    }

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: "battery.75percent")
                    .font(.system(size: 14))
                Text("\(batteryPercent)%")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(IslandTopBarColors.text)
            Text(String(format: "%.0f km", rangeKm))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(IslandTopBarColors.secondary)
            Text(modeLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(IslandTopBarColors.secondary)
            Spacer(minLength: 0)
            Image(systemName: "location.north.fill")
                .font(.system(size: 14))
                .foregroundStyle(IslandTopBarColors.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(appState.isNightRidingMode ? IslandTopBarColors.nightBackground : IslandTopBarColors.background)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

struct IslandParametersView: View {
    var isHidden: Bool = true
    var body: some View {
        if !isHidden {
            Text("Parametri")
                .font(AppTypography.caption)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Color.orange.opacity(0.2))
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
        }
    }
}

struct IslandBasicInfoView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
            Text("Basic info")
                .font(AppTypography.caption)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color(.systemBackground).ignoresSafeArea()
        IslandBottomStackView(island: Island())
            .environmentObject(AppState())
    }
}
