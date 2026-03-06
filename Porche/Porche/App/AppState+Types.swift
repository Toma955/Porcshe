import Foundation

// MARK: - OnboardingStep

enum OnboardingStep {
    case bikeModel
    case welcome
    case permissions
    case completed
}

// MARK: - DevMessage

struct DevMessage: Identifiable {
    let id = UUID()
    let category: DevMessageCategory
    let text: String
    let date: Date
}

// MARK: - DevMessageCategory

enum DevMessageCategory: String, CaseIterable {
    case general = "Općenito"
    case network = "Mreža"
    case bluetooth = "Bluetooth"
    case navigation = "Navigacija"
    case demo = "Demo"
}
