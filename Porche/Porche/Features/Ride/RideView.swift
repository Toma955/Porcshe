import SwiftUI

// MARK: - RideView

struct RideView: View {
    @StateObject private var viewModel = RideViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Vožnja")
                .font(.title2.weight(.semibold))
            if viewModel.state == .active, let m = viewModel.metrics {
                HStack(spacing: 24) {
                    statBlock(title: "Brzina", value: String(format: "%.0f", m.speed), unit: "km/h")
                    statBlock(title: "Kadenca", value: "\(m.cadence)", unit: "o/min")
                    statBlock(title: "Baterija", value: "\(m.batteryPercent)", unit: "%")
                    statBlock(title: "Mod", value: m.assistMode.displayTitle, unit: "")
                }
                .padding()
            } else {
                Text("Spremno za vožnju")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 24)
    }

    private func statBlock(title: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.weight(.semibold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 70)
    }
}
