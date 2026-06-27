import Foundation
import Combine

struct DeletedApp: Codable, Identifiable, Equatable {
    var id: String { path }
    let name: String
    let path: String
    let installSource: String

    init(
        name: String,
        path: String,
        installSource: String
    ) {
        self.name = name
        self.path = path
        self.installSource = installSource
    }
}

class AppStateManager: ObservableObject {
    @Published var deletedApps: [DeletedApp] = []
    @Published var processingRemovals: Set<String> = []
    @Published var processingRestores: Set<String> = []
    @Published var processingInstalls: Set<String> = []
    @Published var processingUpgrades: Set<String> = []
    @Published var installedTokens: Set<String> = []
    @Published var outdatedTokens: Set<String> = []

    private var deletedAppsWatcher: DirectoryWatcher?
    private var deletedAppsReloadWorkItem: DispatchWorkItem?
    
    init() {
        loadState()
        startWatchingDeletedAppsData()
        loadInstalledTokens()
        loadOutdatedTokens()
    }
    
    private func loadInstalledTokens() {
        guard let brewPath = RepoConfig.preferredBrewExecutable() else { return }
        let cmd = "'\(brewPath)' list --cask"
        runCommandForOutput(command: cmd) { [weak self] status, output in
            guard status == 0 else { return }

            let tokens = output
                .split(separator: "\n")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            DispatchQueue.main.async {
                self?.installedTokens = Set(tokens)
            }
        }
    }

