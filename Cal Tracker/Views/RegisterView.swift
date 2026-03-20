import SwiftUI

// RegisterView is no longer reachable in the UI (LoginView handles sign-in via name-only auth).
// Kept to satisfy the compiler.
struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        EmptyView()
    }
}
