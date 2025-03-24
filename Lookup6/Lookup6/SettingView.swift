import SwiftUI

struct SettingView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("readerFontSize") private var fontSize = 18.0

    var body: some View {
        NavigationStack {
            Form {
                // 夜间模式
                Toggle("Dark Mode", isOn: $isDarkMode)

                // 字体大小
                Section(header: Text("Reader Font Size")) {
                    Slider(value: $fontSize, in: 12...30, step: 1)
                    Text("Font Size: \(Int(fontSize))")
                }
            }
            .navigationTitle("Setting")
        }
    }
}

