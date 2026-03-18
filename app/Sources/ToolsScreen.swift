import SwiftUI

struct ToolsScreen: View {
    private static var lastAutoRefreshAt: Date?
    @AppStorage("machelm.autoRefreshToolsOnOpen") private var autoRefreshOnOpen = true
    @State private var inventory = UserConfigExporter.loadToolInventory()
    @State private var searchText = ""
    @State private var isRefreshing = false
    @State private var dataWatcher: DirectoryWatcher?
    @State private var reloadWorkItem: DispatchWorkItem?

    private var filteredTools: [TerminalToolSnapshot] {
        let tools = inventory?.terminalTools ?? []

        return tools.filter { tool in
            guard !searchText.isEmpty else { return true }
            return tool.name.localizedCaseInsensitiveContains(searchText)
                || tool.path.localizedCaseInsensitiveContains(searchText)
                || tool.source.localizedCaseInsensitiveContains(searchText)
                || tool.pathEntry.localizedCaseInsensitiveContains(searchText)
                || (tool.resolvedPath?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                screenHeader(title: "Tools", subtitle: "Terminal tools visible from the current shell PATH.")
                inventorySection
                toolsContent
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            startWatchingDataDirectory()
            if inventory == nil || shouldAutoRefreshOnAppear {
                refreshInventory()
            } else {
                inventory = UserConfigExporter.loadToolInventory()
            }
        }
        .onDisappear {
            reloadWorkItem?.cancel()
            dataWatcher?.stop()
            dataWatcher = nil
        }
    }

    @ViewBuilder
    private var inventorySection: some View {
        if let inventory {
            MacSettingsSection(title: "Inventory") {
                VStack(spacing: 0) {
                    MacSettingsRow {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Search & Refresh")
                                .font(.headline)
                            MacInlineSearchField(prompt: "Search tools...", text: $searchText)
                        }
                    } trailing: {
                        Button(action: refreshInventory) {
                            if isRefreshing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                        }
                        .buttonStyle(MacSecondaryButtonStyle())
                        .disabled(isRefreshing)
                    }

                    MacSettingsRow(showsDivider: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Environment")
                                .font(.headline)
                            Text("\(inventory.username) on \(inventory.hostName)")
                                .foregroundColor(.secondary)
                        }
                    } trailing: {
                        HStack(spacing: 16) {
                            metricPill("\(filteredTools.count)", label: "Visible")
                            metricPill("\(inventory.terminalTools.count)", label: "Indexed")
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var toolsContent: some View {
        if let _ = inventory {
            if filteredTools.isEmpty {
                MacSettingsCard {
                    MacSettingsEmptyState(
                        symbol: "terminal",
                        title: searchText.isEmpty ? "No tools found" : "No matching tools",
                        message: searchText.isEmpty ? "Refresh the tool inventory to scan your current PATH." : "Try a different search term."
                    )
                }
            } else {
                MacSettingsSection(title: "Installed Tools") {
                    ForEach(Array(filteredTools.enumerated()), id: \.element.id) { index, tool in
                        VStack(spacing: 0) {
                            ToolListRow(tool: tool)

                            if index < filteredTools.count - 1 {
                                MacSettingsDivider()
                            }
                        }
                    }
                }
            }
        } else if isRefreshing {
            MacSettingsCard {
                MacSettingsEmptyState(
                    symbol: "terminal",
                    title: "Scanning terminal tools",
                    message: "MacHelm is rebuilding the current tool inventory."
                )
            }
        } else {
            MacSettingsCard {
                MacSettingsEmptyState(
                    symbol: "terminal",
                    title: "No tool inventory yet",
                    message: "Refresh the tool inventory to generate terminal-tool data."
                )
            }
        }
    }

    private func screenHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 24, weight: .semibold))
            Text(subtitle)
                .font(.system(size: 13.5))
                .foregroundColor(.secondary)
        }
    }

    private func metricPill(_ value: String, label: String) -> some View {
        MacMetricPill(value: value, label: label)
    }

    private var shouldAutoRefreshOnAppear: Bool {
        guard autoRefreshOnOpen else { return false }
        guard let lastAutoRefreshAt = Self.lastAutoRefreshAt else { return true }
        return Date().timeIntervalSince(lastAutoRefreshAt) > 180
    }

    private func refreshInventory() {
        isRefreshing = true
        Self.lastAutoRefreshAt = Date()

        DispatchQueue.global(qos: .userInitiated).async {
            UserConfigExporter.refreshTerminalInventory()
            let reloadedInventory = UserConfigExporter.loadToolInventory()

            DispatchQueue.main.async {
                inventory = reloadedInventory
                isRefreshing = false
            }
        }
    }

    private func startWatchingDataDirectory() {
        guard dataWatcher == nil else { return }

        let watcher = DirectoryWatcher(url: UserConfigExporter.userDirectoryURL()) {
            scheduleInventoryReload()
        }
        watcher.start()
        dataWatcher = watcher
    }

    private func scheduleInventoryReload() {
        reloadWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            let reloadedInventory = UserConfigExporter.loadToolInventory()
            DispatchQueue.main.async {
                inventory = reloadedInventory
            }
        }

        reloadWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
}

private struct ToolListRow: View {
    let tool: TerminalToolSnapshot

    private var managementState: ManagementState {
        ManagementResolver.toolState(for: tool)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            regularContent
            compactContent
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }

    private var regularContent: some View {
        HStack(spacing: 16) {
            iconView
            detailsView
            Spacer()
            actionButtons
        }
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                iconView
                detailsView
            }

            HStack(spacing: 8) {
                Spacer()
                actionButtons
            }
        }
    }

    private var iconView: some View {
        Image(systemName: iconName(for: tool.source))
            .font(.title3)
            .foregroundColor(color(for: tool.source))
            .frame(width: 26)
    }

    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tool.name)
                .font(.headline)

            metadataFlow

            Text(tool.path)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)

            if let resolvedPath = tool.resolvedPath, resolvedPath != tool.path {
                Text(resolvedPath)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Text(managementState.detail)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }

    private var metadataFlow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                metadataItems
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(tool.source)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    ManagementBadge(state: managementState)
                }

                HStack(spacing: 6) {
                    if let installIntent = tool.installIntent {
                        Text(installIntent)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if let formulaName = tool.formulaName {
                        Text(formulaName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(tool.pathEntry)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    @ViewBuilder
    private var metadataItems: some View {
        Text(tool.source)
            .font(.subheadline)
            .foregroundColor(.secondary)
        ManagementBadge(state: managementState)
        if let installIntent = tool.installIntent {
            Text("•")
                .foregroundColor(.secondary)
            Text(installIntent)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        if let formulaName = tool.formulaName {
            Text("•")
                .foregroundColor(.secondary)
            Text(formulaName)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        Text("•")
            .foregroundColor(.secondary)
        Text(tool.pathEntry)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(1)
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button("Reveal") {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: tool.path)])
            }
            .buttonStyle(MacSecondaryButtonStyle())

            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(tool.path, forType: .string)
            }
            .buttonStyle(MacPrimaryButtonStyle())
        }
    }

    private func iconName(for source: String) -> String {
        switch source {
        case "Homebrew":
            return "shippingbox.fill"
        case "Nix":
            return "cube.box.fill"
        case "System":
            return "apple.terminal"
        default:
            return "terminal"
        }
    }

    private func color(for source: String) -> Color {
        switch source {
        case "Homebrew":
            return .orange
        case "Nix":
            return .blue
        case "System":
            return .green
        default:
            return .secondary
        }
    }
}

#Preview {
    ToolsScreen()
        .frame(width: 1000, height: 700)
}
