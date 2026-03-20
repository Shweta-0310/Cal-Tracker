import SwiftUI

@main
struct Cal_TrackerApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var mealStore = MealStore()
    @AppStorage("hasLoggedFirstMeal") private var hasLoggedFirstMeal = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !authVM.isAuthenticated {
                    LoginView()
                } else if !hasLoggedFirstMeal {
                    WelcomeView()
                } else {
                    DashboardView()
                }
            }
            .environmentObject(authVM)
            .environmentObject(mealStore)
            .task { await authVM.checkSession() }
        }
    }
}
