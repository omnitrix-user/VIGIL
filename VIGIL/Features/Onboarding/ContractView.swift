//
//  ContractView.swift
//  VIGIL
//

import CryptoKit
import SwiftUI

struct ContractView: View {
    let onSigned: (String) -> Void

    @State private var points: [CGPoint] = []
    @State private var animateOut = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            Text("THE VIGIL CONTRACT")
                .font(Font.vigil.titleLarge)
                .foregroundStyle(Color.accent.primary)

            ScrollView {
                Text(contractBody)
                    .font(Font.vigil.body)
                    .foregroundStyle(Color.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SignatureCanvas(points: $points)
                .frame(height: 160)
                .background(Color.bg.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button(action: sign) {
                Text("SIGN")
                    .font(Font.vigil.headline)
                    .foregroundStyle(Color.bg.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md.rawValue)
                    .background(points.isEmpty ? Color.bg.tertiary : Color.accent.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(points.isEmpty)
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bg.primary.ignoresSafeArea())
        .scaleEffect(animateOut ? 1.08 : 1)
        .opacity(animateOut ? 0 : 1)
        .animation(.easeOut(duration: 0.25), value: animateOut)
    }

    private var contractBody: String {
        """
You accept consequence for compliance failure.
You accept permanent record of violations.
You will not manipulate or falsify system logs.
You accept that the system does not negotiate.
No mercy protocol remains active at all times.
The system never sleeps.
"""
    }

    private func sign() {
        let serial = points.map { "\($0.x),\($0.y)" }.joined(separator: "|")
        let digest = SHA256.hash(data: Data(serial.utf8))
        let hash = digest.map { String(format: "%02x", $0) }.joined()
        animateOut = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onSigned(hash)
        }
    }
}

private struct SignatureCanvas: View {
    @Binding var points: [CGPoint]

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Path { path in
                    guard points.count > 1 else { return }
                    path.move(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(Color.text.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        points.append(value.location)
                    }
            )
        }
    }
}
