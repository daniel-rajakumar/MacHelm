import SwiftUI

struct NixApp: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let icon: NSImage?
    var installSource: String {
        let fileManager = FileManager.default
        
        // 0. Resolve symlink if needed for accurate source detection
        var actualPath = path
        if let destination = try? fileManager.destinationOfSymbolicLink(atPath: path) {
            // Resolve relative paths if any, and make absolute
            let url = URL(fileURLWithPath: path)
            actualPath = URL(fileURLWithPath: destination, relativeTo: url).path
        }

        // 1. Nix check: based on directory path
        let isNix = actualPath.contains("Nix Apps") || actualPath.contains("Nix-Karabiner") || actualPath.contains("Home Manager Apps") || actualPath.contains("/nix/store")
        if isNix {
            return "Nix"
        }
        
        // 2. Mac App Store check: presence of _MASReceipt
        let isMacStore = fileManager.fileExists(atPath: actualPath + "/Contents/_MASReceipt/receipt")
        if isMacStore {
            return "Mac Store"
        }
        
        // 3. Homebrew check: Check if symlink or if cask directory exists
        var isHomebrew = false
        if actualPath.contains("homebrew") || actualPath.contains("Caskroom") {
            isHomebrew = true
        } else {
            // Rough format match for cask name e.g., "Google Chrome" -> "google-chrome"
            let appNameFormatted = name.lowercased().replacingOccurrences(of: " ", with: "-")
            let caskroom1 = "/opt/homebrew/Caskroom/" + appNameFormatted
            let caskroom2 = "/usr/local/Caskroom/" + appNameFormatted
            if fileManager.fileExists(atPath: caskroom1) || fileManager.fileExists(atPath: caskroom2) {
                isHomebrew = true
            }
        }
        
        if isHomebrew {
            return "Homebrew"
        }
        
        // 4. System check
        if actualPath.hasPrefix("/System/Applications") || actualPath.contains("/Applications/Utilities") {
            return "System"
        }
        
        return "Others"
    }
}

struct AppsScreen: View {
    enum FilterCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case nix = "Nix"
        case homebrew = "Homebrew"
        case macStore = "Mac Store"
        case system = "System"
        case others = "Others"
        case deleted = "Deleted Apps"
        
        var id: String { self.rawValue }
    }

    @StateObject private var stateManager = AppStateManager()
    @State private var apps: [NixApp] = []
    @State private var isLoading = true
    @State private var watchers: [DirectoryWatcher] = []
    @State private var selectedFilter: FilterCategory = .all
    @StateObject private var storeManager = StoreManager()
    @State private var searchText = ""
    
    let scanPaths = [
        "/Applications",
        "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications",
        "/System/Applications",
        "/System/Applications/Utilities",
        // Specific Nix App Directories
        "/Applications/Nix Apps",
        "/Applications/Nix-Karabiner",
        "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications/Home Manager Apps"
    ]
    
    var installableCasks: [BrewCask] {
        let filtered = storeManager.casks.filter { cask in
            if searchText.isEmpty { return true }
            return cask.name.first?.localizedCaseInsensitiveContains(searchText) ?? false || 
                   cask.token.localizedCaseInsensitiveContains(searchText) || 
                   cask.desc?.localizedCaseInsensitiveContains(searchText) ?? false
        }
        return filtered.filter { !stateManager.installedTokens.contains($0.token) }
    }

    var filteredApps: [NixApp] {
        let searchedApps = apps.filter { app in
            if searchText.isEmpty { return true }
            return app.name.localizedCaseInsensitiveContains(searchText) || 
                   app.path.localizedCaseInsensitiveContains(searchText) || 
                   app.installSource.localizedCaseInsensitiveContains(searchText)
        }
        let undeletedApps = searchedApps.filter { !stateManager.isDeleted(appPath: $0.path) }
        if selectedFilter == .all {
            return undeletedApps
        }
        return undeletedApps.filter { $0.installSource == selectedFilter.rawValue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !searchText.isEmpty {
                // Search Results View (Lazy using List and Sections)
                List {
                    if !filteredApps.isEmpty {
                        Section("Installed Apps") {
                            ForEach(filteredApps) { app in
                                AppListRow(app: app, stateManager: stateManager)
                            }
                        }
                    }
                    
                    if !installableCasks.isEmpty {
                        Section("Available to Install") {
                            ForEach(installableCasks) { cask in
                                StoreAppRow(cask: cask, stateManager: stateManager)
                            }
                        }
                    }
                    
                    if filteredApps.isEmpty && installableCasks.isEmpty {
                        Section {
                            VStack {
                                Spacer()
                                Text("No apps match your search.")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                            .frame(height: 300)
                        }
                    }
                }
                .listStyle(.inset)
            } else {
                // Normal Filtered View
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Installed Applications")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("All applications on your Mac")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                    
                    Divider()
                    
                    if isLoading {
                        Spacer()
                        HStack {
                            Spacer()
                            ProgressView("Scanning for apps...")
                            Spacer()
                        }
                        Spacer()
                    } else if apps.isEmpty {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "app.dashed")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("No applications found")
                                    .font(.headline)
                                Text("This is unusual. Are the scan paths correct?")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        Spacer()
                    } else {
                        Picker("Filter by Source", selection: $selectedFilter) {
                            ForEach(FilterCategory.allCases) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        
                        if selectedFilter == .deleted {
                            if stateManager.deletedApps.isEmpty {
                                Spacer()
                                Text("No deleted apps.")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                Spacer()
                            } else {
                                List(stateManager.deletedApps) { deletedApp in
                                    DeletedAppListRow(app: deletedApp, stateManager: stateManager)
                                }
                                .listStyle(.plain)
                            }
                        } else {
                            if filteredApps.isEmpty {
                                Spacer()
                                Text("No apps found for this category.")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                Spacer()
                            } else {
                                List(filteredApps) { app in
                                    AppListRow(app: app, stateManager: stateManager)
                                }
                                .listStyle(.plain)
                            }
                        }
                    }
                }
            }
        }

        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    loadApps()
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .help("Refresh App List")
            }
        }
        .searchable(text: $searchText, prompt: "Search apps...")
        .onAppear {
            setupWatchers()
            loadApps()
            storeManager.fetchCasks()
        }
        .onDisappear {
            stopWatchers()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ReloadApps"))) { _ in
            loadApps()
        }
    }
    
    func setupWatchers() {
        watchers = scanPaths.map { path in
            let url = URL(fileURLWithPath: path)
            let watcher = DirectoryWatcher(url: url) {
                DispatchQueue.main.async {
                    loadApps()
                }
            }
            watcher.start()
            return watcher
        }
    }
    
    func stopWatchers() {
        watchers.forEach { $0.stop() }
        watchers = []
    }
    
    func loadApps() {
        isLoading = apps.isEmpty // Only show loading if we don't have any apps yet
        DispatchQueue.global(qos: .userInitiated).async {
            var loadedApps: [NixApp] = []
            let fileManager = FileManager.default
            
            for scanPath in self.scanPaths {
                guard let contents = try? fileManager.contentsOfDirectory(atPath: scanPath) else { continue }
                
                let pathApps = contents.filter { $0.hasSuffix(".app") }.compactMap { appName -> NixApp? in
                    let fullPath = (scanPath as NSString).appendingPathComponent(appName)
                    let name = (appName as NSString).deletingPathExtension
                    let icon = NSWorkspace.shared.icon(forFile: fullPath)
                    return NixApp(name: name, path: fullPath, icon: icon)
                }
                loadedApps.append(contentsOf: pathApps)
            }
            
            let finalApps = loadedApps.sorted { $0.name.lowercased() < $1.name.lowercased() }
            
            DispatchQueue.main.async {
                self.apps = finalApps
                self.isLoading = false
            }
        }
    }
}

