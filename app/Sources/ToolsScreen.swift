import SwiftUI

struct ToolsScreen: View {
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Installed Tools")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Terminal tools visible in your shell PATH")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)

            Divider()

            if let inventory {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 16) {
                        Text("User: \(inventory.username)")
                            .foregroundColor(.secondary)
                        Text("Host: \(inventory.hostName)")
                            .foregroundColor(.secondary)
                        Text("Last Refresh: \(inventory.generatedAt)")
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)

                    if filteredTools.isEmpty {
                        Spacer()
                        Text(searchText.isEmpty ? "No tools found." : "No tools match your search.")
                            .foregroundColor(.secondary)
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
                    Text("No tool inventory yet.")
                        .font(.headline)
                    Text("Refresh the tool inventory to generate terminal-tool data.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
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
            if inventory == nil {
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
