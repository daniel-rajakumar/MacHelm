import SwiftUI

struct StoreScreen: View {
    @StateObject private var storeManager = StoreManager()
    @StateObject private var stateManager = AppStateManager()
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    SettingsSidebarIcon(symbol: "bag.fill", color: .pink, size: 44)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Store")
                            .font(.system(size: 28, weight: .semibold))
                        Text("Discover and install Homebrew packages")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
                
                if storeManager.isLoading && storeManager.casks.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView("Loading catalog...")
                        Spacer()
                    }
                    Spacer()
                } else if let error = storeManager.errorMessage {
                    Spacer()
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                } else {
                    MacSettingsCard {
                        HStack(spacing: 18) {
                            Text("\(storeManager.filteredCasks.count) available casks")
                            Text("\(stateManager.installedTokens.count) installed tokens")
                            Spacer()
                            Text("Homebrew catalog")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)

                    List(storeManager.filteredCasks) { cask in
                        StoreAppRow(cask: cask, stateManager: stateManager)
                    }
                    .listStyle(.plain)
                    .searchable(text: $storeManager.searchText, prompt: "Search Homebrew (e.g., spotify, vscode...)")
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .onAppear {
            storeManager.fetchCasks()
        }
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
                    // Optionally allow removal
                    Button("Remove") {
                        withAnimation {
                            stateManager.uninstallHomebrewCask(token: cask.token)
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Install") {
                        withAnimation {
                            stateManager.installHomebrewCask(token: cask.token)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .listRowBackground(Color(NSColor.controlBackgroundColor))
        .listRowSeparator(.hidden)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
