import SwiftUI
import MapKit

// MARK: - Island na dnu ekrana
// Početak: samo "Porche". Prvi klik → island se širi, pojave se gumbi (Route, Graph, Bike, Settings, chevron.down).
// Klik na gumb → ispod se prikaže sadržaj tog gumba. Glavni natpis "Porche" uvijek na vrhu.

private let islandSpring = Animation.spring(response: 0.35, dampingFraction: 0.82)
private let islandSpringContent = Animation.spring(response: 0.4, dampingFraction: 0.8)

/// Paleta boja islanda; kad je night = true, crne boje postaju narančaste (vožnja po noći).
private struct IslandColorSet {
    let background: Color
    let backgroundExpanded: Color
    let surface: Color
    let title: Color
    let titleGradient: LinearGradient
    let accent: Color
    /// Zelena u danu, #FF4B33 u noćnom modu (Mod, odabir na karti, itd.).
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

private struct IslandColorsEnvironmentKey: EnvironmentKey {
    static let defaultValue: IslandColorSet = IslandColorSet(night: false)
}
extension EnvironmentValues {
    fileprivate var islandColors: IslandColorSet {
        get { self[IslandColorsEnvironmentKey.self] }
        set { self[IslandColorsEnvironmentKey.self] = newValue }
    }
}

/// Vrsta smjera za uputu (da znamo rotirati „ravno” prema gore).
private enum NavInstructionKind {
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
    /// Ravno (forward) treba rotirati 90° da gleda prema gore.
    var rotationDegrees: Double { self == .forward ? -90 : 0 }
}

/// Jedna uputa za navigaciju: smjer, preostala udaljenost (m); odbrojava se do 0 pa sljedeća.
private struct NavInstructionItem: Identifiable {
    let id: UUID
    let kind: NavInstructionKind
    let distanceMeters: Double
    var icon: Image { kind.icon }
    init(id: UUID = UUID(), kind: NavInstructionKind, distanceMeters: Double) {
        self.id = id
        self.kind = kind
        self.distanceMeters = distanceMeters
    }
}

/// Koji je gumb u islandu odabran (sadržaj ispod).
private enum IslandSelectedButton: String, CaseIterable {
    case route
    case graph
    case bike
    case settings
}

struct PorcheIslandView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var island: Island
    var accentColor: Color = .white

    private var islandColors: IslandColorSet { IslandColorSet(night: appState.isNightRidingMode) }
    var isMapVisible: Bool = false
    var isFindMeMode: Bool = true
    var onFindMe: (() -> Void)? = nil
    var onCancelFindMe: (() -> Void)? = nil
    var onPokreniNavigaciju: ((Bool, String, String) -> Void)? = nil

    private let collapsedHeight: CGFloat = 72
    private let iconSizeExpanded: CGFloat = 62
    /// Kad je proširen, samo red ikona (bez natpisa) – visina tog dijela.
    private var expandedPillSectionHeight: CGFloat { iconSizeExpanded + 28 }
    private let horizontalPadding: CGFloat = 20
    /// Veći radijus + continuous stil da prati zaobljenost donjeg ruba ekrana.
    private let cornerRadius: CGFloat = 40

    @State private var showButtonsContent = false
    /// Kad true, u vožnji se prikazuje panel s navigacijskim strelicama (upute) umjesto Odaziv/Moment/Podrška.
    @State private var showNavigationInstructionsInIsland = false
    /// Za panel navigacije: ulica, lokacija, smjer (stupnjevi), upute s udaljenošću, falija (povratak).
    @State private var navStreet: String = "Ilica"
    @State private var navLocation: String = "Zagreb"
    @State private var navHeadingDegrees: Double = 0
    @State private var navInstructions: [NavInstructionItem] = [
        NavInstructionItem(kind: .turnRight, distanceMeters: 600),
        NavInstructionItem(kind: .turnLeft, distanceMeters: 800),
        NavInstructionItem(kind: .forward, distanceMeters: 1200)
    ]
    @State private var navFailed: Bool = false
    @State private var navReturnMeters: Double = 0
    @State private var navExpandFullscreen: Bool = false
    private let contentDelay: Double = 0.12
    /// Klik na koji gumb – ispod se prikaže njegov sadržaj.
    @State private var selectedButton: IslandSelectedButton?
    /// Destinacije za rutu (kao na Google Maps: od točke A do točke B).
    @State private var routeOrigin: String = ""
    @State private var routeDestination: String = ""
    @StateObject private var locationCompleter = LocationSearchCompleter()
    @FocusState private var focusedDestinationField: DestinationField?
    @State private var showModPicker = false

    private enum DestinationField {
        case origin, destination
    }

