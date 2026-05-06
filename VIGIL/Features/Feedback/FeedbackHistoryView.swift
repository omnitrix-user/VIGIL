import SwiftData
import SwiftUI

struct FeedbackHistoryView: View {
    @Query(sort: \FeedbackEntry.createdAt, order: .reverse) private var entries: [FeedbackEntry]

    var body: some View {
        List(entries, id: \.id) { entry in
            NavigationLink {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
                        Text("[\(entry.kind.rawValue.uppercased())]")
                            .font(.vigil.headline)
                            .foregroundStyle(Color.accent.primary)
                        if let title = entry.title, !title.isEmpty {
                            Text(title.uppercased()).font(.vigil.system).foregroundStyle(Color.text.secondary)
                        }
                        Text(entry.body).font(.vigil.body).foregroundStyle(Color.text.primary)
                    }
                    .padding()
                }
                .background(Color.bg.primary.ignoresSafeArea())
            } label: {
                HStack {
                    Text(entry.kind.rawValue.uppercased()).font(.vigil.caption)
                    Spacer()
                    SystemBadge(text: entry.submitted ? "SUBMITTED" : "UNSUBMITTED", color: entry.submitted ? .status.success : .status.warning)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.bg.primary)
    }
}
