import SwiftUI

struct HomeScreen: View {
    @State private var snapshot: UserConfigSnapshot?
    @State private var toolInventory: ToolInventorySnapshot?
    @State private var binaryInventory: BinaryInventorySnapshot?
    @State private var dataWatcher: DirectoryWatcher?
    @State private var reloadWorkItem: DispatchWorkItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                screenHeader(title: "Home", subtitle: "Manage your Mac apps, settings, windows, and saved MacHelm data from one place.")
                safetySection
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
        MacSettingsSection(title: "Saved Data") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MacHelm folder")
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
                        Text("Your saved Mac data")
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
                        Text("Last scan")
                            .font(.headline)
                        Text(snapshot?.generatedAt ?? "No scan has been saved yet")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    homeBadge(title: Host.current().localizedName ?? "Mac")
                }
            }
        }
    }

    private var safetySection: some View {
        MacSettingsCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.green)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 6) {
                    Text("You stay in control")
                        .font(.headline)
                    Text("MacHelm shows what it finds first. Actions that install, remove, restore, sync, or change services ask before they run.")
                        .font(.system(size: 13.5))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var inventorySection: some View {
        MacSettingsSection(title: "What MacHelm Found") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Applications")
                            .font(.headline)
                        Text("Mac apps found in common Applications folders.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    inventoryValue("\(snapshot?.installedApps.count ?? 0)")
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Command-line tools")
                            .font(.headline)
                        Text("Advanced tools available in Terminal.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    inventoryValue("\(toolInventory?.terminalTools.count ?? 0)")
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Advanced executables")
                            .font(.headline)
                        Text("Executable files found in folders MacHelm scans.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    inventoryValue("\(binaryInventory?.binaries.count ?? 0)")
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apps removed with MacHelm")
                            .font(.headline)
                        Text("Apps MacHelm can remember for restore or review.")
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
                        Text("Reveal the folder where MacHelm saves this Mac's scan data.")
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
                        Text("Refresh this page from the latest saved MacHelm data.")
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
                    .fill(Color.accentColor)
            )
    }

    private func inventoryValue(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.primary)
            .frame(minWidth: 42, alignment: .trailing)
    }

    private func reloadData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let reloadedSnapshot = UserConfigExporter.loadSnapshot()
            let reloadedToolInventory = UserConfigExporter.loadToolInventory()
            let reloadedBinaryInventory = UserConfigExporter.loadBinaryInventory()

            DispatchQueue.main.async {
                snapshot = reloadedSnapshot
                toolInventory = reloadedToolInventory
                binaryInventory = reloadedBinaryInventory
            }
        }
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
            reloadData()
        }

        reloadWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
}

#Preview {
    HomeScreen()
        .frame(width: 1000, height: 700)
}
