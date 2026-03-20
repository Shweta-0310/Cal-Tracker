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
                VStack(spacing: 20) {
                    // Date navigator
                    HStack {
                        Button { vm.goToPreviousDay() } label: {
                            Image(systemName: "chevron.left")
                        }
                        Text(vm.dateLabel).font(.headline)
                        Button { vm.goToNextDay() } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(vm.isToday)
                    }

                    // Donut chart
                    SegmentedDonutView(totals: mealStore.totals, mealCount: mealStore.meals.count)
                        .frame(width: 200, height: 200)

                    // Macro progress rows
                    VStack(spacing: 8) {
                        MacroProgressRow(label: "Calories", value: mealStore.totals.calories, goal: vm.goals.calories, color: .orange)
                        MacroProgressRow(label: "Protein",  value: mealStore.totals.protein,  goal: vm.goals.protein,  color: .blue)
                        MacroProgressRow(label: "Fats",     value: mealStore.totals.fats,     goal: vm.goals.fats,     color: .pink)
                        MacroProgressRow(label: "Carbs",    value: mealStore.totals.carbs,    goal: vm.goals.carbs,    color: Color(hex: "#FFBF69"))
                        MacroProgressRow(label: "Others",   value: mealStore.totals.others,   goal: vm.goals.others,   color: .purple)
                    }.padding(.horizontal)

                    // Meal list
                    ForEach(mealStore.meals) { meal in
                        NavigationLink {
                            MealDetailView(meal: meal) { }
                        } label: {
                            MealCardView(meal: meal)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Cal Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sign Out") { Task { await authVM.signOut() } }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button { showWeekly = true } label: {
                            Image(systemName: "chart.bar")
                        }
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(goals: $vm.goals)
            }
            .sheet(isPresented: $showWeekly) {
                WeeklySummaryView()
            }
            .safeAreaInset(edge: .bottom) {
                Button("Upload Meal Photo") { showAddMeal = true }
                    .buttonStyle(.borderedProminent)
                    .padding()
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
}
