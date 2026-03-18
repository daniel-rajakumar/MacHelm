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
            case .data:
                return "externaldrive"
            case .support:
                return "questionmark.circle"
            }
        }

        var group: Group {
            switch self {
            case .general, .refresh, .sidebar:
                return .preferences
            case .data:
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
            case .data:
                return "Inspect repo-backed data paths and current exported inventory."
            case .support:
                return "Quick actions and operational status for the current workspace."
            }
        }
    }

    @Binding var selectedCategory: Category
    @AppStorage("machelm.autoRefreshToolsOnOpen") private var autoRefreshToolsOnOpen = true
    @AppStorage("machelm.autoRefreshBinariesOnOpen") private var autoRefreshBinariesOnOpen = true
    @AppStorage("machelm.showToolsTab") private var showToolsTab = true
    @AppStorage("machelm.showBinariesTab") private var showBinariesTab = true
    @State private var snapshot = UserConfigExporter.loadSnapshot()
    @State private var dataWatcher: DirectoryWatcher?
    @State private var reloadWorkItem: DispatchWorkItem?

    private let dataDirectoryURL = UserConfigExporter.dataDirectoryURL()
    private let userDataDirectoryURL = UserConfigExporter.userDirectoryURL()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedCategory.title)
                        .font(.system(size: 24, weight: .semibold))
                    Text(selectedCategory.subtitle)
                        .font(.system(size: 13.5))
                        .foregroundColor(.secondary)
                }

                currentCategoryView
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            startWatchingDataDirectory()
            snapshot = UserConfigExporter.loadSnapshot()
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
        case .data:
            dataSettingsView
        case .support:
            supportSettingsView
        }
    }

    private var generalSettingsView: some View {
        VStack(alignment: .leading, spacing: 24) {
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
        VStack(alignment: .leading, spacing: 24) {
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
        VStack(alignment: .leading, spacing: 24) {
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
        VStack(alignment: .leading, spacing: 24) {
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
        VStack(alignment: .leading, spacing: 24) {
            SettingsDetailSection(title: "Quick Actions") {
                SettingsActionRow(
                    title: "Refresh snapshot",
                    description: "Reload the current repo-backed user snapshot from disk.",
                    buttonTitle: "Reload"
                ) {
                    snapshot = UserConfigExporter.loadSnapshot()
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

private struct SettingsDetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
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
                            .font(.system(size: 15, weight: .semibold))
                        Text(description)
                            .font(.system(size: 13))
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
                            .font(.system(size: 15, weight: .semibold))
                        Text(description)
                            .font(.system(size: 13))
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
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

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
                            .font(.system(size: 15, weight: .semibold))
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 12)

                    Text(value)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Text(value)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

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
                            .font(.system(size: 15, weight: .semibold))
                        Text(description)
                            .font(.system(size: 13))
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
                            .font(.system(size: 15, weight: .semibold))
                        Text(description)
                            .font(.system(size: 13))
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
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

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
