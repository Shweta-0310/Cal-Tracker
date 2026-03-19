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
                colors: [.black.opacity(0.5), .black.opacity(0.1)],
                startPoint: .bottom, endPoint: .top
            ).ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Text("Cal Tracker")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("What's your name?")
                    .foregroundStyle(.white.opacity(0.85))

                TextField("Your name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .multilineTextAlignment(.center)

                if let err = authVM.errorMessage {
                    Text(err).foregroundStyle(.red).font(.caption)
                }

                Button {
                    Task { await authVM.signInWithName(name) }
                } label: {
                    if authVM.isLoading {
                        ProgressView()
                    } else {
                        Text("Get Started")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(authVM.isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty)

                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject({
            let vm = AuthViewModel()
            return vm
        }())
}