    func loadOutdatedTokens() {
        guard let brewPath = RepoConfig.preferredBrewExecutable() else { return }
        let cmd = "\(brewPath) outdated --cask --json"
        
        runCommandForOutput(command: cmd) { [weak self] status, output in
            guard status == 0, let data = output.data(using: .utf8) else { return }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let casks = json["casks"] as? [[String: Any]] {
                let tokens = casks.compactMap { $0["token"] as? String ?? $0["name"] as? String }
                DispatchQueue.main.async {
                    self?.outdatedTokens = Set(tokens)
                    print("Loaded outdated tokens: \(tokens)")
                }
            }
        }
    }

    
    func deleteApp(app: InstalledApp) {
        let capturedSource = app.installSource
        print("DeleteApp called for \(app.name), source: \(capturedSource)")
        if capturedSource == "Homebrew" {
            processingRemovals.insert(app.path)
            let appNameParam = app.name.lowercased().replacingOccurrences(of: " ", with: "-")
            guard let brewPath = RepoConfig.preferredBrewExecutable() else {
                processingRemovals.remove(app.path)
                return
            }
            let cmd = "'\(brewPath)' uninstall --cask \(appNameParam)"
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
                        self?.installedTokens.remove(appNameParam)
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadApps"), object: nil)
                    } else {
                        print("Command failed, not adding to deleted apps")
                    }
                }
            }
        } else if capturedSource == "Others" {
            processingRemovals.insert(app.path)
            
            // For manual apps, move them to the Trash. 
            // We use SUDO_ASKPASS because apps in /Applications often require root to move.
            let trashPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash").path
            let command = "mv \"\(app.path)\" \"\(trashPath)/\""
            
            print("Moving 'Others' app to trash with elevation: \(command)")
            runElevatedCommandWithAskpass(command: command) { [weak self] status in
                DispatchQueue.main.async {
                    self?.processingRemovals.remove(app.path)
                    if status == 0 {
                        let deletedApp = DeletedApp(name: app.name, path: app.path, installSource: capturedSource)
                        self?.deletedApps.append(deletedApp)
                        self?.saveState()
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadApps"), object: nil)
                    } else {
                        print("Failed to move app to trash, status: \(status)")
                    }
                }
            }
        } else {
            // Fallback for any unknown sources
            let deletedApp = DeletedApp(name: app.name, path: app.path, installSource: capturedSource)
            deletedApps.append(deletedApp)
            saveState()
            NotificationCenter.default.post(name: NSNotification.Name("ReloadApps"), object: nil)
        }
    }
    
    func restoreApp(deletedApp: DeletedApp) {
        print("RestoreApp called for \(deletedApp.name), source: \(deletedApp.installSource)")
        if deletedApp.installSource == "Homebrew" {
            processingRestores.insert(deletedApp.path)
            let appNameParam = deletedApp.name.lowercased().replacingOccurrences(of: " ", with: "-")
            guard let brewPath = RepoConfig.preferredBrewExecutable() else {
                processingRestores.remove(deletedApp.path)
                return
            }
            let cmd = "'\(brewPath)' install --cask \(appNameParam)"
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
    
    func uninstallHomebrewCask(token: String) {
        print("UninstallCask called for token: \(token)")
        processingRemovals.insert(token)
        guard let brewPath = RepoConfig.preferredBrewExecutable() else {
            processingRemovals.remove(token)
            return
        }
        let command = "\(brewPath) uninstall --cask \(token)"
        
        print("Running Homebrew uninstall command with SUDO_ASKPASS: \(command)")
        runHomebrewCommand(command: command) { [weak self] status in
            DispatchQueue.main.async {
                print("Homebrew uninstall command finished with status: \(status)")
                self?.processingRemovals.remove(token)
                if status == 0 {
                    self?.installedTokens.remove(token)
                    NotificationCenter.default.post(name: NSNotification.Name("ReloadApps"), object: nil)
                }
            }
        }
    }
    
    func installHomebrewCask(token: String) {
        print("InstallCask called for token: \(token)")
        processingInstalls.insert(token)
        
        guard let brewPath = RepoConfig.preferredBrewExecutable() else {
            processingInstalls.remove(token)
            return
        }
        let command = "\(brewPath) install --cask \(token) --force"
        
        print("Running Homebrew install command with SUDO_ASKPASS: \(command)")
        runHomebrewCommand(command: command) { [weak self] status in
            DispatchQueue.main.async {
                print("Homebrew install command finished with status: \(status)")
                self?.processingInstalls.remove(token)
                if status == 0 {
                    self?.installedTokens.insert(token)
                    self?.loadOutdatedTokens()
                    NotificationCenter.default.post(name: NSNotification.Name("ReloadApps"), object: nil)
                }
            }
        }
    }

    func upgradeHomebrewCask(token: String) {
        print("UpgradeCask called for token: \(token)")
        processingUpgrades.insert(token)
        
        guard let brewPath = RepoConfig.preferredBrewExecutable() else {
            processingUpgrades.remove(token)
            return
        }
        let command = "\(brewPath) upgrade --cask \(token)"
        
        print("Running Homebrew upgrade command with SUDO_ASKPASS: \(command)")
        runHomebrewCommand(command: command) { [weak self] status in
            DispatchQueue.main.async {
                print("Homebrew upgrade command finished with status: \(status)")
                self?.processingUpgrades.remove(token)
                if status == 0 {
                    self?.loadOutdatedTokens()
                    NotificationCenter.default.post(name: NSNotification.Name("ReloadApps"), object: nil)
                }
            }
        }
    }

    private func runHomebrewCommand(command: String, completion: @escaping (Int32) -> Void) {
        let askpassPath = "/Users/danielrajakumar/code/MacHelm/scripts/machelm-askpass"
        // For Homebrew, we don't use sudo -A BEFORE the command, because brew handles its own elevation.
        let fullCommand = "export SUDO_ASKPASS='\(askpassPath)'; \(command)"
        
        runCommandInBackground(command: "/bin/bash -c \"\(fullCommand)\"") { status in
            completion(status)
        }
    }

    private func runElevatedCommandWithAskpass(command: String, completion: @escaping (Int32) -> Void) {
        let askpassPath = "/Users/danielrajakumar/code/MacHelm/scripts/machelm-askpass"
        // Force command to use the askpass helper by pre-authenticating via sudo -A
        let fullCommand = "export SUDO_ASKPASS='\(askpassPath)'; sudo -A -v && sudo -A \(command)"
        
        runCommandInBackground(command: "/bin/bash -c \"\(fullCommand)\"") { status in
            completion(status)
        }
    }

    private func runPrivilegedCommand(command: String, completion: @escaping (Int32) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let escapedCommand = command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            let script = "do shell script \"\(escapedCommand)\" with administrator privileges"
            
            let process = Process()
            process.launchPath = "/usr/bin/osascript"
            process.arguments = ["-e", script]
            
            // Set basic environment variables
            var env = ProcessInfo.processInfo.environment
            env["PATH"] = RepoConfig.commandSearchPathString()
            process.environment = env
            
            process.terminationHandler = { process in
                completion(process.terminationStatus)
            }
            
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("Failed to run privileged command: \(error)")
                completion(-1)
            }
        }
    }

    func isDeleted(appPath: String) -> Bool {
        return deletedApps.contains { $0.path == appPath }
    }
    
    private func saveState() {
        UserConfigExporter.saveDeletedApps(deletedApps)
    }
    
    private func loadState() {
        deletedApps = UserConfigExporter.loadDeletedApps()
    }

    private func startWatchingDeletedAppsData() {
        let watcher = DirectoryWatcher(url: UserConfigExporter.userDirectoryURL()) { [weak self] in
            self?.scheduleDeletedAppsReload()
        }
        watcher.start()
        deletedAppsWatcher = watcher
    }

    private func scheduleDeletedAppsReload() {
        deletedAppsReloadWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let reloadedApps = UserConfigExporter.loadDeletedApps()

            DispatchQueue.main.async {
                if self.deletedApps != reloadedApps {
                    self.deletedApps = reloadedApps
                }
            }
        }

        deletedAppsReloadWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
    
    private func runCommandInBackground(command: String, completion: ((Int32) -> Void)? = nil) {
        runCommandForOutput(command: command) { status, _ in
            completion?(status)
        }
    }

    private func runCommandForOutput(
        command: String,
        completion: @escaping (Int32, String) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.launchPath = "/bin/bash"
            task.arguments = ["-c", command]
            
            var env = ProcessInfo.processInfo.environment
            env["PATH"] = RepoConfig.commandSearchPathString() + (env["PATH"].map { ":" + $0 } ?? "")
            env["HOME"] = FileManager.default.homeDirectoryForCurrentUser.path
            env["USER"] = NSUserName()
            task.environment = env
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                task.waitUntilExit()
                if let output = String(data: data, encoding: .utf8) {
                    print("Command Output for '\(command)':\n\(output)")
                    completion(task.terminationStatus, output)
                } else {
                    completion(task.terminationStatus, "")
                }
            } catch {
                print("Failed to run command: \(error)")
                completion(-1, "")
            }
        }
    }

    deinit {
        deletedAppsReloadWorkItem?.cancel()
        deletedAppsWatcher?.stop()
    }
}
