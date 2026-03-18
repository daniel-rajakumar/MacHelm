import SwiftUI

struct HomeScreen: View {
    var body: some View {
        MacSettingsPage(
            title: "Home",
            subtitle: "Overview of your MacHelm workspace and machine state",
            symbol: "house.fill",
            symbolColor: .orange
        ) {
            MacSettingsIntroCard(
                symbol: "steeringwheel",
                color: .orange,
                title: "MacHelm",
                description: "Manage apps, tools, data exports, and declarative macOS workflows from one native control surface."
            )

            MacSettingsStatGrid(items: [
                MacSettingsStatItem(
                    title: "System Status",
                    value: "Healthy",
                    subtitle: "Current workspace is available",
                    symbol: "checkmark.seal.fill"
                ),
                MacSettingsStatItem(
                    title: "Configuration",
                    value: "flake.nix",
                    subtitle: "Repo-backed system configuration",
                    symbol: "doc.text.fill"
                ),
                MacSettingsStatItem(
                    title: "Data Store",
                    value: "data/",
                    subtitle: "User and machine snapshots",
                    symbol: "externaldrive.fill"
                )
            ])

            MacSettingsSection(title: "Quick Actions") {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rebuild app")
                            .font(.headline)
                        Text("Compile and relaunch the current MacHelm app build.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Button("Restart App") {
                        NSApp.sendAction(#selector(NSApplication.terminate(_:)), to: nil, from: nil)
                    }
                    .buttonStyle(.borderedProminent)
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open data folder")
                            .font(.headline)
                        Text("Reveal the exported workspace data used by the frontend.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Button("Reveal") {
                        NSWorkspace.shared.activateFileViewerSelecting([UserConfigExporter.userDirectoryURL()])
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}

#Preview {
    HomeScreen()
        .frame(width: 1000, height: 700)
}