struct AppListRow: View {
    let app: NixApp
    @ObservedObject var stateManager: AppStateManager
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.headline)
                
                HStack(spacing: 6) {
                    Image(systemName: getIconForSource(app.installSource))
                        .foregroundColor(getColorForSource(app.installSource))
                    Text(app.installSource)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if stateManager.processingRemovals.contains(app.path) {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                    Text("Removing...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 8)
            } else if isHovered {
                if app.installSource != "System" {
                    Button("Remove") {
                        withAnimation {
                            stateManager.deleteApp(app: app)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    Text("System Application")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)
                }
            }
            
            Button("Launch") {
                NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
            }
            .buttonStyle(.borderedProminent)
            .disabled(stateManager.processingRemovals.contains(app.path))
            .opacity(isHovered ? 1.0 : 0.4)
            .padding(.leading, 8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
        }
    }
    
    private func getIconForSource(_ source: String) -> String {
        switch source {
        case "Nix": return "cube.box.fill"
        case "Homebrew": return "mug.fill"
        case "Mac Store": return "bag.fill"
        case "System": return "applelogo"
        default: return "app.badge"
        }
    }
    
    private func getColorForSource(_ source: String) -> Color {
        switch source {
        case "Nix": return .blue
        case "Homebrew": return .orange
        case "Mac Store": return .indigo
        case "System": return .primary
        default: return .secondary
        }
    }
}

struct DeletedAppListRow: View {
    let app: DeletedApp
    @ObservedObject var stateManager: AppStateManager
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "trash.slash.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 6) {
                    Image(systemName: getIconForSource(app.installSource))
                        .foregroundColor(getColorForSource(app.installSource))
                        .opacity(0.5)
                    Text(app.installSource)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if stateManager.processingRestores.contains(app.path) {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                    Text("Restoring...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 8)
            } else {
                Button("Restore") {
                    withAnimation {
                        stateManager.restoreApp(deletedApp: app)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
    
    private func getIconForSource(_ source: String) -> String {
        switch source {
        case "Nix": return "cube.box.fill"
        case "Homebrew": return "mug.fill"
        case "Mac Store": return "bag.fill"
        case "System": return "applelogo"
        default: return "app.badge"
        }
    }
    
    private func getColorForSource(_ source: String) -> Color {
        switch source {
        case "Nix": return .blue
        case "Homebrew": return .orange
        case "Mac Store": return .indigo
        case "System": return .primary
        default: return .secondary
        }
    }
}

#Preview {
    AppsScreen()
        .frame(width: 800, height: 600)
}
