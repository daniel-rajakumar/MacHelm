import SwiftUI

struct SettingsScreen: View {
    enum Category: String, CaseIterable, Identifiable {
        enum Group: CaseIterable {
            case preferences
            case workspace
            case system

            var title: String {
                switch self {
                case .preferences:
                    return "Preferences"
                case .workspace:
                    return "Workspace"
                case .system:
                    return "System"
                }
            }
        }

        case general
        case refresh
        case sidebar
        case github
        case data
        case support

        var id: String { rawValue }

        var title: String {
            switch self {
            case .general:
                return "General"
            case .refresh:
                return "Refresh"
            case .sidebar:
                return "Sidebar"
            case .github:
                return "GitHub"
            case .data:
                return "Data"
            case .support:
                return "Support"
            }
        }

        var symbol: String {
            switch self {
            case .general:
                return "gearshape"
            case .refresh:
                return "arrow.clockwise"
            case .sidebar:
                return "sidebar.left"
            case .github:
                return "person.crop.circle"
            case .data:
                return "externaldrive"
            case .support:
                return "questionmark.circle"
            }
        }

        var iconColor: Color {
            switch self {
            case .general:
                return Color(red: 0.72, green: 0.72, blue: 0.74)
            case .refresh:
                return .blue
            case .sidebar:
                return .indigo
            case .github:
                return Color(red: 0.18, green: 0.18, blue: 0.2)
            case .data:
                return .teal
            case .support:
                return .orange
            }
        }

        var group: Group {
            switch self {
            case .general, .refresh, .sidebar:
                return .preferences
            case .github, .data:
                return .workspace
            case .support:
                return .system
            }
        }

        var subtitle: String {
            switch self {
            case .general:
                return "Core MacHelm behavior and workspace preferences."
            case .refresh:
                return "Control automatic inventory refresh for tools and binaries."
            case .sidebar:
                return "Choose which management tabs are visible in the main sidebar."
            case .github:
                return "Sync your MacHelm configuration across Macs with GitHub."
            case .data:
                return "Inspect repo-backed data paths and current exported inventory."
            case .support:
                return "Quick actions and operational status for the current workspace."
            }
        }
    }

    @Binding var selectedCategory: Category
    var syncManager: GitHubSyncManager? = nil
    @AppStorage("machelm.autoRefreshToolsOnOpen") private var autoRefreshToolsOnOpen = true
    @AppStorage("machelm.autoRefreshBinariesOnOpen") private var autoRefreshBinariesOnOpen = true
    @AppStorage("machelm.showToolsTab") private var showToolsTab = true
    @AppStorage("machelm.showBinariesTab") private var showBinariesTab = true
    @State private var snapshot: UserConfigSnapshot?
    @State private var dataWatcher: DirectoryWatcher?
    @State private var reloadWorkItem: DispatchWorkItem?

    private let dataDirectoryURL = UserConfigExporter.dataDirectoryURL()
    private let userDataDirectoryURL = UserConfigExporter.userDirectoryURL()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SettingsCategoryHeader(category: selectedCategory)

