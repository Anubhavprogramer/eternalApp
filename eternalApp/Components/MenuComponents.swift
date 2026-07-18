import SwiftUI

struct AppHeaderView: View {
    let restaurant: RestaurantProfile
    let cartCount: Int
    let onCartTap: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(restaurant.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.zomatoTextPrimary)
                Text(restaurant.area)
                    .font(.subheadline)
                    .foregroundStyle(Color.zomatoTextSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            Button(action: onCartTap) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "cart.fill")
                        .font(.title3.weight(.semibold))
                        .frame(width: 46, height: 46)
                        .background(.white.opacity(0.10), in: Circle())
                        .foregroundStyle(.white)
                    if cartCount > 0 {
                        Text("\(cartCount)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.zomatoAccent, in: Capsule())
                            .offset(x: 8, y: -6)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

struct SearchBarView: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.red.opacity(0.85))
            TextField("Search for \"ice cream\"", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Image(systemName: "mic.fill")
                .foregroundStyle(Color.red.opacity(0.85))
        }
        .font(.callout.weight(.medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.black.opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

struct HeroCardView: View {
    let restaurant: RestaurantProfile

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.77, blue: 0.24), Color(red: 0.98, green: 0.84, blue: 0.58)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(restaurant.heroHeadline)
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.94, green: 0.37, blue: 0.12))
                        .lineLimit(3)
                    Text(restaurant.heroCaption)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Color(red: 0.43, green: 0.24, blue: 0.10))
                    Button {
                    } label: {
                        Text("Order Now")
                            .font(.callout.weight(.bold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(Color(red: 0.95, green: 0.49, blue: 0.18), in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)

                Image(systemName: "scooter")
                    .font(.system(size: 96, weight: .regular))
                    .foregroundStyle(Color(red: 0.12, green: 0.42, blue: 0.43))
                    .rotationEffect(.degrees(-4))
                    .padding(.trailing, 6)
            }
            .padding(22)
        }
        .frame(height: 236)
        .padding(.horizontal, 20)
    }
}

struct OfferBannerView: View {
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("FLASH SALE")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.83, green: 0.38, blue: 0.18))
                Text("Limited time deals on your favorite meals")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(red: 0.57, green: 0.35, blue: 0.30))
            }
            Spacer()
            Image(systemName: "megaphone.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Color(red: 0.93, green: 0.45, blue: 0.49))
                .padding(14)
                .background(.white.opacity(0.65), in: Circle())
        }
        .padding(18)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [6]))
        )
        .padding(.horizontal, 20)
    }
}

struct CategoryChipsView: View {
    let categories: [MenuCategory]
    @Binding var selectedCategoryID: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories) { category in
                    Button {
                        selectedCategoryID = category.id
                    } label: {
                        Text(category.title)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(selectedCategoryID == category.id ? Color.zomatoSurfaceAlt : Color.zomatoSurface.opacity(0.85), in: Capsule())
                            .foregroundStyle(selectedCategoryID == category.id ? .white : .white.opacity(0.78))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct MenuItemCardView: View {
    let item: MenuItem
    let quantity: Int
    let onAdd: () -> Void
    let onIncrease: () -> Void
    let onDecrease: () -> Void

    private var priceText: String {
        item.price.formatted(.currency(code: "INR").precision(.fractionLength(item.price.rounded() == item.price ? 0 : 2)))
    }

    private var originalPriceText: String? {
        guard let originalPrice = item.originalPrice else { return nil }
        return originalPrice.formatted(.currency(code: "INR").precision(.fractionLength(originalPrice.rounded() == originalPrice ? 0 : 2)))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 110, height: 110)
                    .overlay {
                        RemoteFoodImage(urlString: item.imageURL)
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                            )
                    }
                    .clipped()
                Button(action: onAdd) {
                    Image(systemName: quantity == 0 ? "plus" : "plus")
                        .font(.headline.weight(.bold))
                        .frame(width: 34, height: 34)
                        .background(Color.zomatoAccent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                }
                .offset(x: 10, y: 10)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: item.isVegetarian ? "leaf.fill" : "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(item.isVegetarian ? .green : .red)
                    Text(item.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(priceText)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    if let originalPriceText {
                        Text(originalPriceText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.42))
                            .strikethrough()
                    }
                }

                if quantity > 0 {
                    HStack(spacing: 10) {
                        Button(action: onDecrease) {
                            Image(systemName: "minus")
                                .font(.caption.weight(.bold))
                                .frame(width: 26, height: 26)
                                .background(Color.white.opacity(0.08), in: Circle())
                        }
                        .buttonStyle(.plain)

                        Text("\(quantity)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 18)

                        Button(action: onIncrease) {
                            Image(systemName: "plus")
                                .font(.caption.weight(.bold))
                                .frame(width: 26, height: 26)
                                .background(Color.zomatoAccent, in: Circle())
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.zomatoSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct CartRowView: View {
    let lineItem: CartLineItem
    let onIncrease: () -> Void
    let onDecrease: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RemoteFoodImage(urlString: lineItem.item.imageURL)
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(lineItem.item.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(lineItem.item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(2)
                Text(lineItem.item.price.formatted(.currency(code: "INR").precision(.fractionLength(lineItem.item.price.rounded() == lineItem.item.price ? 0 : 2))))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Button(action: onIncrease) {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .frame(width: 30, height: 30)
                        .background(Color.zomatoAccent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Text("\(lineItem.quantity)")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.white)

                Button(action: onDecrease) {
                    Image(systemName: "minus")
                        .font(.caption.weight(.bold))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.zomatoSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct MakeMealWidgetButton: View {
    let action: () -> Void

    @State private var isPressed = false
    @State private var isPulsing = false
    @State private var shimmerOffset: CGFloat = -120

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 34, height: 34)
                        .scaleEffect(isPulsing ? 1.18 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                            value: isPulsing
                        )

                    Image(systemName: "fork.knife")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("Make your meal")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.80))
            }
            .padding(.leading, 10)
            .padding(.trailing, 18)
            .padding(.vertical, 12)
            .background {
                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.zomatoAccent, Color(red: 0.85, green: 0.20, blue: 0.28)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // shimmer overlay
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.22),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                        .clipped()
                        .mask(Capsule())
                }
            }
            .shadow(color: Color.zomatoAccent.opacity(0.52), radius: 18, x: 0, y: 8)
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            isPulsing = true
            startShimmer()
        }
    }

    private func startShimmer() {
        shimmerOffset = -120
        withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
            shimmerOffset = 200
        }
    }
}
