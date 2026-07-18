import Foundation

// MARK: - Feature Flag

/// Set to `true` to use mock data, `false` to hit the real API.
let useMockRecommendation: Bool = true

// MARK: - Request

struct MealRecommendationRequest: Encodable {
    let user_response: String
    let vegetarian: Bool
    let non_vegetarian: Bool
    let vegan: Bool
    let high_protein: Bool
    let diabetic_friendly: Bool
    let budget_friendly: Bool
    let max_budget: Int
    let max_cooking_time_minutes: Int
}

// MARK: - Error

enum MealRecommendationError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int, body: String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .httpError(let code, let body):
            return "HTTP \(code): \(body)"
        case .networkError(let err):
            return err.localizedDescription
        }
    }
}

// MARK: - Mock Data

private let mockResponseJSON = """
{
  "status": "success",
  "meta": {
    "normalized_diet": "veg",
    "inventory_source": "backend_file",
    "llm_provider": "openai",
    "normalized_goals": ["high_protein"],
    "inventory_sent_to_llm_count": 46,
    "user_response": "Bread tea and coffee",
    "inventory_received_count": 50
  },
  "recommendations": [
    {
      "meal_name": "Paneer Stuffed Brown Bread Sandwich",
      "description": "A high protein vegetarian sandwich using paneer and brown bread, toasted to perfection.",
      "why_this_meal": "Uses user's bread and adds paneer, a good source of protein, fitting vegetarian and high protein goals.",
      "diet_tags": ["veg", "high_protein"],
      "cooking_time_minutes": 20,
      "budget_score": 1.0,
      "estimated_missing_cost": 89,
      "ingredients_user_has": ["Bread"],
      "missing_ingredients": [
        {
          "product_id": "blinkit_paneer_001",
          "name": "Fresh Paneer",
          "quantity": "100g",
          "price": 89,
          "eta_minutes": 8,
          "blinkit_available": true,
          "priority": "required"
        }
      ],
      "optional_ingredients": [
        { "product_id": "blinkit_tomato_001", "name": "Tomato",          "quantity": "1 medium",    "price": 28, "eta_minutes": 8, "blinkit_available": true },
        { "product_id": "blinkit_onion_001",  "name": "Onion",           "quantity": "1 small",     "price": 35, "eta_minutes": 8, "blinkit_available": true },
        { "product_id": "blinkit_chilli_001", "name": "Green Chilli",    "quantity": "1 small",     "price": 16, "eta_minutes": 8, "blinkit_available": true },
        { "product_id": "blinkit_cori_001",   "name": "Fresh Coriander", "quantity": "small bunch", "price": 18, "eta_minutes": 8, "blinkit_available": true }
      ]
    },
    {
      "meal_name": "Whole Wheat Wrap with Soya Chunks and Veggies",
      "description": "A quick whole wheat wrap filled with protein-rich soya chunks and fresh vegetables.",
      "why_this_meal": "Incorporates user's need for bread-like staple and adds soya chunks for high protein.",
      "diet_tags": ["veg", "high_protein"],
      "cooking_time_minutes": 25,
      "budget_score": 0.85,
      "estimated_missing_cost": 132,
      "ingredients_user_has": [],
      "missing_ingredients": [
        { "product_id": "blinkit_wrap_001",     "name": "Whole Wheat Wrap",  "quantity": "2 wraps",  "price": 45, "eta_minutes": 8, "blinkit_available": true, "priority": "required" },
        { "product_id": "blinkit_soya_001",     "name": "Soya Chunks",       "quantity": "100g",     "price": 55, "eta_minutes": 8, "blinkit_available": true, "priority": "required" },
        { "product_id": "blinkit_capsicum_001", "name": "Green Capsicum",    "quantity": "1 medium", "price": 32, "eta_minutes": 8, "blinkit_available": true, "priority": "required" }
      ],
      "optional_ingredients": [
        { "product_id": "blinkit_onion_001",  "name": "Onion",           "quantity": "1 small",     "price": 35, "eta_minutes": 8, "blinkit_available": true },
        { "product_id": "blinkit_tomato_001", "name": "Tomato",          "quantity": "1 medium",    "price": 28, "eta_minutes": 8, "blinkit_available": true },
        { "product_id": "blinkit_cori_001",   "name": "Fresh Coriander", "quantity": "small bunch", "price": 18, "eta_minutes": 8, "blinkit_available": true }
      ]
    },
    {
      "meal_name": "Moong Dal with Brown Rice",
      "description": "A protein-rich meal of moong dal served with brown rice. Nutritious and fulfilling.",
      "why_this_meal": "Uses staple lentils and rice, both high protein plant-based foods, fitting vegetarian diet.",
      "diet_tags": ["veg", "high_protein"],
      "cooking_time_minutes": 25,
      "budget_score": 0.6,
      "estimated_missing_cost": 218,
      "ingredients_user_has": [],
      "missing_ingredients": [
        { "product_id": "blinkit_dal_001",        "name": "Moong Dal",   "quantity": "100g", "price": 88,  "eta_minutes": 9,  "blinkit_available": true, "priority": "required" },
        { "product_id": "blinkit_brown_rice_001", "name": "Brown Rice",  "quantity": "150g", "price": 130, "eta_minutes": 12, "blinkit_available": true, "priority": "required" }
      ],
      "optional_ingredients": [
        { "product_id": "blinkit_turmeric_001", "name": "Turmeric Powder", "quantity": "1 tsp",    "price": 38, "eta_minutes": 8, "blinkit_available": true },
        { "product_id": "blinkit_garlic_001",   "name": "Garlic",          "quantity": "2 cloves", "price": 36, "eta_minutes": 8, "blinkit_available": true },
        { "product_id": "blinkit_onion_001",    "name": "Onion",           "quantity": "1 medium", "price": 35, "eta_minutes": 8, "blinkit_available": true }
      ]
    }
  ],
  "needs_user_confirmation": false,
  "extracted_ingredients": [
    { "name": "Bread",  "quantity_estimate": "unknown", "confidence": 0.9 },
    { "name": "Tea",    "quantity_estimate": "unknown", "confidence": 0.7 },
    { "name": "Coffee", "quantity_estimate": "unknown", "confidence": 0.7 }
  ]
}
"""

