import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            BookShelfView()
                .tabItem {
                    Label("Bookshelf", systemImage: "books.vertical")
                }
                .tag(0)
            
            ImportView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .tag(1)

            SourceView()
                .tabItem {
                    Label("Source", systemImage: "magnifyingglass")
                }
                .tag(2)

            SettingView()
                .tabItem {
                    Label("Setting", systemImage: "gearshape")
                }
                .tag(3)
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(4)
        }
    }
}