    private var isExpanded: Bool { island.state != .compact }
    private var hasRouteDestinations: Bool { !routeOrigin.isEmpty || !routeDestination.isEmpty }
    /// Brzina + stupanj + motor panel prikazujemo kad je mapa/vožnja uključena (i "Pokreni navigaciju" i "Pokreni bez navigacije").
    private var isRideMapActive: Bool { appState.isRouteActive }
    private var navSpeed: Int { min(99, max(0, appState.navigationSpeed)) }
    private var navGear: Int { min(99, max(0, appState.navigationGear)) }
    private let maxGear: Int = 12
    private var gearRatioText: String { "\(min(maxGear, max(1, navGear)))/\(maxGear)" }
    private var batteryPercent: Int { appState.batteryStatus?.percent ?? 100 }
    private var batteryRangeKm: Double { appState.batteryStatus?.estimatedRangeKm ?? 99 }

    /// Jedna ćelija u redu statistika. fontSize: nil = 28, manji za prijenos (npr. 22).
    private func rideModeStatCell(_ value: String, unit: String, fontSize: CGFloat? = nil) -> some View {
        let size = fontSize ?? 28
        return Group {
            if unit.isEmpty {
                Text(value)
            } else {
                Text(value + " " + unit)
            }
        }
        .font(.system(size: size, weight: .semibold))
        .foregroundStyle(islandColors.title)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
    }

