import SwiftUI
import PhotosUI

struct UploadMealSheetView: View {
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
    @State private var showPhotoPicker = false

    private let goals = GoalsStore.load()

    var body: some View {
        VStack(spacing: 8) {
            topImageSection
            bottomSection
        }
        .background(Color(hex: "#f7f1e8"))
        .presentationDetents([.fraction(0.8)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    selectedImage = UIImage(data: data)
                    result = nil
                    errorMessage = nil
                }
            }
        }
    }

    // MARK: - Top image section

    @ViewBuilder private var topImageSection: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                Color(hex: "#fffcf5")
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(Color(hex: "#161616"))
                        Text("Upload image from your Gallery")
                            .font(.custom("DMSans-Regular", size: 14))
                            .tracking(-0.56)
                            .foregroundStyle(Color(hex: "#777777"))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 336)
            .clipped()
        }
    }

    // MARK: - Bottom section

    @ViewBuilder private var bottomSection: some View {
        VStack(spacing: 0) {
            if let result {
                // Nutrition detail content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(result.mealName ?? "Meal")
                            .font(.custom("DMSans-SemiBold", size: 20))
                            .tracking(-0.4)
                            .foregroundStyle(.black)
                            .lineSpacing(5)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 16) {
                            NutritionRow(
                                label: "Calories",
                                value: "\(Int(result.calories)) kcal",
                                color: MacroColor.calories
                            )
                            NutritionRow(
                                label: "Protein",
                                value: "\(Int(result.protein)) g",
                                color: MacroColor.protein
                            )
                            NutritionRow(
                                label: "Fats",
                                value: "\(Int(result.fats)) g",
                                color: MacroColor.fats
                            )
                            NutritionRow(
                                label: "Carbohydrates",
                                value: "\(Int(result.carbs)) g",
                                color: MacroColor.carbs
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("DMSans-Regular", size: 13))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }

                // Two-button row
                HStack(spacing: 8) {
                    Button {
                        self.result = nil
                        self.selectedImage = nil
                        self.selectedImageData = nil
                        self.errorMessage = nil
                        showPhotoPicker = true
                    } label: {
                        Text("Re-Upload")
                            .font(.system(size: 16))
                            .tracking(-0.64)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .foregroundStyle(Color(hex: "#161616"))
                    }
                    .background(Color(hex: "#f7f1e8"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#161616"), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        Task { await save() }
                    } label: {
                        Group {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Confirm")
                                    .font(.system(size: 16))
                                    .tracking(-0.64)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .foregroundStyle(.white)
                    .background(Color(hex: "#161616"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(isSaving)
                }
                .padding(8)
                .background(Color(hex: "#f7f1e8"))
                .overlay(alignment: .top) {
                    Color(hex: "#efdcc1").frame(height: 1)
                }

            } else {
                // Empty / pre-analysis state
                Group {
                    Image("bowl-illustration")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 82, height: 69)
                        .opacity(0.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("DMSans-Regular", size: 13))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }

                Button {
                    Task { await analyze() }
                } label: {
                    Group {
                        if isAnalyzing {
                            ProgressView().tint(Color(hex: "#bababa"))
                        } else {
                            Text("Analyze Meal")
                                .font(.custom("DMSans-Regular", size: 16))
                                .tracking(-0.64)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                }
                .foregroundStyle(selectedImage != nil ? .white : Color(hex: "#bababa"))
                .background(selectedImage != nil ? Color(hex: "#161616") : Color(hex: "#777777"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(selectedImage == nil || isAnalyzing)
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#f7f1e8"))
    }

    // MARK: - Logic

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
                do { uploadedUrl = try await APIService.shared.uploadMealImage(data) }
                catch { print("Image upload failed: \(error)") }
            }
            let saved = try await APIService.shared.createMeal(from: draft, imageUrl: uploadedUrl)
            mealStore.addMeal(saved, image: selectedImage)
            authVM.markFirstMealLogged()
            await onConfirm?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - NutritionRow

private struct NutritionRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 10, height: 10)
            Text("\(label): ")
                .font(.system(size: 16))
                .tracking(-0.64)
                .foregroundStyle(Color(hex: "#777777"))
            + Text(value)
                .font(.system(size: 16, weight: .medium))
                .tracking(-0.64)
                .foregroundStyle(Color(hex: "#161616"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Empty State") {
    Color(hex: "#f7f1e8").sheet(isPresented: .constant(true)) {
        UploadMealSheetView()
            .environmentObject(MealStore())
            .environmentObject(AuthViewModel())
    }
}

#Preview("After Analysis") {
    // Shows the post-upload result state with mock meal data
    _UploadMealSheetPreview()
}

private struct _UploadMealSheetPreview: View {
    @State private var selectedImage: UIImage? = UIImage(systemName: "fork.knife")
    @State private var result: Meal? = Meal(
        id: UUID(),
        userId: nil,
        imageUrl: nil,
        mealName: "Roasted Chicken Dinner with Roasted Potatoes, Sweet Potatoes, Broccoli, and Green Peas",
        calories: 1140,
        protein: 89,
        carbs: 105,
        fats: 46,
        fiber: 8,
        sugar: 12,
        loggedAt: Date(),
        createdAt: nil
    )

    var body: some View {
        Color(hex: "#f7f1e8").sheet(isPresented: .constant(true)) {
            VStack(spacing: 8) {
                // Mock image section
                ZStack {
                    Color(hex: "#fffcf5")
                    Image(systemName: "fork.knife.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                        .foregroundStyle(Color(hex: "#fdccaf"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 336)

                // Reuse the bottom section via a real sheet view seeded with result
                _NutritionBottomSheet(result: result)
            }
            .background(Color(hex: "#f7f1e8"))
            .presentationDetents([.fraction(0.8)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(32)
        }
    }
}

private struct _NutritionBottomSheet: View {
    let result: Meal?

    var body: some View {
        VStack(spacing: 0) {
            if let result {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(result.mealName ?? "Meal")
                            .font(.custom("DMSans-SemiBold", size: 20))
                            .tracking(-0.4)
                            .foregroundStyle(.black)
                            .lineSpacing(5)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 16) {
                            NutritionRow(label: "Calories",      value: "\(Int(result.calories)) kcal", color: MacroColor.calories)
                            NutritionRow(label: "Protein",       value: "\(Int(result.protein)) g",     color: MacroColor.protein)
                            NutritionRow(label: "Fats",          value: "\(Int(result.fats)) g",        color: MacroColor.fats)
                            NutritionRow(label: "Carbohydrates", value: "\(Int(result.carbs)) g",       color: MacroColor.carbs)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }

                HStack(spacing: 8) {
                    Text("Re-Upload")
                        .font(.system(size: 16))
                        .tracking(-0.64)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundStyle(Color(hex: "#161616"))
                        .background(Color(hex: "#f7f1e8"))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#161616"), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Confirm")
                        .font(.system(size: 16))
                        .tracking(-0.64)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundStyle(.white)
                        .background(Color(hex: "#161616"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(8)
                .background(Color(hex: "#f7f1e8"))
                .overlay(alignment: .top) {
                    Color(hex: "#efdcc1").frame(height: 1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#f7f1e8"))
    }
}
