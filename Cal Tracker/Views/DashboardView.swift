import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var mealStore: MealStore
    @StateObject private var vm = DashboardViewModel()
    @State private var showAddMeal = false
    @State private var showSettings = false
    @State private var showWeekly = false
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 56) {
                    // Date navigator
                    HStack(spacing: 16) {
                        Button { vm.goToPreviousDay() } label: {
                            Image(systemName: "chevron.left")
                        }
                        Text(vm.dateLabel)
                            .font(.custom("Georgia-Bold", size: 20))
                        Button { vm.goToNextDay() } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(vm.isToday)
                    }

                    // Donut chart + Macro progress rows
                    VStack(spacing: 56) {
                        SegmentedDonutView(totals: vm.totals, goals: vm.goals, mealCount: vm.mealCount)
                            .frame(width: 220, height: 220)

                        VStack(spacing: 20) {
                            MacroProgressRow(label: "Calories", value: vm.totals.calories, goal: vm.goals.calories, color: MacroColor.calories)
                            MacroProgressRow(label: "Protein",  value: vm.totals.protein,  goal: vm.goals.protein,  color: MacroColor.protein)
                            MacroProgressRow(label: "Fats",     value: vm.totals.fats,     goal: vm.goals.fats,     color: MacroColor.fats)
                            MacroProgressRow(label: "Carbs",    value: vm.totals.carbs,    goal: vm.goals.carbs,    color: MacroColor.carbs)
                            MacroProgressRow(label: "Others",   value: vm.totals.others,   goal: vm.goals.fiber,    color: MacroColor.others)
                        }
                    }

                    // Meal list
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        ForEach(vm.meals) { meal in
                            NavigationLink {
                                MealDetailView(meal: meal) {
                                    Task { await vm.load() }
                                }
                            } label: {
                                MealCardView(meal: meal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top)
                .padding(.horizontal, 24)
            }
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .topTrailing) {
                Button {
                    showLogoutConfirm = true
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 18))
                        .foregroundStyle(.primary)
                        .padding(12)
                }
            }
            .confirmationDialog("Sign out?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    Task { await authVM.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            }
            .task { await vm.load() }
            .onChange(of: vm.currentDate) { _, _ in
                Task { await vm.load() }
            }
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
                AddMealView(onConfirm: {
                    await vm.load()
                })
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
