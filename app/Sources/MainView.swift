import SwiftUI

struct MainView: View {
    @AppStorage("machelm.showToolsTab") private var showToolsTab = true
    @AppStorage("machelm.showBinariesTab") private var showBinariesTab = true
    @State private var selection: SidebarItem = .home
    @State private var appsFilter: AppsScreen.FilterCategory = .all
    @State private var showsAppsTree = false
    @State private var showsSettingsTree = false
    @State private var settingsCategory: SettingsScreen.Category = .general
    @State private var hasPreloadedData = false
    @State private var isRebuilding = false
    @StateObject private var appStateManager = AppStateManager()
    @StateObject private var storeManager = StoreManager()
    @StateObject private var appsModel = AppsScreenModel()

    enum SidebarItem: String, CaseIterable, Hashable {
        case home
        case apps
        case tools
        case binaries
        case store
        case system
        case settings

        var title: String {
            switch self {
            case .home:
                return "Home"
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
                settingsCategory: $settingsCategory,
                showsSettingsTree: $showsSettingsTree,
                isRebuilding: isRebuilding,
                rebuildAction: rebuildApp,
                relaunchAction: relaunchApp
            )
            .frame(width: 215)
            .clipped()
            .zIndex(1)

            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .zIndex(0)
        }
        .background(Color(red: 0.118, green: 0.118, blue: 0.122))
        .background(WindowChromeConfigurator())
        .ignoresSafeArea(.container, edges: .top)
        .frame(
            minWidth: 720,
            idealWidth: 720,
            maxWidth: 720,
            minHeight: 660,
            idealHeight: 740
        )
        .onAppear {
            guard !hasPreloadedData else { return }
            hasPreloadedData = true
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
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection {
        case .home:
            HomeScreen()
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
        case .system:
            SettingsScreen(selectedCategory: $settingsCategory)
        case .settings:
            SettingsScreen(selectedCategory: $settingsCategory)
        }
    }

    private var visibleSidebarItems: [SidebarItem] {
        SidebarItem.allCases.filter { item in
            switch item {
            case .tools:
                return showToolsTab
            case .binaries:
                return showBinariesTab
            case .settings:
                return false
            default:
                return true
            }
        }
    }

    private func normalizeSelection() {
        if selection == .tools && !showToolsTab {
            selection = .home
            showsAppsTree = false
            showsSettingsTree = false
        }

        if selection == .binaries && !showBinariesTab {
            selection = .home
            showsAppsTree = false
            showsSettingsTree = false
        }
    }
    
    private func rebuildApp() {
        guard !isRebuilding else { return }
        isRebuilding = true

        let appDirectory = "/Users/danielrajakumar/code/MacHelm/app"
        let buildTask = Process()
        buildTask.executableURL = URL(fileURLWithPath: "/bin/zsh")
        buildTask.arguments = ["-lc", "cd '\(appDirectory)' && swift build >/tmp/machelm-rebuild.log 2>&1"]

        buildTask.terminationHandler = { process in
            DispatchQueue.main.async {
                isRebuilding = false
                if process.terminationStatus != 0 {
                    print("Background rebuild failed; see /tmp/machelm-rebuild.log")
                }
            }
        }

        do {
            try buildTask.run()
        } catch {
            isRebuilding = false
            print("Failed to start background rebuild: \(error)")
        }
    }

