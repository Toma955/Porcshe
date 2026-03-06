import SwiftUI

// MARK: - Island styling & helpers

let islandSpring = Animation.spring(response: 0.35, dampingFraction: 0.82)
let islandSpringContent = Animation.spring(response: 0.4, dampingFraction: 0.8)
let expandedContentTransition = AnyTransition.asymmetric(
    insertion: .move(edge: .bottom).combined(with: .opacity),
    removal: .move(edge: .bottom).combined(with: .opacity)
)

struct IslandColorSet {
    let background: Color
    let backgroundExpanded: Color
    let surface: Color
    let title: Color
    let titleGradient: LinearGradient
    let accent: Color
    let accentGreen: Color
    let secondary: Color
    let border: Color
    let buttonBg: Color
    let shadowColor: Color
    init(night: Bool) {
        if night {
            let orange = AppColors.nightRidingOrange
            background = orange
            backgroundExpanded = orange.opacity(0.95)
            surface = orange.opacity(0.85)
            title = .white
            titleGradient = LinearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom)
            accent = .white
            accentGreen = AppColors.nightRidingAccent
            secondary = Color.white.opacity(0.9)
            border = Color.white.opacity(0.25)
            buttonBg = Color.white.opacity(0.2)
            shadowColor = orange.opacity(0.5)
        } else {
            background = .black
            backgroundExpanded = Color.black.opacity(0.9)
            surface = Color(red: 0.15, green: 0.15, blue: 0.17)
            title = .white
            titleGradient = LinearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom)
            accent = .white
            accentGreen = Color.green
            secondary = Color.white.opacity(0.8)
            border = Color.white.opacity(0.2)
            buttonBg = Color.white.opacity(0.12)
            shadowColor = Color.black.opacity(0.4)
        }
    }
}

struct IslandColorsEnvironmentKey: EnvironmentKey {
    static let defaultValue: IslandColorSet = IslandColorSet(night: false)
}

extension EnvironmentValues {
    var islandColors: IslandColorSet {
        get { self[IslandColorsEnvironmentKey.self] }
        set { self[IslandColorsEnvironmentKey.self] = newValue }
    }
}

struct IslandShapeModifier: ViewModifier {
    let cornerRadius: CGFloat
    let backgroundExpanded: Color
    let background: Color
    let border: Color
    let isExpanded: Bool
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }
    func body(content: Content) -> some View {
        content
            .clipShape(shape)
            .background(
                shape
                    .fill(isExpanded ? backgroundExpanded : background)
                    .overlay(shape.stroke(border, lineWidth: 1))
            )
    }
}

enum NavInstructionKind {
    case turnLeft, turnRight, forward, turnBack, compass
    var icon: Image {
        switch self {
        case .turnLeft: return AppIcons.imageTurnLeft
        case .turnRight: return AppIcons.imageTurnRight
        case .forward: return AppIcons.imageForward
        case .turnBack: return AppIcons.imageTurnBack
        case .compass: return AppIcons.imageCompass
        }
    }
    var rotationDegrees: Double { self == .forward ? -90 : 0 }
}

struct NavInstructionItem: Identifiable {
    let id: UUID
    let kind: NavInstructionKind
    let distanceMeters: Double
    let instructionText: String
    var icon: Image { kind.icon }
    init(id: UUID = UUID(), kind: NavInstructionKind, distanceMeters: Double, instructionText: String = "") {
        self.id = id
        self.kind = kind
        self.distanceMeters = distanceMeters
        self.instructionText = instructionText
    }
}

enum IslandSelectedButton: String, CaseIterable {
    case route
    case graph
    case bike
    case settings
}
