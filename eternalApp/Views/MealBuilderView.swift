import SwiftUI

// MARK: - Ripple Ring

private struct RippleRing: View {
    let size: CGFloat
    let lineWidth: CGFloat
    let opacity: Double
    let duration: Double
    let delay: Double

    @State private var animating = false

    var body: some View {
        Circle()
            .stroke(Color.zomatoAccent.opacity(animating ? 0 : opacity), lineWidth: lineWidth)
            .frame(width: size, height: size)
            .scaleEffect(animating ? 1.35 : 1.0)
            .onAppear {
                withAnimation(
                    .easeOut(duration: duration)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    animating = true
                }
            }
    }
}

// MARK: - MealBuilderView

struct MealBuilderView: View {
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var envDismiss

    @StateObject private var viewModel = MealBuilderViewModel()

    // Banner
    @State private var shimmerOffset: CGFloat = -280
    @State private var bannerOpacity: Double  = 0
    @State private var bannerScale: CGFloat   = 0.94

    // Headline glow pulse — unused, kept for future use

    // Entrance
    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            
            Color.zomatoBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 18)

                banner
                    .padding(.horizontal, 20)

                Spacer()

                micControl
                    .padding(.bottom, 40)
            }
        }
        .opacity(contentOpacity)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear { runEntranceAnimations() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                viewModel.stop()
                if let onDismiss { onDismiss() } else { envDismiss() }
            } label: {
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
    }

    // MARK: - Banner

    private var banner: some View {
        ZStack {
                

            // Decorative blobs
            Circle().fill(.white.opacity(0.08))
                .frame(width: 110, height: 110)
                .offset(x: -90, y: -20)
                .blur(radius: 1)
            Circle().fill(.white.opacity(0.06))
                .frame(width: 80, height: 80)
                .offset(x: 80, y: 30)
                .blur(radius: 1)

            // Shimmer sweep
            

            // Content
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(.white.opacity(0.14)).frame(width: 46, height: 46)
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
        .glassEffect(.clear)
    }

    // MARK: - Mic Control

    private var micControl: some View {
        VStack(spacing: 16) {

            // ── Waveform + transcript (listening only) ────────────────
            if viewModel.state == .listening {
                VStack(spacing: 12) {

                    Text(viewModel.transcript.isEmpty ? "Listening…" : viewModel.transcript)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .animation(.easeInOut(duration: 0.15), value: viewModel.transcript)
                }
                .transition(.scale(scale: 0.92).combined(with: .opacity))
            }

            // ── Done: transcript result ───────────────────────────────
            if viewModel.state == .done {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: viewModel.state)

                    Text(viewModel.transcript)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button { viewModel.reset() } label: {
                        Text("Tap to speak again")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                }
                .transition(.scale(scale: 0.92).combined(with: .opacity))
            }

            // ── Denied ────────────────────────────────────────────────
            if viewModel.state == .denied {
                VStack(spacing: 8) {
                    Image(systemName: "mic.slash.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.zomatoAccent)
                    Text("Microphone access denied.\nPlease enable it in Settings.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.60))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .transition(.opacity)
            }

            // ── Button row ────────────────────────────────────────────
            ZStack {
                // Idle / done / denied — single mic button
                if viewModel.state != .listening {
                    ZStack {
                        Button { viewModel.toggle() } label: {
                            ZStack {
                                Circle()
                                    .fill(micButtonGradient)
                                    .frame(width: 66, height: 66)
                                    .shadow(color: micButtonShadow, radius: 20, x: 0, y: 8)
                                Image(systemName: micButtonIcon)
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }

                // Listening — cross | waveform | check
                if viewModel.state == .listening {
                    HStack(spacing: 36) {
                        // Cancel
                        Button {
                            viewModel.cancel()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.12))
                                    .frame(width: 62, height: 62)
                                Image(systemName: "xmark")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                        }
                        .buttonStyle(.plain)
                        
                        WaveformView(level: viewModel.audioLevel)
                        
                        // Confirm
                        Button { viewModel.confirm() } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.88))
                                    .frame(width: 62, height: 62)
                                    .shadow(color: .green.opacity(0.45), radius: 14, x: 0, y: 6)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.36, dampingFraction: 0.70), value: viewModel.state)

            Text(micButtonLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.38))
                .animation(.easeInOut(duration: 0.2), value: viewModel.state)
        }
    }

    // MARK: - Mic Button Appearance

    private var micButtonIcon: String {
        switch viewModel.state {
        case .idle:      return "mic.fill"
        case .listening: return "stop.fill"
        case .done:      return "arrow.counterclockwise"
        case .denied:    return "mic.slash.fill"
        }
    }

    private var micButtonLabel: String {
        switch viewModel.state {
        case .idle:      return "Tap to speak"
        case .listening: return ""
        case .done:      return "Tap to redo"
        case .denied:    return "Permission denied"
        }
    }

    private var micButtonGradient: LinearGradient {
        switch viewModel.state {
        case .done:
            return LinearGradient(
                colors: [.green.opacity(0.85), .green],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .denied:
            return LinearGradient(
                colors: [.gray.opacity(0.5), .gray.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color.zomatoAccent, Color(red: 0.85, green: 0.20, blue: 0.28)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    private var micButtonShadow: Color {
        switch viewModel.state {
        case .done:   return .green.opacity(0.50)
        case .denied: return .clear
        default:      return Color.zomatoAccent.opacity(0.55)
        }
    }

    // MARK: - Entrance Animations

    private func runEntranceAnimations() {
        withAnimation(.easeIn(duration: 0.22)) {
            contentOpacity = 1
        }
        withAnimation(.spring(response: 0.50, dampingFraction: 0.75).delay(0.12)) {
            bannerOpacity = 1
            bannerScale   = 1.0
        }
        shimmerOffset = -280
        withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false).delay(0.3)) {
            shimmerOffset = 380
        }
    }
}
