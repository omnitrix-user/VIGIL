import SwiftData
import SwiftUI
import UIKit

private struct TourModifier: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @Query private var tourStates: [TourState]

    let id: TourID
    let content: TourContent
    let autoShow: Bool
    @Binding var forceShow: Bool
    @State private var isShowing = false

    func body(content base: Content) -> some View {
        base
            .onAppear {
                if autoShow && !state().hasSeen(id) {
                    isShowing = true
                }
            }
            .onChange(of: forceShow) { _, new in
                if new {
                    isShowing = true
                    forceShow = false
                }
            }
            .overlay {
                if isShowing {
                    TourOverlayView(
                        content: content,
                        onSkip: { dismiss(markSeen: true) },
                        onAcknowledge: { dismiss(markSeen: true) }
                    )
                }
            }
    }

    private func dismiss(markSeen: Bool) {
        if markSeen {
            let row = state()
            row.markSeen(id)
            if tourStates.isEmpty { modelContext.insert(row) }
            try? modelContext.save()
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isShowing = false
    }

    private func state() -> TourState {
        tourStates.first ?? TourState()
    }
}

extension View {
    func tour(
        id: TourID,
        content: TourContent,
        forceShow: Binding<Bool>,
        autoShow: Bool = true
    ) -> some View {
        modifier(TourModifier(id: id, content: content, autoShow: autoShow, forceShow: forceShow))
    }
}
