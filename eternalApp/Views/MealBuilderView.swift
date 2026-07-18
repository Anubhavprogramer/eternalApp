import SwiftUI

// MARK: - Typewriter Text

private struct TypewriterText: View {
    let fullText: String
    let font: Font
    let delay: Double
    var charInterval: Double = 0.045  // seconds per character
    var pauseAfterFinish: Double = 1.2 // pause before erasing
    var eraseInterval: Double = 0.025  // faster erase

    @State private var displayed: String = ""
    @State private var isErasing: Bool   = false

    var body: some View {
        Text(displayed)
            .font(font)
            .onAppear { scheduleNextCycle(initialDelay: delay) }
    }

    // Kick off a full type → pause → erase → repeat cycle
    private func scheduleNextCycle(initialDelay: Double) {
        displayed  = ""
        isErasing  = false
        typeChar(index: 0, startDelay: initialDelay)
    }

    private func typeChar(index: Int, startDelay: Double) {
        let chars = Array(fullText)
        guard index < chars.count else {
            // Finished typing — pause then start erasing
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + pauseAfterFinish) {
                eraseChar(from: chars.count - 1)
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + Double(index) * charInterval) {
            displayed.append(chars[index])
            typeChar(index: index + 1, startDelay: startDelay)
        }
    }

    private func eraseChar(from index: Int) {
        guard index >= 0 else {
            // Fully erased — restart after a brief gap
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                scheduleNextCycle(initialDelay: 0)
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(Array(fullText).count - 1 - index) * eraseInterval) {
            if !displayed.isEmpty { displayed.removeLast() }
            eraseChar(from: index - 1)
        }
    }
}

// MARK: - Animated Gradient Background

private struct AnimatedGradientBackground: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                // Base dark fill
                ctx.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color(red: 0.08, green: 0.07, blue: 0.10))
                )

                // Blob 1 — slow diagonal drift, accent red
                let b1x = size.width  * (0.20 + 0.30 * sin(t * 0.18))
                let b1y = size.height * (0.20 + 0.25 * cos(t * 0.14))
                let blob1 = Path(ellipseIn: CGRect(
                    x: b1x - 160, y: b1y - 160, width: 320, height: 320))
                ctx.fill(blob1, with: .color(
                    Color(red: 0.90, green: 0.22, blue: 0.28).opacity(0.28)))

                // Blob 2 — opposite phase, warm orange
                let b2x = size.width  * (0.75 + 0.22 * cos(t * 0.13))
                let b2y = size.height * (0.65 + 0.20 * sin(t * 0.17))
                let blob2 = Path(ellipseIn: CGRect(
                    x: b2x - 180, y: b2y - 180, width: 360, height: 360))
                ctx.fill(blob2, with: .color(
                    Color(red: 0.80, green: 0.30, blue: 0.10).opacity(0.20)))

                // Blob 3 — small, slow, top-right, deep purple tint
                let b3x = size.width  * (0.80 + 0.12 * sin(t * 0.09))
                let b3y = size.height * (0.12 + 0.14 * cos(t * 0.11))
                let blob3 = Path(ellipseIn: CGRect(
                    x: b3x - 120, y: b3y - 120, width: 240, height: 240))
                ctx.fill(blob3, with: .color(
                    Color(red: 0.40, green: 0.15, blue: 0.55).opacity(0.18)))
            }
            .blur(radius: 60)   // soft edges, no hard transitions
        }
        .ignoresSafeArea()
    }
}

struct MealBuilderView: View {
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var envDismiss

    // Banner
    @State private var shimmerOffset: CGFloat = -280
    @State private var bannerOpacity: Double  = 0
    @State private var bannerScale: CGFloat   = 0.94

    // Glow pulse on headline
    @State private var glowPulse: Bool = false

    // Mic button
    @State private var micPulse:   Bool = false
    @State private var micPressed: Bool = false

    // Entrance
    @State private var contentOpacity: Double = 0
    @State private var contentOffset:  CGFloat = 28

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()

            VStack(spacing: 0) {

                // ── Top bar ──────────────────────────────────────────
                HStack {
                    Button { dismiss() } label: {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.10))
                                .frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 18)

