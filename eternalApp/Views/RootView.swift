import SwiftUI

struct RootView: View {
    @StateObject private var cartViewModel = CartViewModel()
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .cart:
                        CartView()
                    }
                }
        }
        .environmentObject(cartViewModel)
    }
}
