import SwiftUI

@main
struct Cal_TrackerApp: App {
    @StateObject private var authVM = AuthViewModel()
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
            .task { await authVM.checkSession() }
        }
    }
}
