import SwiftUI

struct BracketedText: View {
    let value: String
    var color: Color = .text.primary
    var font: Font = .vigil.system

    var body: some View {
        Text("[\(value.uppercased())]")
            .font(font)
            .foregroundStyle(color)
            .fixedSize()
    }
}
