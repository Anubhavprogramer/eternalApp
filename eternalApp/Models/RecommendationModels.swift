import Foundation

// MARK: - Top-level response

struct RecommendationResponse: Decodable, Hashable {
    let status: String
    let meta: RecommendationMeta
    let recommendations: [MealRecommendation]
    let needsUserConfirmation: Bool
    let extractedIngredients: [ExtractedIngredient]

    enum CodingKeys: String, CodingKey {
        case status
        case meta
        case recommendations
        case needsUserConfirmation  = "needs_user_confirmation"
        case extractedIngredients   = "extracted_ingredients"
    }
}

// MARK: - Meta

struct RecommendationMeta: Decodable, Hashable {
    let normalizedDiet: String
    let inventorySource: String
    let llmProvider: String
    let normalizedGoals: [String]
    let userResponse: String
    let inventorySentToLlmCount: Int
    let inventoryReceivedCount: Int

    enum CodingKeys: String, CodingKey {
        case normalizedDiet          = "normalized_diet"
        case inventorySource         = "inventory_source"
        case llmProvider             = "llm_provider"
        case normalizedGoals         = "normalized_goals"
        case userResponse            = "user_response"
        case inventorySentToLlmCount = "inventory_sent_to_llm_count"
        case inventoryReceivedCount  = "inventory_received_count"
    }
}

// MARK: - Meal Recommendation

struct MealRecommendation: Decodable, Identifiable, Hashable {
    var id: String { mealName }

    let mealName: String
    let description: String
    let whyThisMeal: String
    let dietTags: [String]
    let cookingTimeMinutes: Int
    let budgetScore: Double
    let estimatedMissingCost: Int
    let ingredientsUserHas: [String]
    let missingIngredients: [RecommendationIngredient]
    let optionalIngredients: [RecommendationIngredient]

    enum CodingKeys: String, CodingKey {
        case mealName               = "meal_name"
        case description
        case whyThisMeal            = "why_this_meal"
        case dietTags               = "diet_tags"
        case cookingTimeMinutes     = "cooking_time_minutes"
        case budgetScore            = "budget_score"
        case estimatedMissingCost   = "estimated_missing_cost"
        case ingredientsUserHas     = "ingredients_user_has"
        case missingIngredients     = "missing_ingredients"
        case optionalIngredients    = "optional_ingredients"
    }
}

// MARK: - Ingredient

struct RecommendationIngredient: Decodable, Hashable {
    let productId: String
    let name: String
    let quantity: String
    let price: Int
    let etaMinutes: Int
    let blinkitAvailable: Bool
    let priority: String?

    enum CodingKeys: String, CodingKey {
        case productId        = "product_id"
        case name
        case quantity
        case price
        case etaMinutes       = "eta_minutes"
        case blinkitAvailable = "blinkit_available"
        case priority
    }
}

// MARK: - Extracted Ingredient

struct ExtractedIngredient: Decodable, Hashable {
    let name: String
    let quantityEstimate: String
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case name
        case quantityEstimate = "quantity_estimate"
        case confidence
    }
}
