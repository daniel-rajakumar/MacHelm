import SwiftUI

struct StoreScreen: View {
    @ObservedObject var storeManager: StoreManager
    @ObservedObject var stateManager: AppStateManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                screenHeader(title: "Store", subtitle: "Install and manage Homebrew casks from a repo-backed catalog.")
                controlsSection
                contentSection
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            storeManager.fetchCasks()
        }
    }

    private var controlsSection: some View {
        MacSettingsSection(title: "Catalog") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search Homebrew")
                            .font(.headline)
                        MacInlineSearchField(
                            prompt: "Search Homebrew (e.g. spotify, vscode...)",
                            text: $storeManager.searchText
                        )
                    }
                } trailing: {
                    if storeManager.isLoading {
                        ProgressView()
                            .frame(width: 28)
                    } else {
                        Image(systemName: "shippingbox")
                            .foregroundColor(.secondary)
                            .frame(width: 28)
                    }
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Source")
                            .font(.headline)
                        Text("Homebrew catalog")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    HStack(spacing: 16) {
                            metricPill("\(storeManager.filteredCasks.count)", label: "Available")
                            metricPill("\(stateManager.installedTokens.count)", label: "Installed")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        if storeManager.isLoading && storeManager.casks.isEmpty {
            MacSettingsCard {
                MacSettingsEmptyState(
                    symbol: "shippingbox",
                    title: "Loading catalog",
                    message: "MacHelm is fetching the current Homebrew cask catalog."
                )
            }
        } else if let error = storeManager.errorMessage {
            MacSettingsCard {
                MacSettingsEmptyState(
                    symbol: "exclamationmark.triangle",
                    title: "Catalog error",
                    message: error
                )
            }
        } else if storeManager.filteredCasks.isEmpty {
            MacSettingsCard {
                MacSettingsEmptyState(
                    symbol: "shippingbox",
                    title: "No matching casks",
                    message: "Try a different search term."
                )
            }
        } else {
            MacSettingsSection(title: "Homebrew Casks") {
                LazyVStack(spacing: 0) {
                    ForEach(Array(storeManager.filteredCasks.enumerated()), id: \.element.id) { index, cask in
                        VStack(spacing: 0) {
                            StoreAppRow(cask: cask, stateManager: stateManager)

                            if index < storeManager.filteredCasks.count - 1 {
                                MacSettingsDivider()
                            }
                        }
                    }
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

    private func metricPill(_ value: String, label: String) -> some View {
        MacMetricPill(value: value, label: label)
    }
}

struct StoreAppRow: View {
    let cask: BrewCask
    @ObservedObject var stateManager: AppStateManager

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            if let url = cask.iconURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .cornerRadius(8)
                    } else if phase.error != nil {
                        Image(systemName: "square.grid.2x2.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .foregroundColor(.accentColor)
                            .opacity(0.8)
                    } else {
                        ProgressView()
                            .frame(width: 48, height: 48)
                    }
                }
            } else {
                Image(systemName: "square.grid.2x2.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .foregroundColor(.accentColor)
                    .opacity(0.8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(cask.name.first ?? cask.token)
                    .font(.headline)

                if let desc = cask.desc {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    if let version = cask.version {
                        Text("v\(version)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("Homebrew")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if stateManager.processingInstalls.contains(cask.token) {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                    Text("Installing...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 8)
            } else {
                if stateManager.installedTokens.contains(cask.token) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Installed")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 8)
                    Button("Remove") {
                        withAnimation {
                            stateManager.uninstallHomebrewCask(token: cask.token)
                        }
                    }
                    .buttonStyle(MacSecondaryButtonStyle())
                } else {
                    Button("Install") {
                        withAnimation {
                            stateManager.installHomebrewCask(token: cask.token)
                        }
                    }
                    .buttonStyle(MacPrimaryButtonStyle())
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
