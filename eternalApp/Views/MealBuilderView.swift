import SwiftUI

// MARK: - Diet Chip

private struct DietChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(isSelected
                              ? LinearGradient(
                                    colors: [Color.zomatoAccent, Color(red: 0.85, green: 0.20, blue: 0.28)],
                                    startPoint: .leading, endPoint: .trailing)
                              : LinearGradient(
                                    colors: [Color.white.opacity(0.08), Color.white.opacity(0.08)],
                                    startPoint: .leading, endPoint: .trailing))
                        .overlay(
                            Capsule()
                                .stroke(isSelected
                                        ? Color.zomatoAccent.opacity(0.40)
                                        : Color.white.opacity(0.10), lineWidth: 1)
                        )
                }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.28, dampingFraction: 0.70), value: isSelected)
    }
}

// MARK: - Meal Preferences Card

private struct MealPreferencesCard: View {
    @Binding var budget: Double
    @Binding var selectedDiets: Set<String>

    private let dietOptions: [(key: String, label: String)] = [
        ("vegetarian",        "🌿 Vegetarian"),
        ("non_vegetarian",    "🍖 Non Vegetarian"),
        ("vegan",             "🥦 Vegan"),
        ("high_protein",      "💪 High Protein"),
        ("diabetic_friendly", "🩺 Diabetic Friendly"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // ── Budget Slider ──────────────────────────────────────
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Budget")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.50))
                        .textCase(.uppercase)

                    Spacer()

                    Text("₹\(Int(budget))")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.zomatoAccent.opacity(0.22), in: Capsule())
                }

                Slider(value: $budget, in: 100...600, step: 50)
                    .tint(Color.zomatoAccent)

