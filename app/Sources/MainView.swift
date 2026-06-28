import SwiftUI

struct MainView: View {
    @AppStorage("machelm.showToolsTab") private var showToolsTab = true
    @AppStorage("machelm.showBinariesTab") private var showBinariesTab = true
    @AppStorage("machelm.sidebar.selection") private var persistedSelectionRawValue = SidebarItem.home.rawValue
    @AppStorage("machelm.sidebar.appsFilter") private var persistedAppsFilterRawValue = AppsScreen.FilterCategory.all.rawValue
    @AppStorage("machelm.sidebar.showsAppsTree") private var persistedShowsAppsTree = false
    @AppStorage("machelm.sidebar.showsWindowsTree") private var persistedShowsWindowsTree = false
    @AppStorage("machelm.sidebar.showsSettingsTree") private var persistedShowsSettingsTree = false
    @AppStorage("machelm.sidebar.windowsSection") private var persistedWindowsSectionRawValue = WindowsScreen.Section.overview.rawValue
    @AppStorage("machelm.sidebar.settingsCategory") private var persistedSettingsCategoryRawValue = SettingsScreen.Category.general.rawValue
    @State private var selection: SidebarItem = .home
    @State private var appsFilter: AppsScreen.FilterCategory = .all
    @State private var showsAppsTree = false
    @State private var showsWindowsTree = false
    @State private var showsSettingsTree = false
    @State private var windowsSection: WindowsScreen.Section = .overview
    @State private var settingsCategory: SettingsScreen.Category = .general
    @State private var sidebarSearchText = ""
    @State private var hasPreloadedData = false
    @State private var isRebuilding = false
    @StateObject private var appStateManager = AppStateManager()
    @StateObject private var storeManager = StoreManager()
    @StateObject private var appsModel = AppsScreenModel()
    @StateObject private var syncManager = GitHubSyncManager()

    enum SidebarItem: String, CaseIterable, Hashable {
        case home
        case apps
        case store
        case tools
        case binaries
        case windows
        case keyboard
        case sync
        case dock
        case appearance
        case system
        case settings

        var title: String {
            switch self {
            case .home:
                return "Home"
            case .dock:
                return "Dock"
            case .appearance:
                return "Appearance"
            case .keyboard:
                return "Keyboard"
            case .windows:
                return "Windows"
            case .sync:
                return "Sync"
            case .apps:
                return "Apps"
            case .tools:
                return "Tools"
            case .binaries:
                return "Binaries"
            case .store:
                return "Store"
            case .system:
                return "Settings"
            case .settings:
                return "Settings"
            }
        }

