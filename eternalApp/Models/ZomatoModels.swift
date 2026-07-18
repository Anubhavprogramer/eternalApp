import Foundation

struct RestaurantProfile {
    let name: String
    let area: String
    let deliveryTime: String
    let rating: Double
    let savedAmount: String
    let heroHeadline: String
    let heroCaption: String
}

struct MenuCategory: Identifiable, Hashable {
    let id: String
    let title: String
}

struct MenuItem: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let price: Double
    let originalPrice: Double?
    let imageURL: String
    let category: String
    let isVegetarian: Bool
}

struct CartLineItem: Identifiable, Hashable {
    var id: String { item.id }
    let item: MenuItem
    var quantity: Int
}
