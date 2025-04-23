//
//  QuickLookView.swift
//  Lookup8
//
//  Created by Wangzhen Wu on 22/04/2025.
//

import SwiftUI
import QuickLook

struct QuickLookView: UIViewControllerRepresentable {
    let filePath: String
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // no-op
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(filePath: filePath)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let filePath: String
        
        init(filePath: String) {
            self.filePath = filePath
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return URL(fileURLWithPath: filePath) as QLPreviewItem
        }
    }
}

