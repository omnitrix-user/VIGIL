//
//  QuestBoardView.swift
//  VIGIL
//

import SwiftData
import SwiftUI

struct QuestBoardView: View {
    @Query(sort: \Quest.assignedAt, order: .reverse) private var quests: [Quest]
    @State private var viewModel = QuestBoardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: Spacing.md.rawValue) {
                    column(
                        title: "ACTIVE",
                        quests: viewModel.activeQuests,
                        emptyText: "No quests assigned. The system is watching. Perform and they will come.",
                        reduceOpacity: false
                    )
                    column(
                        title: "COMPLETED",
                        quests: viewModel.completedQuests,
                        emptyText: "No completed quests logged.",
                        reduceOpacity: false
                    )
                    column(
                        title: "FAILED",
                        quests: viewModel.failedQuests,
                        emptyText: "The system has not needed to punish you. Yet.",
                        reduceOpacity: true
                    )
                }
                .padding(.horizontal, Spacing.md.rawValue)
                .padding(.vertical, Spacing.lg.rawValue)
            }
            .background(Color.bg.primary.ignoresSafeArea())
            .navigationTitle("QUEST BOARD")
        }
        .onAppear {
            viewModel.refresh(quests: quests)
        }
        .onChange(of: quests.count) {
            viewModel.refresh(quests: quests)
        }
    }

    private func column(title: String, quests: [Quest], emptyText: String, reduceOpacity: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Text("\(title) (\(quests.count))")
                .font(Font.vigil.headline)
                .foregroundStyle(Color.text.primary)
                .padding(.horizontal, Spacing.xs.rawValue)

            if quests.isEmpty {
                Text(emptyText)
                    .font(Font.vigil.body)
                    .foregroundStyle(Color.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 280, alignment: .leading)
                    .padding(Spacing.md.rawValue)
                    .background(Color.bg.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                LazyVStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
                    ForEach(quests, id: \.id) { quest in
                        NavigationLink {
                            QuestDetailView(quest: quest, viewModel: viewModel)
                                .navigationBarBackButtonHidden(false)
                        } label: {
                            QuestCardView(quest: quest)
                                .opacity(reduceOpacity ? 0.5 : 1)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 280)
                    }
                }
            }
        }
        .frame(width: 300, alignment: .topLeading)
    }
}
