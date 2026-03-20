import SwiftUI
import PhotosUI

struct AddMealView: View {
    var onConfirm: (() async -> Void)? = nil

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var mealStore: MealStore
    @AppStorage("hasLoggedFirstMeal") private var hasLoggedFirstMeal = false

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var result: Meal?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    private let goals = GoalsStore.load()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Meal image
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color(.systemGray5))
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.secondary)
                                    Text("Tap to select a photo")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                }
                            )
                    }
                }
                .onChange(of: selectedItem) { _, item in
                    Task {
                        if let data = try? await item?.loadTransferable(type: Data.self) {
                            selectedImage = UIImage(data: data)
                            result = nil
                        }
                    }
                }

                if let result {
                    VStack(spacing: 24) {
                        // Meal name
                        Text(result.mealName ?? "Meal")
                            .font(.system(size: 20, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        // Macro progress rows
                        VStack(spacing: 20) {
                            MacroProgressRow(label: "Calories", value: result.calories, goal: goals.calories, color: Color(hex: "#7B68EE"))
                            MacroProgressRow(label: "Protein",  value: result.protein,  goal: goals.protein,  color: Color(hex: "#5BC8D5"))
                            MacroProgressRow(label: "Fats",     value: result.fats,     goal: goals.fats,     color: Color(hex: "#F06292"))
                            MacroProgressRow(label: "Carbs",    value: result.carbs,    goal: goals.carbs,    color: Color(hex: "#FFAA5C"))
                            MacroProgressRow(label: "Others",   value: result.others,   goal: goals.fiber,    color: Color(hex: "#FFD166"))
                        }
                        .padding(.horizontal, 24)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal, 24)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if result != nil {
                Button("Confirm and Save") {
                    if let result {
                        mealStore.addMeal(result)
                        hasLoggedFirstMeal = true
                        Task {
                            await onConfirm?()
                            dismiss()
                        }
                    }
                }
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.black)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            } else if selectedImage != nil {
                Button {
                    Task { await analyze() }
                } label: {
                    if isAnalyzing {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                    } else {
                        Text("Analyze Meal")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                }
                .background(Color.black)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                .disabled(isAnalyzing)
            }
        }
    }

    private func analyze() async {
        guard let image = selectedImage,
              let jpeg = image.jpegData(compressionQuality: 0.7) else { return }
        isAnalyzing = true
        errorMessage = nil
        do {
            result = try await APIService.shared.createMeal(imageData: jpeg, mimeType: "image/jpeg")
        } catch {
            errorMessage = error.localizedDescription
        }
        isAnalyzing = false
    }
}

#Preview("Empty State") {
    AddMealView()
        .environmentObject(MealStore())
}
