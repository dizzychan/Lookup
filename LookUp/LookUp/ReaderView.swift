import SwiftUI

// If not declared elsewhere, we need the custom PreferenceKey here again.
// Make sure this is only declared once in your entire project.
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
    
    // 1. We'll split the content into lines. If there's no content, we provide a single "No content" line for display.
    private var lines: [String] {
        guard let text = content, !text.isEmpty else {
            return ["No content available."]
        }
        // Split by line breaks
        return text.components(separatedBy: .newlines)
    }
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                // 2. A hidden GeometryReader to track scroll offset via PreferenceKey
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: -geo.frame(in: .named("scrollArea")).origin.y
                        )
                }
                .frame(height: 0)
                
                VStack(alignment: .leading, spacing: 10) {
                    // Optional: Show the book title as the first "line"
                    Text(bookTitle)
                        .font(.system(size: fontSize + 2))
                        .bold()
                        .padding(.bottom, 5)
                    
                    // 3. Display each line with an ID for scroll-to
                    ForEach(lines.indices, id: \.self) { index in
                        Text(lines[index])
                            .font(.system(size: fontSize))
                            .id(index) // Mark each line by index
                    }
                }
                .padding(.horizontal)
            }
            // Named coordinate space for offset calculation
            .coordinateSpace(name: "scrollArea")
            // Listen to offset changes
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                updateReadingProgress(offset: offset)
            }
            // 4. On appear, scroll to last progress
            .onAppear {
                // We'll compute approximate line index from progress
                let targetIndex = Int(Double(lines.count) * readingProgress)
                let clampedIndex = max(0, min(lines.count - 1, targetIndex))
                // Then scroll to that line
                scrollProxy.scrollTo(clampedIndex, anchor: .top)
            }
        }
        .navigationTitle("Reading \(bookTitle)")
        .onAppear {
            // If there's an existing progress from DataModel, use that
            if let bookIndex = dataModel.books.firstIndex(where: { $0.id == bookID }) {
                readingProgress = dataModel.books[bookIndex].progress
            }
        }
    }
    
    // MARK: - Update Reading Progress
    private func updateReadingProgress(offset: CGFloat) {
        // Let's do a simpler approach: offset / totalScrollableHeight
        // totalScrollableHeight ~ (lines.count * lineHeight) - ScrollView visible region
        // We'll do a rough approach. For more accurate approach, do a full measurement with GeometryReader on content size.
        
        // Estimate total text height:
        let approximateLineHeight = fontSize * 1.4
        let totalHeight = approximateLineHeight * Double(lines.count)
        
        // Current offset
        let currentOffset = Double(offset)
        
        // The visible height of the screen (for clamping)
        // This can be refined with exact device size or geometry
        let visibleHeight = 600.0  // a rough guess, or measure with another geometry
        let scrollableHeight = max(totalHeight - visibleHeight, 1)
        
        var progress = currentOffset / scrollableHeight
        progress = max(0, min(1, progress))
        
        // Update local state + DataModel
        readingProgress = progress
        
        if let index = dataModel.books.firstIndex(where: { $0.id == bookID }) {
            dataModel.books[index].progress = progress
        }
    }
}

