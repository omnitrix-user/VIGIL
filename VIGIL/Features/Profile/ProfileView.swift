//
//  ProfileView.swift
//  VIGIL
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(sort: \Player.createdAt) private var players: [Player]
    @State private var showTour = false

    var body: some View {
        ZStack {
            Color.bg.primary
                .ignoresSafeArea()

            if let player = players.first {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
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
                        HStack {
                            Circle().fill(Color.bg.secondary).frame(width: 92, height: 92).overlay(Image(systemName: "person.fill").foregroundStyle(Color.accent.primary))
                            VStack(alignment: .leading) {
                                Text(player.username.asSystemID).font(.vigil.headline).foregroundStyle(Color.text.primary)
                                Text("RANK: \(player.currentRank.rawValue)").font(.vigil.system).foregroundStyle(Color.text.secondary)
                                Rectangle().fill(Color.bg.tertiary).frame(height: 2).overlay(alignment: .leading) { Rectangle().fill(Color.accent.primary).frame(width: 120, height: 2) }
                            }
                        }
                        Text("SYSTEM MESSAGES").font(.vigil.system).foregroundStyle(Color.accent.secondary)
                        ForEach(player.verdicts.prefix(5), id: \.id) { verdict in
                            Text(verdict.message.uppercased()).font(.vigil.caption).foregroundStyle(Color.text.secondary).padding().background(Color.bg.secondary).overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1)).overlay(ScanlineOverlay())
                        }
                    }
                    .padding(Spacing.md.rawValue)
                }
            }
        }
        .tour(
            id: .profile,
            content: TourContentRegistry.content(for: .profile),
            forceShow: $showTour,
            autoShow: true
        )
    }
}
