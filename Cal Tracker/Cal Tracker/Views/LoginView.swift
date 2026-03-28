import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            Image("login_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.52)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 10) {
                    Text("Hello")
                        .font(.custom("DMSans-Semibold", size: 46))
                        .foregroundStyle(.white)

                    Text("know how close are you to your goal!")
                        .font(.custom("DMSans-Regular", size: 18))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Spacer()
                    .frame(height: 40)

                VStack(spacing: 12) {
                    if let err = authVM.errorMessage {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    Button {
                        Task { await authVM.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 12) {
                            GoogleGIcon()
                                .frame(width: 22, height: 22)
                            Text("Google Login")
                                .font(.custom("DMSans-Medium", size: 16))
                                .foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(authVM.isLoading)
                    .opacity(authVM.isLoading ? 0.6 : 1)
                }
                .padding(.horizontal, 24)

                Spacer()

                Text("Counting calories can feel overwhelming, But atleast it might help you dazzle in that party!")
                    .font(.custom("DMSans-Regular", size: 16))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
    }
}

/// Simple four-color "G" representing the Google logo.
private struct GoogleGIcon: View {
    var body: some View {
        ZStack {
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
