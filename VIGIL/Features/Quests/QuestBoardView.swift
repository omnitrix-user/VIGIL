//
//  QuestBoardView.swift
//  VIGIL
//

import SwiftData
import SwiftUI

struct QuestBoardView: View {
    @Query(sort: \Quest.assignedAt, order: .reverse) private var quests: [Quest]
    @State private var viewModel = QuestBoardViewModel()
    @State private var showCompleted = false
    @State private var showFailed = false
    @State private var showTour = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
                    HStack {
                        Spacer()
                        Button { showTour = true } label: {
                            Text("[?]")
                                .font(.vigil.system)
                                .foregroundStyle(Color.accent.primary)
                                .padding(Spacing.sm.rawValue)
                                .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    Text("QUEST BOARD")
                        .font(Font.vigil.titleLarge)
                        .foregroundStyle(Color.accent.primary)
                        .padding(.top, Spacing.sm.rawValue)

                    sectionHeader("ACTIVE", count: viewModel.activeQuests.count, collapsible: false, expanded: true)
                    questList(
                        quests: viewModel.activeQuests,
                        emptyText: "No quests assigned. The system is watching. Perform and they will come.",
                        reduceOpacity: false
                    )

                    sectionHeader("COMPLETED", count: viewModel.completedQuests.count, collapsible: true, expanded: showCompleted)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) { showCompleted.toggle() }
                        }
                    if showCompleted {
                        questList(
                            quests: viewModel.completedQuests,
                            emptyText: "No completed quests logged.",
                            reduceOpacity: false
                        )
                    }

                    sectionHeader("FAILED", count: viewModel.failedQuests.count, collapsible: true, expanded: showFailed)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) { showFailed.toggle() }
                        }
                    if showFailed {
                        questList(
                            quests: viewModel.failedQuests,
                            emptyText: "The system has not needed to punish you. Yet.",
                            reduceOpacity: true
                        )
                    }
                }
                .padding(.horizontal, Spacing.md.rawValue)
                .padding(.vertical, Spacing.lg.rawValue)
            }
            .background(Color.bg.primary.ignoresSafeArea())
        }
        .onAppear {
            viewModel.refresh(quests: quests)
        }
        .onChange(of: quests.count) {
            viewModel.refresh(quests: quests)
        }
        .tour(
            id: .questBoard,
            content: TourContentRegistry.content(for: .questBoard),
            forceShow: $showTour,
            autoShow: true
        )
    }

    private func sectionHeader(_ title: String, count: Int, collapsible: Bool, expanded: Bool) -> some View {
        HStack {
            Text("\(title) (\(count))")
                .font(Font.vigil.headline)
                .foregroundStyle(Color.accent.primary)
            Spacer()
            if collapsible {
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.text.secondary)
            }
        }
        .padding(.horizontal, Spacing.xs.rawValue)
    }

    private func questList(quests: [Quest], emptyText: String, reduceOpacity: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            if quests.isEmpty {
                Text(emptyText)
                    .font(Font.vigil.body)
                    .foregroundStyle(Color.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md.rawValue)
                    .background(Color.bg.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                ForEach(quests, id: \.id) { quest in
                    NavigationLink {
                        QuestDetailView(quest: quest, viewModel: viewModel)
                            .navigationBarBackButtonHidden(false)
                    } label: {
                        QuestCardView(quest: quest)
                            .opacity(reduceOpacity ? 0.5 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
