import SwiftUI

struct MainView: View {
    @State private var selection: SidebarItem = .home
    @State private var appsFilter: AppsScreen.FilterCategory = .all
    @State private var showsAppsTree = false
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
                return "General"
            case .settings:
                return "Accessibility"
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
                items: SidebarItem.allCases,
                appsFilter: $appsFilter,
                showsAppsTree: $showsAppsTree
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
            appsModel.start(scanPaths: AppsScreenModel.defaultScanPaths)
            storeManager.fetchCasks()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: rebuildApp) {
                    if isRebuilding {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "hammer")
                    }
                }
                .help(isRebuilding ? "Rebuilding MacHelm..." : "Rebuild MacHelm")
                .disabled(isRebuilding)

                Button(action: relaunchApp) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Relaunch MacHelm")
                .disabled(isRebuilding)
            }
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
            SystemScreen()
        case .settings:
            SettingsScreen()
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

private struct MacSidebar: View {
    @Binding var selection: MainView.SidebarItem
    let items: [MainView.SidebarItem]
    @Binding var appsFilter: AppsScreen.FilterCategory
    @Binding var showsAppsTree: Bool

    var body: some View {
        ZStack {
            Color(red: 0.117, green: 0.117, blue: 0.12)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.121, green: 0.121, blue: 0.124))
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 8)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 8)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        if showsAppsTree {
                            AppsTreeSidebar(
                                selection: $selection,
                                appsFilter: $appsFilter,
                                showsAppsTree: $showsAppsTree
                            )
                        } else {
                            ForEach(items, id: \.self) { item in
                                SidebarNavButton(
                                    item: item,
                                    isSelected: selection == item
                                ) {
                                    if item == .apps {
                                        selection = .apps
                                        showsAppsTree = true
                                    } else {
                                        selection = item
                                        showsAppsTree = false
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 56)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }
}

private struct AppsTreeSidebar: View {
    @Binding var selection: MainView.SidebarItem
    @Binding var appsFilter: AppsScreen.FilterCategory
    @Binding var showsAppsTree: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                showsAppsTree = false
            } label: {
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

private struct AppFilterSidebarButton: View {
    let category: AppsScreen.FilterCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SidebarIconChip(symbol: iconName, color: iconColor)

                Text(category.rawValue)
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isSelected ? Color(red: 0.27, green: 0.63, blue: 0.18) : Color.clear)
            )
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

    private var iconColor: Color {
        switch category {
        case .all:
            return .blue
        case .nix:
            return .indigo
        case .homebrew:
            return .orange
        case .macStore:
            return .pink
        case .system:
            return Color(red: 0.72, green: 0.72, blue: 0.74)
        case .others:
            return .gray
        case .deleted:
            return .red
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
                SidebarIconChip(symbol: item.symbol, color: item.color)

                Text(item.title)
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isSelected ? Color(red: 0.27, green: 0.63, blue: 0.18) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SidebarIconChip: View {
    let symbol: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.98), color.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: symbol)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 22, height: 22)
    }
}

#Preview {
    MainView()
}
