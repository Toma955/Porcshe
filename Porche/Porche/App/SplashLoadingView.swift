import SwiftUI

struct SplashLoadingView: View {
    var progress: Double
    var onExitComplete: () -> Void

    @State private var barAppeared = false
    @State private var barHidden = false
    @State private var isExiting = false

    private let amblemThenBarDelay: Double = 0.4
    private let barEntranceDuration: Double = 0.5
    private let barExitDuration: Double = 0.55
    private let holdAtFullDuration: Double = 0.2

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            Image("Porche")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 200, maxHeight: 200)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                progressBar
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + amblemThenBarDelay) {
                withAnimation(.easeOut(duration: barEntranceDuration)) {
                    barAppeared = true
                }
            }
        }
        .onChange(of: progress) { _, p in
            if p >= 1.0, !isExiting {
                isExiting = true
                DispatchQueue.main.asyncAfter(deadline: .now() + holdAtFullDuration) {
                    withAnimation(.easeOut(duration: barExitDuration)) {
                        barHidden = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + barExitDuration + 0.08) {
                        onExitComplete()
                    }
                }
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black.opacity(0.12))
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black)
                    .frame(width: max(0, geo.size.width * progress), height: 4)
                    .animation(.easeInOut(duration: 0.28), value: progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 44)
        .padding(.bottom, 60)
        .opacity(barAppeared && !barHidden ? 1 : 0)
        .animation(.easeOut(duration: barEntranceDuration), value: barAppeared)
        .animation(.easeOut(duration: barExitDuration), value: barHidden)
    }
}

#Preview {
    SplashLoadingView(progress: 0.65) {}
}
