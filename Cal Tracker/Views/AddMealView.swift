import SwiftUI
import PhotosUI

struct AddMealView: View {
    var onConfirm: (() async -> Void)? = nil

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var mealStore: MealStore
    @EnvironmentObject var authVM: AuthViewModel

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedImageData: Data?
    @State private var result: Meal?
    @State private var isAnalyzing = false
    @State private var isSaving = false
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
                            .font(.custom("Georgia-Bold", size: 22))
                            .multilineTextAlignment(.center)

                        // Macro progress rows
                        VStack(spacing: 20) {
                            MacroProgressRow(label: "Calories", value: result.calories, goal: goals.calories, color: MacroColor.calories)
                            MacroProgressRow(label: "Protein",  value: result.protein,  goal: goals.protein,  color: MacroColor.protein)
                            MacroProgressRow(label: "Fats",     value: result.fats,     goal: goals.fats,     color: MacroColor.fats)
                            MacroProgressRow(label: "Carbs",    value: result.carbs,    goal: goals.carbs,    color: MacroColor.carbs)
                            MacroProgressRow(label: "Others",   value: result.others,   goal: goals.fiber,    color: MacroColor.others)
                        }
                    }
                    .padding(.horizontal, 24)
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
            VStack(spacing: 0) {
                if result != nil {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                        } else {
                            Text("Confirm and Save")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                    }
                    .background(Color.black)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(isSaving)
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
                    .disabled(isAnalyzing)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    private func analyze() async {
        guard let image = selectedImage,
              let jpeg = image.jpegData(compressionQuality: 0.7) else { return }
        isAnalyzing = true
        errorMessage = nil
        selectedImageData = jpeg
        do {
            result = try await APIService.shared.analyzeMeal(imageData: jpeg, mimeType: "image/jpeg")
        } catch {
            errorMessage = error.localizedDescription
        }
        isAnalyzing = false
    }

    private func save() async {
        guard let draft = result else { return }
        isSaving = true
        errorMessage = nil
        do {
            var uploadedUrl: String? = nil
            if let data = selectedImageData {
                do {
                    uploadedUrl = try await APIService.shared.uploadMealImage(data)
                } catch {
                    print("Image upload failed: \(error)")
                    // Continue saving meal without image
                }
            }
            let saved = try await APIService.shared.createMeal(from: draft, imageUrl: uploadedUrl)
            mealStore.addMeal(saved)
            authVM.markFirstMealLogged()
            await onConfirm?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview("Empty State") {
    AddMealView()
        .environmentObject(MealStore())
        .environmentObject(AuthViewModel())
}
