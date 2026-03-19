import Foundation
import Combine
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func checkSession() async {
        let session = try? await SupabaseManager.shared.auth.session
        isAuthenticated = session != nil
        if let meta = session?.user.userMetadata,
           case .string(let name) = meta["name"] {
            userName = name
            UserDefaults.standard.set(name, forKey: "lastUserName")
        }
    }

    // Sign in or sign up using only a name — no password needed from the user.
    // Email and password are derived internally and never shown.
    func signInWithName(_ name: String) async {
        isLoading = true; errorMessage = nil
        let normalized = name.trimmingCharacters(in: .whitespaces).lowercased()
        let email = "\(normalized)@caltracker.app"
        let password = "ct_\(normalized)_secret"

        do {
            // Try existing user first
            let session = try await SupabaseManager.shared.auth.signIn(
                email: email, password: password
            )
            if case .string(let savedName) = session.user.userMetadata["name"] {
                userName = savedName
            } else {
                userName = name
            }
            UserDefaults.standard.set(userName, forKey: "lastUserName")
            isAuthenticated = true
        } catch {
            // New user — sign up
            do {
                _ = try await SupabaseManager.shared.auth.signUp(
                    email: email,
                    password: password,
                    data: ["name": .string(name)]
                )
                userName = name
                UserDefaults.standard.set(name, forKey: "lastUserName")
                isAuthenticated = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func signOut() async {
        try? await SupabaseManager.shared.auth.signOut()
        isAuthenticated = false
        userName = ""
    }
}
