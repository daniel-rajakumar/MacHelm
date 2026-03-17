import SwiftUI

struct StoreScreen: View {
    @StateObject private var storeManager = StoreManager()
    @StateObject private var stateManager = AppStateManager()
    @State private var searchText = ""
    
    var filteredCasks: [BrewCask] {
        if searchText.isEmpty {
            return storeManager.casks
        } else {
            return storeManager.casks.filter { cask in
                cask.name.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) ||
                cask.token.localizedCaseInsensitiveContains(searchText) ||
                (cask.desc?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("App Store")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Discover and install Homebrew packages")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                
                Divider()
                
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
                    List(filteredCasks) { cask in
                        StoreAppRow(cask: cask, stateManager: stateManager)
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Search Homebrew (e.g., spotify, vscode...)")
                }
            }
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
            Image(systemName: "square.grid.2x2.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .foregroundColor(.accentColor)
                .opacity(0.8)
            
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
                Button("Install") {
                    withAnimation {
                        stateManager.installHomebrewCask(token: cask.token)
                    }
                }
                .buttonStyle(.borderedProminent)
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
