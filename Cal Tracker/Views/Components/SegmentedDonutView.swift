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
    let goals: NutritionTotals
    let mealCount: Int

    // Each macro's % of goal (0–1) — must use the SAME goal divisor as MacroProgressRow in DashboardView
    private var weights: [Double] {
        [
            min(totals.calories / max(goals.calories, 1), 1.0),
            min(totals.protein  / max(goals.protein,  1), 1.0),
            min(totals.fats     / max(goals.fats,     1), 1.0),
            min(totals.carbs    / max(goals.carbs,    1), 1.0),
            min(totals.others   / max(goals.fiber,    1), 1.0)   // matches DashboardView Others goal
        ]
    }

    private var colors: [Color] {
        [MacroColor.calories, MacroColor.protein, MacroColor.fats, MacroColor.carbs, MacroColor.others]
    }

    // Precompute (startAngle, endAngle) for each segment outside the view builder
    // so SwiftUI doesn't have to rely on the mutable-state trick inside ForEach.
    private var segmentArcs: [(start: Double, end: Double)] {
        let gap = 5.4           // degrees of gap between segments
        let totalGap = gap * Double(colors.count)
        let available = 360.0 - totalGap
        let weightSum = weights.reduce(0, +)

        var arcs: [(Double, Double)] = []
        var cursor = -90.0
        for w in weights {
            let fraction = weightSum > 0 ? w / weightSum : 1.0 / Double(colors.count)
            let sweep = fraction * available
            arcs.append((cursor, cursor + sweep))
            cursor += sweep + gap
        }
        return arcs
    }

    var body: some View {
        ZStack {
            let arcs = segmentArcs

            ForEach(0..<colors.count, id: \.self) { i in
                Arc(startAngle: arcs[i].start, endAngle: arcs[i].end)
                    .stroke(colors[i], lineWidth: 24)
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
        totals: NutritionTotals(calories: 560, protein: 32, carbs: 63, fats: 33, fiber: 10, sugar: 15),
        goals:  NutritionTotals(calories: 2000, protein: 150, carbs: 250, fats: 65, fiber: 25, sugar: 50),
        mealCount: 1
    )
    .frame(width: 220, height: 220)
    .padding()
}
