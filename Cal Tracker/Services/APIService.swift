import Foundation

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
        request.setValue(AuthViewModel.userID, forHTTPHeaderField: "X-User-ID")
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
