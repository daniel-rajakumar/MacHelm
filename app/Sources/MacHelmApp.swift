import SwiftUI

@main
struct MacHelmApp: App {
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
