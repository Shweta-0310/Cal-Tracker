import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
            } else {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
            }
        }
        .tint(.black)
        .buttonStyle(.borderedProminent)
        .opacity(isLoading || isDisabled ? 0.7 : 1.0)
        .allowsHitTesting(!(isLoading || isDisabled))
    }
}
