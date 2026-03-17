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

    static func snapshotFileURL(for username: String = NSUserName()) -> URL {
        dataDirectoryURL().appendingPathComponent("\(username).json")
    }

    static func deletedAppsFileURL() -> URL {
        dataDirectoryURL().appendingPathComponent("deleted-apps.json")
    }

    static func loadSnapshot(for username: String = NSUserName()) -> UserConfigSnapshot? {
        let fileURL = snapshotFileURL(for: username)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(UserConfigSnapshot.self, from: data)
    }

    static func loadDeletedApps() -> [DeletedApp] {
        let fileURL = deletedAppsFileURL()
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([DeletedApp].self, from: data)) ?? []
    }

    static func saveDeletedApps(_ deletedApps: [DeletedApp]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            try ensureDataDirectoryExists()
            let data = try encoder.encode(deletedApps)
            try data.write(to: deletedAppsFileURL())
        } catch {
            print("Failed to write deleted apps data: \(error)")
        }
    }

    static func writeSnapshot(
        apps: [NixApp],
        deletedApps: [DeletedApp],
        installedTokens: Set<String>,
        scanPaths: [String]
    ) {
        let fileManager = FileManager.default

        do {
            try ensureDataDirectoryExists()
        } catch {
            print("Failed to create data directory: \(error)")
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

        let snapshot = UserConfigSnapshot(
            username: NSUserName(),
            hostName: Host.current().localizedName ?? Host.current().name ?? "Unknown Host",
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            homeDirectory: fileManager.homeDirectoryForCurrentUser.path,
            scanPaths: scanPaths,
            installedApps: installedApps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending },
            deletedApps: deletedApps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending },
            installedHomebrewCasks: installedTokens.sorted()
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(snapshot)
            try data.write(to: snapshotFileURL())
        } catch {
            print("Failed to write user config snapshot: \(error)")
        }
    }

    private static func ensureDataDirectoryExists() throws {
        try FileManager.default.createDirectory(at: dataDirectoryURL(), withIntermediateDirectories: true)
    }
}
