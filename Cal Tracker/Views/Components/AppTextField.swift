import SwiftUI

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .autocapitalization(.words)
        .disableAutocorrection(true)
        .multilineTextAlignment(.center)
    }
}
