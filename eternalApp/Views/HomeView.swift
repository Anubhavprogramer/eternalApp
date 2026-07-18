import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var cartViewModel: CartViewModel
    @Binding var path: [AppRoute]

    private let store = ZomatoMenuStore()
    @State private var query = ""
    @State private var selectedCategoryID = "popular"
    @State private var showingMealBuilder = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [Color(red: 0.99, green: 0.84, blue: 0.34), Color(red: 0.98, green: 0.96, blue: 0.90)],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            // Tap anywhere on the background to dismiss keyboard
            .onTapGesture { UIApplication.shared.dismissKeyboard() }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    AppHeaderView(
                        restaurant: store.restaurant,
                        cartCount: cartViewModel.itemCount,
                        onCartTap: { path.append(.cart) }
                    )

                    SearchBarView(query: $query)

                    HeroCardView(restaurant: store.restaurant)

                    OfferBannerView()

                    VStack(alignment: .leading, spacing: 16) {
                        Text("WHAT'S ON YOUR MIND?")
                            .font(.caption.weight(.heavy))
                            .tracking(2)
                            .foregroundStyle(Color.black.opacity(0.60))
                            .padding(.horizontal, 20)

                        CategoryChipsView(categories: store.categories, selectedCategoryID: $selectedCategoryID)

                        LazyVStack(spacing: 14) {
                            ForEach(filteredItems) { item in
                                MenuItemCardView(
                                    item: item,
                                    quantity: cartViewModel.quantity(for: item),
                                    onAdd:      { cartViewModel.add(item)      },
                                    onIncrease: { cartViewModel.increase(item) },
                                    onDecrease: { cartViewModel.decrease(item) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 110)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Floating widget button
            MakeMealWidgetButton {
                UIApplication.shared.dismissKeyboard()
                withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                    showingMealBuilder = true
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 32)

            // Custom modal overlay
            if showingMealBuilder {
                Color.black.opacity(0.50)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                            showingMealBuilder = false
                        }
                    }
                    .transition(.opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(1)

                GeometryReader { geo in
                    VStack(spacing: 0) {
                        Spacer()
                        MealBuilderView(onDismiss: {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                                showingMealBuilder = false
                            }
                        })
                        .frame(height: geo.size.height * 0.80)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    }
                }
                .ignoresSafeArea()
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.spring(response: 0.48, dampingFraction: 0.82), value: showingMealBuilder)
    }

    private var filteredItems: [MenuItem] {
        let categoryItems = store.items(
            for: store.categories.first(where: { $0.id == selectedCategoryID }) ?? store.categories[0]
        )
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return categoryItems }
        return categoryItems.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedQuery) ||
            $0.subtitle.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }
}
