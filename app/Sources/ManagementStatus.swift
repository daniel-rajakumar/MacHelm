import Foundation
import SwiftUI

enum ManagementState {
    case managed(String)
    case detected(String)

    var label: String {
        switch self {
        case .managed:
            return "Managed"
        case .detected:
            return "Detected"
        }
    }

    var detail: String {
        switch self {
        case let .managed(detail), let .detected(detail):
            return detail
        }
    }

    var color: Color {
        switch self {
        case .managed:
            return .green
        case .detected:
            return .secondary
        }
    }

    var isManaged: Bool {
        if case .managed = self {
            return true
        }

        return false
    }
}

struct ManagementBadge: View {
    let state: ManagementState

    var body: some View {
        Text(state.label)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(state.color.opacity(0.14))
            .foregroundColor(state.color)
            .clipShape(Capsule())
            .help(state.detail)
    }
}

enum ManagementResolver {
    private static let repoNixFiles = [
        "/Users/danielrajakumar/code/MacHelm/hosts/daniel.nix",
        "/Users/danielrajakumar/code/MacHelm/hosts/macbook.nix"
    ]
    private static let cacheQueue = DispatchQueue(label: "machelm.management-resolver.cache")
    private static var cachedRepoPackageTokens: Set<String>?

    static func invalidateRepoPackageCache() {
        cacheQueue.sync {
            cachedRepoPackageTokens = nil
        }
    }

    static func appState(for app: NixApp, matchingCask: BrewCask?) -> ManagementState {
        switch app.installSource {
        case "Homebrew":
            return .managed("Managed through Homebrew")
        case "Nix":
            return activeRepoPackageTokens().isDisjoint(with: appPackageCandidates(for: app))
                ? .detected("Detected from Nix, but not declared in this repo")
                : .managed("Managed by this repo's Nix configuration")
        case "Others":
            return .managed("Managed as a manually installed app on disk")
        case "System":
            return .detected("Built into macOS")
        case "Mac Store":
            return .detected("Detected from the App Store; no removal flow yet")
        default:
            return matchingCask != nil
                ? .detected("Detected on disk; brew install is available, but this copy is not managed")
                : .detected("Detected on disk only")
        }
    }

    static func toolState(for tool: TerminalToolSnapshot) -> ManagementState {
        switch tool.source {
        case "Homebrew":
            if let installIntent = tool.installIntent {
                return .managed("Managed by Homebrew as a \(installIntent.lowercased()) formula")
            }
            return .managed("Managed by Homebrew")
        case "Nix":
            return activeRepoPackageTokens().isDisjoint(with: toolPackageCandidates(for: tool))
                ? .detected("Detected from Nix paths, but not declared in this repo")
                : .managed("Managed by this repo's Nix configuration")
        case "System":
            return .detected("Built into macOS")
        default:
            return .detected("Detected from the filesystem")
        }
    }

    private static func activeRepoPackageTokens() -> Set<String> {
        if let cached = cacheQueue.sync(execute: { cachedRepoPackageTokens }) {
            return cached
        }

        var tokens = Set<String>()

        for path in repoNixFiles {
            guard let content = try? String(contentsOfFile: path) else { continue }

            for line in content.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.hasPrefix("#") else { continue }

                let codePart = trimmed
                    .components(separatedBy: "#")
                    .first?
                    .trimmingCharacters(in: .whitespaces) ?? ""

                guard !codePart.isEmpty else { continue }

                let nsRange = NSRange(codePart.startIndex..<codePart.endIndex, in: codePart)
                let regex = try? NSRegularExpression(pattern: #"pkgs\.([A-Za-z0-9+._-]+)"#)
                let matches = regex?.matches(in: codePart, range: nsRange) ?? []

                for match in matches {
                    guard let tokenRange = Range(match.range(at: 1), in: codePart) else { continue }
                    tokens.insert(normalizedPackageIdentifier(String(codePart[tokenRange])))
                }

                if codePart.range(of: #"^[A-Za-z0-9+._-]+$"#, options: .regularExpression) != nil {
                    tokens.insert(normalizedPackageIdentifier(codePart))
                }
            }
        }

        cacheQueue.sync {
            cachedRepoPackageTokens = tokens
        }

        return tokens
    }

    private static func appPackageCandidates(for app: NixApp) -> Set<String> {
        var candidates = Set<String>()
        let resolvedPath = URL(fileURLWithPath: app.path).resolvingSymlinksInPath().path

        candidates.insert(normalizedPackageIdentifier(app.name))
        candidates.insert(normalizedPackageIdentifier(((resolvedPath as NSString).deletingPathExtension as NSString).lastPathComponent))

        if let storePackage = storePackageName(from: resolvedPath) {
            candidates.insert(normalizedPackageIdentifier(storePackage))
        }

        return candidates.filter { !$0.isEmpty }
    }

    private static func toolPackageCandidates(for tool: TerminalToolSnapshot) -> Set<String> {
        var candidates = Set<String>()
        candidates.insert(normalizedPackageIdentifier(tool.name))

        if let formulaName = tool.formulaName {
            candidates.insert(normalizedPackageIdentifier(formulaName))
        }

        if let resolvedPath = tool.resolvedPath, let storePackage = storePackageName(from: resolvedPath) {
            candidates.insert(normalizedPackageIdentifier(storePackage))
        }

        return candidates.filter { !$0.isEmpty }
    }

    private static func storePackageName(from path: String) -> String? {
        let components = URL(fileURLWithPath: path).pathComponents
        guard let storeComponent = components.first(where: { $0.contains("-") && !$0.hasPrefix("/") }) else {
            return nil
        }

        let parts = storeComponent.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count >= 2 else { return nil }

        let packageWithVersion = parts.dropFirst().joined(separator: "-")
        if let versionRange = packageWithVersion.range(of: #"-\d"#, options: .regularExpression) {
            return String(packageWithVersion[..<versionRange.lowerBound])
        }

        return packageWithVersion
    }

    private static func normalizedPackageIdentifier(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}
