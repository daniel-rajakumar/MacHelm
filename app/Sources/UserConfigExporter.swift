import Foundation
import SwiftUI

struct InstalledAppSnapshot: Codable, Identifiable {
    var id: String { path }
    let name: String
    let path: String
    let resolvedPath: String?
    let installSource: String
    let isDeleted: Bool
}

struct UserMetadataSnapshot: Codable {
    let username: String
    let hostName: String
    let generatedAt: String
    let homeDirectory: String
}

struct TerminalToolSnapshot: Codable, Identifiable {
    var id: String { name }
    let name: String
    let path: String
    let resolvedPath: String?
    let source: String
    let pathEntry: String
    let formulaName: String?
    let installIntent: String?

    enum CodingKeys: String, CodingKey {
        case name
        case path
        case resolvedPath
        case source
        case pathEntry
        case formulaName
        case installIntent
    }

    init(
        name: String,
        path: String,
        resolvedPath: String?,
        source: String,
        pathEntry: String,
        formulaName: String? = nil,
        installIntent: String? = nil
    ) {
        self.name = name
        self.path = path
        self.resolvedPath = resolvedPath
        self.source = source
        self.pathEntry = pathEntry
        self.formulaName = formulaName
        self.installIntent = installIntent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        path = try container.decode(String.self, forKey: .path)
        resolvedPath = try container.decodeIfPresent(String.self, forKey: .resolvedPath)
        source = try container.decode(String.self, forKey: .source)
        pathEntry = try container.decode(String.self, forKey: .pathEntry)
        formulaName = try container.decodeIfPresent(String.self, forKey: .formulaName)
        installIntent = try container.decodeIfPresent(String.self, forKey: .installIntent)
    }
}

struct ToolInventorySnapshot {
    let username: String
    let hostName: String
    let generatedAt: String
    let terminalTools: [TerminalToolSnapshot]
    let shellPaths: [String]
    let installedHomebrewFormulae: [String]
    let manualHomebrewFormulae: [String]
    let dependencyHomebrewFormulae: [String]
    let nixTools: [TerminalToolSnapshot]
    let thirdPartyTools: [TerminalToolSnapshot]
}

struct UserConfigSnapshot: Codable {
    let username: String
    let hostName: String
    let generatedAt: String
    let homeDirectory: String
    let scanPaths: [String]
    let installedApps: [InstalledAppSnapshot]
    let deletedApps: [DeletedApp]
    let installedHomebrewCasks: [String]
    let terminalTools: [TerminalToolSnapshot]
    let shellPaths: [String]
    let installedHomebrewFormulae: [String]
    let manualHomebrewFormulae: [String]
    let dependencyHomebrewFormulae: [String]
    let nixTools: [TerminalToolSnapshot]
    let thirdPartyTools: [TerminalToolSnapshot]

    enum CodingKeys: String, CodingKey {
        case username
        case hostName
        case generatedAt
        case homeDirectory
        case scanPaths
        case installedApps
        case deletedApps
        case installedHomebrewCasks
        case terminalTools
        case shellPaths
        case installedHomebrewFormulae
        case manualHomebrewFormulae
        case dependencyHomebrewFormulae
        case nixTools
        case thirdPartyTools
    }

