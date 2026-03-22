import Foundation

enum GoalsStore {
    private static let defaults = UserDefaults.standard

    private static var prefix: String {
        let uid = defaults.string(forKey: "currentUserID") ?? "default"
        return "\(uid)_"
    }

    static func load() -> NutritionTotals {
        let p = prefix
        return NutritionTotals(
            calories: defaults.double(forKey: "\(p)goal_calories").nonZero ?? 2000,
            protein:  defaults.double(forKey: "\(p)goal_protein").nonZero  ?? 150,
            carbs:    defaults.double(forKey: "\(p)goal_carbs").nonZero    ?? 250,
            fats:     defaults.double(forKey: "\(p)goal_fats").nonZero     ?? 65,
            fiber:    defaults.double(forKey: "\(p)goal_fiber").nonZero    ?? 25,
            sugar:    defaults.double(forKey: "\(p)goal_sugar").nonZero    ?? 50
        )
    }

    static func save(_ goals: NutritionTotals) {
        let p = prefix
        defaults.set(goals.calories, forKey: "\(p)goal_calories")
        defaults.set(goals.protein,  forKey: "\(p)goal_protein")
        defaults.set(goals.carbs,    forKey: "\(p)goal_carbs")
        defaults.set(goals.fats,     forKey: "\(p)goal_fats")
        defaults.set(goals.fiber,    forKey: "\(p)goal_fiber")
        defaults.set(goals.sugar,    forKey: "\(p)goal_sugar")
    }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