        var symbol: String {
            switch self {
            case .home:
                return "house.fill"
            case .dock:
                return "dock.rectangle"
            case .appearance:
                return "circle.lefthalf.filled.inverse"
            case .keyboard:
                return "keyboard"
            case .windows:
                return "macwindow.on.rectangle"
            case .sync:
                return "arrow.triangle.2.circlepath"
            case .apps:
                return "square.grid.2x2.fill"
            case .tools:
                return "terminal.fill"
            case .binaries:
                return "doc.text.magnifyingglass"
            case .store:
                return "bag.fill"
            case .system:
                return "gearshape.fill"
            case .settings:
                return "figure.wave.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .home:
                return .orange
            case .dock:
                return .green
            case .appearance:
                return Color(red: 0.76, green: 0.45, blue: 0.20)
            case .keyboard:
                return .yellow
            case .windows:
                return Color(red: 0.20, green: 0.58, blue: 0.86)
            case .sync:
                return .teal
            case .apps:
                return .blue
            case .tools:
                return .mint
            case .binaries:
                return .indigo
            case .store:
                return .pink
            case .system:
                return Color(red: 0.72, green: 0.72, blue: 0.74)
            case .settings:
                return .blue
            }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            MacSidebar(
                selection: $selection,
                items: visibleSidebarItems,
                appsFilter: $appsFilter,
                showsAppsTree: $showsAppsTree,
                windowsSection: $windowsSection,
                showsWindowsTree: $showsWindowsTree,
                settingsCategory: $settingsCategory,
                showsSettingsTree: $showsSettingsTree,
                searchText: $sidebarSearchText,
                syncManager: syncManager,
                isRebuilding: isRebuilding,
                updateAction: updateApp
            )
            .frame(width: 222)
            .clipped()
            .zIndex(1)

            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .zIndex(0)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .background(WindowChromeConfigurator())
        .ignoresSafeArea(.container, edges: .top)
        .frame(
            minWidth: 720,
            idealWidth: 720,
            maxWidth: 860,
            minHeight: 660,
            idealHeight: 740
        )
        .onAppear {
            guard !hasPreloadedData else { return }
            hasPreloadedData = true
            restoreNavigationState()
            normalizeSelection()
            appsModel.start(scanPaths: AppsScreenModel.defaultScanPaths)
            storeManager.fetchCasks()
        }
        .onChange(of: showToolsTab) {
            normalizeSelection()
        }
        .onChange(of: showBinariesTab) {
            normalizeSelection()
        }
        .onChange(of: selection) {
            persistNavigationState()
        }
        .onChange(of: appsFilter) {
            persistNavigationState()
        }
        .onChange(of: showsAppsTree) {
            persistNavigationState()
        }
        .onChange(of: showsWindowsTree) {
            persistNavigationState()
        }
        .onChange(of: showsSettingsTree) {
            persistNavigationState()
        }
        .onChange(of: windowsSection) {
            persistNavigationState()
        }
        .onChange(of: settingsCategory) {
            persistNavigationState()
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection {
        case .home:
            HomeScreen()
        case .dock:
            DockScreen()
        case .appearance:
            AppearanceScreen()
        case .keyboard:
            KeyboardScreen()
        case .windows:
            WindowsScreen(selectedSection: $windowsSection)
        case .apps:
            AppsScreen(
                stateManager: appStateManager,
                storeManager: storeManager,
                model: appsModel,
                selectedFilter: $appsFilter
            )
        case .tools:
            ToolsScreen()
        case .binaries:
            BinariesScreen()
        case .store:
            StoreScreen(storeManager: storeManager, stateManager: appStateManager)
        case .sync:
            SettingsScreen(selectedCategory: .constant(.github), syncManager: syncManager)
        case .system:
            SettingsScreen(selectedCategory: $settingsCategory, syncManager: syncManager)
        case .settings:
            SettingsScreen(selectedCategory: $settingsCategory, syncManager: syncManager)
        }
    }

    private var visibleSidebarItems: [SidebarItem] {
        SidebarItem.allCases.filter { item in
            switch item {
            case .tools:
                return showToolsTab
            case .binaries:
                return showBinariesTab
            case .dock, .appearance, .settings:
                return false
            default:
                return true
            }
        }
    }

    private func normalizeSelection() {
        if selection == .settings {
            selection = .system
        }

        if selection == .dock || selection == .appearance {
            selection = .home
            showsAppsTree = false
            showsWindowsTree = false
            showsSettingsTree = false
        }

        if selection == .tools && !showToolsTab {
            selection = .home
            showsAppsTree = false
            showsWindowsTree = false
            showsSettingsTree = false
        }

        if selection == .binaries && !showBinariesTab {
            selection = .home
            showsAppsTree = false
            showsWindowsTree = false
            showsSettingsTree = false
        }

        if selection != .apps {
            showsAppsTree = false
        }

        if selection != .windows {
            showsWindowsTree = false
        }

        if selection != .system && selection != .settings {
            showsSettingsTree = false
        }

        if showsAppsTree {
            showsWindowsTree = false
            showsSettingsTree = false
        } else if showsWindowsTree {
            showsSettingsTree = false
        }

        persistNavigationState()
    }

    private func restoreNavigationState() {
        selection = SidebarItem(rawValue: persistedSelectionRawValue) ?? .home
        appsFilter = AppsScreen.FilterCategory(rawValue: persistedAppsFilterRawValue) ?? .all
        windowsSection = WindowsScreen.Section(rawValue: persistedWindowsSectionRawValue) ?? .overview
        settingsCategory = SettingsScreen.Category(rawValue: persistedSettingsCategoryRawValue) ?? .general
        showsAppsTree = persistedShowsAppsTree
        showsWindowsTree = persistedShowsWindowsTree
        showsSettingsTree = persistedShowsSettingsTree
    }

    private func persistNavigationState() {
        persistedSelectionRawValue = selection.rawValue
        persistedAppsFilterRawValue = appsFilter.rawValue
        persistedShowsAppsTree = showsAppsTree
        persistedShowsWindowsTree = showsWindowsTree
        persistedShowsSettingsTree = showsSettingsTree
        persistedWindowsSectionRawValue = windowsSection.rawValue
        persistedSettingsCategoryRawValue = settingsCategory.rawValue
    }
    
    private func updateApp() {
        guard !isRebuilding else { return }
        isRebuilding = true

        let repoDirectory = "/Users/danielrajakumar/code/MacHelm"
        let updateTask = Process()
        updateTask.executableURL = URL(fileURLWithPath: "/bin/zsh")
        updateTask.arguments = ["-lc", "cd '\(repoDirectory)' && ./scripts/build-app-bundle.sh >/tmp/machelm-update.log 2>&1"]

        updateTask.terminationHandler = { process in
            DispatchQueue.main.async {
                isRebuilding = false
                if process.terminationStatus != 0 {
                    print("App update failed; see /tmp/machelm-update.log")
                    return
                }

                let configuration = NSWorkspace.OpenConfiguration()
                configuration.activates = true
                configuration.createsNewApplicationInstance = true
                let bundleURL = URL(fileURLWithPath: "/Users/danielrajakumar/Applications/MacHelm.app")

                NSWorkspace.shared.openApplication(
                    at: bundleURL,
                    configuration: configuration
                ) { _, error in
                    if let error {
                        print("Failed to relaunch updated app: \(error)")
                        return
                    }

                    DispatchQueue.main.async {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
        }

        do {
            try updateTask.run()
        } catch {
            isRebuilding = false
            print("Failed to start app update: \(error)")
        }
    }
}

private struct WindowChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            configureWindow(for: view)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configureWindow(for: nsView)
        }
    }

    private func configureWindow(for view: NSView) {
        guard let window = view.window else { return }
        guard
            let closeButton = window.standardWindowButton(.closeButton),
            let miniaturizeButton = window.standardWindowButton(.miniaturizeButton),
            let zoomButton = window.standardWindowButton(.zoomButton),
            let titlebarView = closeButton.superview
        else {
            return
        }

        let buttonY = titlebarView.bounds.height - closeButton.frame.height - 21
        let startX: CGFloat = 24
        let spacing: CGFloat = 24

        closeButton.setFrameOrigin(NSPoint(x: startX, y: buttonY))
        miniaturizeButton.setFrameOrigin(NSPoint(x: startX + spacing, y: buttonY))
        zoomButton.setFrameOrigin(NSPoint(x: startX + (spacing * 2), y: buttonY))
    }
}

private struct SidebarVisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

private struct MacSidebar: View {
    private enum NavigationDirection {
        case forward
        case backward
    }

