import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isLoading || isDisabled ? 0.7 : 1.0)
        .allowsHitTesting(!(isLoading || isDisabled))
    }
}
