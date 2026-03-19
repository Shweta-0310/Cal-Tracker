import SwiftUI

struct SettingsView: View {
    @Binding var goals: NutritionTotals
    @Environment(\.dismiss) var dismiss

    @State private var calories: String = ""
    @State private var protein: String  = ""
    @State private var carbs: String    = ""
    @State private var fats: String     = ""
    @State private var fiber: String    = ""
    @State private var sugar: String    = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Goals") {
                    goalField("Calories (kcal)", value: $calories)
                    goalField("Protein (g)",     value: $protein)
                    goalField("Carbs (g)",       value: $carbs)
                    goalField("Fats (g)",        value: $fats)
                    goalField("Fiber (g)",       value: $fiber)
                    goalField("Sugar (g)",       value: $sugar)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear { populate() }
        }
    }

    @ViewBuilder
    private func goalField(_ label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }

    private func populate() {
        calories = String(Int(goals.calories))
        protein  = String(Int(goals.protein))
        carbs    = String(Int(goals.carbs))
        fats     = String(Int(goals.fats))
        fiber    = String(Int(goals.fiber))
        sugar    = String(Int(goals.sugar))
    }

    private func save() {
        let updated = NutritionTotals(
            calories: Double(calories) ?? goals.calories,
            protein:  Double(protein)  ?? goals.protein,
            carbs:    Double(carbs)    ?? goals.carbs,
            fats:     Double(fats)     ?? goals.fats,
            fiber:    Double(fiber)    ?? goals.fiber,
            sugar:    Double(sugar)    ?? goals.sugar
        )
        GoalsStore.save(updated)
        goals = updated
        dismiss()
    }
}
