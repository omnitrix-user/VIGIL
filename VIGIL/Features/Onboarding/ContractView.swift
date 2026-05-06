//
//  ContractView.swift
//  VIGIL
//

import CryptoKit
import PencilKit
import SwiftUI

struct ContractView: View {
    let goalsText: [String]
    let onSigned: (String) -> Void

    @State private var drawing = PKDrawing()
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

            SignatureCanvas(drawing: $drawing)
                .frame(height: 160)
                .background(Color.bg.secondary)
                .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))

            Button(action: sign) {
                Text("SIGN")
                    .font(Font.vigil.headline)
                    .foregroundStyle(Color.bg.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md.rawValue)
                    .background(drawing.bounds.isEmpty ? Color.bg.tertiary : Color.accent.primary)
                    .overlay(Rectangle().stroke(Color.accent.primary, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(drawing.bounds.isEmpty)
        }
        .padding(Spacing.md.rawValue)
        .background(Color.bg.primary.ignoresSafeArea())
        .scaleEffect(animateOut ? 1.08 : 1)
        .opacity(animateOut ? 0 : 1)
        .animation(.easeOut(duration: 0.25), value: animateOut)
    }

    private var contractBody: String {
        """
YOU HAVE COMMITTED TO \(goalsText.joined(separator: ", ")).
THE SYSTEM WILL HOLD YOU TO THIS.
YOU ACCEPT CONSEQUENCE FOR COMPLIANCE FAILURE.
THE SYSTEM DOES NOT NEGOTIATE.
"""
    }

    private func sign() {
        let digest = SHA256.hash(data: drawing.dataRepresentation())
        let hash = digest.map { String(format: "%02x", $0) }.joined()
        animateOut = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onSigned(hash)
        }
    }
}

private struct SignatureCanvas: View {
    @Binding var drawing: PKDrawing

    var body: some View {
        SignatureCanvasRepresentable(drawing: $drawing)
    }
}

private struct SignatureCanvasRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.drawingPolicy = .anyInput
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: SignatureCanvasRepresentable
        init(parent: SignatureCanvasRepresentable) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}
