import Foundation
import Combine

struct DeletedApp: Codable, Identifiable {
    var id: String { path }
    let name: String
    let path: String
    let installSource: String
}

class AppStateManager: ObservableObject {
    @Published var deletedApps: [DeletedApp] = []
    @Published var processingRemovals: Set<String> = []
    @Published var processingRestores: Set<String> = []
    @Published var processingInstalls: Set<String> = []
    
    private let deletedKey = "MacHelmDeletedApps"
    
    init() {
        loadState()
    }
    
    func deleteApp(app: NixApp) {
        let capturedSource = app.installSource
        print("DeleteApp called for \(app.name), source: \(capturedSource)")
        if capturedSource == "Homebrew" {
            processingRemovals.insert(app.path)
            let appNameParam = app.name.lowercased().replacingOccurrences(of: " ", with: "-")
            let cmd = "/opt/homebrew/bin/brew uninstall --cask \(appNameParam) || /usr/local/bin/brew uninstall --cask \(appNameParam)"
            print("Running command: \(cmd)")
            runCommandInBackground(command: cmd) { [weak self] status in
                DispatchQueue.main.async {
                    print("Command finished with status: \(status)")
                    self?.processingRemovals.remove(app.path)
                    if status == 0 {
                        let deletedApp = DeletedApp(name: app.name, path: app.path, installSource: capturedSource)
                        self?.deletedApps.append(deletedApp)
                        self?.saveState()
                        print("Saved deleted app to state")
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadApps"), object: nil)
                    } else {
                        print("Command failed, not adding to deleted apps")
                    }
                }
            }
        } else {
            let deletedApp = DeletedApp(name: app.name, path: app.path, installSource: capturedSource)
            deletedApps.append(deletedApp)
            saveState()
            print("Saved non-homebrew deleted app to state")
            NotificationCenter.default.post(name: NSNotification.Name("ReloadApps"), object: nil)
        }
    }
    
    func restoreApp(deletedApp: DeletedApp) {
        print("RestoreApp called for \(deletedApp.name), source: \(deletedApp.installSource)")
        if deletedApp.installSource == "Homebrew" {
            processingRestores.insert(deletedApp.path)
            let appNameParam = deletedApp.name.lowercased().replacingOccurrences(of: " ", with: "-")
            let cmd = "/opt/homebrew/bin/brew install --cask \(appNameParam) || /usr/local/bin/brew install --cask \(appNameParam)"
            print("Running command: \(cmd)")
            runCommandInBackground(command: cmd) { [weak self] status in
                DispatchQueue.main.async {
                    print("Command finished with status: \(status)")
                    self?.processingRestores.remove(deletedApp.path)
                    if status == 0 {
                        if let index = self?.deletedApps.firstIndex(where: { $0.path == deletedApp.path }) {
                            self?.deletedApps.remove(at: index)
                            self?.saveState()
                            print("Removed restored app from state")
                            NotificationCenter.default.post(name: NSNotification.Name("ReloadApps"), object: nil)
                        }
                    } else {
                        print("Command failed, not removing from deleted apps")
                    }
                }
            }
        } else {
            if let index = deletedApps.firstIndex(where: { $0.path == deletedApp.path }) {
                deletedApps.remove(at: index)
                saveState()
                NotificationCenter.default.post(name: NSNotification.Name("ReloadApps"), object: nil)
            }
        }
    }
    
    func installHomebrewCask(token: String) {
        print("InstallCask called for token: \(token)")
        processingInstalls.insert(token)
        
        let cmd = "/opt/homebrew/bin/brew install --cask \(token) || /usr/local/bin/brew install --cask \(token)"
        print("Running install command: \(cmd)")
        
        runCommandInBackground(command: cmd) { [weak self] status in
            DispatchQueue.main.async {
                print("Install command finished with status: \(status)")
                self?.processingInstalls.remove(token)
                if status == 0 {
                    print("App installed successfully via Store")
                    NotificationCenter.default.post(name: NSNotification.Name("ReloadApps"), object: nil)
                }
            }
        }
    }
    
    func isDeleted(appPath: String) -> Bool {
        return deletedApps.contains { $0.path == appPath }
    }
    
    private func saveState() {
        if let data = try? JSONEncoder().encode(deletedApps) {
            UserDefaults.standard.set(data, forKey: deletedKey)
        }
    }
    
    private func loadState() {
        if let data = UserDefaults.standard.data(forKey: deletedKey),
           let decoded = try? JSONDecoder().decode([DeletedApp].self, from: data) {
            deletedApps = decoded
        }
    }
    
    private func runCommandInBackground(command: String, completion: ((Int32) -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.launchPath = "/bin/bash"
            task.arguments = ["-c", command]
            
            var env = ProcessInfo.processInfo.environment
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" + (env["PATH"].map { ":" + $0 } ?? "")
            env["HOME"] = FileManager.default.homeDirectoryForCurrentUser.path
            env["USER"] = NSUserName()
            task.environment = env
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    print("Command Output for '\(command)':\n\(output)")
                }
                task.waitUntilExit()
                completion?(task.terminationStatus)
            } catch {
                print("Failed to run command: \(error)")
                completion?(-1)
            }
        }
    }
}
