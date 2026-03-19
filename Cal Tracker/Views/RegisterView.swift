import SwiftUI

// RegisterView is no longer reachable in the UI (LoginView handles both
// sign-in and sign-up via name-only auth). Kept to satisfy the compiler.
struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Create Account").font(.title.bold())

            TextField("Your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.words)
                .disableAutocorrection(true)

            if let err = authVM.errorMessage {
                Text(err).foregroundStyle(.red).font(.caption)
            }

            Button {
                Task { await authVM.signInWithName(name) }
            } label: {
                if authVM.isLoading { ProgressView() }
                else { Text("Get Started").frame(maxWidth: .infinity) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(authVM.isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty)

            Button("Back") { dismiss() }
        }
        .padding()
    }
}
