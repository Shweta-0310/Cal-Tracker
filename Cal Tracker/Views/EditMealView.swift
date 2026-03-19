import SwiftUI

struct EditMealView: View {
    let meal: Meal
    var onSave: (() async -> Void)? = nil

    @Environment(\.dismiss) var dismiss
    @State private var mealName: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fats: String
    @State private var fiber: String
    @State private var sugar: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(meal: Meal, onSave: (() async -> Void)? = nil) {
        self.meal = meal
        self.onSave = onSave
        _mealName = State(initialValue: meal.mealName ?? "")
        _calories = State(initialValue: String(Int(meal.calories)))
        _protein  = State(initialValue: String(Int(meal.protein)))
        _carbs    = State(initialValue: String(Int(meal.carbs)))
        _fats     = State(initialValue: String(Int(meal.fats)))
        _fiber    = State(initialValue: String(Int(meal.fiber)))
        _sugar    = State(initialValue: String(Int(meal.sugar)))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal Name") {
                    TextField("Name", text: $mealName)
                }
                Section("Nutrition") {
                    nutriField("Calories (kcal)", value: $calories)
                    nutriField("Protein (g)",     value: $protein)
                    nutriField("Carbs (g)",        value: $carbs)
                    nutriField("Fats (g)",         value: $fats)
                    nutriField("Fiber (g)",        value: $fiber)
                    nutriField("Sugar (g)",        value: $sugar)
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(isSaving || mealName.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private func nutriField(_ label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            _ = try await APIService.shared.updateMeal(
                id: meal.id,
                mealName: mealName,
                calories: Double(calories) ?? meal.calories,
                protein:  Double(protein)  ?? meal.protein,
                carbs:    Double(carbs)    ?? meal.carbs,
                fats:     Double(fats)     ?? meal.fats,
                fiber:    Double(fiber)    ?? meal.fiber,
                sugar:    Double(sugar)    ?? meal.sugar
            )
            await onSave?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
