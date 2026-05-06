//
//  ProfileView.swift
//  VIGIL
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            Color.bg.primary
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
                Text("PROFILE")
                    .font(Font.vigil.titleLarge)
                    .foregroundStyle(Color.accent.primary)

                Text("Player records and system outputs are archived here.")
                    .font(Font.vigil.body)
                    .foregroundStyle(Color.text.secondary)

                Text("System online.")
                    .font(Font.vigil.system)
                    .foregroundStyle(Color.text.primary)

                Spacer()
            }
            .padding(Spacing.md.rawValue)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
