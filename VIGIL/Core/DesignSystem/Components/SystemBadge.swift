import SwiftUI

struct SystemBadge: View {
    let text: String
    var color: Color = .accent.primary

    var body: some View {
        Text("[\(text.uppercased())]")
            .font(.vigil.caption)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.sm.rawValue)
            .padding(.vertical, Spacing.xs.rawValue)
            .background(Color.bg.secondary)
            .overlay(
                Rectangle().stroke(color, lineWidth: 1)
            )
    }
}
