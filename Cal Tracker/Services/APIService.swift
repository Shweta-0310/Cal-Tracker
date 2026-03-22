import Foundation
import Supabase

class APIService {
    static let shared = APIService()

    static let iso: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let str = try decoder.singleValueContainer().decode(String.self)
            let withMS = ISO8601DateFormatter()
            withMS.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withMS.date(from: str) { return date }
            let withoutMS = ISO8601DateFormatter()
            withoutMS.formatOptions = [.withInternetDateTime]
            if let date = withoutMS.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(),
                debugDescription: "Invalid date: \(str)")
        }
        return d
    }()

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func request(_ path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> Data {
        guard let url = URL(string: Config.apiBaseURL + path) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        let currentUserID = UserDefaults.standard.string(forKey: "currentUserID") ?? "anonymous"
        request.setValue(currentUserID, forHTTPHeaderField: "X-User-ID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
                ?? "Server error \(http.statusCode)"
            throw NSError(domain: "APIError", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return data
    }

    /// Calls Gemini to analyze the image but does NOT persist anything.
    func analyzeMeal(imageData: Data, mimeType: String = "image/jpeg") async throws -> Meal {
        struct AnalyzeResponse: Decodable {
            let mealName: String?
            let calories: Double
            let protein: Double
            let carbs: Double
            let fats: Double
            let fiber: Double
            let sugar: Double
            enum CodingKeys: String, CodingKey {
                case mealName = "meal_name", calories, protein, carbs, fats, fiber, sugar
            }
        }
        let body: [String: Any] = [
            "imageData": imageData.base64EncodedString(),
            "mimeType": mimeType
        ]
        let data = try await request("/meals/analyze", method: "POST", body: body)
        let r = try APIService.iso.decode(AnalyzeResponse.self, from: data)
        // Build a temporary Meal for display (no real ID/date yet)
        return Meal(id: UUID(), userId: nil, imageUrl: nil,
                    mealName: r.mealName, calories: r.calories,
                    protein: r.protein, carbs: r.carbs, fats: r.fats,
                    fiber: r.fiber, sugar: r.sugar,
                    loggedAt: Date(), createdAt: nil)
    }

    /// Uploads a meal image to Supabase Storage and returns its public URL.
    func uploadMealImage(_ data: Data) async throws -> String {
        let currentUserID = UserDefaults.standard.string(forKey: "currentUserID") ?? "anonymous"
        let path = "\(currentUserID)/\(UUID().uuidString).jpg"
        try await SupabaseManager.shared.storage
            .from("meal-images")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
        let publicURL = try SupabaseManager.shared.storage
            .from("meal-images")
            .getPublicURL(path: path)
        return publicURL.absoluteString
    }

    /// Persists the confirmed meal to Supabase and returns the saved record.
    func createMeal(from meal: Meal, imageUrl: String? = nil) async throws -> Meal {
        var body: [String: Any] = [
            "meal_name": meal.mealName ?? "Meal",
            "calories": meal.calories,
            "protein": meal.protein,
            "carbs": meal.carbs,
            "fats": meal.fats,
            "fiber": meal.fiber,
            "sugar": meal.sugar
        ]
        if let imageUrl { body["image_url"] = imageUrl }
        let data = try await request("/meals", method: "POST", body: body)
        return try APIService.iso.decode(Meal.self, from: data)
    }

    func getDailyAnalytics(date: Date = Date()) async throws -> DailyAnalytics {
        let dateString = APIService.dateFormatter.string(from: date)
        let data = try await request("/analytics/daily?date=\(dateString)")
        return try APIService.iso.decode(DailyAnalytics.self, from: data)
    }

    func updateMeal(id: UUID, mealName: String, calories: Double, protein: Double, carbs: Double, fats: Double, fiber: Double, sugar: Double) async throws -> Meal {
        let body: [String: Any] = [
            "meal_name": mealName,
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "fats": fats,
            "fiber": fiber,
            "sugar": sugar
        ]
        let data = try await request("/meals/\(id.uuidString)", method: "PUT", body: body)
        return try APIService.iso.decode(Meal.self, from: data)
    }

    func getWeeklyAnalytics(date: Date = Date()) async throws -> WeeklyAnalytics {
        let dateString = APIService.dateFormatter.string(from: date)
        let data = try await request("/analytics/weekly?date=\(dateString)")
        return try APIService.iso.decode(WeeklyAnalytics.self, from: data)
    }

    func deleteMeal(id: UUID) async throws {
        _ = try await request("/meals/\(id.uuidString)", method: "DELETE")
    }
}
