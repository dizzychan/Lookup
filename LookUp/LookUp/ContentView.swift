import SwiftUI

// Book data model
struct Book: Identifiable {
    let id = UUID()
    var title: String
    var author: String
    var progress: Double
    var content: String?
}



// Data manager class
class DataModel: ObservableObject {
    @Published var books: [Book] = [
        Book(title: "Sample Book 1", author: "Author A", progress: 0.3, content: """
            This is some example text for Sample Book 1.
            You can replace it with actual content in the future.
            """),
        
        Book(title: "Sample Book 2", author: "Author B", progress: 0.7, content: """
            Once upon a time, in a distant land, there was a tale about Sample Book 2...
            """)
    ]
    
    @Published var searchResults: [Book] = []
}


// Main Bookshelf View
struct BookshelfView: View {
    @EnvironmentObject var dataModel: DataModel
    
    let columns = [GridItem(.adaptive(minimum: 150))]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(dataModel.books) { book in
                        NavigationLink {
                            // Pass book.id so ReaderView can update the correct Book's progress
                            ReaderView(
                                bookTitle: book.title,
                                content: book.content,
                                bookID: book.id
                            )
                        } label: {
                            VStack {
                                Image(systemName: "book.closed.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 120)
                                    .foregroundColor(.blue)
                                
                                Text(book.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                
                                ProgressView(value: book.progress)
                                    .padding(.horizontal)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("My Bookshelf")
        }
    }
}


// Import View
struct ImportView: View {
    @EnvironmentObject var dataModel: DataModel
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
                do {
                    // Try reading the file content as a string (assuming it's a txt file)
                    let fileContent = try String(contentsOf: url, encoding: .utf8)
                    
                    let newBook = Book(
                        title: url.lastPathComponent,
                        author: "Unknown",
                        progress: 0,
                        content: fileContent // Assign the file's text here
                    )
                    dataModel.books.append(newBook)
                } catch {
                    print("Error reading file content: \(error)")
                }
            }
        }
    }
}

// Online Source View
struct SourceView: View {
    @EnvironmentObject var dataModel: DataModel
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search by Title or Author", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                Button("Search") {
                    // Execute search logic
                    dataModel.searchResults = [
                        Book(title: "Search Result 1", author: "Author X", progress: 0),
                        Book(title: "Search Result 2", author: "Author Y", progress: 0)
                    ]
                }
            }
            .padding()
            
            List(dataModel.searchResults) { book in
                HStack {
                    Text(book.title)
                    Spacer()
                    Button("Add to Bookshelf") {
                        dataModel.books.append(book)
                    }
                }
            }
        }
        .navigationTitle("Online Library")
    }
}

// Settings View
struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("fontSize") private var fontSize = 16.0
    
    var body: some View {
        Form {
            Section("Display Settings") {
                Toggle("Dark Mode", isOn: $darkMode)
                Stepper("Font Size: \(Int(fontSize))", value: $fontSize, in: 12...24)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                }
                
                Link("Help Documentation", destination: URL(string: "https://example.com")!)
            }
        }
        .navigationTitle("Settings")
    }
}

// Main Entry
struct ContentView: View {
    @StateObject private var dataModel = DataModel()
    
    var body: some View {
        TabView {
            BookshelfView()
                .tabItem {
                    Label("Bookshelf", systemImage: "books.vertical.fill")
                }
            
            ImportView()
                .tabItem {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            
            SourceView()
                .tabItem {
                    Label("Sources", systemImage: "globe")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(dataModel)
    }
}

// Document Picker (requires UIKit integration)
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

