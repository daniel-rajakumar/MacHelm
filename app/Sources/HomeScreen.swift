import SwiftUI

struct HomeScreen: View {
    @State private var snapshot = UserConfigExporter.loadSnapshot()
    @State private var toolInventory = UserConfigExporter.loadToolInventory()
    @State private var binaryInventory = UserConfigExporter.loadBinaryInventory()
    @State private var dataWatcher: DirectoryWatcher?
    @State private var reloadWorkItem: DispatchWorkItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                screenHeader(title: "Home", subtitle: "Overview of the current MacHelm workspace, inventory state, and repo-backed data.")
                overviewSection
                inventorySection
                quickActionsSection
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            startWatchingDataDirectory()
            reloadData()
        }
        .onDisappear {
            reloadWorkItem?.cancel()
            dataWatcher?.stop()
            dataWatcher = nil
        }
    }

    private var overviewSection: some View {
        MacSettingsSection(title: "Workspace") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Repo")
                            .font(.headline)
                        Text("/Users/danielrajakumar/code/MacHelm")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } trailing: {
                    homeBadge(title: "Active")
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("User data")
                            .font(.headline)
                        Text(UserConfigExporter.userDirectoryURL().path)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } trailing: {
                    homeBadge(title: snapshot == nil ? "Missing" : "Ready")
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last snapshot")
                            .font(.headline)
                        Text(snapshot?.generatedAt ?? "No snapshot generated yet")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    homeBadge(title: Host.current().localizedName ?? "Mac")
                }
            }
        }
    }

    private var inventorySection: some View {
        MacSettingsSection(title: "Inventories") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Applications")
                            .font(.headline)
                        Text("Installed GUI apps discovered by MacHelm.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    inventoryValue("\(snapshot?.installedApps.count ?? 0)")
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Terminal tools")
                            .font(.headline)
                        Text("Commands visible from the current shell PATH.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    inventoryValue("\(toolInventory?.terminalTools.count ?? 0)")
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Filesystem binaries")
                            .font(.headline)
                        Text("Executables discovered under configured scan roots.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    inventoryValue("\(binaryInventory?.binaries.count ?? 0)")
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Deleted apps")
                            .font(.headline)
                        Text("Items currently tracked in the deleted-apps state file.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    inventoryValue("\(snapshot?.deletedApps.count ?? 0)")
                }
            }
        }
    }

    private var quickActionsSection: some View {
        MacSettingsSection(title: "Quick Actions") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open user data folder")
                            .font(.headline)
                        Text("Reveal the repo-backed user directory in Finder.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Button("Reveal") {
                        NSWorkspace.shared.activateFileViewerSelecting([UserConfigExporter.userDirectoryURL()])
                    }
                    .buttonStyle(MacSecondaryButtonStyle())
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reload overview")
                            .font(.headline)
                        Text("Refresh the Home dashboard from the current data files.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Button("Reload") {
                        reloadData()
                    }
                    .buttonStyle(MacPrimaryButtonStyle())
                }
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

    private func homeBadge(title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(red: 0.27, green: 0.63, blue: 0.18))
            )
    }

    private func inventoryValue(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.primary)
            .frame(minWidth: 42, alignment: .trailing)
    }

    private func reloadData() {
        snapshot = UserConfigExporter.loadSnapshot()
        toolInventory = UserConfigExporter.loadToolInventory()
        binaryInventory = UserConfigExporter.loadBinaryInventory()
    }

    private func startWatchingDataDirectory() {
        guard dataWatcher == nil else { return }

        let watcher = DirectoryWatcher(url: UserConfigExporter.userDirectoryURL()) {
            scheduleReload()
        }
        watcher.start()
        dataWatcher = watcher
    }

    private func scheduleReload() {
        reloadWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            DispatchQueue.main.async {
                reloadData()
            }
        }

        reloadWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
}

#Preview {
    HomeScreen()
        .frame(width: 1000, height: 700)
}