    /// Unutarnji padding da sav sadržaj ostane unutar zaobljenog crnog područja (izbjegava izlazak na rubove).
    private let islandInnerPadding: CGFloat = 16
    /// Visina reda brzine + omjera u vožnji (title3 + subheadline).
    private let rideModeSpeedRowHeight: CGFloat = 40
    /// Visina reda gumba Mod.
    private let rideModeButtonsRowHeight: CGFloat = 44
    /// Visina donjeg reda ikona (Moon, Paths, …).
    private let rideModeBottomBarHeight: CGFloat = 56
    /// Red s 4 jednake ćelije: km/h, prijenos, baterija %, domet.
    private let rideModeStatsRowSpacing: CGFloat = 8
    /// Unutarnji prostor skoro do rubova da se sve vidi (km/h, %, km).
    private let rideModeStatsHorizontalPadding: CGFloat = 10

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                if isExpanded, isRideMapActive, showModPicker {
                    modePickerInIslandContent
                } else if isExpanded, isRideMapActive, appState.showMapControlsInIsland {
                    mapControlsInIslandContent
                } else if isExpanded, isRideMapActive {
                    // 4 jednake ćelije: km/h, prijenos, baterija %, domet
                    HStack(spacing: rideModeStatsRowSpacing) {
                        rideModeStatCell("\(navSpeed)", unit: "km/h", fontSize: 22)
                        rideModeStatCell(gearRatioText, unit: "", fontSize: 22)
                        rideModeStatCell("\(batteryPercent)", unit: "%")
                        rideModeStatCell(String(format: "%.0f", batteryRangeKm), unit: "km", fontSize: 22)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: rideModeSpeedRowHeight)
                    .padding(.horizontal, rideModeStatsHorizontalPadding)
                    .padding(.top, islandInnerPadding)
                    .padding(.bottom, 6)
                    if isExpanded {
                        expandedContent
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                    }
                    if !showNavigationInstructionsInIsland {
                        Button { showModPicker = true } label: {
                            Text(appState.assistMode.displayTitle)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity)
                                .frame(height: rideModeButtonsRowHeight)
                                .background(islandColors.accentGreen, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, islandInnerPadding)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                    }
                    rideModeBottomBar
                        .padding(.horizontal, islandInnerPadding)
                        .padding(.bottom, islandInnerPadding)
                } else if isExpanded {
                    expandedContent
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
                if !isExpanded || !isRideMapActive {
                    pillBar
                }
            }
            .frame(width: islandWidth)
            .frame(height: islandFrameHeight)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isExpanded ? islandColors.backgroundExpanded : islandColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(islandColors.border, lineWidth: 1)
                    )
            )
            .shadow(color: islandColors.shadowColor, radius: 16, x: 0, y: 6)
            .animation(islandSpring, value: island.state)
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, 20)
            .environment(\.islandColors, islandColors)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .onChange(of: island.state) { _, newState in
            if newState != .compact {
                DispatchQueue.main.asyncAfter(deadline: .now() + contentDelay) {
                    if island.state != .compact { showButtonsContent = true }
                }
            } else {
                showButtonsContent = false
                selectedButton = nil
                showModPicker = false
                appState.showMapControlsInIsland = false
                showNavigationInstructionsInIsland = false
            }
        }
        .onChange(of: island.requestClose) { _, requested in
            guard requested else { return }
            withAnimation(islandSpring) {
                showButtonsContent = false
                selectedButton = nil
                showModPicker = false
                appState.showMapControlsInIsland = false
                island.state = .compact
            }
            // Odgodi reset da se izbjegne "Modifying state during view update"
            DispatchQueue.main.async { island.requestClose = false }
        }
    }

    private var islandWidth: CGFloat {
        switch island.state {
        case .compact: return UIScreen.main.bounds.width - horizontalPadding * 2
        case .actions: return 400
        case .fullStats: return UIScreen.main.bounds.width - horizontalPadding * 2
        }
    }

    private var expandedMaxHeight: CGFloat? {
        switch island.state {
        case .compact: return collapsedHeight
        case .actions:
            if isRideMapActive { return expandedHeightForRideMode }
            return selectedButton != nil ? (expandedPillSectionHeight + 220) : expandedPillSectionHeight
        case .fullStats: return UIScreen.main.bounds.height * 0.85
        }
    }

    /// Fiksna visina u vožnji da sav sadržaj stane unutar crnog područja (brzina, panel, gumbi, donji red).
    private var expandedHeightForRideMode: CGFloat {
        let top = islandInnerPadding + rideModeSpeedRowHeight + 6
        let panel: CGFloat = 200
        let buttons = 8 + rideModeButtonsRowHeight + 6
        let bottomBar = rideModeBottomBarHeight + islandInnerPadding
        return top + panel + buttons + bottomBar
    }

    /// Visina islanda kad je otvoren prozor za izbor modova (lista 8 modova + bijela strelica).
    private var expandedHeightForModePicker: CGFloat {
        let topPadding: CGFloat = islandInnerPadding
        let rowHeight: CGFloat = 44
        let listHeight = CGFloat(AssistMode.allCases.count) * rowHeight
        let chevronArea: CGFloat = rideModeChevronRoundSize + islandInnerPadding * 2
        return topPadding + min(listHeight, 320) + chevronArea
    }

    /// Visina islanda kad su otvorene kontrole mape (3 stupca + okrugli povratak).
    private var expandedHeightForMapControls: CGFloat {
        let top: CGFloat = islandInnerPadding
        let sideBtnSize: CGFloat = 52
        let sideGap: CGFloat = 12
        let contentH: CGFloat = 3 * sideBtnSize + 2 * sideGap
        let chevronArea: CGFloat = rideModeChevronRoundSize + islandInnerPadding * 2
        return top + contentH + 14 + chevronArea
    }

    /// Korištena visina za frame – sve unutar crnog područja bez overflowa.
    private var islandFrameHeight: CGFloat {
        switch island.state {
        case .compact: return collapsedHeight
        case .actions:
            if isRideMapActive, showModPicker { return expandedHeightForModePicker }
            if isRideMapActive, appState.showMapControlsInIsland { return expandedHeightForMapControls }
            if isRideMapActive { return expandedHeightForRideMode }
            return selectedButton != nil ? (expandedPillSectionHeight + 220) : expandedPillSectionHeight
        case .fullStats: return UIScreen.main.bounds.height * 0.85
        }
    }

    /// Compact: "Porche" ili (tijekom navigacije) brzina + stupanj. Prošireno: red ikona ili navigacijski red.
    private var pillBar: some View {
        Group {
            if isExpanded {
                if !isRideMapActive {
                    islandIconRow
                }
            } else {
                Button {
                    withAnimation(islandSpring) { island.state = .actions }
                } label: {
                    if isRideMapActive {
                        HStack(spacing: rideModeStatsRowSpacing) {
                            rideModeStatCell("\(navSpeed)", unit: "km/h", fontSize: 22)
                            rideModeStatCell(gearRatioText, unit: "", fontSize: 22)
                            rideModeStatCell("\(batteryPercent)", unit: "%")
                            rideModeStatCell(String(format: "%.0f", batteryRangeKm), unit: "km", fontSize: 22)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: collapsedHeight)
                        .padding(.horizontal, rideModeStatsHorizontalPadding)
                    } else {
                        Text(island.title)
                            .font(AppTypography.headline)
                            .foregroundStyle(islandColors.titleGradient)
                            .frame(maxWidth: .infinity)
                            .frame(height: collapsedHeight)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, isExpanded ? 14 : 0)
        .padding(.horizontal, isExpanded ? iconRowGap : 20)
    }

    /// Veličina kružnih gumba u donjem redu (Moon, Paths, Island, Mapa).
    private let rideModeCircleButtonSize: CGFloat = 44
    /// Bijeli okrugli gumb „povratak” (strelica) – ista širina i visina za krug.
    private let rideModeChevronRoundSize: CGFloat = 52
    /// Razmak između gumba u lijevoj i desnoj skupini – simetričan raspored.
    private let rideModeButtonGap: CGFloat = 12

    /// Donji red u vožnji. Kad su upute aktivne: lijevo povećaj, sredina bijeli „natrag”, desno ulica/lokacija/smjer.
    private var rideModeBottomBar: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if showNavigationInstructionsInIsland {
                Button {
                    navExpandFullscreen.toggle()
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 18))
                        .foregroundStyle(islandColors.title)
                        .frame(width: rideModeCircleButtonSize, height: rideModeCircleButtonSize)
                        .background(islandColors.buttonBg, in: Circle())
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
                Button {
                    withAnimation(islandSpring) { showNavigationInstructionsInIsland = false }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: rideModeChevronRoundSize, height: rideModeChevronRoundSize)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(.black)
                            .rotationEffect(.degrees(90))
                    }
                    .frame(width: rideModeChevronRoundSize, height: rideModeChevronRoundSize)
                    .contentShape(Circle())
                }
                .buttonStyle(ChevronCapsuleButtonStyle())
                Spacer(minLength: 0)
                AppIcons.imageCompass
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(islandColors.title)
                    .rotationEffect(.degrees(-navHeadingDegrees))
                    .padding(.bottom, 4)
            } else {
                HStack(spacing: rideModeButtonGap) {
                    Button {
                        appState.isNightRidingMode.toggle()
                    } label: {
                        AppIcons.imageMoon
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(islandColors.title)
                            .frame(width: rideModeCircleButtonSize, height: rideModeCircleButtonSize)
                            .background(appState.isNightRidingMode ? AppColors.nightRidingOrange : islandColors.buttonBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                    Button {
                        withAnimation(islandSpring) { showNavigationInstructionsInIsland = true }
                    } label: {
                        AppIcons.imagePaths
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(islandColors.title)
                            .frame(width: rideModeCircleButtonSize, height: rideModeCircleButtonSize)
                            .background(islandColors.buttonBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
                Button {
                    withAnimation(islandSpring) {
                        selectedButton = nil
                        island.state = .compact
                        showNavigationInstructionsInIsland = false
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(width: rideModeChevronRoundSize, height: rideModeChevronRoundSize)
                        .background(Color.white, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
                HStack(spacing: rideModeButtonGap) {
                    Button { } label: {
                        AppIcons.imageIsland
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(islandColors.title)
                            .frame(width: rideModeCircleButtonSize, height: rideModeCircleButtonSize)
                            .background(islandColors.buttonBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                    Button {
                        withAnimation(islandSpring) { appState.showMapControlsInIsland.toggle() }
                    } label: {
                        Image(systemName: "map.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(islandColors.title)
                            .frame(width: rideModeCircleButtonSize, height: rideModeCircleButtonSize)
                            .background(islandColors.buttonBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: rideModeBottomBarHeight)
    }

    /// Dvije nijanse po modu za ukosi gradijent unutar slova (topLeading → bottomTrailing).
    private static let modePickerColors: (
        off: (Color, Color), eco: (Color, Color), tour: (Color, Color), sport: (Color, Color),
        turbo: (Color, Color), custom: (Color, Color), auto: (Color, Color), walk: (Color, Color)
    ) = (
        off: (.white, Color.white.opacity(0.82)),
        eco: (Color(red: 0.45, green: 0.85, blue: 0.35), Color(red: 0.12, green: 0.5, blue: 0.12)),
        tour: (Color(red: 0.15, green: 0.35, blue: 0.75), Color(red: 0.4, green: 0.65, blue: 1.0)),
        sport: (Color(red: 0.9, green: 0.35, blue: 0.7), Color(red: 0.6, green: 0.1, blue: 0.45)),
        turbo: (Color(red: 0.5, green: 0.7, blue: 1.0), Color(red: 0.15, green: 0.35, blue: 0.85)),
        custom: (Color(red: 1.0, green: 0.95, blue: 0.4), Color(red: 0.85, green: 0.7, blue: 0.1)),
        auto: (.white, Color.white.opacity(0.75)),
        walk: (Color.white.opacity(0.95), Color.white.opacity(0.7))
    )
    private static let modePickerGradientDiagonal = (start: UnitPoint.topLeading, end: UnitPoint.bottomTrailing)

    /// Prozor za izbor modova unutar islanda: lista 8 modova (slova obojana) + bijeli gumb na istom mjestu, strelica rotirana u suprotnu stranu.
    private var modePickerInIslandContent: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(AssistMode.allCases, id: \.self) { mode in
                        Button {
                            appState.assistMode = mode
                            withAnimation(islandSpring) { showModPicker = false }
                        } label: {
                            modePickerLabel(for: mode)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if mode != AssistMode.allCases.last {
                            Rectangle()
                                .fill(islandColors.border)
                                .frame(height: 1)
                                .padding(.leading, islandInnerPadding)
                        }
                    }
                }
            }
            .frame(maxHeight: 320)
            .padding(.top, islandInnerPadding)

            Spacer(minLength: 8)
            Button {
                withAnimation(islandSpring) { showModPicker = false }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: rideModeChevronRoundSize, height: rideModeChevronRoundSize)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.black)
                        .rotationEffect(.degrees(90))
                }
                .frame(width: rideModeChevronRoundSize, height: rideModeChevronRoundSize)
                .contentShape(Circle())
            }
            .buttonStyle(ChevronCapsuleButtonStyle())
            .padding(.bottom, islandInnerPadding)
        }
        .padding(.horizontal, islandInnerPadding)
    }

    private func modePickerLabel(for mode: AssistMode) -> some View {
        let (c1, c2) = Self.modePickerGradientColors(for: mode)
        let g = Self.modePickerGradientDiagonal
        return Text(mode.displayTitle)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(LinearGradient(colors: [c1, c2], startPoint: g.start, endPoint: g.end))
    }

    private static func modePickerGradientColors(for mode: AssistMode) -> (Color, Color) {
        let c = modePickerColors
        switch mode {
        case .off: return c.off
        case .eco: return c.eco
        case .tourTrail: return c.tour
        case .sport: return c.sport
        case .turboBoost: return c.turbo
        case .customIndividual: return c.custom
        case .auto: return c.auto
        case .walk: return c.walk
        }
    }

    /// Kontrole mape: lijevo topologija, sredina strelice + centriraj, desno light/dark, 2D/3D, ruka. Lijevi/desni gumbi veći, od vrha do dna.
    private var mapControlsInIslandContent: some View {
        let sideBtnSize: CGFloat = 52
        let sideGap: CGFloat = 12
        let contentHeight: CGFloat = 3 * sideBtnSize + 2 * sideGap
        let arrowSize: CGFloat = 34
        let centerBtnSize: CGFloat = 32
        let colGap: CGFloat = 18
        return VStack(spacing: 0) {
            HStack(alignment: .center, spacing: colGap) {
                // Lijevi stupac: 3 veća gumba topologije – od vrha do dna
                VStack(spacing: sideGap) {
                    ForEach([MapTerrainStyle.standard, .satellite, .hybrid], id: \.rawValue) { style in
                        Button {
                            appState.mapStyle = style
                        } label: {
                            Image(systemName: mapStyleIcon(style))
                                .font(.system(size: 20))
                                .foregroundStyle(appState.mapStyle == style ? islandColors.accentGreen : islandColors.title)
                                .frame(width: sideBtnSize, height: sideBtnSize)
                                .background(appState.mapStyle == style ? islandColors.accentGreen.opacity(0.25) : islandColors.buttonBg, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: contentHeight)
                .frame(maxWidth: .infinity)

                // Sredina: strelice u + s centriraj u sredini
                VStack(spacing: 6) {
                    Button {
                        appState.mapCameraDistance = min(2000, appState.mapCameraDistance + 80)
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(islandColors.title)
                            .frame(width: arrowSize, height: arrowSize)
                            .background(islandColors.buttonBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                    HStack(spacing: 6) {
                        Button {
                            appState.mapHeading -= 15
                            if appState.mapHeading < 0 { appState.mapHeading += 360 }
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(islandColors.title)
                                .frame(width: arrowSize, height: arrowSize)
                                .background(islandColors.buttonBg, in: Circle())
                        }
                        .buttonStyle(.plain)
                        Button {
                            appState.focusMapOnUserLocationTrigger += 1
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(islandColors.title)
                                .frame(width: centerBtnSize, height: centerBtnSize)
                                .background(islandColors.buttonBg, in: Circle())
                        }
                        .buttonStyle(.plain)
                        Button {
                            appState.mapHeading += 15
                            if appState.mapHeading >= 360 { appState.mapHeading -= 360 }
                        } label: {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(islandColors.title)
                                .frame(width: arrowSize, height: arrowSize)
                                .background(islandColors.buttonBg, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    Button {
                        appState.mapCameraDistance = max(200, appState.mapCameraDistance - 80)
                    } label: {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(islandColors.title)
                            .frame(width: arrowSize, height: arrowSize)
                            .background(islandColors.buttonBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: contentHeight)
                .frame(maxWidth: .infinity)

                // Desni stupac: light/dark, 2D/3D, ruka (pomicanje) – veći gumbi od vrha do dna
                VStack(spacing: sideGap) {
                    Button {
                        appState.mapDarkStyle.toggle()
                    } label: {
                        Image(systemName: appState.mapDarkStyle ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(islandColors.title)
                            .frame(width: sideBtnSize, height: sideBtnSize)
                            .background(islandColors.buttonBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                    Button {
                        appState.mapIs3D.toggle()
                    } label: {
                        Text(appState.mapIs3D ? "3D" : "2D")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(islandColors.title)
                            .frame(width: sideBtnSize, height: sideBtnSize)
                            .background(islandColors.buttonBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                    Button {
                        appState.mapPanningEnabled.toggle()
                    } label: {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(appState.mapPanningEnabled ? .white : islandColors.title)
                            .frame(width: sideBtnSize, height: sideBtnSize)
                            .background(appState.mapPanningEnabled ? islandColors.accentGreen : islandColors.buttonBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: contentHeight)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, islandInnerPadding)
            .padding(.top, islandInnerPadding)

            Spacer(minLength: 10)
            Button {
                withAnimation(islandSpring) { appState.showMapControlsInIsland = false }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: rideModeChevronRoundSize, height: rideModeChevronRoundSize)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.black)
                        .rotationEffect(.degrees(90))
                }
                .frame(width: rideModeChevronRoundSize, height: rideModeChevronRoundSize)
                .contentShape(Circle())
            }
            .buttonStyle(ChevronCapsuleButtonStyle())
            .padding(.bottom, islandInnerPadding)
        }
    }

    private func mapStyleLabel(_ style: MapTerrainStyle) -> String {
        switch style {
        case .standard: return "Standard"
        case .satellite: return "Satelit"
        case .hybrid: return "Hibrid"
        case .flyover: return "3D"
        }
    }

    private func mapStyleIcon(_ style: MapTerrainStyle) -> String {
        switch style {
        case .standard: return "map"
        case .satellite: return "globe.europe.africa.fill"
        case .hybrid: return "map.fill"
        case .flyover: return "map"
        }
    }

    /// Brzina, prijenos, baterija, domet – iste dimenzije; strelica desno.
    private var navigationPillRow: some View {
        HStack(spacing: rideModeStatsRowSpacing) {
            rideModeStatCell("\(navSpeed)", unit: "km/h", fontSize: 22)
            rideModeStatCell(gearRatioText, unit: "", fontSize: 22)
            rideModeStatCell("\(batteryPercent)", unit: "%")
            rideModeStatCell(String(format: "%.0f", batteryRangeKm), unit: "km", fontSize: 22)
            Spacer(minLength: 0)
            Button {
                withAnimation(islandSpring) {
                    selectedButton = nil
                    island.state = .compact
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(islandColors.accent)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, iconRowGap)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Navigacijski panel: Odaziv | Moment | Podrška – jednako od ruba do ruba, veći elementi
    private var navigationPanel: some View {
        HStack(alignment: .top, spacing: 0) {
            NavigationControlColumn(
                label: "Odaziv",
                valueLabel: "\(Int(appState.dynamicResponse * 100))%",
                step: 0.1
            ) { appState.dynamicResponse = min(1, max(0, appState.dynamicResponse + $0)) }
            .frame(maxWidth: .infinity)

            NavigationControlColumn(
                label: "Okretni moment",
                valueLabel: "\(Int(appState.maxTorqueNm)) Nm",
                step: 1
            ) { appState.maxTorqueNm = min(85, max(20, appState.maxTorqueNm + $0)) }
            .frame(maxWidth: .infinity)

            NavigationControlColumn(
                label: "Podrška",
                valueLabel: "\(Int(appState.supportLevel * 100))%",
                step: 0.1
            ) { appState.supportLevel = min(1, max(0, appState.supportLevel + $0)) }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, islandInnerPadding)
        .padding(.vertical, 10)
    }

    /// Jedan red: Route, Graph, strelica, Bike, Settings. Isti razmak između gumba i do rubova.
    private let iconRowGap: CGFloat = 12
    private var islandIconRow: some View {
        HStack(spacing: iconRowGap) {
            IslandRoundIconButton(image: AppIcons.imageRoute, size: iconSizeExpanded, isSelected: selectedButton == .route) {
                withAnimation(islandSpring) { selectedButton = selectedButton == .route ? nil : .route }
            }
            IslandRoundIconButton(image: AppIcons.imageGraph, size: iconSizeExpanded, isSelected: selectedButton == .graph) {
                withAnimation(islandSpring) { selectedButton = selectedButton == .graph ? nil : .graph }
            }
            IslandRoundIconButton(image: Image(systemName: "chevron.down"), size: iconSizeExpanded, isSelected: false) {
                withAnimation(islandSpring) {
                    selectedButton = nil
                    island.state = .compact
                }
            }
            IslandRoundIconButton(image: AppIcons.imageBike, size: iconSizeExpanded, isSelected: selectedButton == .bike) {
                withAnimation(islandSpring) { selectedButton = selectedButton == .bike ? nil : .bike }
            }
            IslandRoundIconButton(image: AppIcons.imageSettings, size: iconSizeExpanded, isSelected: selectedButton == .settings) {
                withAnimation(islandSpring) { selectedButton = selectedButton == .settings ? nil : .settings }
            }
        }
        .padding(.horizontal, iconRowGap)
        .frame(maxWidth: .infinity)
        .opacity(showButtonsContent ? 1 : 0)
    }

    @ViewBuilder
    private var expandedContent: some View {
        Group {
            if isRideMapActive {
                Group {
                    if showNavigationInstructionsInIsland {
                        navigationInstructionsPanel
                    } else {
                        navigationPanel
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: expandedContentHeight)
                .padding(.horizontal, islandInnerPadding)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else if let selected = selectedButton, showButtonsContent {
                buttonContent(selected)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .frame(maxWidth: .infinity)
                    .frame(height: expandedContentHeight)
            }
        }
        .animation(islandSpringContent, value: selectedButton)
        .animation(islandSpringContent, value: showButtonsContent)
        .animation(islandSpringContent, value: isRideMapActive)
        .animation(islandSpringContent, value: showNavigationInstructionsInIsland)
    }

    /// Dijagonala: od gornjeg kuta prema sredini; kartica mala pa raste. Odbrojavanje do 0 pa sljedeća.
    private static let navFromTopLeadingTransition = AnyTransition.asymmetric(
        insertion: .offset(x: -180, y: -90).combined(with: .scale(scale: 0.35)),
        removal: .offset(x: 120, y: 0).combined(with: .scale(scale: 0.7)).combined(with: .opacity)
    )

    /// Panel navigacije: samo 3 upute, samo ukoso (dijagonalno od gornjeg kuta prema sredini). Kad upališ – točno 3.
    private var navigationInstructionsPanel: some View {
        let visibleThree = Array(navInstructions.prefix(3))
        return ZStack(alignment: .topLeading) {
            // Samo 2 sljedeće – UKOSO: najbliža gornjem lijevom rubu najmanja, druga na dijagonali malo veća
            if visibleThree.count > 2 {
                navInstructionSmallCard(visibleThree[2], size: .smallest)
                    .offset(x: 8, y: 8)
            }
            if visibleThree.count > 1 {
                navInstructionSmallCard(visibleThree[1], size: .medium)
                    .offset(x: 50, y: 30)
            }

            // Sredina: trenutna (najveća), dolazi ukoso
            if let current = visibleThree.first {
                VStack(spacing: 8) {
                    current.icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .foregroundStyle(islandColors.title)
                        .rotationEffect(.degrees(current.kind.rotationDegrees))
                    if navFailed {
                        Text("Povratak: \(navReturnMeters >= 1000 ? String(format: "%.1f km", navReturnMeters / 1000) : "\(Int(navReturnMeters)) m")")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(islandColors.accentGreen)
                    } else {
                        Text(distanceLabel(current.distanceMeters))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(islandColors.title)
                    }
                }
                .frame(minWidth: 88)
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .background(islandColors.buttonBg.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .transition(Self.navFromTopLeadingTransition)
                .id(current.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .animation(islandSpringContent, value: Array(navInstructions.prefix(3)).map(\.id))
        .onAppear {
            if navInstructions.count > 3 {
                navInstructions = Array(navInstructions.prefix(3))
            }
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            guard !navFailed, !navInstructions.isEmpty else { return }
            let first = navInstructions[0]
            let currentD = first.distanceMeters
            // Tek kad je došlo do 0 – prebaci na sljedeći znak. Do tad samo odbrojavaj.
            if currentD <= 0 {
                withAnimation(islandSpringContent) {
                    navInstructions = Array(navInstructions.dropFirst())
                }
                return
            }
            let step: Double = 30
            var nextD = currentD - step
            if nextD < 0 { nextD = 0 }
            // Isti znak, ista id – samo se smanjuje broj do 0
            withAnimation(.easeOut(duration: 0.25)) {
                navInstructions = [NavInstructionItem(id: first.id, kind: first.kind, distanceMeters: nextD)] + Array(navInstructions.dropFirst())
            }
        }
    }

    private enum NavCardSize {
        case smallest, medium
        var iconSize: CGFloat { self == .smallest ? 18 : 24 }
        var frameWidth: CGFloat { self == .smallest ? 36 : 44 }
    }

    private func navInstructionSmallCard(_ item: NavInstructionItem, size: NavCardSize) -> some View {
        VStack(spacing: 2) {
            item.icon
                .resizable()
                .scaledToFit()
                .frame(width: size.iconSize, height: size.iconSize)
                .foregroundStyle(islandColors.secondary)
                .rotationEffect(.degrees(item.kind.rotationDegrees))
            Text(distanceLabel(item.distanceMeters))
                .font(.system(size: size == .smallest ? 9 : 10, weight: .medium))
                .foregroundStyle(islandColors.secondary)
        }
        .frame(width: size.frameWidth)
        .padding(.vertical, 4)
        .background(islandColors.buttonBg.opacity(0.4), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private func distanceLabel(_ meters: Double) -> String {
        if meters >= 1000 { return String(format: "%.1f km", meters / 1000) }
        return "\(Int(meters)) m"
    }

    private var expandedContentHeight: CGFloat {
        switch island.state {
        case .compact: return 0
        case .actions: return isRideMapActive ? 200 : 220
        case .fullStats: return (UIScreen.main.bounds.height * 0.85) - expandedPillSectionHeight - 24
        }
    }

    @ViewBuilder
    private func buttonContent(_ button: IslandSelectedButton) -> some View {
        switch button {
        case .route:
            routeContent
        case .graph:
            graphContent
        case .bike:
            bikeContent
        case .settings:
            settingsContent
        }
    }

    private var routeContent: some View {
        VStack(alignment: .center, spacing: 14) {
            if isMapVisible {
                Button { onCancelFindMe?() } label: {
                    Text("Poništi")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.red)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
            destinationRows
                .frame(maxWidth: .infinity)
            Button { onPokreniNavigaciju?(hasRouteDestinations, routeOrigin, routeDestination) } label: {
                HStack(spacing: 6) {
                    if hasRouteDestinations {
                        AppIcons.imageStart
                            .font(.system(size: 14))
                    }
                    Text(hasRouteDestinations ? "Pokreni navigaciju" : "Pokreni bez navigacije")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Capsule().fill(islandColors.accentGreen))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    /// Redovi za polazište (A) i odredište (B) – TextField + autocomplete europskih lokacija.
    private var destinationRows: some View {
        VStack(spacing: 0) {
            destinationRow(
                icon: "circle.fill",
                iconColor: islandColors.accentGreen,
                label: "Polazište",
                text: $routeOrigin,
                placeholder: "Adresa ili trenutna lokacija",
                field: .origin,
                onUseMyLocation: { routeOrigin = "Trenutna lokacija" }
            )
            Rectangle()
                .fill(islandColors.border)
                .frame(height: 1)
                .padding(.leading, 32)
            destinationRow(
                icon: "circle.fill",
                iconColor: Color.red,
                label: "Odredište",
                text: $routeDestination,
                placeholder: "Unesi adresu odredišta",
                field: .destination,
                onUseMyLocation: { routeDestination = "Trenutna lokacija" }
            )
            if focusedDestinationField != nil, !locationCompleter.results.isEmpty {
                Divider()
                    .background(islandColors.border)
                    .padding(.leading, 32)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(locationCompleter.results.enumerated()), id: \.offset) { _, completion in
                            Button {
                                applySuggestion(completion)
                            } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(islandColors.secondary)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(completion.title)
                                            .font(AppTypography.caption)
                                            .foregroundStyle(islandColors.title)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        if !completion.subtitle.isEmpty {
                                            Text(completion.subtitle)
                                                .font(AppTypography.caption2)
                                                .foregroundStyle(islandColors.secondary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 260)
            }
        }
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(islandColors.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(islandColors.border, lineWidth: 1)
        )
        .onChange(of: focusedDestinationField) { _, newValue in
            switch newValue {
            case .origin:
                locationCompleter.queryFragment = routeOrigin
            case .destination:
                locationCompleter.queryFragment = routeDestination
            case nil:
                locationCompleter.clear()
            }
        }
        .onChange(of: routeOrigin) { _, _ in
            if focusedDestinationField == .origin { locationCompleter.queryFragment = routeOrigin }
        }
        .onChange(of: routeDestination) { _, _ in
            if focusedDestinationField == .destination { locationCompleter.queryFragment = routeDestination }
        }
    }

    private func applySuggestion(_ completion: MKLocalSearchCompletion) {
        let text = [completion.title, completion.subtitle].filter { !$0.isEmpty }.joined(separator: ", ")
        if focusedDestinationField == .origin {
            routeOrigin = text
        } else {
            routeDestination = text
        }
        focusedDestinationField = nil
        locationCompleter.clear()
    }

    private func destinationRow(
        icon: String,
        iconColor: Color,
        label: String,
        text: Binding<String>,
        placeholder: String,
        field: DestinationField,
        onUseMyLocation: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppTypography.caption2)
                    .foregroundStyle(islandColors.secondary)
                TextField(placeholder, text: text)
                    .font(AppTypography.caption)
                    .foregroundStyle(islandColors.title)
                    .textContentType(.fullStreetAddress)
                    .submitLabel(.done)
                    .focused($focusedDestinationField, equals: field)
            }
            Spacer(minLength: 0)
            Button(action: onUseMyLocation) {
                Image(systemName: "location.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(islandColors.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var graphContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistika")
                .font(AppTypography.headline)
                .foregroundStyle(islandColors.titleGradient)
            Text("Grafovi i statistika vožnje.")
                .font(AppTypography.caption)
                .foregroundStyle(islandColors.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var bikeContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bicikl")
                .font(AppTypography.headline)
                .foregroundStyle(islandColors.titleGradient)
            Text("Status bicikla, baterija, motor.")
                .font(AppTypography.caption)
                .foregroundStyle(islandColors.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Postavke")
                .font(AppTypography.headline)
                .foregroundStyle(islandColors.titleGradient)
            Text("Postavke aplikacije i uređaja.")
                .font(AppTypography.caption)
                .foregroundStyle(islandColors.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

}

/// Animacija bijelog gumba (strelica): pritisak smanji scale, otpuštanje spring natrag.
private struct ChevronCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

/// Okrugli gumb za red ikona u islandu (Route, Graph, chevron.down, Bike, Settings).
private struct IslandRoundIconButton: View {
    @Environment(\.islandColors) private var islandColors
    let image: Image
    var size: CGFloat = 40
    var isSelected: Bool = false
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
    }
}

/// Jedan stupac u navigacijskom panelu: gore broj, vertikalno +/− (veći, rastu prema gore), dolje natpis.
private struct NavigationControlColumn: View {
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

/// Gumb na lijevoj strani navigacijskog panela (3 vertikalna). Može SF Symbol (icon) ili custom slika (customImage).
private struct NavigationPanelSideButton: View {
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

private struct IslandActionButton: View {
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

#Preview {
    ZStack(alignment: .bottom) {
        Color.gray.opacity(0.3).ignoresSafeArea()
        PorcheIslandView(island: Island())
    }
}
