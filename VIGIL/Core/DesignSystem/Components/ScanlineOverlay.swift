import SwiftUI

struct ScanlineOverlay: View {
    var lineHeight: CGFloat = 2
    var spacing: CGFloat = 4

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: spacing) {
                ForEach(0..<Int(proxy.size.height / (lineHeight + spacing) + 1), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.scanline.color)
                        .frame(height: lineHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .allowsHitTesting(false)
    }
}
