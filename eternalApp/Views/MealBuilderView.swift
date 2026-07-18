import SwiftUI
import PhotosUI

// MARK: - Input Mode

private enum InputMode: String, CaseIterable {
    case image = "Photo"
    case text  = "Ingredients"

    var icon: String {
        switch self {
        case .image: return "camera.fill"
        case .text:  return "list.bullet"
        }
    }
}

// MARK: - Main View

struct MealBuilderView: View {
    @Environment(\.dismiss) private var dismiss

    // Banner animation
    @State private var shimmerOffset: CGFloat = -300
    @State private var bannerScale: CGFloat  = 0.92
    @State private var bannerOpacity: Double = 0
    @State private var floatOffset: CGFloat  = 4

    // Input state
    @State private var selectedMode: InputMode = .image
    @State private var ingredientText: String  = ""
    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage?  = nil
    @State private var inputPanelHeight: CGFloat = 0

    // Segment animation
    @State private var segmentAppeared = false

    var body: some View {
        ZStack(alignment: .bottom) {

            // ── Background ──────────────────────────────────────────────
            Color.zomatoBackground.ignoresSafeArea()

            // ── Scrollable body ─────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    heroBanner
                    Spacer().frame(height: inputPanelHeight + 16)
                }
                .padding(.top, 12)
            }

            // ── Sticky input panel ──────────────────────────────────────
            inputPanel
                .background {
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { inputPanelHeight = geo.size.height }
                            .onChange(of: selectedMode) { _, _ in
                                inputPanelHeight = geo.size.height
                            }
                    }
                }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "arrow.left")
                        .font(.headline.weight(.semibold))
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.08), in: Circle())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear { runBannerAnimations() }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        ZStack {
            // Base gradient
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.60, green: 0.12, blue: 0.18),
                            Color.zomatoAccent,
                            Color(red: 0.95, green: 0.52, blue: 0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 210)

            // Decorative blobs
            Circle()
                .fill(.white.opacity(0.07))
                .frame(width: 160, height: 160)
                .offset(x: -100, y: -50)
                .blur(radius: 2)

            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 120, height: 120)
                .offset(x: 110, y: 60)
                .blur(radius: 2)

            // Shimmer sweep
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.18), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 180)
                .offset(x: shimmerOffset)
                .clipped()
                .mask(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .frame(height: 210)
                )

            // Content
            VStack(spacing: 12) {
                // Floating emoji
                Image(systemName: "fork.knife")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)


                VStack(spacing: 6) {
                    Text("Let us help you")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.78))
                        .textCase(.uppercase)

                    Text("Make Your Meal")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)

                    Text("Share a photo or list your ingredients\nand we'll build the perfect dish for you.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 210)
        .padding(.horizontal, 20)
        .scaleEffect(bannerScale)
        .opacity(bannerOpacity)
        .clipped()
    }

    // MARK: - Input Panel

    private var inputPanel: some View {
        VStack(spacing: 0) {
            // Pill handle
            Capsule()
                .fill(.white.opacity(0.15))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 16)

            // Mode segment control
            modeSegment
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // Active input
            Group {
                if selectedMode == .image {
                    imageInput
                } else {
                    textInput
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.38, dampingFraction: 0.80), value: selectedMode)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.zomatoSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(.white.opacity(0.07), lineWidth: 1)
                )
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.45), radius: 32, x: 0, y: -8)
        }
    }

    // MARK: - Mode Segment

    private var modeSegment: some View {
        HStack(spacing: 0) {
            ForEach(InputMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(mode.rawValue)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(selectedMode == mode ? .white : .white.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background {
                        if selectedMode == mode {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.zomatoAccent, Color(red: 0.85, green: 0.20, blue: 0.28)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .matchedGeometryEffect(id: "segment", in: segmentNS)
                                .shadow(color: Color.zomatoAccent.opacity(0.40), radius: 10, x: 0, y: 4)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @Namespace private var segmentNS

    // MARK: - Image Input

    private var imageInput: some View {
        VStack(spacing: 14) {
            if let image = selectedImage {
                // Preview
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedImage = nil
                            pickerItem   = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.4), radius: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                }
                .transition(.scale(scale: 0.92).combined(with: .opacity))

            } else {
                // Picker drop zone
                PhotosPicker(
                    selection: $pickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.zomatoAccent.opacity(0.14))
                                .frame(width: 64, height: 64)
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(Color.zomatoAccent)
                        }
                        Text("Tap to upload a photo")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("JPEG, PNG or HEIF · max 20 MB")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.42))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            .fill(Color.white.opacity(0.14))
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: pickerItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let ui   = UIImage(data: data) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedImage = ui
                            }
                        }
                    }
                }
            }

            analyseButton(
                label: selectedImage == nil ? "Choose a photo first" : "Analyse Photo",
                icon: "sparkles",
                enabled: selectedImage != nil
            )
        }
    }

    // MARK: - Text Input

    private var textInput: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                ingredientText.isEmpty
                                    ? Color.white.opacity(0.10)
                                    : Color.zomatoAccent.opacity(0.50),
                                lineWidth: 1
                            )
                    )

                if ingredientText.isEmpty {
                    Text("e.g. chicken, rice, onion, tomatoes…")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.30))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $ingredientText)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .frame(minHeight: 110, maxHeight: 140)
            }
            .frame(minHeight: 110)
            .animation(.easeInOut(duration: 0.2), value: ingredientText.isEmpty)

            analyseButton(
                label: ingredientText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Add ingredients first"
                    : "Find Matching Dishes",
                icon: "fork.knife.circle.fill",
                enabled: !ingredientText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
    }

    // MARK: - Shared Analyse Button

    @ViewBuilder
    private func analyseButton(label: String, icon: String, enabled: Bool) -> some View {
        Button {
            // TODO: hook up AI analysis
        } label: {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.headline.weight(.bold))
                Text(label)
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        enabled
                            ? LinearGradient(
                                colors: [Color.zomatoAccent, Color(red: 0.85, green: 0.20, blue: 0.28)],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.08)],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                    )
                    .shadow(
                        color: enabled ? Color.zomatoAccent.opacity(0.40) : .clear,
                        radius: 16, x: 0, y: 8
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .animation(.easeInOut(duration: 0.2), value: enabled)
    }

    // MARK: - Animations

    private func runBannerAnimations() {
        // Entrance
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.05)) {
            bannerScale   = 1.0
            bannerOpacity = 1.0
        }
        // Float loop
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            floatOffset = -4
        }
        // Shimmer loop
        shimmerOffset = -300
        withAnimation(.linear(duration: 2.6).repeatForever(autoreverses: false).delay(0.4)) {
            shimmerOffset = 420
        }
    }
}

// MARK: - Hint Row

private struct HintRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.52))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.zomatoSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        )
        .scaleEffect(appeared ? 1.0 : 0.92)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72).delay(0.12)) {
                appeared = true
            }
        }
    }
}
