import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showAddMeal = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                topCard
                emptyStateCard
                    .padding(.horizontal, 8)
                    .padding(.top, 40)
                    .padding(.bottom, 16)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color(hex: "#f7f1e8"))
        .overlay(alignment: .top) {
            Color(hex: "#fffcf5")
                .ignoresSafeArea(edges: .top)
                .frame(height: 0)
        }
        .safeAreaInset(edge: .bottom) { uploadButton }
        .sheet(isPresented: $showAddMeal) { UploadMealSheetView() }
    }

    // MARK: Top card

    @ViewBuilder private var topCard: some View {
        VStack(spacing: 40) {
            dateHeader
            ringView
            macroRow
        }
        .padding(.top, 16)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 24,
                bottomTrailingRadius: 24, topTrailingRadius: 0
            )
            .fill(Color(hex: "#fffcf5"))
            .ignoresSafeArea(edges: .top)
        )
    }

    @ViewBuilder private var dateHeader: some View {
        HStack(spacing: 40) {
            Image(systemName: "chevron.left")
                .font(.custom("DMSans-Medium", size: 16))
                .foregroundStyle(Color(hex: "#161616").opacity(0.3))
            Text("Today")
                .font(.custom("DMSans-Regular", size: 18))
                .tracking(-0.32)
                .foregroundStyle(Color(hex: "#161616"))
            Image(systemName: "chevron.right")
                .font(.custom("DMSans-Medium", size: 16))
                .foregroundStyle(Color(hex: "#161616").opacity(0.3))
        }
    }

    @ViewBuilder private var ringView: some View {
        ZStack {
            Circle()
                .stroke(Color(red: 0.9, green: 0.89, blue: 0.88), lineWidth: 10)
                .frame(width: 166.5, height: 166.5)
            VStack(spacing: 0) {
                Text("0")
                    .font(.custom("DMSans-Regular", size: 32))
                    .foregroundStyle(Color(hex: "#161616"))
                Text("Total Meal")
                    .font(.custom("DMSans-Regular", size: 16))
                    .tracking(-0.32)
                    .foregroundStyle(Color(hex: "#161616"))
            }
        }
    }

    @ViewBuilder private var macroRow: some View {
        HStack(spacing: 3) {
            MacroStatColumn(label: "Calories", value: 0, color: MacroColor.calories, unit: "kcal")
            MacroStatColumn(label: "Protein",  value: 0, color: MacroColor.protein,  unit: "g")
            MacroStatColumn(label: "Fats",     value: 0, color: MacroColor.fats,     unit: "g")
            MacroStatColumn(label: "Carbs",    value: 0, color: MacroColor.carbs,    unit: "g")
        }
        .padding(.horizontal, 16)
    }

    // MARK: Empty state

    @ViewBuilder private var emptyStateCard: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(hex: "#fffcf5"))
            .frame(height: 372)
            .overlay {
                VStack(spacing: 16) {
                    Image("bowl-illustration")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 82, height: 69)
                    Text("A good day starts\nwith a good meal")
                        .font(.custom("DMSans-Regular", size: 16))
                        .tracking(-0.72)
                        .foregroundStyle(Color(hex: "#B6B6B6"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .frame(width: 170)
            }
    }

    // MARK: Upload button

    @ViewBuilder private var uploadButton: some View {
        Button("Upload Meal") { showAddMeal = true }
            .font(.custom("DMSans-Regular", size: 16))
            .tracking(-0.64)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(.white)
            .background(Color(hex: "#161616"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(8)
            .background {
                Color(hex: "#f7f1e8")
                    .overlay(alignment: .top) {
                        Color(hex: "#efdcc1").frame(height: 1)
                    }
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
