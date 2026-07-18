import Foundation

struct ZomatoMenuStore {
    let restaurant = RestaurantProfile(
        name: "Tadka Rani",
        area: "Vishwakarma Chowk, Sant Pura, Ludhiana",
        deliveryTime: "24 min",
        rating: 4.5,
        savedAmount: "₹223",
        heroHeadline: "Your Cravings, Delivered Fresh",
        heroCaption: "Restaurant-style meals, delivered hot and fast."
    )

    let categories: [MenuCategory] = [
        MenuCategory(id: "popular", title: "Popular"),
        MenuCategory(id: "biryani", title: "Biryani"),
        MenuCategory(id: "curries", title: "Curries"),
        MenuCategory(id: "grill", title: "Grill"),
        MenuCategory(id: "sides", title: "Sides")
    ]

    let menuItems: [MenuItem] = [
        MenuItem(
            id: "tandoori_half",
            name: "Tandoori Chicken (Half)",
            subtitle: "Plain",
            price: 222.50,
            originalPrice: 445,
            imageURL: "https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&w=900&q=80",
            category: "grill",
            isVegetarian: false
        ),
        MenuItem(
            id: "dum_chicken_biryani",
            name: "Dum Chicken Biryani",
            subtitle: "Hyderabadi style, aromatic rice",
            price: 227.50,
            originalPrice: 325,
            imageURL: "https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&w=900&q=80",
            category: "biryani",
            isVegetarian: false
        ),
        MenuItem(
            id: "veg_dum_biryani",
            name: "Vegetable Dum Biryani",
            subtitle: "Fresh vegetables, saffron rice",
            price: 265,
            originalPrice: nil,
            imageURL: "https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&w=900&q=80",
            category: "biryani",
            isVegetarian: true
        ),
        MenuItem(
            id: "chicken_curry",
            name: "Chicken Curry",
            subtitle: "House gravy, medium spicy",
            price: 187.50,
            originalPrice: 375,
            imageURL: "https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&w=900&q=80",
            category: "curries",
            isVegetarian: false
        ),
    ]

    func items(for category: MenuCategory) -> [MenuItem] {
        if category.id == "popular" {
            return Array(menuItems.prefix(4))
        }
        return menuItems.filter { $0.category == category.id }
    }
}
