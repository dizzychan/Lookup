
import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            BookShelfView()
                .tabItem {
                    Label("Bookshelf", systemImage: "books.vertical")
                }
            
            ImportView()
                .tabItem {
                    Label("Import", systemImage: "square.and.arrow.down")
                }

            SourceView()
                .tabItem {
                    Label("Source", systemImage: "magnifyingglass")
                }

            SettingView()
                .tabItem {
                    Label("Setting", systemImage: "gearshape")
                }
        }
    }
}
