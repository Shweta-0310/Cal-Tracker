import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var name = ""

    var body: some View {
        ZStack {
            Image("login_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.5), .black.opacity(0.5)],
                startPoint: .bottom, endPoint: .top
            ).ignoresSafeArea()

            VStack(spacing: 56) {
                Spacer()

                Text("Keeps You Growing")
                    .font(.custom("Georgia-Bold", size: 30))
                    .foregroundStyle(.white)

                VStack(spacing: 48) {
                    VStack(spacing: 16) {
                        Text("What's your name?")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))

                        AppTextField(placeholder: "Your name", text: $name)
                    }

                    if let err = authVM.errorMessage {
                        Text(err).foregroundStyle(.red).font(.caption)
                    }

                    PrimaryButton(
                        title: "Get Started",
                        isLoading: authVM.isLoading,
                        isDisabled: name.trimmingCharacters(in: .whitespaces).isEmpty
                    ) {
                        Task { await authVM.signInWithName(name) }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
