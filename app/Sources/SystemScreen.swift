import SwiftUI

struct SystemScreen: View {
    @State private var snapshot = UserConfigExporter.loadSnapshot()

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
        "shell-paths.json"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Data")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Frontend reads and updates machine data from the repo data folder")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Data Folder")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(userDataDirectoryURL.path)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Button("Reveal Data Folder") {
                            NSWorkspace.shared.activateFileViewerSelecting([userDataDirectoryURL])
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Refresh Data") {
                            snapshot = UserConfigExporter.loadSnapshot()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Files")
                        .font(.title2)
                        .fontWeight(.semibold)

                    ForEach(dataFiles, id: \.self) { fileName in
                        Text(fileName)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 32)

                if let snapshot {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 16)], spacing: 16) {
                        SummaryCard(title: "User", value: snapshot.username, subtitle: snapshot.hostName, icon: "person.crop.circle")
                        SummaryCard(title: "Installed Apps", value: "\(snapshot.installedApps.count)", subtitle: "Across configured scan paths", icon: "app.window.stack")
                        SummaryCard(title: "Terminal Tools", value: "\(snapshot.terminalTools.count)", subtitle: "Visible in PATH", icon: "terminal")
                        SummaryCard(title: "Deleted Apps", value: "\(snapshot.deletedApps.count)", subtitle: "Tracked by MacHelm", icon: "trash")
                        SummaryCard(title: "Homebrew Casks", value: "\(snapshot.installedHomebrewCasks.count)", subtitle: "Installed cask tokens", icon: "shippingbox")
                        SummaryCard(title: "Homebrew Formulae", value: "\(snapshot.installedHomebrewFormulae.count)", subtitle: "CLI packages from brew", icon: "shippingbox.fill")
                        SummaryCard(title: "Brew Manual", value: "\(snapshot.manualHomebrewFormulae.count)", subtitle: "Requested by user", icon: "hand.tap")
                        SummaryCard(title: "Brew Dependencies", value: "\(snapshot.dependencyHomebrewFormulae.count)", subtitle: "Pulled in by brew", icon: "arrow.triangle.branch")
                        SummaryCard(title: "Nix Tools", value: "\(snapshot.nixTools.count)", subtitle: "CLI tools from Nix paths", icon: "cube.box.fill")
                        SummaryCard(title: "Third-Party Tools", value: "\(snapshot.thirdPartyTools.count)", subtitle: "Non-system CLI tools", icon: "wand.and.stars")
                    }
                    .padding(.horizontal, 32)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last Export")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(snapshot.generatedAt)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 32)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("No data snapshot yet.")
                            .font(.headline)
                        Text("Open the Apps screen once to generate the initial user data files.")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 32)
                }
            }
        }
        .onAppear {
            snapshot = UserConfigExporter.loadSnapshot()
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(value)
                .font(.system(size: 28, weight: .bold))
            Text(subtitle)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}
