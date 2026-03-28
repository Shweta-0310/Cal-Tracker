import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var mealStore: MealStore
    @StateObject private var vm = DashboardViewModel()
    @State private var showAddMeal = false
    @State private var newMealIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    topCard
                    dailyMealSection
                        .padding(.horizontal, 16)
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
            .toolbar(.hidden, for: .navigationBar)
            .task { await vm.load() }
            .onChange(of: vm.currentDate) { _, _ in
                newMealIDs = []
                Task { await vm.load() }
            }
            .safeAreaInset(edge: .bottom) { uploadButton }
            .sheet(isPresented: $showAddMeal) {
                UploadMealSheetView(onConfirm: {
                    let previousIDs = Set(vm.meals.map(\.id))
                    await vm.load()
                    newMealIDs = Set(vm.meals.map(\.id)).subtracting(previousIDs)
                })
            }
        }
    }

    // MARK: Top card

    @ViewBuilder private var topCard: some View {
        VStack(spacing: 40) {
            dateHeader
            donutRing
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
        ZStack {
            HStack(spacing: 40) {
                Button { vm.goToPreviousDay() } label: {
                    Image(systemName: "chevron.left")
                        .font(.custom("DMSans-Medium", size: 16))
                        .foregroundStyle(Color(hex: "#161616"))
                }
                Text(vm.dateLabel)
                    .font(.custom("DMSans-Regular", size: 18))
                    .tracking(-0.32)
                    .foregroundStyle(Color(hex: "#161616"))
                Button { vm.goToNextDay() } label: {
                    Image(systemName: "chevron.right")
                        .font(.custom("DMSans-Medium", size: 16))
                        .foregroundStyle(Color(hex: "#161616").opacity(vm.isToday ? 0.3 : 1.0))
                }
                .disabled(vm.isToday)
            }

            HStack {
                Spacer()
                Button {
                    Task { await authVM.signOut() }
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "#161616"))
                }
                .padding(.trailing, 20)
            }
        }
    }

    @ViewBuilder private var donutRing: some View {
        SegmentedDonutView(
            totals: vm.totals,
            mealCount: vm.mealCount
        )
        .frame(width: 166.5, height: 166.5)
    }

    @ViewBuilder private var macroRow: some View {
        HStack(spacing: 3) {
            MacroStatColumn(label: "Calories", value: vm.totals.calories, color: MacroColor.calories, unit: "kcal")
            MacroStatColumn(label: "Protein",  value: vm.totals.protein,  color: MacroColor.protein,  unit: "g")
            MacroStatColumn(label: "Fats",     value: vm.totals.fats,     color: MacroColor.fats,     unit: "g")
            MacroStatColumn(label: "Carbs",    value: vm.totals.carbs,    color: MacroColor.carbs,    unit: "g")
        }
        .padding(.horizontal, 16)
    }

    // MARK: Daily Meal section

    @ViewBuilder private var dailyMealSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Meal")
                .font(.custom("DMSans-SemiBold", size: 18))
                .tracking(-0.36)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .leading)

            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if vm.meals.isEmpty {
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
            } else {
                ForEach(vm.meals) { meal in
                    NavigationLink {
                        MealDetailView(meal: meal) {
                            Task { await vm.load() }
                        }
                    } label: {
                        MealCardView(
                            meal: meal,
                            localImage: mealStore.mealImages[meal.id],
                            isNew: newMealIDs.contains(meal.id),
                            onDelete: {
                                try? await APIService.shared.deleteMeal(id: meal.id)
                                mealStore.removeImage(for: meal.id)
                                await vm.load()
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
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
                    .ignoresSafeArea(edges: .bottom)
                    .overlay(alignment: .top) {
                        Color(hex: "#efdcc1").frame(height: 1)
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
