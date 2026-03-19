import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var analytics: DailyAnalytics?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentDate = Date()

    @Published var goals = GoalsStore.load()

    var totals: NutritionTotals { analytics?.nutritionTotals ?? NutritionTotals(calories:0,protein:0,carbs:0,fats:0,fiber:0,sugar:0) }
    var mealCount: Int { analytics?.mealCount ?? 0 }
    var meals: [Meal] { analytics?.meals ?? [] }

    var isToday: Bool { Calendar.current.isDateInToday(currentDate) }

    var dateLabel: String {
        if isToday { return "Today" }
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: currentDate)
    }

    func load() async {
        isLoading = true
        do { analytics = try await APIService.shared.getDailyAnalytics(date: currentDate) }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func goToPreviousDay() {
        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
    }

    func goToNextDay() {
        guard !isToday else { return }
        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
    }
}
