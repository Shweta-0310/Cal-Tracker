import SwiftUI

struct MealCardView: View {
    let meal: Meal

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife.circle.fill")
                .resizable().scaledToFill()
                .frame(width: 56, height: 56)
                .foregroundStyle(.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(meal.mealName ?? "Meal").font(.headline)
                Text("\(Int(meal.calories)) kcal")
                Text("P: \(Int(meal.protein))g  C: \(Int(meal.carbs))g  F: \(Int(meal.fats))g")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    MealCardView(meal: Meal(
        id: UUID(),
        userId: UUID(),
        imageUrl: nil,
        mealName: "Grilled Chicken & Rice",
        calories: 550,
        protein: 45,
        carbs: 55,
        fats: 12,
        fiber: 4,
        sugar: 2,
        loggedAt: Date(),
        createdAt: Date()
    ))
    .padding()
}
