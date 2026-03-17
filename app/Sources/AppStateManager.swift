import Foundation
import Combine

struct DeletedApp: Codable, Identifiable {
    var id: String { path }
    let name: String
    let path: String
    let installSource: String
    let nixPackageHint: String?
    let nixConfigPath: String?

    init(
        name: String,
        path: String,
        installSource: String,
        nixPackageHint: String? = nil,
        nixConfigPath: String? = nil
    ) {
        self.name = name
        self.path = path
        self.installSource = installSource
        self.nixPackageHint = nixPackageHint
        self.nixConfigPath = nixConfigPath
    }
}

private struct NixConfigMatch {
    let configPath: String
    let packageToken: String
}

class AppStateManager: ObservableObject {
    @Published var deletedApps: [DeletedApp] = []
    @Published var processingRemovals: Set<String> = []
    @Published var processingRestores: Set<String> = []
    @Published var processingInstalls: Set<String> = []
    @Published var installedTokens: Set<String> = []
    
    private let deletedKey = "MacHelmDeletedApps"
    
    init() {
        loadState()
        loadInstalledTokens()
    }
    
    private func loadInstalledTokens() {
        // Use brew list --cask to get installed cask tokens
        let cmd = "/opt/homebrew/bin/brew list --cask || /usr/local/bin/brew list --cask"
        runCommandInBackground(command: cmd) { [weak self] status in
            DispatchQueue.main.async {
                guard status == 0 else { return }
                // The command output is captured in the pipe; we need to read it from the previous runCommandInBackground's output handling.
                // Since runCommandInBackground already prints output, we will re-run a synchronous version here for simplicity.
                let task = Process()
                task.launchPath = "/bin/bash"
                task.arguments = ["-c", cmd]
                let pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = pipe
                do {
                    try task.run()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8) {
                        let tokens = output.split(separator: "\n").map { String($0) }
                        self?.installedTokens = Set(tokens)
                    }
                } catch {
                    print("Failed to load installed tokens: \(error)")
                }
            }
        }
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
        } else if capturedSource == "Nix" {
            processingRemovals.insert(app.path)
            findAndModifyNixConfig(appName: app.name, appPath: app.path, commentOut: true) { [weak self] match in
                guard let self = self else { return }
                guard let match = match else {
                    DispatchQueue.main.async {
                        self.processingRemovals.remove(app.path)
                        print("No matching Nix package found for \(app.name)")
                    }
                    return
                }

                self.triggerNixRebuild { success in
                    if success {
                        DispatchQueue.main.async {
                            self.processingRemovals.remove(app.path)
                            let deletedApp = DeletedApp(
                                name: app.name,
                                path: app.path,
                                installSource: capturedSource,
                                nixPackageHint: match.packageToken,
                                nixConfigPath: match.configPath
                            )
                            self.deletedApps.append(deletedApp)
                            self.saveState()
                            NotificationCenter.default.post(name: NSNotification.Name("ReloadApps"), object: nil)
                        }
                    } else {
                        self.revertNixConfigChange(match: match, commentOut: false)
                        DispatchQueue.main.async {
                            self.processingRemovals.remove(app.path)
                        }
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
        } else if deletedApp.installSource == "Nix" {
            processingRestores.insert(deletedApp.path)
            findAndModifyNixConfig(
                appName: deletedApp.name,
                appPath: deletedApp.path,
                preferredPackageHint: deletedApp.nixPackageHint,
                preferredConfigPath: deletedApp.nixConfigPath,
                commentOut: false
            ) { [weak self] match in
                guard let self = self else { return }
                guard let match = match else {
                    DispatchQueue.main.async {
                        self.processingRestores.remove(deletedApp.path)
                        print("No matching Nix package found for restore: \(deletedApp.name)")
                    }
                    return
                }

                self.triggerNixRebuild { success in
                    if success {
                        DispatchQueue.main.async {
                            self.processingRestores.remove(deletedApp.path)
                            if let index = self.deletedApps.firstIndex(where: { $0.path == deletedApp.path }) {
                                self.deletedApps.remove(at: index)
                                self.saveState()
                                NotificationCenter.default.post(name: NSNotification.Name("ReloadApps"), object: nil)
                            }
                        }
                    } else {
                        self.revertNixConfigChange(match: match, commentOut: true)
                        DispatchQueue.main.async {
                            self.processingRestores.remove(deletedApp.path)
                        }
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

    private func findAndModifyNixConfig(
        appName: String,
        appPath: String,
        preferredPackageHint: String? = nil,
        preferredConfigPath: String? = nil,
        commentOut: Bool,
        completion: @escaping (NixConfigMatch?) -> Void
    ) {
        let normalizedCandidates = normalizedPackageCandidates(
            appName: appName,
            appPath: appPath,
            preferredPackageHint: preferredPackageHint
        )
        let nixFiles = orderedNixConfigPaths(preferredConfigPath: preferredConfigPath)

        DispatchQueue.global(qos: .userInitiated).async {
            completion(self.modifyNixConfig(
                at: nixFiles,
                normalizedCandidates: normalizedCandidates,
                commentOut: commentOut
            ))
        }
    }

    private func triggerNixRebuild(completion: @escaping (Bool) -> Void) {
        let scriptPath = "/Users/danielrajakumar/code/MacHelm/scripts/nix/rebuild-dashboard.sh"
        runCommandInBackground(command: "bash \(scriptPath)") { status in
            print("Nix Rebuild finished with status: \(status)")
            completion(status == 0)
        }
    }

    private func orderedNixConfigPaths(preferredConfigPath: String?) -> [String] {
        let defaultPaths = [
            "/Users/danielrajakumar/code/MacHelm/hosts/daniel.nix",
            "/Users/danielrajakumar/code/MacHelm/hosts/macbook.nix"
        ]

        var orderedPaths: [String] = []
        if let preferredConfigPath, !preferredConfigPath.isEmpty {
            orderedPaths.append(preferredConfigPath)
        }

        for path in defaultPaths where !orderedPaths.contains(path) {
            orderedPaths.append(path)
        }

        return orderedPaths
    }

    private func modifyNixConfig(
        at paths: [String],
        normalizedCandidates: Set<String>,
        commentOut: Bool
    ) -> NixConfigMatch? {
        for path in paths {
            guard let content = try? String(contentsOfFile: path) else { continue }
            let lines = content.components(separatedBy: .newlines)
            var updatedLines: [String] = []
            var match: NixConfigMatch?

            for line in lines {
                guard match == nil, let packageToken = matchingPackageToken(in: line, normalizedCandidates: normalizedCandidates) else {
                    updatedLines.append(line)
                    continue
                }

                let updatedLine = toggledCommentLine(from: line, commentOut: commentOut)
                updatedLines.append(updatedLine)

                if updatedLine != line {
                    match = NixConfigMatch(configPath: path, packageToken: packageToken)
                }
            }

            if let match {
                do {
                    try updatedLines.joined(separator: "\n").write(toFile: path, atomically: true, encoding: .utf8)
                    return match
                } catch {
                    print("Failed to write Nix config at \(path): \(error)")
                }
            }
        }

        return nil
    }

    private func revertNixConfigChange(match: NixConfigMatch, commentOut: Bool) {
        let normalizedCandidates = Set([normalizedPackageIdentifier(match.packageToken)])
        let reverted = modifyNixConfig(
            at: [match.configPath],
            normalizedCandidates: normalizedCandidates,
            commentOut: commentOut
        )

        if reverted == nil {
            print("Failed to revert Nix config change for \(match.packageToken)")
        }
    }

    private func normalizedPackageCandidates(
        appName: String,
        appPath: String,
        preferredPackageHint: String?
    ) -> Set<String> {
        var candidates = Set<String>()

        func addCandidate(_ value: String?) {
            guard let value else { return }
            let normalized = normalizedPackageIdentifier(value)
            if !normalized.isEmpty {
                candidates.insert(normalized)
            }
        }

        addCandidate(appName)
        addCandidate(preferredPackageHint)

        if let symlinkDestination = try? FileManager.default.destinationOfSymbolicLink(atPath: appPath) {
            let appBundleName = ((symlinkDestination as NSString).deletingPathExtension as NSString).lastPathComponent
            addCandidate(appBundleName)
            addCandidate(storePackageName(from: symlinkDestination))
        }

        return candidates
    }

    private func storePackageName(from symlinkDestination: String) -> String? {
        let storeComponent = URL(fileURLWithPath: symlinkDestination).pathComponents.first { $0.contains("-") && !$0.hasPrefix("/") }
        guard let storeComponent else { return nil }

        let parts = storeComponent.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count >= 2 else { return nil }

        let packageWithVersion = parts.dropFirst().joined(separator: "-")
        if let versionRange = packageWithVersion.range(of: #"-\d"#, options: .regularExpression) {
            return String(packageWithVersion[..<versionRange.lowerBound])
        }

        return packageWithVersion
    }

    private func matchingPackageToken(in line: String, normalizedCandidates: Set<String>) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let uncommented = trimmed.replacingOccurrences(of: #"^#\s*"#, with: "", options: .regularExpression)
        let codePart = uncommented
            .components(separatedBy: "#")
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""

        guard !codePart.isEmpty else { return nil }

        let nsRange = NSRange(codePart.startIndex..<codePart.endIndex, in: codePart)
        let packageRegex = try? NSRegularExpression(pattern: #"pkgs\.([A-Za-z0-9+._-]+)"#)
        let packageMatches = packageRegex?.matches(in: codePart, range: nsRange) ?? []

        for match in packageMatches {
            guard
                let tokenRange = Range(match.range(at: 1), in: codePart)
            else {
                continue
            }

            let token = String(codePart[tokenRange])
            if normalizedCandidates.contains(normalizedPackageIdentifier(token)) {
                return token
            }
        }

        let bareToken = codePart
            .replacingOccurrences(of: #"^[\[\(]+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[\]\),;]+$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        if
            bareToken.range(of: #"^[A-Za-z0-9+._-]+$"#, options: .regularExpression) != nil,
            normalizedCandidates.contains(normalizedPackageIdentifier(bareToken))
        {
            return bareToken
        }

        return nil
    }

    private func toggledCommentLine(from line: String, commentOut: Bool) -> String {
        let leadingWhitespace = String(line.prefix { $0.isWhitespace })
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if commentOut {
            guard !trimmed.hasPrefix("#") else { return line }
            return "\(leadingWhitespace)# \(trimmed)"
        }

        guard trimmed.hasPrefix("#") else { return line }
        let uncommented = trimmed.replacingOccurrences(of: #"^#\s*"#, with: "", options: .regularExpression)
        return "\(leadingWhitespace)\(uncommented)"
    }

    private func normalizedPackageIdentifier(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
    
    func uninstallHomebrewCask(token: String) {
        print("UninstallCask called for token: \(token)")
        processingRemovals.insert(token)
        let brewPath = "/opt/homebrew/bin/brew"
        let command = "\(brewPath) uninstall --cask \(token)"
        
        print("Running Homebrew uninstall command with SUDO_ASKPASS: \(command)")
        runElevatedCommandWithAskpass(command: command) { [weak self] status in
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
        
        let brewPath = "/opt/homebrew/bin/brew"
        let command = "\(brewPath) install --cask \(token)"
        
        print("Running Homebrew install command with SUDO_ASKPASS: \(command)")
        runElevatedCommandWithAskpass(command: command) { [weak self] status in
            DispatchQueue.main.async {
                print("Homebrew install command finished with status: \(status)")
                self?.processingInstalls.remove(token)
                if status == 0 {
                    self?.installedTokens.insert(token)
                    NotificationCenter.default.post(name: NSNotification.Name("ReloadApps"), object: nil)
                }
            }
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
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
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
