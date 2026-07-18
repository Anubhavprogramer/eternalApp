import Foundation

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

// MARK: - Service

enum MealRecommendationError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int, body: String)
    case decodingError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:               return "Invalid URL."
        case .httpError(let code, let body): return "HTTP \(code): \(body)"
        case .decodingError(let msg):   return "Decode error: \(msg)"
        case .networkError(let err):    return err.localizedDescription
        }
    }
}

final class MealRecommendationService {

    static let shared = MealRecommendationService()
    private init() {}

    private let endpoint = "https://admin.nudgeit.shop/admin/api/bring-your-own-meal/recommend"
    private let authHeader = "Basic YWRtaW46YWRtaW4xMjM="

    /// Returns the raw JSON response as a pretty-printed string.
    func recommend(_ request: MealRecommendationRequest) async throws -> String {
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

            // Pretty-print JSON if possible, otherwise return raw string
            if let json = try? JSONSerialization.jsonObject(with: data),
               let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let prettyString = String(data: pretty, encoding: .utf8) {
                return prettyString
            }

            return String(data: data, encoding: .utf8) ?? "(empty response)"
        } catch let error as MealRecommendationError {
            throw error
        } catch {
            throw MealRecommendationError.networkError(error)
        }
    }
}
