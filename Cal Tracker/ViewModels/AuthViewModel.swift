import Foundation
import Combine
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoggedFirstMeal = false

    private let userNameKey = "userName"

    /// Per-user stable UUID for name-based accounts.
    var userID: String {
        guard !userName.isEmpty else { return "anonymous" }
        let key = "userID_\(userName)"
        if let existing = UserDefaults.standard.string(forKey: key) { return existing }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }

    func checkSession() async {
        // Check active Supabase session (Google-authenticated users)
        if let user = SupabaseManager.shared.auth.currentSession?.user {
            applyUser(user)
            return
        }
        // Fall back to name-based session
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

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        do {
            try await SupabaseManager.shared.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "caltracker://login-callback")
            )
            if let user = SupabaseManager.shared.auth.currentSession?.user {
                applyUser(user)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func handleAuthCallback(url: URL) async {
        do {
            try await SupabaseManager.shared.auth.session(from: url)
            if let user = SupabaseManager.shared.auth.currentSession?.user {
                applyUser(user)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func markFirstMealLogged() {
        hasLoggedFirstMeal = true
        UserDefaults.standard.set(true, forKey: "hasLoggedFirstMeal_\(userName)")
    }

    func signOut() async {
        try? await SupabaseManager.shared.auth.signOut()
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: "currentUserID")
        isAuthenticated = false
        userName = ""
        hasLoggedFirstMeal = false
    }

    // MARK: - Private

    private func applyUser(_ user: User) {
        var displayName = user.email ?? "Google User"
        if case .string(let name) = user.userMetadata["full_name"] {
            displayName = name
        } else if case .string(let name) = user.userMetadata["name"] {
            displayName = name
        }
        userName = displayName
        UserDefaults.standard.set(displayName, forKey: userNameKey)
        UserDefaults.standard.set(user.id.uuidString, forKey: "currentUserID")
        hasLoggedFirstMeal = UserDefaults.standard.bool(forKey: "hasLoggedFirstMeal_\(displayName)")
        isAuthenticated = true
    }
}
