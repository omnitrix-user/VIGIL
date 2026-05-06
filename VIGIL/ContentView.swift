//
//  ContentView.swift
//  VIGIL
//
//  Created by Qualtech on 06/05/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.bg.primary
                .ignoresSafeArea()

            Text("VIGIL")
                .font(Font.vigil.titleLarge)
                .foregroundStyle(Color.accent.primary)
        }
    }
}

#Preview {
    ContentView()
}
