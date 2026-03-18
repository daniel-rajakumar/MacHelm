import SwiftUI

struct SystemScreen: View {
    @State private var snapshot = UserConfigExporter.loadSnapshot()
    @State private var dataWatcher: DirectoryWatcher?
    @State private var reloadWorkItem: DispatchWorkItem?

    private let userDataDirectoryURL = UserConfigExporter.userDirectoryURL()
    private let dataFiles = [
        "metadata.json",
        "apps.json",
        "deleted-apps.json",
        "homebrew-casks.json",
        "scan-paths.json",
        "terminal-tools.json",
        "homebrew-formulae.json",
        "homebrew-manual-formulae.json",
        "homebrew-dependency-formulae.json",
        "nix-tools.json",
        "third-party-tools.json",
        "shell-paths.json",
        "filesystem-binaries.json",
        "binary-scan-roots.json"
    ]

    var body: some View {
        MacSettingsPage(
            title: "System",
            subtitle: "Repo-backed machine data and exported inventories",
            symbol: "desktopcomputer",
            symbolColor: .gray
        ) {
            MacSettingsSection(title: "Data Folder") {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current user data")
                            .font(.headline)
                        Text(userDataDirectoryURL.path)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } trailing: {
                    HStack(spacing: 10) {
                        Button("Refresh Data") {
                            snapshot = UserConfigExporter.loadSnapshot()
                        }
                        .buttonStyle(.bordered)

                        Button("Reveal") {
                            NSWorkspace.shared.activateFileViewerSelecting([userDataDirectoryURL])
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }

            if let snapshot {
                MacSettingsStatGrid(items: [
                    MacSettingsStatItem(title: "User", value: snapshot.username, subtitle: snapshot.hostName, symbol: "person.crop.circle"),
                    MacSettingsStatItem(title: "Installed Apps", value: "\(snapshot.installedApps.count)", subtitle: "Across configured scan paths", symbol: "square.grid.2x2.fill"),
                    MacSettingsStatItem(title: "Terminal Tools", value: "\(snapshot.terminalTools.count)", subtitle: "Visible in PATH", symbol: "terminal.fill"),
                    MacSettingsStatItem(title: "Deleted Apps", value: "\(snapshot.deletedApps.count)", subtitle: "Tracked by MacHelm", symbol: "trash.fill"),
                    MacSettingsStatItem(title: "Homebrew Casks", value: "\(snapshot.installedHomebrewCasks.count)", subtitle: "Installed cask tokens", symbol: "shippingbox.fill"),
                    MacSettingsStatItem(title: "Homebrew Formulae", value: "\(snapshot.installedHomebrewFormulae.count)", subtitle: "CLI packages from brew", symbol: "shippingbox"),
                    MacSettingsStatItem(title: "Brew Manual", value: "\(snapshot.manualHomebrewFormulae.count)", subtitle: "Requested by user", symbol: "hand.tap.fill"),
                    MacSettingsStatItem(title: "Brew Dependencies", value: "\(snapshot.dependencyHomebrewFormulae.count)", subtitle: "Pulled in by brew", symbol: "arrow.triangle.branch"),
                    MacSettingsStatItem(title: "Nix Tools", value: "\(snapshot.nixTools.count)", subtitle: "CLI tools from Nix paths", symbol: "cube.box.fill"),
                    MacSettingsStatItem(title: "Third-Party Tools", value: "\(snapshot.thirdPartyTools.count)", subtitle: "Non-system CLI tools", symbol: "wand.and.stars")
                ])

                MacSettingsSection(title: "Data Files", footer: "Last export: \(snapshot.generatedAt)") {
                    ForEach(Array(dataFiles.enumerated()), id: \.offset) { index, fileName in
                        MacSettingsRow(showsDivider: index < dataFiles.count - 1) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fileName)
                                    .font(.headline)
                                Text((userDataDirectoryURL.appendingPathComponent(fileName)).path)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        } trailing: {
                            Button("Reveal") {
                                NSWorkspace.shared.activateFileViewerSelecting([userDataDirectoryURL.appendingPathComponent(fileName)])
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            } else {
                MacSettingsCard {
                    MacSettingsEmptyState(
                        symbol: "externaldrive.badge.questionmark",
                        title: "No data snapshot yet",
                        message: "Open Apps, Tools, or Binaries once to generate the initial user data files."
                    )
                }
            }
        }
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
