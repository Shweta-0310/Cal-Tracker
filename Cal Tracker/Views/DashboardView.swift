import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var mealStore: MealStore
    @StateObject private var vm = DashboardViewModel()
    @State private var showAddMeal = false
    @State private var showSettings = false
    @State private var showWeekly = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 56) {
                    // Date navigator
                    HStack(spacing: 16) {
                        Button { vm.goToPreviousDay() } label: {
                            Image(systemName: "chevron.left")
                        }
                        Text(vm.dateLabel).font(.headline)
                        Button { vm.goToNextDay() } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(vm.isToday)
                    }

                    // Donut chart + Macro progress rows
                    VStack(spacing: 56) {
                        // Donut chart
                        SegmentedDonutView(totals: mealStore.totals, mealCount: mealStore.meals.count)
                            .frame(width: 220, height: 220)

                        // Macro progress rows
                        VStack(spacing: 20) {
                            MacroProgressRow(label: "Calories", value: mealStore.totals.calories, goal: vm.goals.calories, color: Color(hex: "#7B68EE"))
                            MacroProgressRow(label: "Protein",  value: mealStore.totals.protein,  goal: vm.goals.protein,  color: Color(hex: "#5BC8D5"))
                            MacroProgressRow(label: "Fats",     value: mealStore.totals.fats,     goal: vm.goals.fats,     color: Color(hex: "#F06292"))
                            MacroProgressRow(label: "Carbs",    value: mealStore.totals.carbs,    goal: vm.goals.carbs,    color: Color(hex: "#FFAA5C"))
                            MacroProgressRow(label: "Others",   value: mealStore.totals.others,   goal: vm.goals.others,   color: Color(hex: "#FFD166"))
                        }
                    }

                    // Meal list
                    ForEach(mealStore.meals) { meal in
                        NavigationLink {
                            MealDetailView(meal: meal) { }
                        } label: {
                            MealCardView(meal: meal)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top)
                .padding(.horizontal, 24)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView(goals: $vm.goals)
            }
            .sheet(isPresented: $showWeekly) {
                WeeklySummaryView()
            }
            .safeAreaInset(edge: .bottom) {
                Button("Upload Meal Photo") { showAddMeal = true }
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.black)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealView()
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject({
            let vm = AuthViewModel()
            vm.userName = "Shweta"
            vm.isAuthenticated = true
            return vm
        }())
        .environmentObject(MealStore())
}
