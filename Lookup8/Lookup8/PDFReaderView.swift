//
//  PDFReaderView.swift
//  Lookup8
//
//  Created by Wangzhen Wu on 22/04/2025.
//

import SwiftUI
import PDFKit

struct PDFReaderView: View {
    let filePath: String

    var body: some View {
        if let doc = PDFDocument(url: URL(fileURLWithPath: filePath)) {
            PDFKitRepresentedView(document: doc)
        } else {
            Text("Failed to load PDF.")
        }
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // No updates needed
    }
}

