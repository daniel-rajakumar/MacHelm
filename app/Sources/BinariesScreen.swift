import SwiftUI

struct BinariesScreen: View {
    private static var lastAutoRefreshAt: Date?
    @AppStorage("machelm.autoRefreshBinariesOnOpen") private var autoRefreshOnOpen = true
    @State private var inventory = UserConfigExporter.loadBinaryInventory()
    @State private var searchText = ""
    @State private var isRefreshing = false
    @State private var dataWatcher: DirectoryWatcher?
    @State private var reloadWorkItem: DispatchWorkItem?

    private var filteredBinaries: [FilesystemBinarySnapshot] {
        let binaries = inventory?.binaries ?? []

        return binaries.filter { binary in
            guard !searchText.isEmpty else { return true }
            return binary.name.localizedCaseInsensitiveContains(searchText)
                || binary.path.localizedCaseInsensitiveContains(searchText)
                || binary.source.localizedCaseInsensitiveContains(searchText)
                || binary.scanRoot.localizedCaseInsensitiveContains(searchText)
                || (binary.resolvedPath?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                screenHeader(title: "Binaries", subtitle: "Filesystem executables discovered under configured scan roots.")
                inventorySection
                binariesContent
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
                inventory = UserConfigExporter.loadBinaryInventory()
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
                            MacInlineSearchField(prompt: "Search binaries...", text: $searchText)
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
                            Text("Scan roots")
                                .font(.headline)
                            Text("\(inventory.username) on \(inventory.hostName)")
                                .foregroundColor(.secondary)
                        }
                    } trailing: {
                        HStack(spacing: 16) {
                            metricPill("\(inventory.scanRoots.count)", label: "Roots")
                            metricPill("\(filteredBinaries.count)", label: "Visible")
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var binariesContent: some View {
        if let _ = inventory {
            if filteredBinaries.isEmpty {
                MacSettingsCard {
                    MacSettingsEmptyState(
                        symbol: "doc.text.magnifyingglass",
                        title: searchText.isEmpty ? "No binaries found" : "No matching binaries",
                        message: searchText.isEmpty ? "Refresh the binary inventory to scan filesystem executables." : "Try a different search term."
                    )
                }
            } else {
                MacSettingsSection(title: "Discovered Binaries") {
                    ForEach(Array(filteredBinaries.enumerated()), id: \.element.id) { index, binary in
                        VStack(spacing: 0) {
                            BinaryListRow(binary: binary)

                            if index < filteredBinaries.count - 1 {
                                MacSettingsDivider()
                            }
                        }
                    }
                }
            }
        } else if isRefreshing {
            MacSettingsCard {
                MacSettingsEmptyState(
                    symbol: "doc.text.magnifyingglass",
                    title: "Scanning filesystem binaries",
                    message: "MacHelm is rebuilding the current binary inventory."
                )
            }
        } else {
            MacSettingsCard {
                MacSettingsEmptyState(
                    symbol: "doc.text.magnifyingglass",
                    title: "No binary inventory yet",
                    message: "Refresh the binary inventory to generate filesystem-binary data."
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
            UserConfigExporter.refreshFilesystemBinaries()
            let reloadedInventory = UserConfigExporter.loadBinaryInventory()

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
            let reloadedInventory = UserConfigExporter.loadBinaryInventory()
            DispatchQueue.main.async {
                inventory = reloadedInventory
            }
        }

        reloadWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
}

private struct BinaryListRow: View {
    let binary: FilesystemBinarySnapshot

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
        Image(systemName: iconName(for: binary.source))
            .font(.title3)
            .foregroundColor(color(for: binary.source))
            .frame(width: 26)
    }

    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(binary.name)
                .font(.headline)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    Text(binary.source)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(binary.scanRoot)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(binary.source)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(binary.scanRoot)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Text(binary.path)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)

            if let resolvedPath = binary.resolvedPath, resolvedPath != binary.path {
                Text(resolvedPath)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button("Reveal") {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: binary.path)])
            }
            .buttonStyle(MacSecondaryButtonStyle())

            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(binary.path, forType: .string)
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
            return "internaldrive"
        default:
            return "doc.text.magnifyingglass"
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
    BinariesScreen()
        .frame(width: 1000, height: 700)
}
