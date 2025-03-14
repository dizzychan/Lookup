import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("书架")
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("书架")
                }
                .tag(0)
            
            Text("导入")
                .tabItem {
                    Image(systemName: "square.and.arrow.down")
                    Text("导入")
                }
                .tag(1)
            
            Text("下载")
                .tabItem {
                    Image(systemName: "arrow.down.circle")
                    Text("下载")
                }
                .tag(2)
            
            Text("设置")
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("设置")
                }
                .tag(3)
        }
        .accentColor(.blue) // 设置选项卡选中颜色
    }
}

