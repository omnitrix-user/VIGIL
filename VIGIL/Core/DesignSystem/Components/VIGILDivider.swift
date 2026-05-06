import SwiftUI

struct VIGILDivider: View {
    let title: String

    var body: some View {
        Text("─────[ \(title.uppercased()) ]─────")
            .font(.vigil.caption)
            .foregroundStyle(Color.text.muted)
            .frame(maxWidth: .infinity)
    }
}
