import SwiftUI

// Shared macro color palette
enum MacroColor {
    static let calories = Color(hex: "#fdccaf")
    static let protein  = Color(hex: "#ffb1ec")
    static let fats     = Color(hex: "#beefff")
    static let carbs    = Color(hex: "#bfbeff")
    static let others   = Color(hex: "#d4d4d4")
}

struct SegmentedDonutView: View {
    let totals: NutritionTotals
    let mealCount: Int

    @State private var animationProgress: CGFloat = 0

    // Each macro's share of the total nutrient sum (proportion of actual values)
    private var weights: [Double] {
        let values: [Double] = [
            totals.calories,
            totals.protein,
            totals.fats,
            totals.carbs
        ]
        let sum = values.reduce(0, +)
        guard sum > 0 else { return Array(repeating: 0.25, count: values.count) }
        return values.map { $0 / sum }
    }

    private var colors: [Color] {
        [MacroColor.calories, MacroColor.protein, MacroColor.fats, MacroColor.carbs]
    }

    // Precompute (startAngle, endAngle) for each segment outside the view builder
    // so SwiftUI doesn't have to rely on the mutable-state trick inside ForEach.
    private var segmentArcs: [(start: Double, end: Double)] {
        let gap = 10.0          // degrees of gap between segments
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
            if mealCount == 0 {
                Circle()
                    .stroke(Color(red: 0.9, green: 0.89, blue: 0.88), lineWidth: 10)
            } else {
                let arcs = segmentArcs
                ZStack {
                    ForEach(0..<colors.count, id: \.self) { i in
                        Arc(startAngle: arcs[i].start, endAngle: arcs[i].end)
                            .stroke(colors[i], style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    }
                }
                .mask(
                    Circle()
                        .trim(from: 0, to: animationProgress)
                        .stroke(style: StrokeStyle(lineWidth: 14, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                )
            }

            VStack(spacing: 0) {
                Text("\(mealCount)")
                    .font(.custom("DMSans-Regular", size: 32))
                    .foregroundStyle(Color(hex: "#161616"))
                Text("Total Meal")
                    .font(.custom("DMSans-Regular", size: 16))
                    .foregroundStyle(Color(hex: "#161616"))
                    .tracking(-0.32)
            }
        }
        .onAppear { triggerAnimation() }
        .onChange(of: mealCount) { _, _ in triggerAnimation() }
    }

    private func triggerAnimation() {
        animationProgress = 0
        withAnimation(.easeInOut(duration: 0.9)) {
            animationProgress = 1
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
        mealCount: 1
    )
    .frame(width: 220, height: 220)
    .padding()
}
