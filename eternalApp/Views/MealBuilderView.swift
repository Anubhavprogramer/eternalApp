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
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var envDismiss

    // Input state
    @State private var selectedMode: InputMode = .image
    @State private var ingredientText: String  = ""
    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage?  = nil

    // Entrance animation
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 24

    @Namespace private var segmentNS

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.zomatoBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Top bar ──────────────────────────────────────────
                HStack {
                    Button {
                        dismiss()
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

                    // Balance the close button on the right
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                Spacer()
            }
        }
        .opacity(contentOpacity)
        .offset(y: contentOffset)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.80).delay(0.05)) {
                contentOpacity = 1
                contentOffset  = 0
            }
        }
    }

    // MARK: - Dismiss helper

    private func dismiss() {
        if let onDismiss {
            onDismiss()
        } else {
            envDismiss()
        }
    }

    // MARK: - Mode Segment

    

    // MARK: - Image Input

    
}
