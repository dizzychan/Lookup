import SwiftUI

/// 字体风格枚举
enum FontStyle: String, CaseIterable, Identifiable {
    case system     = "System"
    case serif      = "Serif"
    case monospaced = "Monospaced"
    case rounded    = "Rounded"

    var id: String { rawValue }

    /// 对应 SwiftUI 的 Font.Design
    var design: Font.Design {
        switch self {
        case .system:     return .default
        case .serif:      return .serif
        case .monospaced: return .monospaced
        case .rounded:    return .rounded
        }
    }
}

struct SettingView: View {
    @AppStorage("isDarkMode") private var isDarkMode     = false
    @AppStorage("readerFontSize") private var fontSize    = 18.0
    @AppStorage("readerFontDesign") private var fontStyle = FontStyle.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                // MARK: – 夜间模式
                Toggle("Dark Mode", isOn: $isDarkMode)

                // MARK: – 字体大小
                Section("Reader Font Size") {
                    Slider(value: $fontSize, in: 12...30, step: 1)
                    Text("Font Size: \(Int(fontSize)) pt")
                }
                
            
                // MARK: – 字体风格
                Section("Reader Font Style") {
                    Picker("Font Style", selection: $fontStyle) {
                        ForEach(FontStyle.allCases) { style in
                            Text(style.rawValue).tag(style.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

