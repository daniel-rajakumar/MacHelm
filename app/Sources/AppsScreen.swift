import SwiftUI

struct NixApp: Identifiable, Equatable {
    let id: String
    let name: String
    let path: String
    let installSource: String

    init(name: String, path: String, installSource: String) {
        self.id = path
        self.name = name
        self.path = path
        self.installSource = installSource
    }

    static func detectInstallSource(name: String, path: String) -> String {
        let fileManager = FileManager.default
        
        // 0. Resolve symlink to get the real path on the system
        let actualPath = URL(fileURLWithPath: path).resolvingSymlinksInPath().path
        
        if name == "Safari" {
            print("DEBUG: Safari detection - Original: \(path), Resolved: \(actualPath)")
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
            // Check multiple name variations for better Homebrew matching (e.g., zoom.us -> zoom)
            var baseName = name.lowercased()
            
            // Handle hidden apps (e.g., .Karabiner-VirtualHIDDevice-Manager)
            if baseName.hasPrefix(".") {
                baseName = String(baseName.dropFirst())
            }
            
            var candidates = [
                baseName.replacingOccurrences(of: " ", with: "-"),
                baseName.replacingOccurrences(of: ".us", with: ""),
                baseName.replacingOccurrences(of: ".com", with: ""),
                baseName.replacingOccurrences(of: "-desktop", with: ""),
                baseName.replacingOccurrences(of: " x", with: ""), // CleanShot X -> cleanshot
                baseName.replacingOccurrences(of: " pro", with: "") 
            ]
            
            // Add a more aggressive dash-only candidate
            let alphanumericOnly = baseName.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "-")
            candidates.append(alphanumericOnly)
            
            // Prefix-based matching: if app name starts with a word found in Caskroom
            // e.g., "Karabiner-EventViewer" starts with "karabiner"
            let words = baseName.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
            if let firstWord = words.first {
                candidates.append(firstWord)
            }
            
            // Additional check: maybe the cask name is a prefix or suffix of the app name?
            // We'll check the Caskroom directory for any folder that matches a substring of the app name.
            let caskroomPath = "/opt/homebrew/Caskroom/"
            if let caskroomFolders = try? fileManager.contentsOfDirectory(atPath: caskroomPath) {
                for folder in caskroomFolders {
                    let folderLower = folder.lowercased()
                    // If "cleanshot" is in "cleanshot x", it's a match
                    // If "karabiner" is a prefix of "karabiner-elements", it's a match
                    if baseName.contains(folderLower) || alphanumericOnly.contains(folderLower) || folderLower.hasPrefix(words.first ?? "") {
                        // Special case: don't match too-short prefixes to avoid false positives
                        if (words.first?.count ?? 0) > 3 {
                            isHomebrew = true
                            break
                        }
                    }
                }
            }
            
            if !isHomebrew {
                for candidate in Set(candidates) where !candidate.isEmpty {
                    let caskroom1 = "/opt/homebrew/Caskroom/" + candidate
                    let caskroom2 = "/usr/local/Caskroom/" + candidate
                    if fileManager.fileExists(atPath: caskroom1) || fileManager.fileExists(atPath: caskroom2) {
                        isHomebrew = true
                        break
                    }
                }
            }
        }
        
        if isHomebrew {
            return "Homebrew"
        }
        
        // 4. System check
        if actualPath.hasPrefix("/System/") || actualPath.contains("/Applications/Utilities") {
            return "System"
        }
        
        return "Others"
    }

    static func == (lhs: NixApp, rhs: NixApp) -> Bool {
        lhs.name == rhs.name
            && lhs.path == rhs.path
            && lhs.installSource == rhs.installSource
    }
}

final class AppsScreenModel: ObservableObject {
    static let defaultScanPaths = [
        "/Applications",
        "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications",
        "/System/Applications",
        "/System/Applications/Utilities",
        "/Applications/Nix Apps",
        "/Applications/Nix-Karabiner",
        "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications/Home Manager Apps"
    ]

