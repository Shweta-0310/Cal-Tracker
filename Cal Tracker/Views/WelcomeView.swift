import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showAddMeal = false
    @State private var quote = WelcomeView.randomQuote()

    private static let quotes = [
        "\u{201C}Eat well, feel well.\u{201D}",
        "\u{201C}You are what you eat, so eat something amazing.\u{201D}",
        "\u{201C}Take care of your body. It\u{2019}s the only place you have to live.\u{201D}",
        "\u{201C}Small steps every day lead to big results.\u{201D}",
        "\u{201C}Good nutrition is the foundation of good health.\u{201D}",
        "\u{201C}A healthy outside starts from the inside.\u{201D}"
    ]

    private static func randomQuote() -> String {
        quotes.randomElement()!
    }

    var body: some View {
        ZStack {
            Image("welcome_bg")
                .resizable().scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                Text("Hello, \(authVM.userName)!")
                    .font(.largeTitle.bold()).foregroundStyle(.white)
                Text("Track your first meal to get started.")
                    .foregroundStyle(.white.opacity(0.85))
                Text(quote)
                    .italic().foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                PrimaryButton(title: "Upload Meal Photo") { showAddMeal = true }
                    .padding(.bottom, 40)
            }
            .padding()
        }
        .sheet(isPresented: $showAddMeal) {
            AddMealView()
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject({
            let vm = AuthViewModel()
            vm.userName = "Shweta"
            return vm
        }())
}
