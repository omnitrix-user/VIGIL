import SwiftUI

struct VIGILButton: View {
    let title: String
    var fill: Color = .accent.primary
    var foreground: Color = .bg.primary
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            BracketedText(value: title, color: foreground, font: .vigil.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md.rawValue)
                .background(isDisabled ? Color.bg.tertiary : fill)
                .overlay(
                    Rectangle()
                        .stroke(Color.accent.primary, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