    @Published var apps: [NixApp] = []
    @Published var isLoading = true

    private var hasStarted = false
    private var dataWatcher: DirectoryWatcher?
    private var reloadWorkItem: DispatchWorkItem?

    func start(scanPaths: [String]) {
        guard !hasStarted else { return }
        hasStarted = true
        startWatchingUserData()

        if !loadAppsFromSnapshot() {
            loadApps(scanPaths: scanPaths)
        }
    }

    func refresh(scanPaths: [String], completion: (() -> Void)? = nil) {
        loadApps(scanPaths: scanPaths, completion: completion)
    }

    private func loadApps(scanPaths: [String], completion: (() -> Void)? = nil) {
        let shouldShowLoading = apps.isEmpty
        DispatchQueue.main.async {
            self.isLoading = shouldShowLoading
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var loadedApps: [NixApp] = []
            let fileManager = FileManager.default

            for scanPath in scanPaths {
                guard let contents = try? fileManager.contentsOfDirectory(atPath: scanPath) else { continue }

                let pathApps = contents.filter { $0.hasSuffix(".app") }.compactMap { appName -> NixApp? in
                    let fullPath = (scanPath as NSString).appendingPathComponent(appName)
                    let name = (appName as NSString).deletingPathExtension
                    let installSource = NixApp.detectInstallSource(name: name, path: fullPath)
                    return NixApp(name: name, path: fullPath, installSource: installSource)
                }
                loadedApps.append(contentsOf: pathApps)
            }

            let finalApps = loadedApps.sorted { $0.name.lowercased() < $1.name.lowercased() }

            DispatchQueue.main.async {
                self.apps = finalApps
                self.isLoading = false
                completion?()
            }
        }
    }

    private func startWatchingUserData() {
        let userDirectoryURL = UserConfigExporter.userDirectoryURL()
        let watcher = DirectoryWatcher(url: userDirectoryURL) { [weak self] in
            self?.scheduleSnapshotReload()
        }
        watcher.start()
        dataWatcher = watcher
    }

    private func scheduleSnapshotReload() {
        reloadWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            _ = self?.loadAppsFromSnapshot()
        }

        reloadWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }

    @discardableResult
    private func loadAppsFromSnapshot() -> Bool {
        let persistedApps = UserConfigExporter.loadInstalledApps().map { snapshot in
            return NixApp(
                name: snapshot.name,
                path: snapshot.path,
                installSource: snapshot.installSource
            )
        }

        guard !persistedApps.isEmpty else { return false }

        DispatchQueue.main.async {
            self.apps = persistedApps
            self.isLoading = false
        }

        return true
    }

    deinit {
        reloadWorkItem?.cancel()
        dataWatcher?.stop()
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

    @ObservedObject var stateManager: AppStateManager
    @ObservedObject var storeManager: StoreManager
    @ObservedObject var model: AppsScreenModel
    @Binding var selectedFilter: FilterCategory
    @State private var searchText = ""
    @State private var visibleAppRows: [AppRowItem] = []
    @State private var visibleInstallableCasks: [BrewCask] = []
    
    let scanPaths = AppsScreenModel.defaultScanPaths

    private struct AppRowItem: Identifiable {
        let app: NixApp
        let matchingCask: BrewCask?
        let managementState: ManagementState

        var id: String { app.id }
    }
    
    var body: some View {
        withBindings(appliedTo: baseContent)
    }

    private var baseContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                screenHeader(title: "Apps", subtitle: "Applications discovered across system, user, and managed locations.")
                controlsSection
                contentSection
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func withBindings<Content: View>(appliedTo content: Content) -> some View {
        let reloadBound = content.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ReloadApps"))) { _ in
            model.refresh(scanPaths: scanPaths) {
                exportUserSnapshot()
            }
        }

        let deletedAppsBound = reloadBound.onChange(of: stateManager.deletedApps) { _, _ in
            exportUserSnapshot()
            recomputeVisibleContent()
        }

        let installedTokensBound = deletedAppsBound.onChange(of: stateManager.installedTokens) { _, _ in
            exportUserSnapshot()
            recomputeVisibleContent()
        }

        let appsBound = installedTokensBound.onChange(of: model.apps) { _, _ in
            exportUserSnapshot()
            recomputeVisibleContent()
        }

        let searchBound = appsBound.onChange(of: searchText) { _, _ in
            recomputeVisibleContent()
        }

        let filterBound = searchBound.onChange(of: selectedFilter) { _, _ in
            recomputeVisibleContent()
        }

        let casksBound = filterBound.onChange(of: storeManager.casks) { _, _ in
            recomputeVisibleContent()
        }

        return casksBound.onAppear {
            recomputeVisibleContent()
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        if model.isLoading && model.apps.isEmpty {
            MacSettingsCard {
                MacSettingsEmptyState(
                    symbol: "app.badge",
                    title: "Scanning applications",
                    message: "MacHelm is refreshing the installed app inventory."
                )
            }
        } else if model.apps.isEmpty {
            MacSettingsCard {
                MacSettingsEmptyState(
                    symbol: "app.dashed",
                    title: "No applications found",
                    message: "MacHelm did not find any apps in the configured scan paths."
                )
            }
        } else if !searchText.isEmpty {
            VStack(alignment: .leading, spacing: 24) {
                if !visibleAppRows.isEmpty {
                    appRowsSection(title: "Installed Apps", rows: visibleAppRows)
                }

                if !visibleInstallableCasks.isEmpty {
                    storeRowsSection(title: "Available to Install", casks: visibleInstallableCasks)
                }

                if visibleAppRows.isEmpty && visibleInstallableCasks.isEmpty {
                    MacSettingsCard {
                        MacSettingsEmptyState(
                            symbol: "magnifyingglass",
                            title: "No apps match your search",
                            message: "Try a different name, path, or source filter."
                        )
                    }
                }
            }
        } else if selectedFilter == .deleted {
            if stateManager.deletedApps.isEmpty {
                MacSettingsCard {
                    MacSettingsEmptyState(
                        symbol: "trash",
                        title: "No deleted apps",
                        message: "Removed apps will appear here after you delete them from MacHelm."
                    )
                }
            } else {
                deletedAppsSection
            }
        } else if visibleAppRows.isEmpty {
            MacSettingsCard {
                MacSettingsEmptyState(
                    symbol: "square.grid.2x2",
                    title: "No apps in this category",
                    message: "Switch filters or refresh the inventory to repopulate this section."
                )
            }
        } else {
            appRowsSection(title: selectedFilter.rawValue, rows: visibleAppRows)
        }
    }

    private var controlsSection: some View {
        MacSettingsSection(title: "Inventory") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search & Refresh")
                            .font(.headline)
                        MacInlineSearchField(prompt: "Search apps...", text: $searchText)
                    }
                } trailing: {
                    Button(action: {
                        model.refresh(scanPaths: scanPaths) {
                            exportUserSnapshot()
                        }
                        runAppBuildInBackground()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(MacSecondaryButtonStyle())
                    .help("Refresh App List")
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current filter")
                            .font(.headline)
                        Text(selectedFilter.rawValue)
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    HStack(spacing: 16) {
                        metricPill("\(visibleAppRows.count)", label: "Visible")
                        metricPill("\(stateManager.deletedApps.count)", label: "Deleted")
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

    private func appRowsSection(title: String, rows: [AppRowItem]) -> some View {
        MacSettingsSection(title: title) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, item in
                VStack(spacing: 0) {
                    AppListRow(
                        app: item.app,
                        matchingCask: item.matchingCask,
                        managementState: item.managementState,
                        stateManager: stateManager
                    )

                    if index < rows.count - 1 {
                        MacSettingsDivider()
                    }
                }
            }
        }
    }

    private func storeRowsSection(title: String, casks: [BrewCask]) -> some View {
        MacSettingsSection(title: title) {
            ForEach(Array(casks.enumerated()), id: \.element.id) { index, cask in
                VStack(spacing: 0) {
                    StoreAppRow(cask: cask, stateManager: stateManager)

                    if index < casks.count - 1 {
                        MacSettingsDivider()
                    }
                }
            }
        }
    }

    private var deletedAppsSection: some View {
        MacSettingsSection(title: "Deleted Apps") {
            ForEach(Array(stateManager.deletedApps.enumerated()), id: \.element.id) { index, deletedApp in
                VStack(spacing: 0) {
                    DeletedAppListRow(app: deletedApp, stateManager: stateManager)

                    if index < stateManager.deletedApps.count - 1 {
                        MacSettingsDivider()
                    }
                }
            }
        }
    }

    func exportUserSnapshot() {
        let apps = model.apps
        let deletedApps = stateManager.deletedApps
        let installedTokens = stateManager.installedTokens
        let scanPaths = scanPaths

        DispatchQueue.global(qos: .utility).async {
            UserConfigExporter.writeSnapshot(
                apps: apps,
                deletedApps: deletedApps,
                installedTokens: installedTokens,
                scanPaths: scanPaths
            )
        }
    }

    private func runAppBuildInBackground() {
        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            task.arguments = ["-lc", "cd /Users/danielrajakumar/code/MacHelm/app && swift build >/dev/null 2>&1"]

            do {
                try task.run()
            } catch {
                print("Failed to start background app build: \(error)")
            }
        }
    }

    private func matchingCask(for app: NixApp) -> BrewCask? {
        let baseName = app.name.lowercased()
        let alphanumericOnly = baseName.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "-")

        return storeManager.caskLookup[baseName] ?? storeManager.caskLookup[alphanumericOnly]
    }

    private func recomputeVisibleContent() {
        let apps = model.apps
        let deletedPaths = Set(stateManager.deletedApps.map(\.path))
        let selectedFilter = selectedFilter
        let searchText = searchText
        let casks = storeManager.casks
        let caskLookup = storeManager.caskLookup
        let installedTokens = stateManager.installedTokens

        DispatchQueue.global(qos: .userInitiated).async {
            let searchedApps = apps.filter { app in
                if searchText.isEmpty { return true }
                return app.name.localizedCaseInsensitiveContains(searchText)
                    || app.path.localizedCaseInsensitiveContains(searchText)
                    || app.installSource.localizedCaseInsensitiveContains(searchText)
            }

            let undeletedApps = searchedApps.filter { !deletedPaths.contains($0.path) }
            let filteredApps = selectedFilter == .all
                ? undeletedApps
                : undeletedApps.filter { $0.installSource == selectedFilter.rawValue }

            let appRows = filteredApps.map { app in
                let baseName = app.name.lowercased()
                let alphanumericOnly = baseName.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "-")
                let matchingCask = caskLookup[baseName] ?? caskLookup[alphanumericOnly]
                return AppRowItem(
                    app: app,
                    matchingCask: matchingCask,
                    managementState: ManagementResolver.appState(for: app, matchingCask: matchingCask)
                )
            }

            let installableCasks = casks.filter { cask in
                if !searchText.isEmpty {
                    let matchesSearch = cask.name.first?.localizedCaseInsensitiveContains(searchText) ?? false
                        || cask.token.localizedCaseInsensitiveContains(searchText)
                        || cask.desc?.localizedCaseInsensitiveContains(searchText) ?? false
                    if !matchesSearch {
                        return false
                    }
                }

                return !installedTokens.contains(cask.token)
            }

            DispatchQueue.main.async {
                self.visibleAppRows = appRows
                self.visibleInstallableCasks = Array(installableCasks.prefix(100))
            }
        }
    }
}

