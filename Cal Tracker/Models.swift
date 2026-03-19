import Foundation

struct Meal: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let imageUrl: String?
    let mealName: String?
    let calories: Double
    let protein: Double
    let carbs: Double
    let fats: Double
    let fiber: Double
    let sugar: Double
    let loggedAt: Date
    let createdAt: Date

    var others: Double { fiber + sugar }

    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", imageUrl = "image_url",
             mealName = "meal_name", calories, protein, carbs, fats,
             fiber, sugar, loggedAt = "logged_at", createdAt = "created_at"
    }
}

struct NutritionTotals {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fats: Double
    var fiber: Double
    var sugar: Double

    var others: Double { fiber + sugar }
}

struct TotalsResponse: Codable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fats: Double
    let fiber: Double
    let sugar: Double
}

struct DayAnalytics: Codable {
    let date: String
    let mealCount: Int
    let totals: TotalsResponse

    enum CodingKeys: String, CodingKey {
        case date, mealCount = "meal_count", totals
    }
}

struct WeeklyAnalytics: Codable {
    let startDate: String
    let endDate: String
    let totalMeals: Int
    let weekTotals: TotalsResponse
    let days: [DayAnalytics]

    enum CodingKeys: String, CodingKey {
        case startDate = "start_date", endDate = "end_date",
             totalMeals = "total_meals", weekTotals = "week_totals", days
    }
}

struct DailyAnalytics: Codable {
    let date: String
    let mealCount: Int
    let totals: TotalsResponse
    let meals: [Meal]

    enum CodingKeys: String, CodingKey {
        case date, mealCount = "meal_count", totals, meals
    }

    var nutritionTotals: NutritionTotals {
        NutritionTotals(
            calories: totals.calories, protein: totals.protein,
            carbs: totals.carbs, fats: totals.fats,
            fiber: totals.fiber, sugar: totals.sugar
        )
    }
}
