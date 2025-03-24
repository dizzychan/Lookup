import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    // 获取 SwiftData 上下文
    @Environment(\.modelContext) private var context

    // 控制是否弹出文件导入器
    @State private var isImporting = false

    // 如果遇到错误，可以把错误信息显示出来
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                }

                // 按钮显示为 “Import File”，支持多种文件类型
                Button("Import File") {
                    isImporting = true
                }
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: [
                        .plainText,  // txt 文件
                        .pdf,        // pdf 文件
                        .epub,       // epub 文件（若系统支持）
                        .item        // 其他文件类型，作为备用
                    ],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        guard let selectedFile = urls.first else { return }
                        handleFile(at: selectedFile)
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
            .navigationTitle("Import")
        }
    }
    
    // 根据文件扩展名，处理不同类型的文件
    private func handleFile(at url: URL) {
        do {
            // 获取文件扩展名，转成小写以便比较
            let ext = url.pathExtension.lowercased()
            // 用文件名（去掉扩展名）作为书名
            let bookTitle = url.deletingPathExtension().lastPathComponent
            
            switch ext {
            case "txt":
                // 对于 txt 文件，直接读取纯文本内容
                let fileContent = try String(contentsOf: url, encoding: .utf8)
                let newBook = Book(title: bookTitle,
                                   content: fileContent,
                                   fileType: .txt)
                context.insert(newBook)
                
            case "pdf":
                // 对于 pdf 文件，先将文件拷贝到沙盒，然后记录路径
                let newURL = try copyFileToDocuments(originalURL: url)
                let newBook = Book(title: bookTitle,
                                   fileType: .pdf,
                                   fileURL: newURL.path)
                context.insert(newBook)
                
            case "epub":
                // 对于 epub 文件，同样拷贝到沙盒
                let newURL = try copyFileToDocuments(originalURL: url)
                let newBook = Book(title: bookTitle,
                                   fileType: .epub,
                                   fileURL: newURL.path)
                context.insert(newBook)
                
            case "docx":
                // 对于 docx 文件，拷贝并记录路径
                let newURL = try copyFileToDocuments(originalURL: url)
                let newBook = Book(title: bookTitle,
                                   fileType: .docx,
                                   fileURL: newURL.path)
                context.insert(newBook)
                
            default:
                // 如果文件类型不认识，则标记为 unknown，并拷贝下来
                let newURL = try copyFileToDocuments(originalURL: url)
                let newBook = Book(title: bookTitle,
                                   fileType: .unknown,
                                   fileURL: newURL.path)
                context.insert(newBook)
            }
            
            // 保存插入的 Book 到数据库
            try context.save()
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // 将选中的文件拷贝到 App 沙盒 Documents 文件夹，并返回新路径
    private func copyFileToDocuments(originalURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = docsURL.appendingPathComponent(originalURL.lastPathComponent)
        
        // 如果目标文件已存在，则先删除
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.copyItem(at: originalURL, to: destinationURL)
        return destinationURL
    }
}