    init(
        username: String,
        hostName: String,
        generatedAt: String,
        homeDirectory: String,
        scanPaths: [String],
        installedApps: [InstalledAppSnapshot],
        deletedApps: [DeletedApp],
        installedHomebrewCasks: [String],
        terminalTools: [TerminalToolSnapshot],
        shellPaths: [String],
        installedHomebrewFormulae: [String],
        manualHomebrewFormulae: [String],
        dependencyHomebrewFormulae: [String],
        nixTools: [TerminalToolSnapshot],
        thirdPartyTools: [TerminalToolSnapshot]
    ) {
        self.username = username
        self.hostName = hostName
        self.generatedAt = generatedAt
        self.homeDirectory = homeDirectory
        self.scanPaths = scanPaths
        self.installedApps = installedApps
        self.deletedApps = deletedApps
        self.installedHomebrewCasks = installedHomebrewCasks
        self.terminalTools = terminalTools
        self.shellPaths = shellPaths
        self.installedHomebrewFormulae = installedHomebrewFormulae
        self.manualHomebrewFormulae = manualHomebrewFormulae
        self.dependencyHomebrewFormulae = dependencyHomebrewFormulae
        self.nixTools = nixTools
        self.thirdPartyTools = thirdPartyTools
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decode(String.self, forKey: .username)
        hostName = try container.decode(String.self, forKey: .hostName)
        generatedAt = try container.decode(String.self, forKey: .generatedAt)
        homeDirectory = try container.decode(String.self, forKey: .homeDirectory)
        scanPaths = try container.decode([String].self, forKey: .scanPaths)
        installedApps = try container.decode([InstalledAppSnapshot].self, forKey: .installedApps)
        deletedApps = try container.decode([DeletedApp].self, forKey: .deletedApps)
        installedHomebrewCasks = try container.decode([String].self, forKey: .installedHomebrewCasks)
        terminalTools = try container.decodeIfPresent([TerminalToolSnapshot].self, forKey: .terminalTools) ?? []
        shellPaths = try container.decodeIfPresent([String].self, forKey: .shellPaths) ?? []
        installedHomebrewFormulae = try container.decodeIfPresent([String].self, forKey: .installedHomebrewFormulae) ?? []
        manualHomebrewFormulae = try container.decodeIfPresent([String].self, forKey: .manualHomebrewFormulae) ?? []
        dependencyHomebrewFormulae = try container.decodeIfPresent([String].self, forKey: .dependencyHomebrewFormulae) ?? []
        nixTools = try container.decodeIfPresent([TerminalToolSnapshot].self, forKey: .nixTools) ?? []
        thirdPartyTools = try container.decodeIfPresent([TerminalToolSnapshot].self, forKey: .thirdPartyTools) ?? []
    }
}

enum UserConfigExporter {
    private static let repoRoot = "/Users/danielrajakumar/code/MacHelm"

    static func dataDirectoryURL() -> URL {
        URL(fileURLWithPath: repoRoot).appendingPathComponent("data", isDirectory: true)
    }

    static func userDirectoryURL(for username: String = NSUserName()) -> URL {
        dataDirectoryURL().appendingPathComponent(username, isDirectory: true)
    }

    static func metadataFileURL(for username: String = NSUserName()) -> URL {
        userDirectoryURL(for: username).appendingPathComponent("metadata.json")
    }

    static func appsFileURL(for username: String = NSUserName()) -> URL {
        userDirectoryURL(for: username).appendingPathComponent("apps.json")
    }

    static func deletedAppsFileURL(for username: String = NSUserName()) -> URL {
        userDirectoryURL(for: username).appendingPathComponent("deleted-apps.json")
    }

    static func homebrewCasksFileURL(for username: String = NSUserName()) -> URL {
        userDirectoryURL(for: username).appendingPathComponent("homebrew-casks.json")
    }

    static func scanPathsFileURL(for username: String = NSUserName()) -> URL {
        userDirectoryURL(for: username).appendingPathComponent("scan-paths.json")
    }

    static func terminalToolsFileURL(for username: String = NSUserName()) -> URL {
        userDirectoryURL(for: username).appendingPathComponent("terminal-tools.json")
    }

    static func shellPathsFileURL(for username: String = NSUserName()) -> URL {
        userDirectoryURL(for: username).appendingPathComponent("shell-paths.json")
    }

    static func homebrewFormulaeFileURL(for username: String = NSUserName()) -> URL {
        userDirectoryURL(for: username).appendingPathComponent("homebrew-formulae.json")
    }

    static func homebrewManualFormulaeFileURL(for username: String = NSUserName()) -> URL {
        userDirectoryURL(for: username).appendingPathComponent("homebrew-manual-formulae.json")
    }

