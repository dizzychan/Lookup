import SwiftUI

// Make sure this struct is declared only once in your entire project:
struct ScrollOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ReaderView: View {
    var bookTitle: String
    var content: String?
    
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @EnvironmentObject var dataModel: DataModel
    var bookID: UUID
    
    @State private var readingProgress: Double = 0.0
    
    // Split the content into lines; if there's no content, show a fallback
    private var lines: [String] {
        guard let text = content, !text.isEmpty else {
            return ["No content available."]
        }
        return text.components(separatedBy: .newlines)
    }
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                // Hidden GeometryReader + PreferenceKey to track scroll offset
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: -geo.frame(in: .named("scrollArea")).origin.y
                        )
                }
                .frame(height: 0)
                
                VStack(alignment: .leading, spacing: 10) {
                    // Optional: Show book title before lines
                    Text(bookTitle)
                        .font(.system(size: fontSize + 2))
                        .bold()
                        .padding(.bottom, 5)
                    
                    // Display each line with a unique .id for scrolling
                    ForEach(lines.indices, id: \.self) { index in
                        Text(lines[index])
                            .font(.system(size: fontSize))
                            .id(index)
                    }
                }
                .padding(.horizontal)
            }
            .coordinateSpace(name: "scrollArea")
            // Listen for scroll offset changes
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                updateReadingProgress(offset: offset)
            }
            // Single onAppear to (1) load saved progress, (2) scroll to correct position
            .onAppear {
                // 1) Load existing progress from dataModel
                if let bookIndex = dataModel.books.firstIndex(where: { $0.id == bookID }) {
                    readingProgress = dataModel.books[bookIndex].progress
                }
                // 2) Compute target line and scroll
                let targetIndex = Int(Double(lines.count) * readingProgress)
                let clampedIndex = max(0, min(lines.count - 1, targetIndex))
                scrollProxy.scrollTo(clampedIndex, anchor: .top)
            }
        }
        .navigationTitle("Reading \(bookTitle)")
    }
    
    /// Updates reading progress and writes it back to dataModel
    private func updateReadingProgress(offset: CGFloat) {
        // Estimate total text height
        let approximateLineHeight = fontSize * 1.4
        let totalHeight = approximateLineHeight * Double(lines.count)
        
        // Approximate visible height
        let visibleHeight = 600.0  // This is a rough guess.
        let scrollableHeight = max(totalHeight - visibleHeight, 1)
        
        let currentOffset = Double(offset)
        var progress = currentOffset / scrollableHeight
        progress = max(0, min(1, progress))  // clamp 0~1
        
        readingProgress = progress
        
        // Update dataModel
        if let index = dataModel.books.firstIndex(where: { $0.id == bookID }) {
            dataModel.books[index].progress = progress
        }
    }
}

