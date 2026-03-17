import SwiftUI

struct MainView: View {
    @State private var selection: SidebarItem? = .home

    enum SidebarItem: Hashable {
        case home
        case apps
        case system
        case settings
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: SidebarItem.home) {
                    Label("Home", systemImage: "house")
                }
                NavigationLink(value: SidebarItem.apps) {
                    Label("Apps", systemImage: "app.window.stack")
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
            case .apps:
                AppsScreen()
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
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: rebuildAndRestart) {
                    Label("Restart", systemImage: "arrow.triangle.2.circlepath")
                }
                .help("Rebuild & Restart App")
            }
        }
    }
    
    private func rebuildAndRestart() {
        let task = Process()
        task.launchPath = "/bin/bash"
        // Use 'open -gj' or just run the executable directly in the background.
        // We'll execute the newly built binary directly to avoid Terminal popping up.
        task.arguments = ["-c", "sleep 1 && cd /Users/danielrajakumar/code/MacHelm/app && swift build && .build/arm64-apple-macosx/debug/MacHelm &"]
        
        do {
            try task.run()
            NSApplication.shared.terminate(nil)
        } catch {
            print("Failed to initiate restart: \(error)")
        }
    }
}

#Preview {
    MainView()
}
