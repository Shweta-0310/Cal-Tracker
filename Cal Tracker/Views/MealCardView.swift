import SwiftUI

struct MealCardView: View {
    let meal: Meal

    var body: some View {
        HStack(spacing: 16) {
            // Meal image
            Group {
                if let urlString = meal.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            fallbackIcon
                        }
                    }
                } else {
                    fallbackIcon
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Meal info
            VStack(alignment: .leading, spacing: 6) {
                Text(meal.mealName ?? "Meal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .truncationMode(.tail)

                Text("\(Int(meal.calories)) kcal")
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)

                Spacer().frame(height: 2)

                Text("P: \(Int(meal.protein))g    C: \(Int(meal.carbs))g    F: \(Int(meal.fats))g")
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var fallbackIcon: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "fork.knife")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
        }
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
