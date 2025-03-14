//
//  ContentView.swift
//  Lookup
//
//  Created by Hu, Shengliang on 07/03/2025.
//
import PDFKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Foundation

//
//  LookupApp.swift
//  Lookup
//
//  Created by Hu, Shengliang on 07/03/2025.
//

struct ContentView: View {
    var body: some View {
        TabView {
            BookshelfView()
                .tabItem {
                    Label("Bookshelf", systemImage: "books.vertical")
                }
            
            InternetSearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct BookshelfView: View {
    @ObservedObject var fileManager = LocalFileManager.shared
    @State private var showImportView = false
    
    var body: some View {
        NavigationStack {
            List(fileManager.getSavedFiles(), id: \.self) { file in
                NavigationLink(destination: FileReaderView(fileURL: file)) {
                    Text(file.lastPathComponent)
                }
            }
            .navigationTitle("Bookshelf")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showImportView = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showImportView) {
                ImportView()
            }
        }
    }
}

struct ImportView: View {
    @State private var isFilePickerPresented = false
    @Environment(\.dismiss) var dismiss
    @ObservedObject var fileManager = LocalFileManager.shared

    var body: some View {
        VStack {
            Button(action: {
                isFilePickerPresented = true
            }) {
                Label("Select Files", systemImage: "doc.fill.badge.plus")
            }
            .padding()
            .fileImporter(
                isPresented: $isFilePickerPresented,
                allowedContentTypes: [UTType.pdf, UTType.plainText, UTType.fileURL, UTType.data],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    for url in urls {
                        fileManager.saveFileToDocuments(from: url)
                    }
                case .failure(let error):
                    print("Error selecting files: \(error.localizedDescription)")
                }
            }
            
            List(fileManager.getSavedFiles(), id: \.self) { file in
                Text(file.lastPathComponent)
            }
            
            Button("Done") {
                dismiss()
            }
            .padding()
        }
        .navigationTitle("Import Files")
    }
}

class LocalFileManager: ObservableObject {
    static let shared = LocalFileManager()
    private init() {}

    private let fileManager = FileManager.default
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    // 复制文件到本地 Documents 目录
    func saveFileToDocuments(from sourceURL: URL) {
        let destinationURL = documentsDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                print("File already exists: \(destinationURL)")
            } else {
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                print("File saved: \(destinationURL)")
            }
        } catch {
            print("Error saving file: \(error.localizedDescription)")
        }
    }

    // 获取存储的所有文件
    func getSavedFiles() -> [URL] {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            print("Error fetching files: \(error.localizedDescription)")
            return []
        }
    }
}

struct InternetSearchView: View {
    var body: some View {
        Text("Internet Search Page")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings Page")
    }
}



import SwiftUI
import PDFKit

struct FileReaderView: View {
    let fileURL: URL
    
    var body: some View {
        if fileURL.pathExtension == "pdf" {
            PDFKitView(url: fileURL)
        } else if fileURL.pathExtension == "txt" {
            TextFileReader(url: fileURL)
        } else {
            Text("Unsupported file type")
        }
    }
}

// PDF 阅读器
struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// TXT 阅读器
struct TextFileReader: View {
    let url: URL
    @State private var content: String = "Loading..."
    
    var body: some View {
        ScrollView {
            Text(content)
                .padding()
        }
        .onAppear {
            loadTextFile()
        }
    }
    
    private func loadTextFile() {
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            content = "Failed to load text file."
        }
    }
}
