//
//  ImportView.swift
//  LookUp
//
//  Created by Wangzhen Wu on 17/03/2025.
//

import SwiftUI
import SwiftData

struct ImportView: View {
    @Environment(\.modelContext) private var context
    @State private var showingDocumentPicker = false
    
    var body: some View {
        VStack {
            Button {
                showingDocumentPicker = true
            } label: {
                VStack {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 60))
                    Text("Import Local Files")
                        .font(.title2)
                }
                .padding()
            }
            
            Text("Supported Formats: txt, epub")
                .foregroundColor(.gray)
                .padding()
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { url in
                importBook(from: url)
            }
        }
    }
    
    private func importBook(from url: URL) {
        do {
            let fileContent = try String(contentsOf: url, encoding: .utf8)
            let newBook = Book(
                title: url.lastPathComponent,
                author: "Unknown",
                content: fileContent
            )
            context.insert(newBook)
            try context.save()
        } catch {
            print("Error reading file: \(error)")
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.text, .epub])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onPick(url)
        }
    }
}
