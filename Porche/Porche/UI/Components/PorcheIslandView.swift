import SwiftUI
import MapKit
import UIKit

// MARK: - PorcheIslandView

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
    var onExitRide: (() -> Void)? = nil
    private let collapsedHeight: CGFloat = 88
    private let iconSizeExpanded: CGFloat = 62
    private var expandedPillSectionHeight: CGFloat { iconSizeExpanded + 26 }
    private let horizontalPadding: CGFloat = 20
    private let cornerRadius: CGFloat = 40
    @State private var showButtonsContent = false
    @State private var showNavigationInstructionsInIsland = false
    @State private var navStreet: String = ""
    @State private var navLocation: String = ""
    @State private var navHeadingDegrees: Double = 0
    @State private var navInstructions: [NavInstructionItem] = []
    @State private var navInstructionIndex: Int = 0
    @State private var navFailed: Bool = false
    @State private var navReturnMeters: Double = 0
    private let contentDelay: Double = 0.12
    @State private var selectedButton: IslandSelectedButton?
    @State private var routeOrigin: String = ""
    @State private var routeDestination: String = ""
    @StateObject private var locationCompleter = LocationSearchCompleter()
    @FocusState private var focusedDestinationField: DestinationField?
    @State private var showModPicker = false
    private enum DestinationField {
        case origin, destination
    }
    @State private var pillPageIndex: Int = 0
    @State private var pillDragOffset: CGFloat = 0
    @State private var showAppDevChoice = false
    private var isExpanded: Bool { island.state != .compact }
    private var hasRouteDestinations: Bool { !routeOrigin.isEmpty || !routeDestination.isEmpty }
    private var isRideMapActive: Bool { appState.isRouteActive }
    private var navSpeed: Int { min(99, max(0, appState.navigationSpeed)) }
    private var navGear: Int { min(12, max(0, appState.navigationGear)) }
    private let maxGear: Int = 12
    private var gearRatioText: String { "\(navGear)/\(maxGear)" }
    private var batteryPercent: Int { appState.batteryStatus?.percent ?? 0 }
    private var batteryRangeKm: Double { appState.batteryStatus?.estimatedRangeKm ?? 0 }
    private var hasActiveRoute: Bool { (appState.activeRoute?.waypoints.isEmpty ?? true) == false }
    private var pillPageCount: Int {
        if !isRideMapActive, appState.isAppUnlocked { return 2 }
        if !isRideMapActive { return 1 }
        if hasActiveRoute { return 8 }
        if isRideMapActive { return 7 }
        return 1
    }
    private var pillDefaultPageIndex: Int { 0 }
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
    private func rideModeCompactCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(islandColors.title)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(islandColors.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
    private let islandInnerPadding: CGFloat = 16
    private let rideModeSpeedRowHeight: CGFloat = 40
    private let rideModeButtonsRowHeight: CGFloat = 44
    private let rideModeBottomBarHeight: CGFloat = 56
    private let rideModeStatsRowSpacing: CGFloat = 8
    private let rideModeStatsHorizontalPadding: CGFloat = 10

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                if isExpanded, isRideMapActive, showModPicker {
                    modePickerInIslandContent
                } else if isExpanded, isRideMapActive, appState.showMapControlsInIsland {
                    mapControlsInIslandContent
                } else if isExpanded, isRideMapActive {
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
                            .transition(expandedContentTransition)
                    }
                    if !showNavigationInstructionsInIsland {
                        HStack(spacing: 12) {
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
                            Button {
                                onExitRide?()
                                withAnimation(islandSpring) {
                                    resetExpandedState()
                                    island.state = .compact
                                }
                            } label: {
                                Text("Kraj putovanja")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: rideModeButtonsRowHeight)
                                    .background(Color.red, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, islandInnerPadding)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                    }
                    rideModeBottomBar
                        .padding(.horizontal, islandInnerPadding)
                        .padding(.bottom, islandInnerPadding)
                } else if isExpanded {
                    expandedContent
                        .transition(expandedContentTransition)
                    Spacer(minLength: 0)
                }
                if !isExpanded || !isRideMapActive {
                    pillBar
                }
            }
            .frame(width: islandWidth)
            .frame(height: islandFrameHeight)
            .modifier(IslandShapeModifier(
                cornerRadius: cornerRadius,
                backgroundExpanded: islandColors.backgroundExpanded,
                background: islandColors.background,
                border: islandColors.border,
                isExpanded: isExpanded
            ))
            .shadow(color: islandColors.shadowColor, radius: 16, x: 0, y: 6)
            .animation(islandSpring, value: island.state)
            .animation(islandSpring, value: isTypingLocation)
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
                DispatchQueue.main.async {
                    showAppDevChoice = false
                    resetExpandedState()
                }
            }
        }
        .onChange(of: island.requestClose) { _, requested in
            guard requested else { return }
            withAnimation(islandSpring) { island.state = .compact }
            DispatchQueue.main.async {
                resetExpandedState()
                island.requestClose = false
            }
        }
        .onChange(of: appState.activeRoute) { _, newRoute in
            if let route = newRoute, !route.steps.isEmpty {
                navInstructions = route.steps.map { step in
                    NavInstructionItem(
                        kind: kindFromInstructionText(step.instructionText),
                        distanceMeters: step.distanceMeters,
                        instructionText: step.instructionText
                    )
                }
                navInstructionIndex = 0
            } else {
                navInstructions = []
                navInstructionIndex = 0
            }
        }
    }
    private func kindFromInstructionText(_ text: String) -> NavInstructionKind {
        let t = text.lowercased()
        if t.contains("turn left") || t.contains("skreni lijevo") || t.contains("lijevo") || t.contains("left") { return .turnLeft }
        if t.contains("turn right") || t.contains("skreni desno") || t.contains("desno") || t.contains("right") { return .turnRight }
        if t.contains("turn around") || t.contains("u-turn") || t.contains("obrni") || t.contains("nazad") { return .turnBack }
        if t.contains("continue") || t.contains("head ") || t.contains("keep ") || t.contains("ravno") || t.contains("straight") || t.contains("nastavi") { return .forward }
        return .compass
    }
    private func resetExpandedState() {
        showButtonsContent = false
        selectedButton = nil
        showModPicker = false
        showAppDevChoice = false
        appState.showMapControlsInIsland = false
        showNavigationInstructionsInIsland = false
    }
    private var islandWidth: CGFloat {
        switch island.state {
        case .compact: return UIScreen.main.bounds.width - horizontalPadding * 2
        case .actions: return 392
        case .fullStats: return UIScreen.main.bounds.width - horizontalPadding * 2
        }
    }
    private var isTypingLocation: Bool { selectedButton == .route && focusedDestinationField != nil }
    private var expandedMaxHeight: CGFloat? {
        switch island.state {
        case .compact: return collapsedHeight
        case .actions:
            if isRideMapActive { return expandedHeightForRideMode }
            if selectedButton == .graph || selectedButton == .bike || selectedButton == .settings { return expandedHeightForStatistics }
            if isTypingLocation { return expandedPillSectionHeight + 460 }
            return selectedButton != nil ? (expandedPillSectionHeight + 220) : expandedPillSectionHeight
        case .fullStats: return UIScreen.main.bounds.height * 0.85
        }
    }
    private var expandedHeightForStatistics: CGFloat {
        UIScreen.main.bounds.height * 0.9 - 24
    }
    private var expandedHeightForRideMode: CGFloat {
        let top = islandInnerPadding + rideModeSpeedRowHeight + 6
        let panel: CGFloat = 200
        let buttons = 8 + rideModeButtonsRowHeight + 6
        let bottomBar = rideModeBottomBarHeight + islandInnerPadding
        return top + panel + buttons + bottomBar
    }
    private var expandedHeightForModePicker: CGFloat {
        let topPadding: CGFloat = islandInnerPadding
        let rowHeight: CGFloat = 44
        let listHeight = CGFloat(AssistMode.allCases.count) * rowHeight
        let chevronArea: CGFloat = rideModeChevronRoundSize + islandInnerPadding * 2
        return topPadding + min(listHeight, 320) + chevronArea
    }
    private var expandedHeightForMapControls: CGFloat {
        let top: CGFloat = islandInnerPadding
        let sideBtnSize: CGFloat = 52
        let sideGap: CGFloat = 12
        let contentH: CGFloat = 3 * sideBtnSize + 2 * sideGap
        let chevronArea: CGFloat = rideModeChevronRoundSize + islandInnerPadding * 2
        return top + contentH + 14 + chevronArea
    }
    private var islandFrameHeight: CGFloat {
        switch island.state {
        case .compact: return collapsedHeight
        case .actions:
            if isRideMapActive, showModPicker { return expandedHeightForModePicker }
            if isRideMapActive, appState.showMapControlsInIsland { return expandedHeightForMapControls }
            if isRideMapActive { return expandedHeightForRideMode }
            if selectedButton == .graph || selectedButton == .bike || selectedButton == .settings { return expandedHeightForStatistics }
            if isTypingLocation { return expandedPillSectionHeight + 460 }
            return selectedButton != nil ? (expandedPillSectionHeight + 220) : expandedPillSectionHeight
        case .fullStats: return UIScreen.main.bounds.height * 0.85
        }
    }
    private var pillBar: some View {
        Group {
            if isExpanded {
                if !isRideMapActive {
                    if appState.isShowingAppWelcomeMessage {
                        appWelcomeMessageRow
                    } else if showAppDevChoice {
                        appDevChoiceRow
                    } else {
                        islandIconRow
                    }
                }
            } else {
                swipeablePillContent
            }
        }
        .padding(.vertical, isExpanded ? 14 : 0)
        .padding(.horizontal, isExpanded ? iconRowGap : (pillPageCount >= 2 ? 0 : 20))
    }

    private var appWelcomeMessageRow: some View {
        Text("Porsche Ebike spojen")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(islandColors.title)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .opacity(appState.isShowingAppWelcomeMessage ? 1 : 0)
    }

    private let appDevButtonWidth: CGFloat = 100
    private let appDevButtonHeight: CGFloat = 40

    private var appDevChoiceRow: some View {
        HStack(spacing: 16) {
            Button {
                appState.isShowingAppWelcomeMessage = true
                WelcomeSoundService.playWelcomeSound()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(islandSpring) {
                        appState.hasCompletedAppWelcome = true
                        appState.isAppUnlocked = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                    withAnimation(islandSpring) {
                        appState.isShowingAppWelcomeMessage = false
                        showAppDevChoice = false
                    }
                }
            } label: {
                Text("App")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: appDevButtonWidth, height: appDevButtonHeight)
                    .background(islandColors.accentGreen, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            Button {
                appState.isDemoMode = true
                appState.isShowingAppWelcomeMessage = true
                WelcomeSoundService.playWelcomeSound()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(islandSpring) {
                        appState.hasCompletedAppWelcome = true
                        appState.isAppUnlocked = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(islandSpring) {
                        appState.isShowingAppWelcomeMessage = false
                        showAppDevChoice = false
                    }
                    runDevModeFlow()
                }
            } label: {
                Text("Dev")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: appDevButtonWidth, height: appDevButtonHeight)
                    .background(islandColors.buttonBg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(islandColors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .opacity(showAppDevChoice ? 1 : 0)
    }
    private let minPillContentWidth: CGFloat = 280
    private var swipeablePillContent: some View {
        Group {
            if pillPageCount >= 2 {
                TabView(selection: $pillPageIndex) {
                    ForEach(0..<pillPageCount, id: \.self) { index in
                        pillPillContent(at: index, pageWidth: islandWidth)
                            .frame(maxWidth: .infinity)
                            .offset(y: 6)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(width: islandWidth, height: collapsedHeight)
                .onTapGesture {
                    withAnimation(islandSpring) {
                        if !appState.hasCompletedAppWelcome { showAppDevChoice = true }
                        island.state = .actions
                    }
                }
            } else {
                GeometryReader { geo in
                    pillPillContent(at: 0, pageWidth: geo.size.width)
                        .frame(width: geo.size.width, height: collapsedHeight)
                        .offset(y: 6)
                }
                .frame(height: collapsedHeight)
                .onTapGesture {
                    withAnimation(islandSpring) {
                        if !appState.hasCompletedAppWelcome { showAppDevChoice = true }
                        island.state = .actions
                    }
                }
            }
        }
        .frame(width: pillPageCount >= 2 ? islandWidth : nil, height: collapsedHeight)
        .padding(.horizontal, pillPageCount >= 2 ? 0 : 20)
        .onChange(of: isRideMapActive) { _, active in
            pillPageIndex = pillDefaultPageIndex
            pillDragOffset = 0
            if active { appState.tripStartedAt = Date() }
            if !active { appState.tripStartedAt = nil }
        }
        .onChange(of: hasActiveRoute) { _, _ in pillPageIndex = pillDefaultPageIndex }
        .onChange(of: appState.isAppUnlocked) { _, _ in pillPageIndex = pillDefaultPageIndex; pillDragOffset = 0 }
        .onChange(of: island.state) { _, newState in
            if newState == .compact {
                DispatchQueue.main.async {
                    pillPageIndex = pillDefaultPageIndex
                    pillDragOffset = 0
                }
            }
        }
        .onAppear { pillPageIndex = pillDefaultPageIndex; pillDragOffset = 0 }
    }
    @ViewBuilder
    private func pillPillContent(at index: Int, pageWidth w: CGFloat) -> some View {
        Group {
            if !isRideMapActive, appState.isAppUnlocked {
                switch index {
                case 0: pillElementPorcheEbike
                case 1: pillElementBaterija
                default: pillElementPorcheEbike
                }
            } else if !isRideMapActive {
                pillElementPorcheEbike
            } else if hasActiveRoute {
                switch index {
                case 0: pillElementVožnjaStats
                case 1: pillElementBaterija
                case 2: pillElementGearMode
                case 3: pillElementChargingMode
                case 4: pillElementTemperatureMode
                case 5: pillElementTripMode
                case 6: pillElementHeartbeatMode
                case 7: pillElementGpsUpute
                default: pillElementVožnjaStats
                }
            } else {
                switch index {
                case 0: pillElementVožnjaStats
                case 1: pillElementBaterija
                case 2: pillElementGearMode
                case 3: pillElementChargingMode
                case 4: pillElementTemperatureMode
                case 5: pillElementTripMode
                case 6: pillElementHeartbeatMode
                default: pillElementVožnjaStats
                }
            }
        }
        .frame(width: w, height: collapsedHeight)
        .clipped()
        .id(index)
    }

    private var pillElementPorcheEbike: some View {
        ZStack {
            VStack(alignment: .center, spacing: 6) {
                Text(appState.hasCompletedAppWelcome ? "Porsche Ebike" : "Porsche")
                    .font(AppTypography.headline)
                    .foregroundStyle(islandColors.titleGradient)
                    .multilineTextAlignment(.center)
                if appState.isDemoMode {
                    devMessagesStrip
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: collapsedHeight)
        .padding(.vertical, appState.isDemoMode && !appState.devMessages.isEmpty ? 8 : 0)
    }

    private var pillElementBaterija: some View {
        let green = islandColors.accentGreen
        return ZStack {
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: batteryIconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(green)
                    Text("\(batteryPercent) %")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(green)
                }
                HStack(spacing: 6) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(green)
                    Text("\(appState.motorTempCelsius ?? 0) °C")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(green)
                }
                HStack(spacing: 6) {
                    Image(systemName: "powerplug.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(green)
                    Text("0:00 min")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(green)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: collapsedHeight)
    }

    private var pillElementGearMode: some View {
        let green = islandColors.accentGreen
        return ZStack {
            HStack(spacing: 10) {
                Button {
                    appState.navigationGear = min(maxGear, max(0, appState.navigationGear + 1))
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 32, height: 32)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
                Text("\(appState.navigationGear)/\(maxGear)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 40)
                Button {
                    appState.navigationGear = min(maxGear, max(0, appState.navigationGear - 1))
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 32, height: 32)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
                Button {
                    appState.isAutoGearOn.toggle()
                } label: {
                    Text(appState.isAutoGearOn ? "AUTO" : "OFF")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(appState.isAutoGearOn ? .white : .red)
                        .frame(width: 48, height: 36)
                        .background(appState.isAutoGearOn ? green : Color.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                Button {
                    appState.gearModeSmallValue = min(3, max(0, appState.gearModeSmallValue - 1))
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 28, height: 28)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
                Text("\(appState.gearModeSmallValue)/3")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 28)
                Button {
                    appState.gearModeSmallValue = min(3, max(0, appState.gearModeSmallValue + 1))
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 28, height: 28)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: collapsedHeight)
    }

    private var pillElementChargingMode: some View {
        let green = islandColors.accentGreen
        let barHeight: CGFloat = 10
        let trackColor = Color.white.opacity(0.2)
        let consumption = appState.motorConsumptionWatts ?? 0
        let consumptionAbs = min(50, abs(consumption))
        let redFraction = consumption != 0 ? CGFloat(consumptionAbs) / 50.0 : CGFloat(appState.chargingMotorPercent / 100)
        let centerText = consumption != 0 ? "\(consumption) W" : "0%"
        return ZStack {
            HStack(spacing: 10) {
                AppIcons.imagePart(.engine)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(islandColors.title)
                GeometryReader { geo in
                    let w = geo.size.width
                    let centerW: CGFloat = 44
                    let half = max(0, (w - centerW) / 2)
                    let redW = half * redFraction
                    let greenW = half * CGFloat(appState.chargingBatteryPercent / 20)
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                            .fill(trackColor)
                            .frame(height: barHeight)
                        HStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Spacer(minLength: 0)
                                RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                                    .fill(Color.red)
                                    .frame(width: max(0, redW), height: barHeight)
                            }
                            .frame(width: half)
                            Text(centerText)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(consumption != 0 ? .red : .white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(width: centerW)
                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                                    .fill(green)
                                    .frame(width: max(0, greenW), height: barHeight)
                                Spacer(minLength: 0)
                            }
                            .frame(width: half)
                        }
                        .frame(height: barHeight)
                    }
                }
                .frame(height: barHeight)
                AppIcons.imagePart(.batery)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(islandColors.title)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: collapsedHeight)
    }

    private var pillElementTemperatureMode: some View {
        ZStack {
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    AppIcons.imagePart(.engine)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(islandColors.title)
                    Text("\(appState.motorTempCelsius ?? 0) °C")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(islandColors.title)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 4) {
                    AppIcons.imagePart(.batery)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(islandColors.title)
                    Text("\(appState.batteryTempCelsius ?? 0) °C")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(islandColors.title)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 4) {
                    AppIcons.imagePart(.brake)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(islandColors.title)
                    Text("\(appState.brakeTempCelsius ?? 0) °C")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(islandColors.title)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: collapsedHeight)
    }

    private var pillElementTripMode: some View {
        ZStack {
            TimelineView(.periodic(from: .now, by: 1.0)) { _ in
                HStack(spacing: 16) {
                    Text(tripElapsedForDisplay)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("\(tripCaloriesForDisplay) kcal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(islandColors.title)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: collapsedHeight)
    }

    private var tripElapsedForDisplay: String {
        let start = appState.tripStartedAt ?? Date()
        let sec = isRideMapActive ? Date().timeIntervalSince(start) : 0
        let h = Int(sec) / 3600
        let m = (Int(sec) % 3600) / 60
        let s = Int(sec) % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }

    private var tripCaloriesForDisplay: Int {
        let start = appState.tripStartedAt ?? Date()
        let sec = isRideMapActive ? Date().timeIntervalSince(start) : 0
        let minutes = sec / 60
        return Int(minutes * 6)
    }

    private var pillElementHeartbeatMode: some View {
        let bpm = appState.heartRateBPM ?? 0
        return ZStack {
            HStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.red)
                heartPulsePath
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 80, height: 28)
                Text("\(bpm)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.red)
                Text("BPM")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.red)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: collapsedHeight)
    }

    private var heartPulsePath: Path {
        var p = Path()
        let w: CGFloat = 80
        let h: CGFloat = 24
        p.move(to: CGPoint(x: 0, y: h / 2))
        p.addLine(to: CGPoint(x: w * 0.2, y: h / 2))
        p.addLine(to: CGPoint(x: w * 0.3, y: h * 0.2))
        p.addLine(to: CGPoint(x: w * 0.4, y: h * 0.8))
        p.addLine(to: CGPoint(x: w * 0.5, y: h / 2))
        p.addLine(to: CGPoint(x: w * 0.6, y: h / 2))
        p.addLine(to: CGPoint(x: w * 0.7, y: h * 0.3))
        p.addLine(to: CGPoint(x: w * 0.8, y: h * 0.7))
        p.addLine(to: CGPoint(x: w, y: h / 2))
        return p
    }

    private var pillElementWeatherMode: some View {
        let rainText = appState.weatherRainInMinutes.map { "Kiša za \($0) min" } ?? ""
        return ZStack {
            HStack(spacing: 14) {
                Image(systemName: "cloud.rain.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(islandColors.title)
                VStack(spacing: 2) {
                    Text(appState.weatherLocationName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(islandColors.title)
                    Text(appState.weatherCondition)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(islandColors.secondary)
                    if !rainText.isEmpty {
                        Text(rainText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(islandColors.accentGreen)
                    }
                }
                .frame(maxWidth: .infinity)
                Text("\(appState.weatherTemperatureCelsius) °C")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(islandColors.title)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: collapsedHeight)
    }

    private func pillPlaceholderElement(title: String, icon: String) -> some View {
        ZStack {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(islandColors.accentGreen)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(islandColors.title)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: collapsedHeight)
    }

    private var batteryIconName: String {
        let p = batteryPercent
        if p >= 95 { return "battery.100percent" }
        if p >= 75 { return "battery.75percent" }
        if p >= 50 { return "battery.50percent" }
        if p >= 25 { return "battery.25percent" }
        return "battery.0percent"
    }

    private var devMessagesStrip: some View {
        Group {
            if appState.devMessages.isEmpty {
                Text("Nema poruka")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(islandColors.secondary)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(appState.devMessages) { msg in
                            HStack(alignment: .top, spacing: 6) {
                                Text("[\(msg.category.rawValue)]")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(islandColors.accentGreen)
                                Text(msg.text)
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundStyle(islandColors.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 72)
            }
        }
    }
    private var pillTemperaturesView: some View {
        HStack(spacing: 12) {
            Image(systemName: "thermometer.medium")
                .font(.system(size: 24))
                .foregroundStyle(islandColors.secondary)
            VStack(alignment: .leading, spacing: 4) {
                labelValueRow("Motor", value: appState.motorTempCelsius.map { "\($0) °C" } ?? "—")
                labelValueRow("Baterija", value: appState.batteryTempCelsius.map { "\($0) °C" } ?? "—")
                labelValueRow("Kočnice", value: appState.brakeTempCelsius.map { "\($0) °C" } ?? "—")
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(islandColors.title)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: collapsedHeight)
        .padding(.horizontal, 16)
    }
    private func labelValueRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(islandColors.secondary)
            Spacer(minLength: 8)
            Text(value)
        }
    }
    private var pillChargingView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "battery.100percent")
                    .font(.system(size: 24))
                    .foregroundStyle(islandColors.title)
                if appState.isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.yellow)
                }
                Text(appState.isCharging ? "Punjenje" : "Baterija")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(islandColors.title)
            }
            Text("\(batteryPercent) %")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(islandColors.title)
            if appState.isCharging {
                let min = appState.minutesToFullCharge ?? 0
                Text(min > 0 ? "Do 100%: \(min) min" : "Do 100%: — min")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(islandColors.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: collapsedHeight)
    }
    private var pillRideStatsView: some View {
        HStack(spacing: rideModeStatsRowSpacing) {
            rideModeCompactCell(value: "\(navSpeed)", label: "km/h")
            rideModeCompactCell(value: gearRatioText, label: "Prijenos")
            rideModeCompactCell(value: "\(batteryPercent)", label: "Baterija")
            rideModeCompactCell(value: String(format: "%.0f", batteryRangeKm), label: "Domet")
        }
        .frame(maxWidth: .infinity)
        .frame(height: collapsedHeight)
        .padding(.horizontal, rideModeStatsHorizontalPadding)
    }

    private var pillElementVožnjaStats: some View {
        ZStack {
            HStack(spacing: rideModeStatsRowSpacing) {
                rideModeCompactCell(value: "\(navSpeed)", label: "km/h")
                rideModeCompactCell(value: gearRatioText, label: "Prijenos")
                rideModeCompactCell(value: "\(batteryPercent)", label: "Baterija")
                rideModeCompactCell(value: String(format: "%.0f", batteryRangeKm), label: "Domet")
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, rideModeStatsHorizontalPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: collapsedHeight)
    }
    private var pillElementGpsUpute: some View {
        let (meters, instruction) = navCountdownToNextTurn
        let instr = instruction ?? "Slijedite rutu"
        let rainText = appState.weatherRainInMinutes.map { "Kiša za \($0) min" } ?? ""
        return ZStack {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: navTurnIcon(instr))
                        .font(.system(size: 28))
                        .foregroundStyle(islandColors.accentGreen)
                    VStack(spacing: 4) {
                        Text(instr)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(islandColors.title)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        Text(meters >= 0 ? "Za \(Int(meters)) m" : "—")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(islandColors.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                HStack(spacing: 8) {
                    Text(appState.weatherLocationName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(islandColors.title)
                    Text(appState.weatherCondition)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(islandColors.secondary)
                    Text("\(appState.weatherTemperatureCelsius) °C")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(islandColors.title)
                    if !rainText.isEmpty {
                        Text(rainText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(islandColors.accentGreen)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: collapsedHeight)
    }

    private var pillNavCountdownView: some View {
        let (meters, instruction) = navCountdownToNextTurn
        return VStack(spacing: 6) {
            if let instr = instruction {
                Image(systemName: navTurnIcon(instr))
                    .font(.system(size: 28))
                    .foregroundStyle(islandColors.title)
            }
            Text(meters >= 0 ? "Za \(Int(meters)) m" : "—")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(islandColors.title)
            Text("Do sljedeće upute")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(islandColors.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: collapsedHeight)
    }
    private var navCountdownToNextTurn: (meters: Double, instruction: String?) {
        guard let route = appState.activeRoute, !route.steps.isEmpty else { return (-1, nil) }
        let progress = appState.routeProgressAlongLine
        let totalLen = route.steps.reduce(0.0) { $0 + Double($1.distanceMeters) }
        let currentLen = progress * totalLen
        var acc: Double = 0
        for (_, step) in route.steps.enumerated() {
            let stepEnd = acc + Double(step.distanceMeters)
            if stepEnd > currentLen {
                let toNext = stepEnd - currentLen
                return (toNext, step.instructionText)
            }
            acc = stepEnd
        }
        return (0, route.steps.last?.instructionText)
    }
    private func navTurnIcon(_ text: String) -> String {
        let t = text.lowercased()
        if t.contains("lijevo") || t.contains("left") { return "arrow.turn.up.left" }
        if t.contains("desno") || t.contains("right") { return "arrow.turn.up.right" }
        if t.contains("ravno") || t.contains("straight") { return "arrow.up" }
        return "location.north.fill"
    }
    private var pillDistanceAtoBView: some View {
        let (total, remaining) = routeDistanceAtoB
        return VStack(spacing: 6) {
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                .font(.system(size: 24))
                .foregroundStyle(islandColors.title)
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(Int(remaining / 1000)) km")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(islandColors.title)
                    Text("Preostalo")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(islandColors.secondary)
                }
                VStack(spacing: 2) {
                    Text("\(Int(total / 1000)) km")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(islandColors.secondary)
                    Text("Ukupno")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(islandColors.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: collapsedHeight)
    }
    private var routeDistanceAtoB: (totalM: Double, remainingM: Double) {
        guard let route = appState.activeRoute, !route.steps.isEmpty else { return (0, 0) }
        let total = route.steps.reduce(0.0) { $0 + Double($1.distanceMeters) }
        let progress = appState.routeProgressAlongLine
        let remaining = (1 - progress) * total
        return (total, remaining)
    }
    private var pillHeartView: some View {
        let bpm = appState.heartRateBPM ?? 0
        return VStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(size: 32))
                .foregroundStyle(.red)
            Text(bpm > 0 ? "\(bpm) BPM" : "—")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(islandColors.title)
            Text("Otkucaj srca")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(islandColors.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: collapsedHeight)
    }
    private let rideModeCircleButtonSize: CGFloat = 44
    private let rideModeChevronRoundSize: CGFloat = 52
    private let rideModeBarSpacing: CGFloat = 16
    private let navPrevNextButtonSize: CGFloat = 44
    private var rideModeBottomBar: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if showNavigationInstructionsInIsland {
                IslandCircleIconButton(size: navPrevNextButtonSize, backgroundColor: islandColors.buttonBg, foregroundColor: .white) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 18, weight: .semibold))
                } action: {
                    withAnimation(islandSpring) {
                        navInstructionIndex = max(0, navInstructionIndex - 1)
                    }
                }
                .disabled(navInstructions.isEmpty || navInstructionIndex <= 0)
                .opacity((navInstructions.isEmpty || navInstructionIndex <= 0) ? 0.5 : 1)
                Spacer(minLength: 0)
                IslandChevronCloseButton(size: rideModeChevronRoundSize) {
                    withAnimation(islandSpring) { showNavigationInstructionsInIsland = false }
                }
                Spacer(minLength: 0)
                IslandCircleIconButton(size: navPrevNextButtonSize, backgroundColor: islandColors.buttonBg, foregroundColor: .white) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .semibold))
                } action: {
                    withAnimation(islandSpring) {
                        navInstructionIndex = min(navInstructions.count - 1, navInstructionIndex + 1)
                    }
                }
                .disabled(navInstructions.isEmpty || navInstructionIndex >= navInstructions.count - 1)
                .opacity((navInstructions.isEmpty || navInstructionIndex >= navInstructions.count - 1) ? 0.5 : 1)
            } else {
                HStack(spacing: rideModeBarSpacing) {
                    IslandCircleIconButton(
                        size: rideModeCircleButtonSize,
                        backgroundColor: appState.isNightRidingMode ? AppColors.nightRidingOrange : islandColors.buttonBg,
                        foregroundColor: islandColors.title
                    ) {
                        AppIcons.imageMoon
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    } action: {
                        appState.isNightRidingMode.toggle()
                    }
                    IslandCircleIconButton(size: rideModeCircleButtonSize, backgroundColor: islandColors.buttonBg, foregroundColor: islandColors.title) {
                        AppIcons.imagePaths
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    } action: {
                        withAnimation(islandSpring) { showNavigationInstructionsInIsland = true }
                    }
                    IslandChevronCloseButton(size: rideModeChevronRoundSize) {
                        withAnimation(islandSpring) {
                            selectedButton = nil
                            island.state = .compact
                            showNavigationInstructionsInIsland = false
                        }
                    }
                    IslandCircleIconButton(size: rideModeCircleButtonSize, backgroundColor: islandColors.buttonBg, foregroundColor: islandColors.title) {
                        AppIcons.imageIsland
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    } action: {
                        withAnimation(islandSpring) {
                            resetExpandedState()
                            island.state = .compact
                        }
                    }
                    IslandCircleIconButton(size: rideModeCircleButtonSize, backgroundColor: islandColors.buttonBg, foregroundColor: islandColors.title) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 18))
                    } action: {
                        withAnimation(islandSpring) { appState.showMapControlsInIsland.toggle() }
                    }
                }
                .padding(.horizontal, rideModeBarSpacing)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: rideModeBottomBarHeight)
    }
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
            IslandChevronCloseButton(size: rideModeChevronRoundSize) {
                withAnimation(islandSpring) { showModPicker = false }
            }
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
    private var mapControlsInIslandContent: some View {
        let sideBtnSize: CGFloat = 52
        let sideGap: CGFloat = 12
        let contentHeight: CGFloat = 3 * sideBtnSize + 2 * sideGap
        let arrowSize: CGFloat = 34
        let centerBtnSize: CGFloat = 32
        let colGap: CGFloat = 18
        return VStack(spacing: 0) {
            HStack(alignment: .center, spacing: colGap) {
                VStack(spacing: sideGap) {
                    Button {
                        appState.mapStyle = mapStyleNext(appState.mapStyle)
                    } label: {
                        Image(systemName: mapStyleIcon(appState.mapStyle))
                            .font(.system(size: 20))
                            .foregroundStyle(islandColors.accentGreen)
                            .frame(width: sideBtnSize, height: sideBtnSize)
                            .background(islandColors.accentGreen.opacity(0.25), in: Circle())
                    }
                    .buttonStyle(.plain)
                    Button {
                        appState.mapCameraDistance = max(200, appState.mapCameraDistance - 80)
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundStyle(islandColors.title)
                            .frame(width: sideBtnSize, height: sideBtnSize)
                            .background(islandColors.buttonBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                    Button {
                        appState.mapCameraDistance = min(2000, appState.mapCameraDistance + 80)
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundStyle(islandColors.title)
                            .frame(width: sideBtnSize, height: sideBtnSize)
                            .background(islandColors.buttonBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: contentHeight)
                .frame(maxWidth: .infinity)
                VStack(spacing: 6) {
                    Button {
                        let hasRoute = appState.activeRoute.map { !$0.waypoints.isEmpty } ?? false
                        if hasRoute {
                            let start = appState.mapPivotProgress
                            let end = min(1.0, start + 0.10)
                            let steps = 12
                            let duration = 0.38
                            for step in 1...steps {
                                let delay = duration * Double(step) / Double(steps)
                                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                    let fraction = Double(step) / Double(steps)
                                    appState.mapPivotProgress = start + (end - start) * fraction
                                }
                            }
                        } else {
                            appState.mapCameraDistance = min(2000, appState.mapCameraDistance + 80)
                        }
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
                            let hasRoute = appState.activeRoute.map { !$0.waypoints.isEmpty } ?? false
                            if hasRoute {
                                appState.focusMapOnBikeTrigger += 1
                            } else {
                                appState.focusMapOnUserLocationTrigger += 1
                            }
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
                        let hasRoute = appState.activeRoute.map { !$0.waypoints.isEmpty } ?? false
                        if hasRoute {
                            let start = appState.mapPivotProgress
                            let end = max(0.0, start - 0.10)
                            let steps = 12
                            let duration = 0.38
                            for step in 1...steps {
                                let delay = duration * Double(step) / Double(steps)
                                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                    let fraction = Double(step) / Double(steps)
                                    appState.mapPivotProgress = start + (end - start) * fraction
                                }
                            }
                        } else {
                            appState.mapCameraDistance = max(200, appState.mapCameraDistance - 80)
                        }
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
            IslandChevronCloseButton(size: rideModeChevronRoundSize) {
                withAnimation(islandSpring) { appState.showMapControlsInIsland = false }
            }
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
    private func mapStyleNext(_ style: MapTerrainStyle) -> MapTerrainStyle {
        switch style {
        case .standard: return .satellite
        case .satellite: return .hybrid
        case .hybrid, .flyover: return .standard
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
    private let iconRowGap: CGFloat = 12
    private var islandIconRow: some View {
        HStack(spacing: iconRowGap) {
            IslandRoundIconButton(image: AppIcons.imageRoute, size: iconSizeExpanded, isSelected: selectedButton == .route, accessibilityId: "islandButtonRoute") {
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
    private var navigationInstructionsPanel: some View {
        Group {
            if navInstructions.isEmpty {
                Text("Upute će se prikazati tijekom navigacije")
                    .font(.subheadline)
                    .foregroundStyle(islandColors.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if navInstructionIndex < navInstructions.count {
                let item = navInstructions[navInstructionIndex]
                VStack(spacing: 10) {
                    HStack(alignment: .center, spacing: 14) {
                        item.icon
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundStyle(islandColors.accentGreen)
                            .rotationEffect(.degrees(item.kind.rotationDegrees))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.instructionText.isEmpty ? navKindDefaultLabel(item.kind) : item.instructionText)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(islandColors.title)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Text(distanceLabel(item.distanceMeters))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(islandColors.secondary)
                        }
                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(islandColors.buttonBg.opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Text("\(navInstructionIndex + 1) / \(navInstructions.count)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(islandColors.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
    private func navKindDefaultLabel(_ kind: NavInstructionKind) -> String {
        switch kind {
        case .turnLeft: return "Skreni lijevo"
        case .turnRight: return "Skreni desno"
        case .forward: return "Ravno"
        case .turnBack: return "Polukružno se okreni"
        case .compass: return "Slijedi rutu"
        }
    }
    private func distanceLabel(_ meters: Double) -> String {
        if meters >= 1000 { return String(format: "%.1f km", meters / 1000) }
        return "\(Int(meters)) m"
    }
    private var expandedContentHeight: CGFloat {
        switch island.state {
        case .compact: return 0
        case .actions:
            if selectedButton == .graph || selectedButton == .bike || selectedButton == .settings {
                return expandedHeightForStatistics - expandedPillSectionHeight - 24 - 60
            }
            if isTypingLocation { return 460 }
            return isRideMapActive ? 200 : 220
        case .fullStats: return (UIScreen.main.bounds.height * 0.85) - expandedPillSectionHeight - 24
        }
    }
    @ViewBuilder
    private func buttonContent(_ button: IslandSelectedButton) -> some View {
        switch button {
        case .route:
            routeContent
        case .graph:
            IslandGraphContent(appState: appState, onDismiss: { withAnimation(islandSpring) { selectedButton = nil } })
        case .bike:
            IslandBikeContent(appState: appState)
        case .settings:
            IslandSettingsContent(appState: appState)
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
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    Text(hasRouteDestinations ? "Pokreni navigaciju" : "Pokreni bez navigacije")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(height: 44)
                .background(Capsule().fill(islandColors.accentGreen))
            }
            .buttonStyle(.plain)
            .fixedSize(horizontal: true, vertical: true)
            .accessibilityIdentifier("pokreniNavigacijuButton")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    private var destinationRows: some View {
        VStack(spacing: 0) {
            destinationRow(
                icon: "circle.fill",
                iconColor: islandColors.accentGreen,
                label: "Polazište",
                text: $routeOrigin,
                placeholder: "Adresa ili trenutna lokacija",
                field: .origin,
                fieldAccessibilityId: "routeOriginField",
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
                fieldAccessibilityId: "routeDestinationField",
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
                .frame(maxHeight: 320)
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
        fieldAccessibilityId: String,
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
                    .accessibilityIdentifier(fieldAccessibilityId)
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
    private func runDevModeFlow() {
        Task { @MainActor in
            withAnimation(islandSpring) { selectedButton = .route }
            try? await Task.sleep(for: .milliseconds(500))
            let origin = "Trg Bana Jelačića"
            routeOrigin = ""
            for c in origin {
                routeOrigin += String(c)
                try? await Task.sleep(for: .milliseconds(45))
            }
            try? await Task.sleep(for: .milliseconds(300))
            let dest = "Jarun Park"
            routeDestination = ""
            for c in dest {
                routeDestination += String(c)
                try? await Task.sleep(for: .milliseconds(45))
            }
            try? await Task.sleep(for: .milliseconds(500))
            onPokreniNavigaciju?(true, routeOrigin, routeDestination)
        }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color.gray.opacity(0.3).ignoresSafeArea()
        PorcheIslandView(island: Island())
    }
}