                currentCategoryView
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 34)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            startWatchingDataDirectory()
            loadSnapshot()
        }
        .onDisappear {
            reloadWorkItem?.cancel()
            dataWatcher?.stop()
            dataWatcher = nil
        }
    }

    @ViewBuilder
    private var currentCategoryView: some View {
        switch selectedCategory {
        case .general:
            generalSettingsView
        case .refresh:
            refreshSettingsView
        case .sidebar:
            sidebarSettingsView
        case .github:
            if let syncManager = syncManager {
                GitHubSyncScreen(syncManager: syncManager)
            } else {
                Text("Sync manager unavailable.")
                    .foregroundColor(.secondary)
            }
        case .data:
            dataSettingsView
        case .support:
            supportSettingsView
        }
    }

    private var generalSettingsView: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsDetailSection(title: "Overview") {
                SettingsInfoRow(
                    title: "Current user",
                    description: snapshot?.username ?? NSUserName(),
                    value: snapshot?.hostName ?? Host.current().localizedName ?? "Unknown Mac"
                )

                SettingsInfoRow(
                    title: "Visible management tabs",
                    description: "Root-level utility sections currently visible in the app shell.",
                    value: "\(visibleUtilityTabCount)"
                )

                SettingsInfoRow(
                    title: "Last data export",
                    description: snapshot?.generatedAt ?? "Not available",
                    value: snapshot == nil ? "Missing" : "Available",
                    showsDivider: false
                )
            }

            SettingsDetailSection(title: "Behavior") {
                SettingsToggleDetailRow(
                    title: "Auto-refresh tools on open",
                    description: "Refresh terminal-tool data when the Tools screen opens.",
                    isOn: $autoRefreshToolsOnOpen
                )

                SettingsToggleDetailRow(
                    title: "Auto-refresh binaries on open",
                    description: "Refresh filesystem-binary data when the Binaries screen opens.",
                    isOn: $autoRefreshBinariesOnOpen,
                    showsDivider: false
                )
            }
        }
    }

    private var refreshSettingsView: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsDetailSection(title: "Automatic Refresh") {
                SettingsToggleDetailRow(
                    title: "Refresh Tools Automatically",
                    description: "Keeps terminal-tool inventory fresh whenever the Tools view is opened.",
                    isOn: $autoRefreshToolsOnOpen
                )

                SettingsToggleDetailRow(
                    title: "Refresh Binaries Automatically",
                    description: "Rebuilds the filesystem binary inventory when the Binaries view is opened.",
                    isOn: $autoRefreshBinariesOnOpen,
                    showsDivider: false
                )
            }

            SettingsDetailSection(title: "Manual Refresh") {
                SettingsInfoRow(
                    title: "Apps",
                    description: "Use the refresh action in the Apps header to rescan installed applications.",
                    value: "Manual"
                )

                SettingsInfoRow(
                    title: "Tools & Binaries",
                    description: "Each inventory screen can still be refreshed manually even if auto-refresh is disabled.",
                    value: "Available",
                    showsDivider: false
                )
            }
        }
    }

    private var sidebarSettingsView: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsDetailSection(title: "Main Sidebar") {
                SettingsToggleDetailRow(
                    title: "Show Tools Tab",
                    description: "Display the Tools section in the main navigation.",
                    isOn: $showToolsTab
                )

                SettingsToggleDetailRow(
                    title: "Show Binaries Tab",
                    description: "Display the Binaries section in the main navigation.",
                    isOn: $showBinariesTab,
                    showsDivider: false
                )
            }
        }
    }

    private var dataSettingsView: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsDetailSection(title: "Data Paths") {
                SettingsActionRow(
                    title: "Shared data folder",
                    description: dataDirectoryURL.path,
                    buttonTitle: "Reveal"
                ) {
                    NSWorkspace.shared.activateFileViewerSelecting([dataDirectoryURL])
                }

                SettingsActionRow(
                    title: "Current user folder",
                    description: userDataDirectoryURL.path,
                    buttonTitle: "Reveal",
                    showsDivider: false
                ) {
                    NSWorkspace.shared.activateFileViewerSelecting([userDataDirectoryURL])
                }
            }

            SettingsDetailSection(title: "Export Snapshot") {
                SettingsInfoRow(
                    title: "Installed apps",
                    description: "Applications discovered across configured scan paths.",
                    value: "\(snapshot?.installedApps.count ?? 0)"
                )

                SettingsInfoRow(
                    title: "Terminal tools",
                    description: "Commands visible in the current shell PATH.",
                    value: "\(snapshot?.terminalTools.count ?? 0)"
                )

                SettingsInfoRow(
                    title: "Deleted apps",
                    description: "Apps currently tracked in MacHelm's deleted list.",
                    value: "\(snapshot?.deletedApps.count ?? 0)"
                )

                SettingsInfoRow(
                    title: "Homebrew casks",
                    description: "Installed GUI packages discovered from Homebrew.",
                    value: "\(snapshot?.installedHomebrewCasks.count ?? 0)",
                    showsDivider: false
                )
            }
        }
    }

    private var supportSettingsView: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsDetailSection(title: "Quick Actions") {
                SettingsActionRow(
                    title: "Refresh snapshot",
                    description: "Reload the current repo-backed user snapshot from disk.",
                    buttonTitle: "Reload"
                ) {
                    loadSnapshot()
                }

                SettingsActionRow(
                    title: "Open shared data folder",
                    description: "Reveal the root data directory in Finder.",
                    buttonTitle: "Reveal"
                ) {
                    NSWorkspace.shared.activateFileViewerSelecting([dataDirectoryURL])
                }

                SettingsActionRow(
                    title: "Open user data folder",
                    description: "Reveal the current user's data directory in Finder.",
                    buttonTitle: "Reveal",
                    showsDivider: false
                ) {
                    NSWorkspace.shared.activateFileViewerSelecting([userDataDirectoryURL])
                }
            }

            SettingsDetailSection(title: "Status") {
                SettingsInfoRow(
                    title: "Workspace mode",
                    description: "MacHelm is reading and writing repo-backed data from the local checkout.",
                    value: "Active"
                )

                SettingsInfoRow(
                    title: "Current export state",
                    description: snapshot?.generatedAt ?? "No snapshot has been generated yet.",
                    value: snapshot == nil ? "Missing" : "Healthy",
                    showsDivider: false
                )
            }
        }
    }

    private var visibleUtilityTabCount: Int {
        [showToolsTab, showBinariesTab].filter { $0 }.count
    }

    private func loadSnapshot() {
        DispatchQueue.global(qos: .userInitiated).async {
            let reloadedSnapshot = UserConfigExporter.loadSnapshot()
            DispatchQueue.main.async {
                snapshot = reloadedSnapshot
            }
        }
    }

    private func startWatchingDataDirectory() {
        guard dataWatcher == nil else { return }

        let watcher = DirectoryWatcher(url: userDataDirectoryURL) {
            scheduleSnapshotReload()
        }
        watcher.start()
        dataWatcher = watcher
    }

    private func scheduleSnapshotReload() {
        reloadWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            let reloadedSnapshot = UserConfigExporter.loadSnapshot()
            DispatchQueue.main.async {
                snapshot = reloadedSnapshot
            }
        }

        reloadWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
}

