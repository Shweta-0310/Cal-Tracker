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

                VStack(spacing: 24) {
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

                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.white.opacity(0.3))
                        Text("or")
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.subheadline)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    Button {
                        Task { await authVM.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 10) {
                            GoogleGIcon()
                                .frame(width: 20, height: 20)
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(white: 0.2))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .disabled(authVM.isLoading)
                    .opacity(authVM.isLoading ? 0.6 : 1)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}

/// Simple four-color "G" representing the Google logo.
private struct GoogleGIcon: View {
    var body: some View {
        ZStack {
            // Four-quadrant color ring
            Circle()
                .trim(from: 0.0, to: 0.25)
                .stroke(Color(red: 0.259, green: 0.522, blue: 0.957), lineWidth: 4)
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0.25, to: 0.5)
                .stroke(Color(red: 0.918, green: 0.263, blue: 0.208), lineWidth: 4)
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0.5, to: 0.75)
                .stroke(Color(red: 0.984, green: 0.737, blue: 0.020), lineWidth: 4)
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0.75, to: 1.0)
                .stroke(Color(red: 0.204, green: 0.659, blue: 0.325), lineWidth: 4)
                .rotationEffect(.degrees(-90))

            // Center "G"
            Text("G")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color(red: 0.259, green: 0.522, blue: 0.957))
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