    @Binding var selection: MainView.SidebarItem
    let items: [MainView.SidebarItem]
    @Binding var appsFilter: AppsScreen.FilterCategory
    @Binding var showsAppsTree: Bool
    @Binding var windowsSection: WindowsScreen.Section
    @Binding var showsWindowsTree: Bool
    @Binding var settingsCategory: SettingsScreen.Category
    @Binding var showsSettingsTree: Bool
    @Binding var searchText: String
    @ObservedObject var syncManager: GitHubSyncManager
    @State private var navigationDirection: NavigationDirection = .forward
    let isRebuilding: Bool
    let updateAction: () -> Void

    var body: some View {
        ZStack {
            SidebarVisualEffectView()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    MacInlineSearchField(prompt: "Search", text: $searchText)
                        .padding(.bottom, 12)

                    ZStack(alignment: .topLeading) {
                        if showsAppsTree {
                            AppsTreeSidebar(
                                selection: $selection,
                                appsFilter: $appsFilter,
                                showsAppsTree: $showsAppsTree,
                                goBack: {
                                    navigationDirection = .backward
                                    withAnimation(sidebarTransitionAnimation) {
                                        showsAppsTree = false
                                    }
                                }
                            )
                            .transition(sidebarTransition)
                        } else if showsWindowsTree {
                            WindowsTreeSidebar(
                                selection: $selection,
                                windowsSection: $windowsSection,
                                showsWindowsTree: $showsWindowsTree,
                                goBack: {
                                    navigationDirection = .backward
                                    withAnimation(sidebarTransitionAnimation) {
                                        showsWindowsTree = false
                                    }
                                }
                            )
                            .transition(sidebarTransition)
                        } else if showsSettingsTree {
                            SettingsTreeSidebar(
                                selection: $selection,
                                settingsCategory: $settingsCategory,
                                showsSettingsTree: $showsSettingsTree,
                                goBack: {
                                    navigationDirection = .backward
                                    withAnimation(sidebarTransitionAnimation) {
                                        showsSettingsTree = false
                                    }
                                }
                            )
                            .transition(sidebarTransition)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(filteredItems, id: \.self) { item in
                                    SidebarNavButton(
                                        item: item,
                                        isSelected: selection == item && !(item == .system && settingsCategory == .github)
                                    ) {
                                        if item == .apps {
                                            navigationDirection = .forward
                                            selection = .apps
                                            withAnimation(sidebarTransitionAnimation) {
                                                showsAppsTree = true
                                                showsWindowsTree = false
                                                showsSettingsTree = false
                                            }
                                        } else if item == .windows {
                                            navigationDirection = .forward
                                            selection = .windows
                                            windowsSection = .overview
                                            withAnimation(sidebarTransitionAnimation) {
                                                showsWindowsTree = true
                                                showsAppsTree = false
                                                showsSettingsTree = false
                                            }
                                        } else if item == .system {
                                            navigationDirection = .forward
                                            selection = .system
                                            settingsCategory = .general
                                            withAnimation(sidebarTransitionAnimation) {
                                                showsSettingsTree = true
                                                showsAppsTree = false
                                                showsWindowsTree = false
                                            }
                                        } else {
                                            selection = item
                                            showsAppsTree = false
                                            showsWindowsTree = false
                                            showsSettingsTree = false
                                        }
                                    }
                                }
                            }
                            .transition(sidebarTransition)
                        }
                    }
                    .padding(.top, 0)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 96)
            }
            .padding(.top, 52)