    static func homebrewDependencyFormulaeFileURL(for username: String = NSUserName()) -> URL {
        userDirectoryURL(for: username).appendingPathComponent("homebrew-dependency-formulae.json")
    }

    static func nixToolsFileURL(for username: String = NSUserName()) -> URL {
        userDirectoryURL(for: username).appendingPathComponent("nix-tools.json")
    }

    static func thirdPartyToolsFileURL(for username: String = NSUserName()) -> URL {
        userDirectoryURL(for: username).appendingPathComponent("third-party-tools.json")
    }

    static func loadSnapshot(for username: String = NSUserName()) -> UserConfigSnapshot? {
        migrateLegacyDataIfNeeded(for: username)

        let manualHomebrewFormulae: [String] = loadJSON(from: homebrewManualFormulaeFileURL(for: username)) ?? []
        let dependencyHomebrewFormulae: [String] = loadJSON(from: homebrewDependencyFormulaeFileURL(for: username)) ?? []

        guard
            let metadata: UserMetadataSnapshot = loadJSON(from: metadataFileURL(for: username)),
            let installedApps: [InstalledAppSnapshot] = loadJSON(from: appsFileURL(for: username)),
            let deletedApps: [DeletedApp] = loadJSON(from: deletedAppsFileURL(for: username)),
            let installedHomebrewCasks: [String] = loadJSON(from: homebrewCasksFileURL(for: username)),
            let scanPaths: [String] = loadJSON(from: scanPathsFileURL(for: username)),
            let terminalTools: [TerminalToolSnapshot] = loadJSON(from: terminalToolsFileURL(for: username)),
            let shellPaths: [String] = loadJSON(from: shellPathsFileURL(for: username)),
            let installedHomebrewFormulae: [String] = loadJSON(from: homebrewFormulaeFileURL(for: username)),
            let nixTools: [TerminalToolSnapshot] = loadJSON(from: nixToolsFileURL(for: username)),
            let thirdPartyTools: [TerminalToolSnapshot] = loadJSON(from: thirdPartyToolsFileURL(for: username))
        else {
            return nil
        }

        return UserConfigSnapshot(
            username: metadata.username,
            hostName: metadata.hostName,
            generatedAt: metadata.generatedAt,
            homeDirectory: metadata.homeDirectory,
            scanPaths: scanPaths,
            installedApps: installedApps,
            deletedApps: deletedApps,
            installedHomebrewCasks: installedHomebrewCasks,
            terminalTools: terminalTools,
            shellPaths: shellPaths,
            installedHomebrewFormulae: installedHomebrewFormulae,
            manualHomebrewFormulae: manualHomebrewFormulae,
            dependencyHomebrewFormulae: dependencyHomebrewFormulae,
            nixTools: nixTools,
            thirdPartyTools: thirdPartyTools
        )
    }

    static func loadToolInventory(for username: String = NSUserName()) -> ToolInventorySnapshot? {
        migrateLegacyDataIfNeeded(for: username)

        let manualHomebrewFormulae: [String] = loadJSON(from: homebrewManualFormulaeFileURL(for: username)) ?? []
        let dependencyHomebrewFormulae: [String] = loadJSON(from: homebrewDependencyFormulaeFileURL(for: username)) ?? []

        guard
            let metadata: UserMetadataSnapshot = loadJSON(from: metadataFileURL(for: username)),
            let terminalTools: [TerminalToolSnapshot] = loadJSON(from: terminalToolsFileURL(for: username)),
            let shellPaths: [String] = loadJSON(from: shellPathsFileURL(for: username)),
            let installedHomebrewFormulae: [String] = loadJSON(from: homebrewFormulaeFileURL(for: username)),
            let nixTools: [TerminalToolSnapshot] = loadJSON(from: nixToolsFileURL(for: username)),
            let thirdPartyTools: [TerminalToolSnapshot] = loadJSON(from: thirdPartyToolsFileURL(for: username))
        else {
            return nil
        }

        return ToolInventorySnapshot(
            username: metadata.username,
            hostName: metadata.hostName,
            generatedAt: metadata.generatedAt,
            terminalTools: terminalTools,
            shellPaths: shellPaths,
            installedHomebrewFormulae: installedHomebrewFormulae,
            manualHomebrewFormulae: manualHomebrewFormulae,
            dependencyHomebrewFormulae: dependencyHomebrewFormulae,
            nixTools: nixTools,
            thirdPartyTools: thirdPartyTools
        )
    }