struct AppListRow: View {
    let app: NixApp
    let matchingCask: BrewCask?
    let managementState: ManagementState
    @ObservedObject var stateManager: AppStateManager
    
    @State private var isHovered = false
    
    var body: some View {
        ViewThatFits(in: .horizontal) {
            regularContent
            compactContent
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

    private var regularContent: some View {
        HStack(spacing: 14) {
            appIcon

            appDetails

            Spacer(minLength: 8)

            actionCluster
        }
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                appIcon
                appDetails
            }

            HStack(spacing: 8) {
                actionCluster
            }
        }
    }

    private var appIcon: some View {
        LazyAppIcon(path: app.path)
        .frame(width: 40, height: 40)
    }

    private var appDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(app.name)
                .font(.headline)
                .lineLimit(1)
            
            HStack(spacing: 6) {
                Image(systemName: getIconForSource(app.installSource))
                    .foregroundColor(getColorForSource(app.installSource))
                Text(app.installSource)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ManagementBadge(state: managementState)
            }

            Text(managementState.detail)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var actionCluster: some View {
        if stateManager.processingRemovals.contains(app.path) {
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 16, height: 16)
                Text("Removing...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } else if let matchingCask = matchingCask, stateManager.processingInstalls.contains(matchingCask.token) {
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 16, height: 16)
                Text("Brewing...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } else if let matchingCask = matchingCask, stateManager.processingUpgrades.contains(matchingCask.token) {
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 16, height: 16)
                Text("Upgrading...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } else if isHovered {
            if app.installSource == "Homebrew" {
                if let token = matchingCask?.token, stateManager.outdatedTokens.contains(token) {
                    Button("Upgrade") {
                        withAnimation {
                            stateManager.upgradeHomebrewCask(token: token)
                        }
                    }
                    .buttonStyle(MacSecondaryButtonStyle())
                }

                Button {
                    withAnimation {
                        stateManager.deleteApp(app: app)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(MacDestructiveButtonStyle())
            } else if managementState.isManaged {
                Button {
                    withAnimation {
                        stateManager.deleteApp(app: app)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(MacDestructiveButtonStyle())
            } else {
                Text("Detected only")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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

private struct LazyAppIcon: View {
    let path: String

    @State private var icon: NSImage?

    var body: some View {
        Group {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.secondary)
                    .padding(6)
            }
        }
        .task(id: path) {
            if let cached = AppIconCache.shared.image(for: path) {
                icon = cached
                return
            }

            DispatchQueue.main.async {
                let loadedIcon = NSWorkspace.shared.icon(forFile: path)
                AppIconCache.shared.setImage(loadedIcon, for: path)
                icon = loadedIcon
            }
        }
    }
}

private final class AppIconCache {
    static let shared = AppIconCache()

    private let cache = NSCache<NSString, NSImage>()

    private init() {}

    func image(for path: String) -> NSImage? {
        cache.object(forKey: path as NSString)
    }

    func setImage(_ image: NSImage, for path: String) {
        cache.setObject(image, forKey: path as NSString)
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
                    ManagementBadge(state: managementState)
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
                .buttonStyle(MacPrimaryButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .listRowBackground(Color(NSColor.controlBackgroundColor))
        .listRowSeparator(.hidden)
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

    private var managementState: ManagementState {
        switch app.installSource {
        case "Homebrew", "Nix":
            return .managed("MacHelm previously removed this from a managed source")
        case "System":
            return .detected("Built into macOS")
        case "Mac Store":
            return .detected("Detected from the App Store")
        default:
            return .detected("Detected on disk only")
        }
    }
}

#Preview {
    AppsScreen(
        stateManager: AppStateManager(),
        storeManager: StoreManager(),
        model: AppsScreenModel(),
        selectedFilter: .constant(.all)
    )
        .frame(width: 800, height: 600)
}