            VStack {
                HStack(spacing: 10) {
                    Spacer()

                    Button(action: updateAction) {
                        if isRebuilding {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .help(isRebuilding ? "Updating MacHelm..." : "Update App")
                    .disabled(isRebuilding)
                    .controlSize(.small)
                    .buttonStyle(.plain)
                }
                .padding(.top, 18)
                .padding(.trailing, 14)

                Spacer()
            }

            VStack {
                Spacer()

                GitHubAccountSidebarButton(
                    syncManager: syncManager,
                    isSelected: selection == .sync || (selection == .system && settingsCategory == .github)
                ) {
                    navigationDirection = .forward
                    selection = .sync
                    showsSettingsTree = false
                    showsAppsTree = false
                    showsWindowsTree = false
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }

    private var sidebarTransitionAnimation: Animation {
        .spring(response: 0.28, dampingFraction: 0.9)
    }

    private var filteredItems: [MainView.SidebarItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return items }
        return items.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    private var sidebarTransition: AnyTransition {
        switch navigationDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }
}

private struct AppsTreeSidebar: View {
    @Binding var selection: MainView.SidebarItem
    @Binding var appsFilter: AppsScreen.FilterCategory
    @Binding var showsAppsTree: Bool
    let goBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: goBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Apps")
                        .font(.system(size: 11.5, weight: .medium))
                    Spacer()
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(AppsScreen.FilterCategory.allCases) { category in
                    AppFilterSidebarButton(
                        category: category,
                        isSelected: appsFilter == category
                    ) {
                        selection = .apps
                        appsFilter = category
                    }
                }
            }
        }
    }
}

private struct GitHubAccountSidebarButton: View {
    @ObservedObject var syncManager: GitHubSyncManager
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                avatar

