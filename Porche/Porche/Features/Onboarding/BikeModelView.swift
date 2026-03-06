import SwiftUI

// MARK: - BikeModelView

struct BikeModelView: View {
    var rotationSpeed: Double = 0.3
    var onNextAction: (() -> Void)?
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea(.container)
            VStack(spacing: 24) {
                Image(systemName: "bicycle")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
                Text("Porsche Ebike")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack {
                Spacer()
                Button("Nastavi") {
                    onNextAction?()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 48)
            }
        }
    }
}
#Preview {
    BikeModelView(rotationSpeed: 0.4) {}
}
