import SwiftUI

struct MealDetailView: View {
    let meal: Meal
    var onDelete: (() async -> Void)? = nil

    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirm = false
    @State private var showEdit = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)

                Text(meal.mealName ?? "Meal")
                    .font(.custom("Georgia-Bold", size: 28))

                let f = DateFormatter()
                let _ = { f.dateStyle = .medium; f.timeStyle = .short }()
                Text(f.string(from: meal.loggedAt))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    nutriRow("Calories", "\(Int(meal.calories)) kcal")
                    nutriRow("Protein",  "\(Int(meal.protein))g")
                    nutriRow("Carbs",    "\(Int(meal.carbs))g")
                    nutriRow("Fats",     "\(Int(meal.fats))g")
                    nutriRow("Others",   "\(Int(meal.others))g")
                }
                .padding()
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button("Edit Meal") { showEdit = true }
                    .buttonStyle(.bordered)

                Button("Delete Meal", role: .destructive) { showDeleteConfirm = true }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            EditMealView(meal: meal) { await onDelete?() }
        }
        .alert("Delete Meal?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await APIService.shared.deleteMeal(id: meal.id)
                    await onDelete?()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func nutriRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}
