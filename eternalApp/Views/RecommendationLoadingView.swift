import SwiftUI

struct RecommendationLoadingView: View {

    @State private var rotation: Double    = 0
    @State private var pulse: Bool         = false
    @State private var textIndex: Int      = 0
    @State private var textOpacity: Double = 1

    private let messages = [
        "Analysing your ingredients…",
        "Finding the best matches…",
        "Calculating your budget…",
        "Curating meal suggestions…",
        "Almost there…"
    ]

    var body: some View {
        ZStack {
            // Background — reuse animated gradient
//            AnimatedGradientBackground()

            VStack(spacing: 36) {

                Spacer()

                // Spinning ring + fork icon
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(Color.zomatoAccent.opacity(pulse ? 0.15 : 0.35), lineWidth: 2)
                        .frame(width: 130, height: 130)
                        .scaleEffect(pulse ? 1.18 : 1.0)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)

                    // Spinning arc
                    Circle()
                        .trim(from: 0, to: 0.72)
                        .stroke(
                            LinearGradient(
                                colors: [Color.zomatoAccent, Color(red: 0.95, green: 0.52, blue: 0.18)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 108, height: 108)
                        .rotationEffect(.degrees(rotation))
                        .animation(.linear(duration: 1.1).repeatForever(autoreverses: false), value: rotation)

                    // Inner frosted circle
                    Circle()
                        .fill(.white.opacity(0.06))
                        .frame(width: 80, height: 80)

                    Image(systemName: "fork.knife")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color.zomatoAccent)
                }

                // Cycling status text
                Text(messages[textIndex])
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
                    .padding(.horizontal, 40)

                Spacer()

                Text("Powered by AI · Backed by real grocery data")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.30))
                    .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            rotation = 360
            pulse    = true
            startTextCycle()
        }
    }

    private func startTextCycle() {
        Timer.scheduledTimer(withTimeInterval: 2.2, repeats: true) { timer in
            withAnimation(.easeOut(duration: 0.3)) { textOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                textIndex = (textIndex + 1) % messages.count
                withAnimation(.easeIn(duration: 0.3)) { textOpacity = 1 }
            }
        }
    }
}
