import SwiftUI

// Shared macro color palette — used by both the donut and progress rows
enum MacroColor {
    static let calories = Color(hex: "#7B68EE")
    static let protein  = Color(hex: "#5BC8D5")
    static let fats     = Color(hex: "#F06292")
    static let carbs    = Color(hex: "#FFAA5C")
    static let others   = Color(hex: "#FFD166")
}

struct SegmentedDonutView: View {
    let totals: NutritionTotals
    let mealCount: Int

    var body: some View {
        ZStack {
            let segments: [(Double, Color)] = [
                (totals.calories, MacroColor.calories),
                (totals.protein,  MacroColor.protein),
                (totals.fats,     MacroColor.fats),
                (totals.carbs,    MacroColor.carbs),
                (totals.others,   MacroColor.others)
            ]
            let total = segments.reduce(0.0) { $0 + $1.0 }

            let gap = 0.02
            var startAngle = -90.0

            ForEach(0..<segments.count, id: \.self) { i in
                let (value, color) = segments[i]
                let fraction = total > 0 ? value / total : 0.2
                let sweep = (fraction * (1 - Double(segments.count) * gap)) * 360
                Arc(startAngle: startAngle, endAngle: startAngle + sweep)
                    .stroke(color, lineWidth: 24)
                let _ = { startAngle += sweep + gap * 360 }()
            }

            VStack(spacing: 4) {
                Text(String(format: "%02d", mealCount))
                    .font(.system(size: 40, weight: .regular))
                Text("Total Meal").font(.system(size: 14)).foregroundStyle(.secondary)
            }
        }
    }
}

struct Arc: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        return p
    }
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    SegmentedDonutView(
        totals: NutritionTotals(calories: 1800, protein: 120, carbs: 200, fats: 60, fiber: 25, sugar: 30),
        mealCount: 3
    )
    .frame(width: 200, height: 200)
    .padding()
}
