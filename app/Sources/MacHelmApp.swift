import SwiftUI

@main
struct MacHelmApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .defaultSize(width: 720, height: 740)
        .windowResizability(.contentSize)
        
        MenuBarExtra("MacHelm", systemImage: "steeringwheel") {
            MenuBarMenu()
        }
        .menuBarExtraStyle(.window)
    }
}
