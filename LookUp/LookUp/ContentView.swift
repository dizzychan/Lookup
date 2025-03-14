import SwiftUI

// 书籍数据模型
struct Book: Identifiable {
    let id = UUID()
    var title: String
    var author: String
    var progress: Double
}

// 数据管理类
class DataModel: ObservableObject {
    @Published var books: [Book] = [
        Book(title: "示例书籍1", author: "作者A", progress: 0.3),
        Book(title: "示例书籍2", author: "作者B", progress: 0.7)
    ]
    
    @Published var searchResults: [Book] = []
}

// 主界面
struct BookshelfView: View {
    @EnvironmentObject var dataModel: DataModel
    
    let columns = [GridItem(.adaptive(minimum: 150))]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(dataModel.books) { book in
                        NavigationLink {
                            // 阅读器界面（待实现）
                            Text(book.title)
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
            .navigationTitle("我的书架")
        }
    }
}

// 导入界面
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
                    Text("导入本地文件")
                        .font(.title2)
                }
                .padding()
            }
            
            Text("支持格式：txt, epub")
                .foregroundColor(.gray)
                .padding()
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { url in
                // 处理文件导入逻辑
                let newBook = Book(title: url.lastPathComponent, author: "未知", progress: 0)
                dataModel.books.append(newBook)
            }
        }
    }
}

// 书源界面
struct SourceView: View {
    @EnvironmentObject var dataModel: DataModel
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("搜索书名或作者", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                Button("搜索") {
                    // 执行搜索逻辑
                    dataModel.searchResults = [
                        Book(title: "搜索结果1", author: "作者X", progress: 0),
                        Book(title: "搜索结果2", author: "作者Y", progress: 0)
                    ]
                }
            }
            .padding()
            
            List(dataModel.searchResults) { book in
                HStack {
                    Text(book.title)
                    Spacer()
                    Button("加入书架") {
                        dataModel.books.append(book)
                    }
                }
            }
        }
        .navigationTitle("在线书库")
    }
}

// 设置界面
struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("fontSize") private var fontSize = 16.0
    
    var body: some View {
        Form {
            Section("显示设置") {
                Toggle("深色模式", isOn: $darkMode)
                Stepper("字体大小: \(Int(fontSize))", value: $fontSize, in: 12...24)
            }
            
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                }
                
                Link("帮助文档", destination: URL(string: "https://example.com")!)
            }
        }
        .navigationTitle("设置")
    }
}

// 主入口
struct ContentView: View {
    @StateObject private var dataModel = DataModel()
    
    var body: some View {
        TabView {
            BookshelfView()
                .tabItem {
                    Label("书架", systemImage: "books.vertical.fill")
                }
            
            ImportView()
                .tabItem {
                    Label("导入", systemImage: "square.and.arrow.down")
                }
            
            SourceView()
                .tabItem {
                    Label("书源", systemImage: "globe")
                }
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
        }
        .environmentObject(dataModel)
    }
}

// 文件选择器（需要UIKit集成）
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
