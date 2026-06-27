import Foundation

enum RepoConfig {
    static let repoRoot = "/Users/danielrajakumar/code/MacHelm"
    static let configRootURL = URL(fileURLWithPath: repoRoot).appendingPathComponent("config", isDirectory: true)

    static func appScanPaths() -> [String] {
        pathList(at: "system/app-scan-paths.json", fallback: [
            "/Applications",
            "$HOME/Applications",
            "/System/Applications",
            "/System/Applications/Utilities"
        ])
    }

    static func binaryScanRoots() -> [String] {
        pathList(at: "system/binary-scan-roots.json", fallback: [
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin",
            "/usr/local/bin",
            "/usr/local/sbin",
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin",
            "/Applications",
            "$HOME/Applications",
            "/System/Applications",
            "/System/Applications/Utilities"
        ])
    }

    static func commandSearchPaths() -> [String] {
        pathList(at: "system/command-search-paths.json", fallback: [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ])
    }

    static func brewExecutableCandidates() -> [String] {
        pathList(at: "system/brew-paths.json", fallback: [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew"
        ])
    }

    static func yabaiExecutableCandidates() -> [String] {
        pathList(at: "yabai/binary-paths.json", fallback: [
            "/opt/homebrew/bin/yabai",
            "/usr/local/bin/yabai"
        ])
    }

    static func commandSearchPathString() -> String {
        commandSearchPaths().joined(separator: ":")
    }

    static func preferredBrewExecutable() -> String? {
        let fileManager = FileManager.default
        return brewExecutableCandidates().first(where: { fileManager.isExecutableFile(atPath: $0) })
            ?? brewExecutableCandidates().first
    }

    private static func pathList(at relativePath: String, fallback: [String]) -> [String] {
        let fileURL = configRootURL.appendingPathComponent(relativePath)

        guard
            let data = try? Data(contentsOf: fileURL),
            let values = try? JSONDecoder().decode([String].self, from: data)
        else {
            return resolvePlaceholders(in: fallback)
        }

        return resolvePlaceholders(in: values)
    }

    private static func resolvePlaceholders(in values: [String]) -> [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return values.map { value in
            value.replacingOccurrences(of: "$HOME", with: home)
        }
    }
}
