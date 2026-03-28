import SwiftUI

struct MealCardView: View {
    let meal: Meal
    var localImage: UIImage? = nil
    var isNew: Bool = false
    var onDelete: (() async -> Void)? = nil

    @State private var showDeleteConfirm = false
    @State private var appeared = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 75×75 meal image
            Group {
                if let urlString = meal.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            if let local = localImage {
                                Image(uiImage: local).resizable().scaledToFill()
                            } else {
                                fallbackIcon
                            }
                        }
                    }
                } else if let local = localImage {
                    Image(uiImage: local).resizable().scaledToFill()
                } else {
                    fallbackIcon
                }
            }
            .frame(width: 75, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Info column
            VStack(alignment: .leading, spacing: 10) {
                // Meal name + X button
                HStack(alignment: .center) {
                    Text(meal.mealName ?? "Meal")
                        .font(.custom("DMSans-Regular", size: 18))
                        .tracking(-0.32)
                        .foregroundStyle(.black)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: "#161616"))
                            .frame(width: 16, height: 16)
                    }
                }

                // Macro grid: 2 rows × 2 columns
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        macroChip(color: MacroColor.calories, label: "Cal",  value: "\(Int(meal.calories)) kcal")
                        macroChip(color: MacroColor.protein,  label: "Pro",  value: "\(Int(meal.protein)) g")
                    }
                    HStack(spacing: 6) {
                        macroChip(color: MacroColor.fats,  label: "Fats",  value: "\(Int(meal.fats)) g")
                        macroChip(color: MacroColor.carbs, label: "Carbs", value: "\(Int(meal.carbs)) g")
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(8)
        .background(Color(hex: "#fffcf5"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(!isNew || appeared ? 1 : 0)
        .offset(y: !isNew || appeared ? 0 : 80)
        .onAppear {
            guard isNew else { return }
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
        .confirmationDialog("Delete this meal?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task { await onDelete?() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func macroChip(color: Color, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 8, height: 8)
            HStack(spacing: 0) {
                Text("\(label): ")
                    .foregroundStyle(Color(hex: "#777777"))
                Text(value)
                    .foregroundStyle(Color(hex: "#161616"))
            }
            .font(.custom("DMSans-Regular", size: 15))
            .tracking(-0.56)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fallbackIcon: some View {
        ZStack {
            Color(hex: "#f7f1e8")
            Image(systemName: "fork.knife")
                .font(.system(size: 24))
                .foregroundStyle(Color(hex: "#777777"))
        }
    }
}

#Preview {
    MealCardView(meal: Meal(
        id: UUID(),
        userId: UUID(),
        imageUrl: nil,
        mealName: "Paratha with Curd",
        calories: 450,
        protein: 12,
        carbs: 55,
        fats: 18,
        fiber: 4,
        sugar: 2,
        loggedAt: Date(),
        createdAt: Date()
    ))
    .padding()
    .background(Color(hex: "#f7f1e8"))
}
