import SwiftUI

// MARK: - IslandSettingsContent

struct IslandSettingsContent: View {
    @ObservedObject var appState: AppState
    @Environment(\.islandColors) private var islandColors

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                settingsSection("Exit") {
                    Button {
                        exit(0)
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 14))
                                .foregroundStyle(islandColors.accentGreen)
                            Text("Exit mode")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(islandColors.title)
                            Spacer(minLength: 8)
                            Text("Zatvori app")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(islandColors.accentGreen)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(islandColors.buttonBg.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(.bottom, 4)
                    }
                    .buttonStyle(.plain)
                }
                settingsSection("Sistemske postavke") {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "gear")
                                .font(.system(size: 14))
                                .foregroundStyle(islandColors.accentGreen)
                            Text("Otvori postavke sustava")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(islandColors.title)
                            Spacer(minLength: 8)
                            Text("Otvori")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(islandColors.accentGreen)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .background(islandColors.buttonBg.opacity(0.6), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(.bottom, 4)
                    }
                    .buttonStyle(.plain)
                }
                settingsSection("1. Postavke bicikla (Bike Settings)") {
                    settingsRow("Motor Tune (Eco, Trail, Sport, Turbo)")
                    settingsRow("Max Support – postotak snage motora")
                    settingsRow("Max Torque – limit okretnog momenta (Nm)")
                    settingsRow("Start Gear – brzina pri pokretanju")
                    settingsRow("Auto-Unlock (Bluetooth Proximity)")
                    settingsRow("Light Settings – Auto / On / Off, jačina")
                }
                settingsSection("2. Navigacija i mape") {
                    settingsRow("Map Style – Standard / Satellite / Hybrid")
                    settingsRow("Route Preference – Najbrža / Zelena / Flat")
                    settingsRow("Offline Maps – preuzimanje regija")
                    settingsRow("Range Overlay – oblak dosega na karti")
                }
                settingsSection("3. Povezivost i senzori") {
                    settingsRow("Sensor Management – Apple Watch, HRM, TPMS")
                    settingsRow("Data Export – Strava, Apple Health, Komoot")
                }
                settingsSection("4. Servis i dijagnostika") {
                    settingsRow("Component Log – datumi servisa komponenti")
                    settingsRow("Firmware Update – motor i baterija")
                    settingsRow("System Diagnostics – test senzora i elektronike")
                    settingsRow("User Manual – digitalni priručnik")
                }
                settingsSection("5. Korisnički profil") {
                    settingsRow("Biometrija – težina i visina vozača")
                    settingsRow("Fitness Level – za izračun pomoći motora")
                    settingsRow("Emergency Contact – broj pri Crash Detection")
                }
                settingsSection("6. Izgled i jedinice") {
                    settingsRow("Theme – Light / Dark / Auto")
                    settingsRow("Units – Metric (km, bar) / Imperial (miles, psi)")
                    settingsRow("Haptic Feedback – vibracije pri kliku")
                    settingsRow("Sound Effects – elektromehanički zvuk")
                }
                settingsSection("7. Privatnost i sigurnost") {
                    settingsRow("Bike PIN – otključavanje na biciklu")
                    settingsRow("Find My Bike – GPS u slučaju krađe")
                    settingsRow("Biometric App Lock – Face ID / Touch ID")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(islandColors.accentGreen)
            VStack(spacing: 0) {
                content()
            }
        }
    }

    private func settingsRow(_ label: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(islandColors.title)
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(islandColors.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(islandColors.buttonBg.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.bottom, 4)
    }
}
