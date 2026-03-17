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
        
        MenuBarExtra("MacHelm", systemImage: "steeringwheel") {
            MenuBarMenu()
        }
        .menuBarExtraStyle(.window)
    }
}