    static func loadDeletedApps(for username: String = NSUserName()) -> [DeletedApp] {
        migrateLegacyDataIfNeeded(for: username)
        return loadJSON(from: deletedAppsFileURL(for: username)) ?? []
    }

    static func saveDeletedApps(_ deletedApps: [DeletedApp], for username: String = NSUserName()) {
        do {
            try ensureUserDirectoryExists(for: username)
            try writeJSON(deletedApps, to: deletedAppsFileURL(for: username))
        } catch {
            print("Failed to write deleted apps data: \(error)")
        }
    }

    static func writeSnapshot(
        apps: [NixApp],
        deletedApps: [DeletedApp],
        installedTokens: Set<String>,
        scanPaths: [String],
        username: String = NSUserName()
    ) {
        let fileManager = FileManager.default

        do {
            try ensureUserDirectoryExists(for: username)
        } catch {
            print("Failed to create user data directory: \(error)")
            return
        }

        let deletedPaths = Set(deletedApps.map(\.path))
        let installedApps = apps.map { app in
            InstalledAppSnapshot(
                name: app.name,
                path: app.path,
                resolvedPath: try? fileManager.destinationOfSymbolicLink(atPath: app.path),
                installSource: app.installSource,
                isDeleted: deletedPaths.contains(app.path)
            )
        }

        let metadata = UserMetadataSnapshot(
            username: username,
            hostName: Host.current().localizedName ?? Host.current().name ?? "Unknown Host",
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            homeDirectory: fileManager.homeDirectoryForCurrentUser.path
        )
        let terminalInventory = terminalInventorySnapshot()

        let sortedApps = installedApps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let sortedDeletedApps = deletedApps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let sortedInstalledTokens = installedTokens.sorted()
        let sortedScanPaths = scanPaths.sorted()

        do {
            try writeJSON(metadata, to: metadataFileURL(for: username))
            try writeJSON(sortedApps, to: appsFileURL(for: username))
            try writeJSON(sortedDeletedApps, to: deletedAppsFileURL(for: username))
            try writeJSON(sortedInstalledTokens, to: homebrewCasksFileURL(for: username))
            try writeJSON(sortedScanPaths, to: scanPathsFileURL(for: username))
            try writeJSON(terminalInventory.terminalTools, to: terminalToolsFileURL(for: username))
            try writeJSON(terminalInventory.shellPaths, to: shellPathsFileURL(for: username))
            try writeJSON(terminalInventory.homebrewFormulae, to: homebrewFormulaeFileURL(for: username))
            try writeJSON(terminalInventory.manualHomebrewFormulae, to: homebrewManualFormulaeFileURL(for: username))
            try writeJSON(terminalInventory.dependencyHomebrewFormulae, to: homebrewDependencyFormulaeFileURL(for: username))
            try writeJSON(terminalInventory.nixTools, to: nixToolsFileURL(for: username))
            try writeJSON(terminalInventory.thirdPartyTools, to: thirdPartyToolsFileURL(for: username))
        } catch {
            print("Failed to write user config snapshot: \(error)")
        }
    }

