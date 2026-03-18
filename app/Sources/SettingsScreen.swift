import SwiftUI

struct SettingsScreen: View {
    @AppStorage("machelm.autoRefreshToolsOnOpen") private var autoRefreshToolsOnOpen = true
    @AppStorage("machelm.autoRefreshBinariesOnOpen") private var autoRefreshBinariesOnOpen = true
    @AppStorage("machelm.showToolsTab") private var showToolsTab = true
    @AppStorage("machelm.showBinariesTab") private var showBinariesTab = true

    private let dataDirectoryURL = UserConfigExporter.dataDirectoryURL()
    private let userDataDirectoryURL = UserConfigExporter.userDirectoryURL()

    var body: some View {
        MacSettingsPage(
            title: "Settings",
            subtitle: "Preferences and workspace paths for MacHelm",
            symbol: "gearshape.fill",
            symbolColor: .green
        ) {
            MacSettingsSection(title: "Inventory Refresh") {
                SettingsToggleRow(
                    title: "Auto-refresh Tools",
                    description: "Refresh terminal-tool data whenever the Tools screen opens.",
                    isOn: $autoRefreshToolsOnOpen
                )

                SettingsToggleRow(
                    title: "Auto-refresh Binaries",
                    description: "Refresh filesystem-binary data whenever the Binaries screen opens.",
                    isOn: $autoRefreshBinariesOnOpen,
                    showsDivider: false
                )
            }

            MacSettingsSection(title: "Sidebar") {
                SettingsToggleRow(
                    title: "Show Tools Tab",
                    description: "Display the Tools section in the sidebar.",
                    isOn: $showToolsTab
                )

                SettingsToggleRow(
                    title: "Show Binaries Tab",
                    description: "Display the Binaries section in the sidebar.",
                    isOn: $showBinariesTab,
                    showsDivider: false
                )
            }

            MacSettingsSection(title: "Data Paths") {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Shared data folder")
                            .font(.headline)
                        Text(dataDirectoryURL.path)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } trailing: {
                    Button("Reveal") {
                        NSWorkspace.shared.activateFileViewerSelecting([dataDirectoryURL])
                    }
                    .buttonStyle(.bordered)
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current user folder")
                            .font(.headline)
                        Text(userDataDirectoryURL.path)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } trailing: {
                    Button("Reveal") {
                        NSWorkspace.shared.activateFileViewerSelecting([userDataDirectoryURL])
                    }
                    .buttonStyle(.bordered)
                }
            }

            MacSettingsSection(
                title: "Actions",
                footer: "Use the toolbar refresh actions in Apps, Tools, and Binaries when you want to regenerate inventories immediately."
            ) {
                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("App behavior")
                            .font(.headline)
                        Text("These preferences are stored locally and applied automatically on screen open.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    var showsDivider = true

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Text(description)
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
                            .font(.headline)
                        Text(description)
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
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            if showsDivider {
                Divider()
                    .padding(.leading, 20)
            }
        }
    }
}

#Preview {
    SettingsScreen()
        .frame(width: 1000, height: 700)
}
