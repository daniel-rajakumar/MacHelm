import SwiftUI

struct ToolsScreen: View {
    @AppStorage("machelm.autoRefreshToolsOnOpen") private var autoRefreshOnOpen = true
    @State private var inventory = UserConfigExporter.loadToolInventory()
    @State private var searchText = ""
    @State private var isRefreshing = false

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
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                SettingsSidebarIcon(symbol: "terminal.fill", color: .mint, size: 44)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tools")
                        .font(.system(size: 28, weight: .semibold))
                    Text("Terminal tools visible in your shell PATH")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 32)
            .padding(.bottom, 20)

            if let inventory {
                VStack(alignment: .leading, spacing: 0) {
                    MacSettingsCard {
                        HStack(spacing: 18) {
                            Text("User: \(inventory.username)")
                            Text("Host: \(inventory.hostName)")
                            Text("Last Refresh: \(inventory.generatedAt)")
                            Spacer()
                            Text("\(filteredTools.count) tools")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)

                    if filteredTools.isEmpty {
                        Spacer()
                        MacSettingsEmptyState(
                            symbol: "terminal",
                            title: searchText.isEmpty ? "No tools found" : "No matching tools",
                            message: searchText.isEmpty ? "Refresh the tool inventory to scan your current PATH." : "Try a different search term."
                        )
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        List(filteredTools) { tool in
                            ToolListRow(tool: tool)
                        }
                        .listStyle(.plain)
                    }
                }
            } else if isRefreshing {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView("Scanning terminal tools...")
                    Spacer()
                }
                Spacer()
            } else {
                Spacer()
                VStack(spacing: 12) {
                    MacSettingsEmptyState(
                        symbol: "terminal",
                        title: "No tool inventory yet",
                        message: "Refresh the tool inventory to generate terminal-tool data."
                    )
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: refreshInventory) {
                    if isRefreshing {
                        ProgressView()
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
                .help("Refresh Tool Inventory")
                .disabled(isRefreshing)
            }
        }
        .searchable(text: $searchText, prompt: "Search tools...")
        .onAppear {
            if inventory == nil || autoRefreshOnOpen {
                refreshInventory()
            } else {
                inventory = UserConfigExporter.loadToolInventory()
            }
        }
    }

    private func refreshInventory() {
        isRefreshing = true

        DispatchQueue.global(qos: .userInitiated).async {
            UserConfigExporter.refreshTerminalInventory()
            let reloadedInventory = UserConfigExporter.loadToolInventory()

            DispatchQueue.main.async {
                inventory = reloadedInventory
                isRefreshing = false
            }
        }
    }
}

private struct ToolListRow: View {
    let tool: TerminalToolSnapshot

    private var managementState: ManagementState {
        ManagementResolver.toolState(for: tool)
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName(for: tool.source))
                .font(.title2)
                .foregroundColor(color(for: tool.source))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.name)
                    .font(.headline)

                HStack(spacing: 6) {
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
                    .lineLimit(1)
            }

            Spacer()

            Button("Reveal") {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: tool.path)])
            }
            .buttonStyle(.bordered)

            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(tool.path, forType: .string)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .listRowBackground(Color(NSColor.controlBackgroundColor))
        .listRowSeparator(.hidden)
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