    static func refreshTerminalInventory(for username: String = NSUserName()) {
        do {
            try ensureUserDirectoryExists(for: username)

            let existingMetadata: UserMetadataSnapshot? = loadJSON(from: metadataFileURL(for: username))
            let metadata = UserMetadataSnapshot(
                username: username,
                hostName: existingMetadata?.hostName ?? Host.current().localizedName ?? Host.current().name ?? "Unknown Host",
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                homeDirectory: existingMetadata?.homeDirectory ?? FileManager.default.homeDirectoryForCurrentUser.path
            )

            let terminalInventory = terminalInventorySnapshot()

            try writeJSON(metadata, to: metadataFileURL(for: username))
            try writeJSON(terminalInventory.terminalTools, to: terminalToolsFileURL(for: username))
            try writeJSON(terminalInventory.shellPaths, to: shellPathsFileURL(for: username))
            try writeJSON(terminalInventory.homebrewFormulae, to: homebrewFormulaeFileURL(for: username))
            try writeJSON(terminalInventory.manualHomebrewFormulae, to: homebrewManualFormulaeFileURL(for: username))
            try writeJSON(terminalInventory.dependencyHomebrewFormulae, to: homebrewDependencyFormulaeFileURL(for: username))
            try writeJSON(terminalInventory.nixTools, to: nixToolsFileURL(for: username))
            try writeJSON(terminalInventory.thirdPartyTools, to: thirdPartyToolsFileURL(for: username))
        } catch {
            print("Failed to refresh terminal inventory: \(error)")
        }
    }

    private static func ensureDataDirectoryExists() throws {
        try FileManager.default.createDirectory(at: dataDirectoryURL(), withIntermediateDirectories: true)
    }

    private static func ensureUserDirectoryExists(for username: String) throws {
        try ensureDataDirectoryExists()
        try FileManager.default.createDirectory(at: userDirectoryURL(for: username), withIntermediateDirectories: true)
    }

    private static func loadJSON<T: Decodable>(from fileURL: URL) -> T? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func writeJSON<T: Encodable>(_ value: T, to fileURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        try data.write(to: fileURL)
    }

    private static func legacySnapshotFileURL(for username: String) -> URL {
        dataDirectoryURL().appendingPathComponent("\(username).json")
    }

    private static func legacyDeletedAppsFileURL() -> URL {
        dataDirectoryURL().appendingPathComponent("deleted-apps.json")
    }

    private static func migrateLegacyDataIfNeeded(for username: String) {
        let userDirectory = userDirectoryURL(for: username)
        let legacySnapshotURL = legacySnapshotFileURL(for: username)
        let legacyDeletedAppsURL = legacyDeletedAppsFileURL()
        let fileManager = FileManager.default

        let userDirectoryExists = fileManager.fileExists(atPath: userDirectory.path)
        let metadataExists = fileManager.fileExists(atPath: metadataFileURL(for: username).path)

        if metadataExists {
            return
        }

        guard
            let legacyData = try? Data(contentsOf: legacySnapshotURL),
            let legacySnapshot = try? JSONDecoder().decode(UserConfigSnapshot.self, from: legacyData)
        else {
            if !userDirectoryExists, let deletedApps: [DeletedApp] = loadJSON(from: legacyDeletedAppsURL) {
                do {
                    try ensureUserDirectoryExists(for: username)
                    try writeJSON(deletedApps, to: deletedAppsFileURL(for: username))
                    try? fileManager.removeItem(at: legacyDeletedAppsURL)
                } catch {
                    print("Failed to migrate legacy deleted apps data: \(error)")
                }
            }
            return
        }

        do {
            try ensureUserDirectoryExists(for: username)

            let metadata = UserMetadataSnapshot(
                username: legacySnapshot.username,
                hostName: legacySnapshot.hostName,
                generatedAt: legacySnapshot.generatedAt,
                homeDirectory: legacySnapshot.homeDirectory
            )

            try writeJSON(metadata, to: metadataFileURL(for: username))
            try writeJSON(legacySnapshot.installedApps, to: appsFileURL(for: username))
            try writeJSON(legacySnapshot.deletedApps, to: deletedAppsFileURL(for: username))
            try writeJSON(legacySnapshot.installedHomebrewCasks, to: homebrewCasksFileURL(for: username))
            try writeJSON(legacySnapshot.scanPaths, to: scanPathsFileURL(for: username))
            try writeJSON(legacySnapshot.terminalTools, to: terminalToolsFileURL(for: username))
            try writeJSON(legacySnapshot.shellPaths, to: shellPathsFileURL(for: username))
            try writeJSON(legacySnapshot.installedHomebrewFormulae, to: homebrewFormulaeFileURL(for: username))
            try writeJSON(legacySnapshot.manualHomebrewFormulae, to: homebrewManualFormulaeFileURL(for: username))
            try writeJSON(legacySnapshot.dependencyHomebrewFormulae, to: homebrewDependencyFormulaeFileURL(for: username))
            try writeJSON(legacySnapshot.nixTools, to: nixToolsFileURL(for: username))
            try writeJSON(legacySnapshot.thirdPartyTools, to: thirdPartyToolsFileURL(for: username))

            try? fileManager.removeItem(at: legacySnapshotURL)
            if fileManager.fileExists(atPath: legacyDeletedAppsURL.path) {
                try? fileManager.removeItem(at: legacyDeletedAppsURL)
            }
        } catch {
            print("Failed to migrate legacy snapshot data: \(error)")
        }
    }

