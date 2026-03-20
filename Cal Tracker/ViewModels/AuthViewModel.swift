import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userNameKey = "userName"

    /// Persistent device-based user ID — generated once, stored forever.
    static var userID: String {
        if let existing = UserDefaults.standard.string(forKey: "userID") { return existing }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: "userID")
        return new
    }

    func checkSession() async {
        if let saved = UserDefaults.standard.string(forKey: userNameKey), !saved.isEmpty {
            userName = saved
            isAuthenticated = true
        }
    }

    func signInWithName(_ name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        userName = trimmed
        UserDefaults.standard.set(trimmed, forKey: userNameKey)
        _ = AuthViewModel.userID
        isAuthenticated = true
        isLoading = false
    }

    func signOut() async {
        UserDefaults.standard.removeObject(forKey: userNameKey)
        isAuthenticated = false
        userName = ""
    }
}