// MARK: - Service

final class MealRecommendationService {

    static let shared = MealRecommendationService()
    private init() {}

    private let endpoint   = "https://admin.nudgeit.shop/admin/api/bring-your-own-meal/recommend"
    private let authHeader = "Basic YWRtaW46YWRtaW4xMjM="

    /// Returns the raw JSON response as a pretty-printed string.
    /// Respects the `useMockRecommendation` flag — no code changes needed to switch.
    func recommend(_ request: MealRecommendationRequest) async throws -> String {
        if useMockRecommendation {
            print("🧪 [MOCK] Returning mock recommendation response.")
            // Simulate a small network delay so the loading state is visible
            try await Task.sleep(nanoseconds: 800_000_000)
            return prettyPrint(mockResponseJSON) ?? mockResponseJSON
        }

        return try await liveRecommend(request)
    }

    // MARK: - Live

    private func liveRecommend(_ request: MealRecommendationRequest) async throws -> String {
        guard let url = URL(string: endpoint) else { throw MealRecommendationError.invalidURL }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(authHeader,         forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        urlRequest.httpBody = try encoder.encode(request)

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? "(empty)"
                throw MealRecommendationError.httpError(statusCode: http.statusCode, body: body)
            }

            return prettyPrint(data) ?? (String(data: data, encoding: .utf8) ?? "(empty response)")
        } catch let error as MealRecommendationError {
            throw error
        } catch {
            throw MealRecommendationError.networkError(error)
        }
    }

    // MARK: - Helpers

    private func prettyPrint(_ string: String) -> String? {
        guard let data = string.data(using: .utf8) else { return nil }
        return prettyPrint(data)
    }

    private func prettyPrint(_ data: Data) -> String? {
        guard
            let json   = try? JSONSerialization.jsonObject(with: data),
            let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        else { return nil }
        return String(data: pretty, encoding: .utf8)
    }
}
