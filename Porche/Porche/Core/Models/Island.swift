import SwiftUI

// MARK: - IslandButtonItem

struct IslandButtonItem: Identifiable {
    let id: String
    let icon: String
    let label: String
    var subtitle: String?
    var action: (() -> Void)?
}
@MainActor
final class Island: ObservableObject {
    static let defaultTitle = "Porsche Ebike"
    @Published var title: String = Island.defaultTitle
    @Published var buttons: [IslandButtonItem] = []
    @Published var state: IslandState = .compact
    @Published var message: String?
    @Published var requestClose: Bool = false
    var isExpanded: Bool { state != .compact }
    func setButtons(_ items: [IslandButtonItem]) {
        buttons = items
    }
    func setTitle(_ newTitle: String) {
        title = newTitle
    }
    func showMessage(_ text: String?) {
        message = text
    }
    func resetToDefault() {
        title = Island.defaultTitle
        buttons = []
        state = .compact
        message = nil
    }
}