                VStack(alignment: .leading, spacing: 1) {
                    Text(primaryText)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(secondaryText)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("GitHub account")
    }

    @ViewBuilder
    private var avatar: some View {
        if let avatarURL = syncManager.avatarURL {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                default:
                    avatarPlaceholder
                }
            }
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.primary.opacity(0.1))
            Image(systemName: syncManager.authState == .signedIn ? "person.crop.circle.fill" : "person.crop.circle.badge.plus")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.secondary)
        }
        .frame(width: 44, height: 44)
    }

    private var primaryText: String {
        switch syncManager.authState {
        case .signedIn:
            return syncManager.displayName ?? syncManager.username ?? "GitHub User"
        case .authorizing:
            return "GitHub"
        case .signedOut:
            return "GitHub"
        }
    }

    private var secondaryText: String {
        switch syncManager.authState {
        case .signedIn:
            return "GitHub Account"
        case .authorizing:
            return "Authorizing..."
        case .signedOut:
            return "Sign in"
        }
    }
}

private struct SettingsTreeSidebar: View {
    @Binding var selection: MainView.SidebarItem
    @Binding var settingsCategory: SettingsScreen.Category
    @Binding var showsSettingsTree: Bool
    let goBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: goBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Settings")
                        .font(.system(size: 11.5, weight: .medium))
                    Spacer()
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)

            ForEach(SettingsScreen.Category.Group.allCases, id: \.self) { group in
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.title.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.top, group == .preferences ? 0 : 8)
                        .padding(.bottom, 4)

                    ForEach(SettingsScreen.Category.allCases.filter { $0.group == group }) { category in
                        SettingsSidebarButton(
                            category: category,
                            isSelected: settingsCategory == category
                        ) {
                            selection = .system
                            settingsCategory = category
                        }
                    }
                }
            }
        }
    }
}

private struct WindowsTreeSidebar: View {
    @Binding var selection: MainView.SidebarItem
    @Binding var windowsSection: WindowsScreen.Section
    @Binding var showsWindowsTree: Bool
    let goBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: goBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Windows")
                        .font(.system(size: 11.5, weight: .medium))
                    Spacer()
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)

            ForEach(WindowsScreen.Section.Group.allCases, id: \.self) { group in
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.title.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.top, group == .macOS ? 0 : 8)
                        .padding(.bottom, 4)

                    ForEach(WindowsScreen.Section.allCases.filter { $0.group == group }) { section in
                        WindowsSidebarButton(
                            section: section,
                            isSelected: windowsSection == section
                        ) {
                            selection = .windows
                            windowsSection = section
                        }
                    }
                }
            }
        }
    }
}

private struct AppFilterSidebarButton: View {
    let category: AppsScreen.FilterCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SidebarMonoIcon(symbol: iconName, isSelected: isSelected)

                Text(category.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch category {
        case .all:
            return "square.grid.2x2.fill"
        case .homebrew:
            return "mug.fill"
        case .macStore:
            return "bag.fill"
        case .system:
            return "applelogo"
        case .others:
            return "app.badge"
        case .deleted:
            return "trash.fill"
        }
    }

}

private struct SidebarNavButton: View {
    let item: MainView.SidebarItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SettingsSidebarIcon(symbol: item.symbol, color: item.color, size: 26)

                Text(item.title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(.primary)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsSidebarButton: View {
    let category: SettingsScreen.Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SidebarMonoIcon(symbol: category.symbol, isSelected: isSelected)

                Text(category.title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct WindowsSidebarButton: View {
    let section: WindowsScreen.Section
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SidebarMonoIcon(symbol: section.symbol, isSelected: isSelected)

                Text(section.title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SidebarMonoIcon: View {
    let symbol: String
    let isSelected: Bool

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isSelected ? .primary : .secondary)
            .frame(width: 18, height: 18)
            .symbolRenderingMode(.monochrome)
    }
}

#Preview {
    MainView()
}
