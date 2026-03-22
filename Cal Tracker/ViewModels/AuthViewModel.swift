import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoggedFirstMeal = false

    private let userNameKey = "userName"

    /// Per-user stable UUID — each unique username gets its own persistent ID.
    var userID: String {
        guard !userName.isEmpty else { return "anonymous" }
        let key = "userID_\(userName)"
        if let existing = UserDefaults.standard.string(forKey: key) { return existing }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }

    func checkSession() async {
        if let saved = UserDefaults.standard.string(forKey: userNameKey), !saved.isEmpty {
            userName = saved
            UserDefaults.standard.set(userID, forKey: "currentUserID")
            hasLoggedFirstMeal = UserDefaults.standard.bool(forKey: "hasLoggedFirstMeal_\(saved)")
            isAuthenticated = true
        }
    }

    func signInWithName(_ name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        userName = trimmed
        UserDefaults.standard.set(trimmed, forKey: userNameKey)
        UserDefaults.standard.set(userID, forKey: "currentUserID")
        hasLoggedFirstMeal = UserDefaults.standard.bool(forKey: "hasLoggedFirstMeal_\(trimmed)")
        isAuthenticated = true
        isLoading = false
    }

    func markFirstMealLogged() {
        hasLoggedFirstMeal = true
        UserDefaults.standard.set(true, forKey: "hasLoggedFirstMeal_\(userName)")
    }

    func signOut() async {
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: "currentUserID")
        isAuthenticated = false
        userName = ""
        hasLoggedFirstMeal = false
    }
}