struct SettingsDetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

private struct SettingsCategoryHeader: View {
    let category: SettingsScreen.Category

    var body: some View {
        VStack(spacing: 8) {
            SettingsSidebarIcon(symbol: category.symbol, color: category.iconColor, size: 52)

            Text(category.title)
                .font(.system(size: 24, weight: .semibold))

            Text(category.subtitle)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
        .padding(.bottom, 2)
    }
}

private struct SettingsToggleDetailRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    var showsDivider = true

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 13.5, weight: .regular))
                        Text(description)
                            .font(.system(size: 12.5))
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 12)

                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 13.5, weight: .regular))
                        Text(description)
                            .font(.system(size: 12.5))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Spacer(minLength: 0)
                        Toggle("", isOn: $isOn)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if showsDivider {
                MacSettingsDivider()
            }
        }
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let description: String
    let value: String
    var showsDivider = true

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 13.5, weight: .regular))
                        Text(description)
                            .font(.system(size: 12.5))
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 12)

                    Text(value)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 13.5, weight: .regular))
                        Text(description)
                            .font(.system(size: 12.5))
                            .foregroundColor(.secondary)
                    }

                    Text(value)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if showsDivider {
                MacSettingsDivider()
            }
        }
    }
}

private struct SettingsActionRow: View {
    let title: String
    let description: String
    let buttonTitle: String
    var showsDivider = true
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 13.5, weight: .regular))
                        Text(description)
                            .font(.system(size: 12.5))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }

                    Spacer(minLength: 12)

                    Button(buttonTitle, action: action)
                        .buttonStyle(MacSecondaryButtonStyle())
                }

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 13.5, weight: .regular))
                        Text(description)
                            .font(.system(size: 12.5))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }

                    HStack {
                        Spacer(minLength: 0)
                        Button(buttonTitle, action: action)
                            .buttonStyle(MacSecondaryButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if showsDivider {
                MacSettingsDivider()
            }
        }
    }
}

#Preview {
    SettingsScreen(selectedCategory: .constant(.general))
        .frame(width: 1000, height: 700)
}
