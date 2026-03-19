import Foundation

enum GoalsStore {
    private static let defaults = UserDefaults.standard

    static func load() -> NutritionTotals {
        NutritionTotals(
            calories: defaults.double(forKey: "goal_calories").nonZero ?? 2000,
            protein:  defaults.double(forKey: "goal_protein").nonZero  ?? 150,
            carbs:    defaults.double(forKey: "goal_carbs").nonZero    ?? 250,
            fats:     defaults.double(forKey: "goal_fats").nonZero     ?? 65,
            fiber:    defaults.double(forKey: "goal_fiber").nonZero    ?? 25,
            sugar:    defaults.double(forKey: "goal_sugar").nonZero    ?? 50
        )
    }

    static func save(_ goals: NutritionTotals) {
        defaults.set(goals.calories, forKey: "goal_calories")
        defaults.set(goals.protein,  forKey: "goal_protein")
        defaults.set(goals.carbs,    forKey: "goal_carbs")
        defaults.set(goals.fats,     forKey: "goal_fats")
        defaults.set(goals.fiber,    forKey: "goal_fiber")
        defaults.set(goals.sugar,    forKey: "goal_sugar")
    }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
