import SwiftUI

struct BinariesScreen: View {
    @AppStorage("machelm.autoRefreshBinariesOnOpen") private var autoRefreshOnOpen = true
    @State private var inventory = UserConfigExporter.loadBinaryInventory()
    @State private var searchText = ""
    @State private var isRefreshing = false

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
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                SettingsSidebarIcon(symbol: "doc.text.magnifyingglass", color: .indigo, size: 44)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Binaries")
                        .font(.system(size: 28, weight: .semibold))
                    Text("Executable files discovered across common binary and application roots")
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
                            Text("\(inventory.scanRoots.count) scan roots")
                                .foregroundColor(.secondary)
                            Text("\(filteredBinaries.count) binaries")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 32)
                        .padding(.bottom, 16)

                    if filteredBinaries.isEmpty {
                        Spacer()
                        MacSettingsEmptyState(
                            symbol: "doc.text.magnifyingglass",
                            title: searchText.isEmpty ? "No binaries found" : "No matching binaries",
                            message: searchText.isEmpty ? "Refresh the binary inventory to scan filesystem executables." : "Try a different search term."
                        )
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        List(filteredBinaries) { binary in
                            BinaryListRow(binary: binary)
                        }
                        .listStyle(.plain)
                    }
                }
            } else if isRefreshing {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView("Scanning filesystem binaries...")
                    Spacer()
                }
                Spacer()
            } else {
                Spacer()
                VStack(spacing: 12) {
                    MacSettingsEmptyState(
                        symbol: "doc.text.magnifyingglass",
                        title: "No binary inventory yet",
                        message: "Refresh the binary inventory to generate filesystem-binary data."
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
                .help("Refresh Binary Inventory")
                .disabled(isRefreshing)
            }
        }
        .searchable(text: $searchText, prompt: "Search binaries...")
        .onAppear {
            if inventory == nil || autoRefreshOnOpen {
                refreshInventory()
            } else {
                inventory = UserConfigExporter.loadBinaryInventory()
            }
        }
    }

    private func refreshInventory() {
        isRefreshing = true

        DispatchQueue.global(qos: .userInitiated).async {
            UserConfigExporter.refreshFilesystemBinaries()
            let reloadedInventory = UserConfigExporter.loadBinaryInventory()

            DispatchQueue.main.async {
                inventory = reloadedInventory
                isRefreshing = false
            }
        }
    }
}

private struct BinaryListRow: View {
    let binary: FilesystemBinarySnapshot

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName(for: binary.source))
                .font(.title2)
                .foregroundColor(color(for: binary.source))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(binary.name)
                    .font(.headline)

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

            Spacer()

            Button("Reveal") {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: binary.path)])
            }
            .buttonStyle(.bordered)

            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(binary.path, forType: .string)
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