                HStack {
                    Text("₹100")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.35))
                    Spacer()
                    Text("₹350")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.25))
                    Spacer()
                    Text("₹600")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }

            Divider().overlay(Color.white.opacity(0.08))

            // ── Diet Chips ─────────────────────────────────────────
            VStack(alignment: .leading, spacing: 10) {
                Text("Diet Preference")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.50))
                    .textCase(.uppercase)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    alignment: .leading,
                    spacing: 10
                ) {
                    ForEach(dietOptions, id: \.key) { option in
                        DietChip(
                            label: option.label,
                            isSelected: selectedDiets.contains(option.key)
                        ) {
                            if selectedDiets.contains(option.key) {
                                selectedDiets.remove(option.key)
                            } else {
                                selectedDiets.insert(option.key)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - MealBuilderView

struct MealBuilderView: View {
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var envDismiss

    @StateObject private var viewModel = MealBuilderViewModel()

    // Banner
    @State private var bannerOpacity: Double = 0
    @State private var bannerScale: CGFloat  = 0.94

    // Preferences (shown in .done)
    @State private var budget: Double             = 350
    @State private var selectedDiets: Set<String> = []

    // Entrance
    @State private var contentOpacity: Double = 0

    // Full-screen loading / result cover
    @State private var showResultCover = false

    var body: some View {
        ZStack {
            Color.zomatoBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 18)

                    banner
                        .padding(.horizontal, 20)

                    // Centre: done state — transcript + preferences card
                    if viewModel.state == .done {
                        VStack(spacing: 20) {
                            VStack(spacing: 12) {
                                
                                Text(viewModel.transcript)
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)

                            }
                            .padding(.top, 24)

                            MealPreferencesCard(budget: $budget, selectedDiets: $selectedDiets)
                        }
                        .transition(.scale(scale: 0.94).combined(with: .opacity))
                    } else {
                        Spacer().frame(height: 320)
                    }

                    Spacer().frame(height: 20)

                    micControl
                        .padding(.bottom, 40)
                }
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.78), value: viewModel.state)
        }
        .opacity(contentOpacity)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear { runEntranceAnimations() }
        // Watch for loading → open cover; success → keep cover open (NavigationStack handles push)
        .onChange(of: viewModel.recommendationState) { _, newState in
            switch newState {
            case .loading:
                showResultCover = true
            case .failure:
                showResultCover = false
            default:
                break
            }
        }
        .fullScreenCover(isPresented: $showResultCover) {
            ResultCoverView(viewModel: viewModel, onClose: {
                showResultCover = false
                viewModel.reset()
            })
        }
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

            // Listening — transcript preview
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

            // Denied message
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

            // Button row
            ZStack {

                // Idle — mic button
                if viewModel.state == .idle {
                    ZStack {
                        Button { viewModel.toggle() } label: {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color.zomatoAccent, Color(red: 0.85, green: 0.20, blue: 0.28)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 66, height: 66)
                                    .shadow(color: Color.zomatoAccent.opacity(0.55), radius: 20, x: 0, y: 8)
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }

                // Listening — ✕ | waveform | ✓
                if viewModel.state == .listening {
                    HStack(spacing: 36) {
                        Button { viewModel.cancel() } label: {
                            ZStack {
                                Circle().fill(.white.opacity(0.12)).frame(width: 62, height: 62)
                                Image(systemName: "xmark")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                        }
                        .buttonStyle(.plain)

                        WaveformView(level: viewModel.audioLevel)

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

                // Done — Analyse Data button
                if viewModel.state == .done {
                    VStack(spacing: 12) {
                        Button {
                            viewModel.recommend(
                                vegetarian:       selectedDiets.contains("vegetarian"),
                                nonVegetarian:    selectedDiets.contains("non_vegetarian"),
                                vegan:            selectedDiets.contains("vegan"),
                                highProtein:      selectedDiets.contains("high_protein"),
                                diabeticFriendly: selectedDiets.contains("diabetic_friendly"),
                                budgetFriendly:   budget <= 350,
                                maxBudget:        Int(budget)
                            )
                        } label: {
                            HStack(spacing: 10) {
                                if viewModel.recommendationState == .loading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                        .scaleEffect(0.85)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                Text(viewModel.recommendationState == .loading ? "Analysing…" : "Analyse Data")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 28)
                            
//                            .background {
//                                Capsule()
//                                    .fill(LinearGradient(
//                                        colors: viewModel.recommendationState == .loading
//                                            ? [Color.gray.opacity(0.5), Color.gray.opacity(0.5)]
//                                            : [Color.zomatoAccent, Color(red: 0.85, green: 0.20, blue: 0.28)],
//                                        startPoint: .leading, endPoint: .trailing))
//                                    .shadow(
//                                        color: Color.zomatoAccent.opacity(
//                                            viewModel.recommendationState == .loading ? 0 : 0.50),
//                                        radius: 18, x: 0, y: 8)
//                            }
                        }
                        .glassEffect(.clear)
                        .buttonStyle(.plain)
                        .disabled(viewModel.recommendationState == .loading)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.recommendationState)

                        // Error banner
                        if case .failure(let msg) = viewModel.recommendationState {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text(msg)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                                    .lineLimit(2)
                            }
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }

                // Denied — greyed mic slash
                if viewModel.state == .denied {
                    Circle()
                        .fill(Color.gray.opacity(0.30))
                        .frame(width: 66, height: 66)
                        .overlay(
                            Image(systemName: "mic.slash.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.40))
                        )
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }

            } // ZStack (button row)
            .animation(.spring(response: 0.36, dampingFraction: 0.70), value: viewModel.state)

            // Idle label
            if viewModel.state == .idle {
                Text("Tap to speak")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.38))
                    .transition(.opacity)
            }

        } // VStack (micControl)
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
    }
}

// MARK: - Result Cover (full-screen loader only)

private struct ResultCoverView: View {
    @ObservedObject var viewModel: MealBuilderViewModel
    let onClose: () -> Void

    var body: some View {
        ZStack {
            RecommendationLoadingView()

            // Close button — top left
            VStack {
                HStack {
                    Button { onClose() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.10), in: Circle())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 20)
                    .padding(.top, 56)
                    Spacer()
                }
                Spacer()
            }
        }
        .onChange(of: viewModel.recommendationState) { _, state in
            // When data arrives or fails, print and close
            switch state {
            case .success(let response):
                print("✅ \(response.recommendations.count) recommendations received")
                onClose()
            case .failure(let msg):
                print("❌ Error: \(msg)")
                onClose()
            default:
                break
            }
        }
    }
}
