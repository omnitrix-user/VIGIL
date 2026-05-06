import SwiftUI

struct ActivityReviewView: View {
    let event: ActivityEvent
    let aiReasoning: String
    let onSelect: (ActivityCategory) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
                Text("[CATEGORIZE]")
                    .font(.vigil.titleLarge)
                    .foregroundStyle(Color.accent.primary)
                Text(event.name.uppercased())
                    .font(.vigil.headline)
                    .foregroundStyle(Color.text.primary)
                Text(aiReasoning.uppercased())
                    .font(.vigil.system)
                    .foregroundStyle(Color.text.secondary)
                    .padding()
                    .background(Color.bg.secondary)
                    .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
                    .overlay(ScanlineOverlay())

                ScrollView {
                    ForEach(ActivityCategory.allCases, id: \.rawValue) { category in
                        VIGILButton(title: category.rawValue.uppercased()) {
                            onSelect(category)
                        }
                    }
                }
            }
            .padding()
            .background(Color.bg.primary.ignoresSafeArea())
        }
    }
}
