import SwiftUI

@main
struct MacHelmApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
            NSRunningApplication.current.activate(options: [.activateAllWindows])
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .defaultSize(width: 720, height: 740)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        
        MenuBarExtra("MacHelm", systemImage: "steeringwheel") {
            MenuBarMenu()
        }
        .menuBarExtraStyle(.window)
    }
}
