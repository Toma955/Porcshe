import SwiftUI

private let uiTestingLaunchArg = "--uitesting"

enum AppLaunch {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains(uiTestingLaunchArg)
    }
}

@MainActor
final class AppLoader {
    static func run(appState: AppState) {
        appState.loadingProgress = 0
        appState.isAppReady = false

        Task { @MainActor in
            if AppLaunch.isUITesting {
                appState.loadingProgress = 0.5
                try? await Task.sleep(nanoseconds: 200_000_000)
                appState.loadingProgress = 1.0
                appState.onboardingStep = .completed
                appState.isAppReady = true
                return
            }

            let start = Date()
            appState.loadingProgress = 0.1
            try? await Task.sleep(nanoseconds: 100_000_000)

            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                Bike3DSceneView.preloadScene {
                    cont.resume()
                }
            }

            appState.loadingProgress = 0.85
            let elapsed = Date().timeIntervalSince(start)
            if elapsed < 1.0 {
                try? await Task.sleep(nanoseconds: UInt64((1.0 - elapsed) * 1_000_000_000))
            }

            appState.loadingProgress = 1.0
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                appState.isAppReady = true
            }
        }
    }
}
