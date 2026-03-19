import Foundation
import Supabase

class APIService {
    static let shared = APIService()

    static let iso: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
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

        let session = SupabaseManager.shared.auth.currentSession
        guard let token = session?.accessToken else {
            throw URLError(.userAuthenticationRequired)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }

    func createMeal(imageData: Data, mimeType: String = "image/jpeg") async throws -> Meal {
        let body: [String: Any] = [
            "imageData": imageData.base64EncodedString(),
            "mimeType": mimeType
        ]
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
