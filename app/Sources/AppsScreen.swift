import SwiftUI

struct NixApp: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let icon: NSImage?
    
    var installSource: String {
        if path.contains("Nix Apps") || path.contains("Nix-Karabiner") {
            return "Nix-Darwin"
        } else if path.contains("Home Manager Apps") {
            return "Home Manager"
        } else if path.hasPrefix("/System/Applications") {
            return "macOS System"
        } else if path.hasPrefix("/Applications") {
            return "System-wide Application"
        } else {
            return "User Application"
        }
    }
}

struct AppsScreen: View {
    enum FilterCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case nixDarwin = "Nix-Darwin"
        case homeManager = "Home Manager"
        case systemWide = "System-wide Application"
        case macOSSystem = "macOS System"
        case user = "User Application"
        
        var id: String { self.rawValue }
    }

    @State private var apps: [NixApp] = []
    @State private var isLoading = true
    @State private var watchers: [DirectoryWatcher] = []
    @State private var selectedFilter: FilterCategory = .all
    
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
    
    var filteredApps: [NixApp] {
        if selectedFilter == .all {
            return apps
        }
        return apps.filter { $0.installSource == selectedFilter.rawValue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ... (Header and Divider)
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
                VStack(spacing: 0) {
                    Picker("Filter by Source", selection: $selectedFilter) {
                        ForEach(FilterCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
                    
                    if filteredApps.isEmpty {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("No apps found for this category.")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        Spacer()
                    } else {
                        List(filteredApps) { app in
                            AppListRow(app: app)
                        }
                        .listStyle(.plain)
                    }
                }
            }
        }
        .onAppear {
            setupWatchers()
            loadApps()
        }
        .onDisappear {
            stopWatchers()
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
            
            Button("Launch") {
                NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
            }
            .buttonStyle(.bordered)
            .opacity(isHovered ? 1.0 : 0.0)
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
        case "Nix-Darwin", "Home Manager": return "cube.box.fill"
        case "macOS System": return "apple.logo"
        case "System-wide Application": return "macwindow"
        default: return "person.crop.circle"
        }
    }
    
    private func getColorForSource(_ source: String) -> Color {
        switch source {
        case "Nix-Darwin": return .blue
        case "Home Manager": return .purple
        case "macOS System": return .secondary
        case "System-wide Application": return .orange
        default: return .green
        }
    }
}

#Preview {
    AppsScreen()
        .frame(width: 800, height: 600)
}