                // ── Banner ───────────────────────────────────────────
                animatedBanner
                    .padding(.horizontal, 20)

                // ── Centre content: typewriter headline ──────────────
                Spacer()

                headlineSection

                Spacer()

                // ── Mic button pinned to bottom ──────────────────────
                micButton
                    .padding(.bottom, 36)
            }
        }
        .opacity(contentOpacity)
        .offset(y: contentOffset)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear { runAnimations() }
    }

    // MARK: - Dismiss

    private func dismiss() {
        if let onDismiss { onDismiss() } else { envDismiss() }
    }

    // MARK: - Banner

    private var animatedBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.55, green: 0.10, blue: 0.16),
                            Color.zomatoAccent,
                            Color(red: 0.95, green: 0.48, blue: 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 88)

            // Blobs
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 110, height: 110)
                .offset(x: -110, y: -20)
                .blur(radius: 1)

            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 80, height: 80)
                .offset(x: 120, y: 30)
                .blur(radius: 1)

            // Shimmer
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.22), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 100)
                .offset(x: shimmerOffset)
                .mask(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .frame(height: 88)
                )
                .clipped()

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.14))
                        .frame(width: 46, height: 46)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("LET US HELP YOU")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(2.5)
                        .foregroundStyle(.white.opacity(0.75))

                    Text("Build a Meal")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.20), radius: 4, x: 0, y: 2)
                }

                Spacer()

            }
            .padding(.horizontal, 18)
        }
        .frame(height: 88)
        .scaleEffect(bannerScale)
        .opacity(bannerOpacity)
        .clipped()
    }

    // MARK: - Headline (centre)

    private var headlineSection: some View {
        VStack(spacing: 16) {
            
            
            Text("Speak or type what you have —\nwe'll suggest the perfect dish.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.42))
                .multilineTextAlignment(.center)
            
            // Typewriter text with gradient + glow
            TypewriterText(
                fullText: "LIST YOUR\nITEMS HERE..",
                font: .system(size: 40, weight: .black, design: .rounded),
                delay: 0.05
            )
            .multilineTextAlignment(.center)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.zomatoAccent, Color(red: 0.95, green: 0.52, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(
                color: Color.zomatoAccent.opacity(glowPulse ? 0.60 : 0.15),
                radius: glowPulse ? 18 : 5,
                x: 0, y: 0
            )
            .animation(
                .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                value: glowPulse
            )

        }
        .padding(.horizontal, 28)
    }

    // MARK: - Mic Button (bottom)

    private var micButton: some View {
        VStack(spacing: 12) {
            ZStack {
                // Core
                Button {
                    // TODO: trigger voice input
                } label: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.zomatoAccent, Color(red: 0.85, green: 0.20, blue: 0.28)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 66, height: 66)
                        .shadow(color: Color.zomatoAccent.opacity(0.55), radius: 20, x: 0, y: 8)
                        .overlay(
                            Image(systemName: "mic.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                        .scaleEffect(micPressed ? 0.90 : 1.0)
                        .animation(.spring(response: 0.28, dampingFraction: 0.55), value: micPressed)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in micPressed = true  }
                        .onEnded   { _ in micPressed = false }
                )
            }

            Text("Tap to speak")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.38))
        }
    }

    // MARK: - Animations

    private func runAnimations() {
        // Entrance slide-up
        withAnimation(.spring(response: 0.45, dampingFraction: 0.80).delay(0.05)) {
            contentOpacity = 1
            contentOffset  = 0
        }

        // Banner
        withAnimation(.spring(response: 0.50, dampingFraction: 0.75).delay(0.12)) {
            bannerOpacity = 1
            bannerScale   = 1.0
        }

        // Shimmer loop
        shimmerOffset = -280
        withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false).delay(0.3)) {
            shimmerOffset = 380
        }

        // Glow pulse (starts after typewriter finishes approx)
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(1.8)) {
            glowPulse = true
        }

        // Mic ripple
        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(0.5)) {
            micPulse = true
        }
    }
}
