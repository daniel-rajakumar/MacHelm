import SwiftUI

struct MainView: View {
    @State private var selection: SidebarItem? = .home

    enum SidebarItem: Hashable {
        case home
        case system
        case settings
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: SidebarItem.home) {
                    Label("Home", systemImage: "house")
                }
                NavigationLink(value: SidebarItem.system) {
                    Label("System", systemImage: "desktopcomputer")
                }
                NavigationLink(value: SidebarItem.settings) {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .navigationTitle("MacHelm")
        } detail: {
            switch selection {
            case .home:
                HomeScreen()
            case .system:
                Text("System View")
                    .font(.largeTitle)
            case .settings:
                Text("Settings View")
                    .font(.largeTitle)
            case nil:
                Text("Select an item")
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    MainView()
}