    private static func terminalInventorySnapshot() -> (
        terminalTools: [TerminalToolSnapshot],
        shellPaths: [String],
        homebrewFormulae: [String],
        manualHomebrewFormulae: [String],
        dependencyHomebrewFormulae: [String],
        nixTools: [TerminalToolSnapshot],
        thirdPartyTools: [TerminalToolSnapshot]
    ) {
        let shellPaths = normalizedShellPaths()
        let homebrewFormulaInventory = homebrewFormulaInventory()
        let terminalTools = collectTerminalTools(
            from: shellPaths,
            manualFormulae: Set(homebrewFormulaInventory.manualFormulae),
            dependencyFormulae: Set(homebrewFormulaInventory.dependencyFormulae)
        )

        let nixTools = terminalTools
            .filter { $0.source == "Nix" }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let thirdPartyTools = terminalTools
            .filter { $0.source == "Third-Party" }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        return (
            terminalTools.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending },
            shellPaths,
            homebrewFormulaInventory.formulae,
            homebrewFormulaInventory.manualFormulae,
            homebrewFormulaInventory.dependencyFormulae,
            nixTools,
            thirdPartyTools
        )
    }

    private static func normalizedShellPaths() -> [String] {
        let rawPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
        var seen = Set<String>()
        var orderedPaths: [String] = []

        for entry in rawPath.split(separator: ":").map(String.init) where !entry.isEmpty {
            let standardized = URL(fileURLWithPath: entry).standardizedFileURL.path
            if !seen.contains(standardized) {
                seen.insert(standardized)
                orderedPaths.append(standardized)
            }
        }

        return orderedPaths
    }

    private static func collectTerminalTools(
        from shellPaths: [String],
        manualFormulae: Set<String>,
        dependencyFormulae: Set<String>
    ) -> [TerminalToolSnapshot] {
        let fileManager = FileManager.default
        var toolsByName: [String: TerminalToolSnapshot] = [:]

        for pathEntry in shellPaths {
            guard let children = try? fileManager.contentsOfDirectory(atPath: pathEntry) else { continue }

            for child in children {
                guard toolsByName[child] == nil else { continue }

                let fullPath = (pathEntry as NSString).appendingPathComponent(child)
                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory), !isDirectory.boolValue else {
                    continue
                }

                guard fileManager.isExecutableFile(atPath: fullPath) else { continue }

                let resolvedPath = resolvedExecutablePath(at: fullPath)
                let source = classifyTerminalTool(path: fullPath, resolvedPath: resolvedPath)
                let formulaName = source == "Homebrew" ? extractHomebrewFormulaName(path: fullPath, resolvedPath: resolvedPath) : nil
                let installIntent: String?

                if let formulaName {
                    if manualFormulae.contains(formulaName) {
                        installIntent = "Manual"
                    } else if dependencyFormulae.contains(formulaName) {
                        installIntent = "Dependency"
                    } else {
                        installIntent = nil
                    }
                } else {
                    installIntent = nil
                }

                toolsByName[child] = TerminalToolSnapshot(
                    name: child,
                    path: fullPath,
                    resolvedPath: resolvedPath,
                    source: source,
                    pathEntry: pathEntry,
                    formulaName: formulaName,
                    installIntent: installIntent
                )
            }
        }

        return Array(toolsByName.values)
    }

    private static func classifyTerminalTool(path: String, resolvedPath: String?) -> String {
        let candidates = [path, resolvedPath].compactMap { $0?.lowercased() }

        if candidates.contains(where: { $0.hasPrefix("/usr/bin/") || $0.hasPrefix("/bin/") || $0.hasPrefix("/usr/sbin/") || $0.hasPrefix("/sbin/") }) {
            return "System"
        }

        if candidates.contains(where: {
            $0.contains("/opt/homebrew/")
                || $0.contains("/usr/local/cellar/")
                || $0.contains("/usr/local/homebrew/")
                || $0.hasPrefix("/usr/local/bin/")
                || $0.hasPrefix("/usr/local/sbin/")
        }) {
            return "Homebrew"
        }

        if candidates.contains(where: {
            $0.contains("/nix/store/")
                || $0.contains("/.nix-profile/")
                || $0.contains("/etc/profiles/per-user/")
                || $0.contains("/run/current-system/sw/")
                || $0.contains("/nix/var/nix/profiles/")
        }) {
            return "Nix"
        }

        return "Third-Party"
    }

    private static func resolvedExecutablePath(at path: String) -> String? {
        guard let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: path) else {
            return nil
        }

        if destination.hasPrefix("/") {
            return URL(fileURLWithPath: destination).standardizedFileURL.path
        }

        let parentURL = URL(fileURLWithPath: path).deletingLastPathComponent()
        return URL(fileURLWithPath: destination, relativeTo: parentURL).standardizedFileURL.path
    }

    private static func extractHomebrewFormulaName(path: String, resolvedPath: String?) -> String? {
        let candidates = [resolvedPath, path].compactMap { $0 }

        for candidate in candidates {
            if let range = candidate.range(of: "/Cellar/") {
                let suffix = candidate[range.upperBound...]
                return suffix.split(separator: "/").first.map(String.init)
            }

            if let range = candidate.range(of: "Cellar/") {
                let suffix = candidate[range.upperBound...]
                return suffix.split(separator: "/").first.map(String.init)
            }

            if let range = candidate.range(of: "/opt/") {
                let suffix = candidate[range.upperBound...]
                return suffix.split(separator: "/").first.map(String.init)
            }
        }

        return nil
    }

    private static func homebrewFormulaInventory() -> (formulae: [String], manualFormulae: [String], dependencyFormulae: [String]) {
        let output = runCommand([
            "/bin/zsh",
            "-lc",
            "if command -v brew >/dev/null 2>&1; then brew info --json=v2 --installed; fi"
        ])

        guard
            !output.isEmpty,
            let data = output.data(using: .utf8),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let formulae = root["formulae"] as? [[String: Any]]
        else {
            return ([], [], [])
        }

        var allFormulae: [String] = []
        var manualFormulae: [String] = []
        var dependencyFormulae: [String] = []

        for formula in formulae {
            guard let name = formula["name"] as? String else { continue }
            allFormulae.append(name)

            let installMetadata = (formula["installed"] as? [[String: Any]])?.first
            if installMetadata?["installed_on_request"] as? Bool == true {
                manualFormulae.append(name)
            }
            if installMetadata?["installed_as_dependency"] as? Bool == true {
                dependencyFormulae.append(name)
            }
        }

        return (allFormulae.sorted(), manualFormulae.sorted(), dependencyFormulae.sorted())
    }

    private static func runCommandAndSplitLines(_ arguments: [String]) -> [String] {
        runCommand(arguments)
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func runCommand(_ arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: arguments[0])
        process.arguments = Array(arguments.dropFirst())

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            guard process.terminationStatus == 0 else {
                return ""
            }
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            print("Failed to run terminal inventory command: \(error)")
            return ""
        }
    }
}
