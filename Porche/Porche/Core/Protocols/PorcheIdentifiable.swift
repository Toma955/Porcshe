import Foundation
protocol PorcheIdentifiable {
    var porcheIdentity: PorcheIdentity? { get }
    func refreshIdentity() async throws
}
