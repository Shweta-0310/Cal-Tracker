import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showAddMeal = false

    var body: some View {
        VStack(spacing: 56) {
            // Date header
            HStack(spacing: 16) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.primary)
                Text("Today")
                    .font(.headline)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.primary)
            }
            .padding(.top, 8)

            // Empty donut + empty state
            VStack(spacing: 56) {
                // Gray empty ring
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 24)
                        .frame(width: 220, height: 220)

                    VStack(spacing: 4) {
                        Text("00")
                            .font(.system(size: 40, weight: .regular))
                        Text("Total Meal")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }

                Text("No meal uploaded yet")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .safeAreaInset(edge: .bottom) {
            Button("Upload Meal Photo") { showAddMeal = true }
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.black)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
                .padding(.bottom, 8)
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
