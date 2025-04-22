import SwiftUI

struct CustomButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 19)
            .frame(maxWidth: .infinity)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(.white)
            .background(.main)
            .cornerRadius(24)
    }
}

extension View {
    func buttonModifier() -> some View {
        self.modifier(CustomButtonModifier())
    }
}
