import Foundation
import SwiftUI
internal import Combine

@MainActor
final class CartViewModel: ObservableObject {
    
    @Published private(set) var items: [CartLineItem] = []

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Double {
        items.reduce(0) { $0 + ($1.item.price * Double($1.quantity)) }
    }

    var deliveryFee: Double {
        items.isEmpty ? 0 : 19
    }

    var total: Double {
        subtotal + deliveryFee
    }

    func quantity(for item: MenuItem) -> Int {
        items.first(where: { $0.item.id == item.id })?.quantity ?? 0
    }

    func add(_ item: MenuItem) {
        guard let index = items.firstIndex(where: { $0.item.id == item.id }) else {
            items.append(CartLineItem(item: item, quantity: 1))
            return
        }
        items[index].quantity += 1
    }

    func increase(_ item: MenuItem) {
        add(item)
    }

    func decrease(_ item: MenuItem) {
        guard let index = items.firstIndex(where: { $0.item.id == item.id }) else { return }
        if items[index].quantity > 1 {
            items[index].quantity -= 1
        } else {
            items.remove(at: index)
        }
    }

    func remove(_ item: MenuItem) {
        items.removeAll { $0.item.id == item.id }
    }

    func clear() {
        items.removeAll()
    }
}
