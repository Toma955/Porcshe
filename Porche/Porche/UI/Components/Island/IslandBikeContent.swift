import SwiftUI

// MARK: - IslandBikeContent

struct IslandBikeContent: View {
    @ObservedObject var appState: AppState
    @Environment(\.islandColors) private var islandColors

    private let bikePartIconSize: CGFloat = 28

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                Text("Katalog servisa")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(islandColors.title)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)
                ForEach(AppIcons.Part.allCases, id: \.rawValue) { part in
                    bikeCatalogRow(part: part)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func bikeCatalogRow(part: AppIcons.Part) -> some View {
        HStack(spacing: 12) {
            AppIcons.imagePart(part)
                .resizable()
                .scaledToFit()
                .frame(width: bikePartIconSize, height: bikePartIconSize)
                .foregroundStyle(islandColors.accentGreen)
            Text(part.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(islandColors.title)
            Spacer(minLength: 8)
            Text(bikeServiceText(for: part))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(islandColors.accentGreen)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(islandColors.buttonBg.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.bottom, 6)
        .foregroundStyle(islandColors.title)
    }

    private func bikeServiceText(for part: AppIcons.Part) -> String {
        let unit = part == .batery ? " %" : " km"
        switch part {
        case .oil: return "1200/1200\(unit)"
        case .brake: return "800/800\(unit)"
        case .service: return "500/500\(unit)"
        case .wheels: return "3000/3000\(unit)"
        case .gears: return "2000/2000\(unit)"
        case .suspension: return "1800/1800\(unit)"
        case .batery: return "100/100 %"
        case .engine: return "5000/5000\(unit)"
        case .link: return "1500/1500\(unit)"
        }
    }
}
