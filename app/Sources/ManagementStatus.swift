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
    static func appState(for app: InstalledApp, matchingCask: BrewCask?) -> ManagementState {
        switch app.installSource {
        case "Homebrew":
            return .managed("Managed through Homebrew")
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
        case "System":
            return .detected("Built into macOS")
        default:
            return .detected("Detected from the filesystem")
        }
    }
}
