import SwiftUI

// MARK: - Island button styles & subviews

struct ChevronCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct IslandRoundIconButton: View {
    @Environment(\.islandColors) private var islandColors
    let image: Image
    var size: CGFloat = 40
    var isSelected: Bool = false
    var accessibilityId: String? = nil
    let action: () -> Void
    private var iconSize: CGFloat { size * 0.55 }
    var body: some View {
        Button(action: action) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(islandColors.accent)
                .frame(width: size, height: size)
                .background(Circle().fill(islandColors.buttonBg))
                .overlay(
                    Circle()
                        .stroke(islandColors.accent.opacity(isSelected ? 0.8 : 0), lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityId ?? "")
    }
}

struct NavigationControlColumn: View {
    @Environment(\.islandColors) private var islandColors
    let label: String
    let valueLabel: String
    let step: Double
    let onStep: (Double) -> Void
    private let pillWidth: CGFloat = 56
    private let pillHeight: CGFloat = 48
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(valueLabel)
                .font(.callout.weight(.semibold))
                .foregroundStyle(islandColors.title)
            VStack(spacing: 8) {
                Button { onStep(step) } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(islandColors.accent)
                        .frame(width: pillWidth, height: pillHeight)
                        .background(islandColors.buttonBg, in: Capsule())
                }
                .buttonStyle(.plain)
                Button { onStep(-step) } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(islandColors.accent)
                        .frame(width: pillWidth, height: pillHeight)
                        .background(islandColors.buttonBg, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            Text(label)
                .font(.subheadline)
                .foregroundStyle(islandColors.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct NavigationPanelSideButton: View {
    @Environment(\.islandColors) private var islandColors
    var icon: String = "circle"
    var label: String = ""
    var customImage: Image? = nil
    var body: some View {
        Button { } label: {
            VStack(spacing: 4) {
                if let img = customImage {
                    img
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                }
                if !label.isEmpty {
                    Text(label)
                        .font(.caption)
                }
            }
            .foregroundStyle(islandColors.title)
            .frame(width: 48, height: 48)
            .background(islandColors.buttonBg, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

struct IslandActionButton: View {
    @Environment(\.islandColors) private var islandColors
    let icon: String
    let label: String
    var subtitle: String?
    let accentColor: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(AppTypography.caption2)
                if let sub = subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(AppTypography.caption2)
                        .foregroundStyle(islandColors.secondary)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(accentColor)
            .frame(minWidth: 56)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

struct IslandChevronCloseButton: View {
    var size: CGFloat = 52
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: size, height: size)
                Image(systemName: "chevron.down")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.black)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(ChevronCapsuleButtonStyle())
    }
}

struct IslandCircleIconButton<Icon: View>: View {
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    @ViewBuilder let icon: () -> Icon
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            icon()
                .foregroundStyle(foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
