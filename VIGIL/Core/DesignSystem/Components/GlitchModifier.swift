import SwiftUI

struct GlitchModifier: ViewModifier {
    let active: Bool
    @State private var jitter: CGFloat = 0

    func body(content: Content) -> some View {
        ZStack {
            content
                .offset(x: active ? jitter : 0)
            content
                .foregroundStyle(Color.red.opacity(active ? 0.35 : 0))
                .offset(x: active ? -1.5 : 0, y: active ? -0.5 : 0)
            content
                .foregroundStyle(Color.blue.opacity(active ? 0.35 : 0))
                .offset(x: active ? 1.5 : 0, y: active ? 0.5 : 0)
        }
        .onAppear {
            guard active else { return }
            withAnimation(.linear(duration: 0.06).repeatCount(3, autoreverses: true)) {
                jitter = 2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                jitter = 0
            }
        }
    }
}

extension View {
    func vigilGlitch(active: Bool) -> some View {
        modifier(GlitchModifier(active: active))
    }
}
