import SwiftUI

struct CartView: View {
    @EnvironmentObject private var cartViewModel: CartViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.zomatoAccent, Color.zomatoBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    savingsBanner
                    if cartViewModel.items.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 14) {
                            ForEach(cartViewModel.items) { item in
                                CartRowView(
                                    lineItem: item,
                                    onIncrease: {
                                        cartViewModel.increase(item.item)
                                    },
                                    onDecrease: {
                                        cartViewModel.decrease(item.item)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)

                        summaryCard
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.headline.weight(.semibold))
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.06), in: Circle())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text("Your Cart")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Review items before placing the order")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var savingsBanner: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "party.popper.fill")
                .font(.title3)
                .foregroundStyle(.white)
            Text("You saved \(ZomatoMenuStore().restaurant.savedAmount) on this order")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "cart")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
            Text("Your cart is empty")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text("Add items from the menu to start building your order.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            row(title: "Item total", value: cartViewModel.subtotal)
            row(title: "Delivery fee", value: cartViewModel.deliveryFee)
            Divider().overlay(.white.opacity(0.12))
            HStack {
                Text("Payable total")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(cartViewModel.total.formatted(.currency(code: "INR").precision(.fractionLength(cartViewModel.total.rounded() == cartViewModel.total ? 0 : 2))))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }

            Button {
                dismiss()
            } label: {
                Text("View Cart")
            }
            .buttonStyle(ZomatoRoundedButtonStyle(background: .zomatoAccent, foreground: .white))
        }
        .padding(20)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func row(title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.white.opacity(0.72))
            Spacer()
            Text(value.formatted(.currency(code: "INR").precision(.fractionLength(value.rounded() == value ? 0 : 2))))
                .foregroundStyle(.white)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}
