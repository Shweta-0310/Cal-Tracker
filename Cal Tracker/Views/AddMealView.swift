import SwiftUI
import PhotosUI

struct AddMealView: View {
    var onConfirm: (() async -> Void)? = nil

    @Environment(\.dismiss) var dismiss
    @AppStorage("hasLoggedFirstMeal") private var hasLoggedFirstMeal = false

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var result: Meal?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable().scaledToFit().frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(Image(systemName: "photo").font(.largeTitle))
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
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.mealName ?? "Meal").font(.headline)
                    HStack { Text("Calories"); Spacer(); Text("\(Int(result.calories)) kcal") }
                    HStack { Text("Protein");  Spacer(); Text("\(Int(result.protein))g") }
                    HStack { Text("Carbs");    Spacer(); Text("\(Int(result.carbs))g") }
                    HStack { Text("Fats");     Spacer(); Text("\(Int(result.fats))g") }
                    HStack { Text("Others");   Spacer(); Text("\(Int(result.others))g") }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button("Confirm & Save") {
                    hasLoggedFirstMeal = true
                    Task {
                        await onConfirm?()
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.caption)
            }

            if selectedImage != nil && result == nil {
                Button {
                    Task { await analyze() }
                } label: {
                    if isAnalyzing { ProgressView() }
                    else { Text("Analyze Meal").frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAnalyzing)
            }
        }
        .padding()
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
}

#Preview("With Result") {
    let view = AddMealView()
    return view
}
