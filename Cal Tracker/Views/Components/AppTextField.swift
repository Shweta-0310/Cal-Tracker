import SwiftUI

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .autocapitalization(.words)
            .disableAutocorrection(true)
            .multilineTextAlignment(.center)
    }
}
