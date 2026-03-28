import Foundation
import Combine
import UIKit

class MealStore: ObservableObject {
    @Published var meals: [Meal] = []
    @Published var mealImages: [UUID: UIImage] = [:]

    private static var imagesDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MealImages", isDirectory: true)
    }

    init() {
        loadImagesFromDisk()
    }

    func addMeal(_ meal: Meal, image: UIImage? = nil) {
        meals.insert(meal, at: 0)
        if let image {
            mealImages[meal.id] = image
            saveImageToDisk(image, for: meal.id)
        }
    }

    func removeImage(for id: UUID) {
        mealImages.removeValue(forKey: id)
        let file = Self.imagesDirectory.appendingPathComponent(id.uuidString + ".jpg")
        try? FileManager.default.removeItem(at: file)
    }

    var totals: NutritionTotals {
        NutritionTotals(
            calories: meals.reduce(0) { $0 + $1.calories },
            protein:  meals.reduce(0) { $0 + $1.protein },
            carbs:    meals.reduce(0) { $0 + $1.carbs },
            fats:     meals.reduce(0) { $0 + $1.fats },
            fiber:    meals.reduce(0) { $0 + $1.fiber },
            sugar:    meals.reduce(0) { $0 + $1.sugar }
        )
    }

    // MARK: - Disk persistence

    private func saveImageToDisk(_ image: UIImage, for id: UUID) {
        let dir = Self.imagesDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent(id.uuidString + ".jpg")
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: file)
        }
    }

    private func loadImagesFromDisk() {
        let dir = Self.imagesDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil
        ) else { return }
        for file in files where file.pathExtension == "jpg" {
            let name = file.deletingPathExtension().lastPathComponent
            guard let id = UUID(uuidString: name),
                  let data = try? Data(contentsOf: file),
                  let image = UIImage(data: data) else { continue }
            mealImages[id] = image
        }
    }
}