    private func relaunchApp() {
        guard !isRebuilding else { return }

        if Bundle.main.bundleURL.pathExtension == "app" {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            configuration.createsNewApplicationInstance = true

            NSWorkspace.shared.openApplication(
                at: Bundle.main.bundleURL,
                configuration: configuration
            ) { _, error in
                if let error {
                    print("Failed to relaunch app bundle: \(error)")
                    return
                }

                DispatchQueue.main.async {
                    NSApplication.shared.terminate(nil)
                }
            }
            return
        }

        let executablePath = Bundle.main.executablePath ?? "/Users/danielrajakumar/code/MacHelm/app/.build/arm64-apple-macosx/debug/MacHelm"
        let logPath = "/tmp/machelm-relaunch.log"
        FileManager.default.createFile(atPath: logPath, contents: nil)
        let relaunchTask = Process()
        relaunchTask.executableURL = URL(fileURLWithPath: "/usr/bin/nohup")
        relaunchTask.arguments = [
            executablePath
        ]
        relaunchTask.standardOutput = FileHandle(forWritingAtPath: logPath)
        relaunchTask.standardError = FileHandle(forWritingAtPath: logPath)

        do {
            try relaunchTask.run()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                NSApplication.shared.terminate(nil)
            }
        } catch {
            print("Failed to relaunch debug build: \(error)")
            return
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

private struct MacSidebar: View {
    private enum NavigationDirection {
        case forward
        case backward
    }

    @Binding var selection: MainView.SidebarItem
    let items: [MainView.SidebarItem]
    @Binding var appsFilter: AppsScreen.FilterCategory
    @Binding var showsAppsTree: Bool
    @Binding var settingsCategory: SettingsScreen.Category
    @Binding var showsSettingsTree: Bool
    @State private var navigationDirection: NavigationDirection = .forward
    let isRebuilding: Bool
    let rebuildAction: () -> Void
    let relaunchAction: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.117, green: 0.117, blue: 0.12)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.121, green: 0.121, blue: 0.124))
                .padding(.leading, 10)
                .padding(.trailing, 8)
                .padding(.top, 10)
                .padding(.bottom, 8)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .padding(.leading, 10)
                .padding(.trailing, 8)
                .padding(.top, 10)
                .padding(.bottom, 8)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
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
                                ForEach(items, id: \.self) { item in
                                    SidebarNavButton(
                                        item: item,
                                        isSelected: selection == item
                                    ) {
                                        if item == .apps {
                                            navigationDirection = .forward
                                            withAnimation(sidebarTransitionAnimation) {
                                                selection = .apps
                                                showsAppsTree = true
                                                showsSettingsTree = false
                                            }
                                        } else if item == .system {
                                            navigationDirection = .forward
                                            withAnimation(sidebarTransitionAnimation) {
                                                selection = .system
                                                settingsCategory = .general
                                                showsSettingsTree = true
                                                showsAppsTree = false
                                            }
                                        } else {
                                            withAnimation(sidebarTransitionAnimation) {
                                                selection = item
                                                showsAppsTree = false
                                                showsSettingsTree = false
                                            }
                                        }
                                    }
                                }
                            }
                            .transition(sidebarTransition)
                        }
                    }
                    .padding(.top, 48)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }

            VStack {
                HStack(spacing: 10) {
                    Spacer()

                    Button(action: rebuildAction) {
                        if isRebuilding {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "hammer")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                    .help(isRebuilding ? "Rebuilding MacHelm..." : "Rebuild MacHelm")
                    .disabled(isRebuilding)
                    .controlSize(.small)
                    .buttonStyle(.plain)

                    Button(action: relaunchAction) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .help("Relaunch MacHelm")
                    .disabled(isRebuilding)
                    .controlSize(.small)
                    .buttonStyle(.plain)
                }
                .padding(.top, 21)
                .padding(.trailing, 18)

                Spacer()
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }

    private var sidebarTransitionAnimation: Animation {
        .spring(response: 0.28, dampingFraction: 0.9)
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
                    Text("App")
                        .font(.system(size: 11.5, weight: .medium))
                    Spacer()
                }
                .foregroundColor(Color.white.opacity(0.78))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.white.opacity(0.06))
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
                .foregroundColor(Color.white.opacity(0.78))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.white.opacity(0.06))
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

private struct AppFilterSidebarButton: View {
    let category: AppsScreen.FilterCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SidebarMonoIcon(symbol: iconName, isSelected: isSelected)

                Text(category.rawValue)
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isSelected ? Color(red: 0.27, green: 0.63, blue: 0.18) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch category {
        case .all:
            return "square.grid.2x2.fill"
        case .nix:
            return "cube.box.fill"
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
                SidebarMonoIcon(symbol: item.symbol, isSelected: isSelected)

                Text(item.title)
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.white)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isSelected ? Color(red: 0.27, green: 0.63, blue: 0.18) : Color.clear)
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
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isSelected ? Color(red: 0.27, green: 0.63, blue: 0.18) : Color.clear)
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
            .foregroundColor(isSelected ? .white : Color.white.opacity(0.78))
            .frame(width: 18, height: 18)
            .symbolRenderingMode(.monochrome)
    }
}

#Preview {
    MainView()
}
