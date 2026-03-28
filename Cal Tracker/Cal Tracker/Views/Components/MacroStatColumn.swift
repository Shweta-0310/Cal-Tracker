import SwiftUI

struct MacroStatColumn: View {
    let label: String
    let value: Double
    let color: Color
    var unit: String = ""
    var labelFont: Font = .custom("DMSans-Regular", size: 14)
    var valueFont: Font = .custom("DMSans-Regular", size: 18)

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(labelFont)
                    .foregroundStyle(Color(hex: "#777777"))
                    .tracking(-0.56)
            }
            Text(value > 0 ? "\(Int(value))\(unit.isEmpty ? "" : " \(unit)")" : "--")
                .font(valueFont)
                .foregroundStyle(Color(hex: "#161616"))
                .tracking(-0.72)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
