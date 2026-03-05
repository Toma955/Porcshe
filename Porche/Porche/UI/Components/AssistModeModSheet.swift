import SwiftUI

/// Sheet za izbor moda rada motora (8 modova) – otvara se iz zelenog gumba Mod.
struct AssistModeModSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(AssistMode.allCases, id: \.self) { mode in
                Button {
                    appState.assistMode = mode
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.displayTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(mode.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Mod rada motora")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zatvori") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AssistModeModSheet()
        .environmentObject(AppState())
}
