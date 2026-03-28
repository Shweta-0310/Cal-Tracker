import SwiftUI

struct MacroProgressRow: View {
    let label: String
    let value: Double
    let goal: Double
    let color: Color

    private let segments = 20

    var body: some View {
        let progress = min(value / max(goal, 1), 1.0)
        let filled = Int(progress * Double(segments))

        HStack(spacing: 8) {
            Text(label).frame(width: 70, alignment: .leading).font(.system(size: 16))

            HStack(spacing: 3) {
                ForEach(0..<segments, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: 8, height: 16)
                        .foregroundStyle(i < filled ? color : color.opacity(0.15))
                }
            }

            Text("\(Int(progress * 100))%")
                .font(.system(size: 14)).frame(width: 36, alignment: .trailing)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MacroProgressRow(label: "Calories", value: 1400, goal: 2000, color: .orange)
        MacroProgressRow(label: "Protein",  value: 80,   goal: 150,  color: .blue)
        MacroProgressRow(label: "Fats",     value: 45,   goal: 65,   color: .pink)
        MacroProgressRow(label: "Carbs",    value: 160,  goal: 250,  color: Color(hex: "#FFBF69"))
        MacroProgressRow(label: "Others",   value: 20,   goal: 40,   color: .purple)
    }
    .padding()
}
