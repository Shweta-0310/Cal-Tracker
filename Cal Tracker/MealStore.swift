import Foundation
import Combine

class MealStore: ObservableObject {
    @Published var meals: [Meal] = []

    func addMeal(_ meal: Meal) {
        meals.insert(meal, at: 0)
    }

    var totals: NutritionTotals {
        NutritionTotals(
            calories: meals.reduce(0) { $0 + $1.calories },
            protein:  meals.reduce(0) { $0 + $1.protein },
            carbs:    meals.reduce(0) { $0 + $1.carbs },
            fats:     meals.reduce(0) { $0 + $1.fats },
            fiber:    meals.reduce(0) { $0 + $1.fiber },
            sugar:    meals.reduce(0) { $0 + $1.sugar }
        )
    }
}
