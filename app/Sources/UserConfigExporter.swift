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

struct UserConfigSnapshot: Codable {
    let username: String
    let hostName: String
    let generatedAt: String
    let homeDirectory: String
    let scanPaths: [String]
    let installedApps: [InstalledAppSnapshot]
    let deletedApps: [DeletedApp]
    let installedHomebrewCasks: [String]
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

    static func loadSnapshot(for username: String = NSUserName()) -> UserConfigSnapshot? {
        migrateLegacyDataIfNeeded(for: username)

        guard
            let metadata: UserMetadataSnapshot = loadJSON(from: metadataFileURL(for: username)),
            let installedApps: [InstalledAppSnapshot] = loadJSON(from: appsFileURL(for: username)),
            let deletedApps: [DeletedApp] = loadJSON(from: deletedAppsFileURL(for: username)),
            let installedHomebrewCasks: [String] = loadJSON(from: homebrewCasksFileURL(for: username)),
            let scanPaths: [String] = loadJSON(from: scanPathsFileURL(for: username))
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
            installedHomebrewCasks: installedHomebrewCasks
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
        } catch {
            print("Failed to write user config snapshot: \(error)")
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

            try? fileManager.removeItem(at: legacySnapshotURL)
            if fileManager.fileExists(atPath: legacyDeletedAppsURL.path) {
                try? fileManager.removeItem(at: legacyDeletedAppsURL)
            }
        } catch {
            print("Failed to migrate legacy snapshot data: \(error)")
        }
    }
}
