import SwiftUI

struct YabaiManagedSettings: Codable, Equatable {
    enum Layout: String, CaseIterable, Identifiable, Codable {
        case bsp
        case stack
        case float

        var id: String { rawValue }

        var title: String {
            rawValue.capitalized
        }
    }

    enum WindowPlacement: String, CaseIterable, Identifiable, Codable {
        case firstChild = "first_child"
        case secondChild = "second_child"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .firstChild:
                return "First Child"
            case .secondChild:
                return "Second Child"
            }
        }
    }

    enum MouseModifier: String, CaseIterable, Identifiable, Codable {
        case fn
        case alt
        case shift
        case ctrl
        case cmd

        var id: String { rawValue }

        var title: String {
            switch self {
            case .fn:
                return "Fn"
            case .alt:
                return "Alt"
            case .shift:
                return "Shift"
            case .ctrl:
                return "Ctrl"
            case .cmd:
                return "Cmd"
            }
        }
    }

    var layout: Layout = .bsp
    var windowPlacement: WindowPlacement = .secondChild
    var autoBalance = false
    var splitRatio: Double = 0.5
    var outerPadding: Double = 12
    var windowGap: Double = 10
    var mouseFollowsFocus = false
    var focusFollowsMouse = false
    var mouseModifier: MouseModifier = .fn
    var floatSystemSettings = true
    var floatFinder = true
    var floatActivityMonitor = true
    var floatArchiveUtility = true

    static let `default` = YabaiManagedSettings()
}

@MainActor
final class WindowSettingsController: ObservableObject {
    enum MinimizeEffect: String, CaseIterable, Identifiable {
        case genie
        case scale

        var id: String { rawValue }

        var title: String {
            rawValue.capitalized
        }
    }

    enum StageWindowGrouping: Int, CaseIterable, Identifiable {
        case allAtOnce = 0
        case oneAtATime = 1

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .allAtOnce:
                return "All at Once"
            case .oneAtATime:
                return "One at a Time"
            }
        }
    }

    @Published var minimizeToApplication = false
    @Published var rearrangeSpaces = true
    @Published var minimizeEffect: MinimizeEffect = .genie
    @Published var stageManagerEnabled = false
    @Published var stageManagerShowsRecentApps = true
    @Published var stageManagerShowsDesktopItems = false
    @Published var showDesktopWidgets = true
    @Published var showWidgetsInStageManager = true
    @Published var tiledWindowMargins = false
    @Published var stageWindowGrouping: StageWindowGrouping = .oneAtATime
    @Published var isApplying = false
    private var persistedYabaiSettings = YabaiManagedSettings.default
    @Published var yabaiSettings = YabaiManagedSettings.default {
        didSet {
            hasUnsavedYabaiChanges = yabaiSettings != persistedYabaiSettings
        }
    }
    @Published var hasUnsavedYabaiChanges = false
    @Published var isSavingYabaiSettings = false
    @Published var yabaiInstalled = false
    @Published var yabaiRunning = false
    @Published var yabaiBinaryPath: String?
    @Published var yabaiStatusMessage = "Unavailable"
    @Published var isRunningYabaiCommand = false

    private let dockDefaults = UserDefaults(suiteName: "com.apple.dock")
    private let windowManagerDefaults = UserDefaults(suiteName: "com.apple.WindowManager")
    private let repoYabaiDirectoryURL = URL(fileURLWithPath: "/Users/danielrajakumar/code/MacHelm/config/yabai", isDirectory: true)
    private let liveYabaiDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/yabai", isDirectory: true)

    func load() {
        minimizeToApplication = dockDefaults?.object(forKey: "minimize-to-application") as? Bool ?? false
        rearrangeSpaces = dockDefaults?.object(forKey: "mru-spaces") as? Bool ?? true

        if let effect = dockDefaults?.string(forKey: "mineffect"),
           let minimizeEffect = MinimizeEffect(rawValue: effect) {
            self.minimizeEffect = minimizeEffect
        } else {
            minimizeEffect = .genie
        }

        stageManagerEnabled = windowManagerDefaults?.object(forKey: "GloballyEnabled") as? Bool ?? false
        stageManagerShowsRecentApps = !(windowManagerDefaults?.object(forKey: "AutoHide") as? Bool ?? false)
        stageManagerShowsDesktopItems = !(windowManagerDefaults?.object(forKey: "HideDesktop") as? Bool ?? true)
        showDesktopWidgets = !(windowManagerDefaults?.object(forKey: "StandardHideWidgets") as? Bool ?? false)
        showWidgetsInStageManager = !(windowManagerDefaults?.object(forKey: "StageManagerHideWidgets") as? Bool ?? false)
        tiledWindowMargins = windowManagerDefaults?.object(forKey: "EnableTiledWindowMargins") as? Bool ?? false

        if let rawGrouping = windowManagerDefaults?.object(forKey: "AppWindowGroupingBehavior") as? Int,
           let grouping = StageWindowGrouping(rawValue: rawGrouping) {
            stageWindowGrouping = grouping
        } else if let boolGrouping = windowManagerDefaults?.object(forKey: "AppWindowGroupingBehavior") as? Bool {
            stageWindowGrouping = boolGrouping ? .oneAtATime : .allAtOnce
        } else {
            stageWindowGrouping = .oneAtATime
        }

        loadYabaiSettings()
        refreshYabaiStatus()
    }

    func applyMinimizeToApplication(_ value: Bool) {
        minimizeToApplication = value
        writeDock(value, forKey: "minimize-to-application")
    }

    func applyRearrangeSpaces(_ value: Bool) {
        rearrangeSpaces = value
        writeDock(value, forKey: "mru-spaces")
    }

    func applyMinimizeEffect(_ value: MinimizeEffect) {
        minimizeEffect = value
        writeDock(value.rawValue, forKey: "mineffect")
    }

    func applyStageManagerEnabled(_ value: Bool) {
        stageManagerEnabled = value
        writeWindowManager(value, forKey: "GloballyEnabled")
        if value {
            windowManagerDefaults?.set(true, forKey: "GloballyEnabledEver")
            windowManagerDefaults?.synchronize()
        }
    }

    func applyStageManagerShowsRecentApps(_ value: Bool) {
        stageManagerShowsRecentApps = value
        writeWindowManager(!value, forKey: "AutoHide")
    }

    func applyStageManagerShowsDesktopItems(_ value: Bool) {
        stageManagerShowsDesktopItems = value
        writeWindowManager(!value, forKey: "HideDesktop")
    }

    func applyShowDesktopWidgets(_ value: Bool) {
        showDesktopWidgets = value
        writeWindowManager(!value, forKey: "StandardHideWidgets")
    }

    func applyShowWidgetsInStageManager(_ value: Bool) {
        showWidgetsInStageManager = value
        writeWindowManager(!value, forKey: "StageManagerHideWidgets")
    }

    func applyTiledWindowMargins(_ value: Bool) {
        tiledWindowMargins = value
        writeWindowManager(value, forKey: "EnableTiledWindowMargins")
    }

    func applyStageWindowGrouping(_ value: StageWindowGrouping) {
        stageWindowGrouping = value
        writeWindowManager(value.rawValue, forKey: "AppWindowGroupingBehavior")
    }

    var repoSettingsPath: String {
        repoYabaiSettingsURL.path
    }

    var repoConfigPath: String {
        repoYabaiConfigURL.path
    }

    var liveGeneratedConfigPath: String {
        liveYabaiGeneratedConfigURL.path
    }

    var yabaiConfigExists: Bool {
        FileManager.default.fileExists(atPath: liveYabaiGeneratedConfigURL.path)
    }

    func revealRepoSettings() {
        NSWorkspace.shared.activateFileViewerSelecting([repoYabaiSettingsURL])
    }

    func revealLiveGeneratedConfig() {
        NSWorkspace.shared.activateFileViewerSelecting([liveYabaiGeneratedConfigURL])
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func startYabai() {
        runYabaiCommand("yabai --start-service")
    }

    func restartYabai() {
        runYabaiCommand("yabai --restart-service || yabai --start-service")
    }

    func stopYabai() {
        runYabaiCommand("yabai --stop-service")
    }

    func resetYabaiSettings() {
        yabaiSettings = .default
    }

    func saveYabaiSettings() {
        guard !isSavingYabaiSettings else { return }
        isSavingYabaiSettings = true
        let settings = yabaiSettings

        do {
            try writeYabaiManagedFiles(settings)
            persistedYabaiSettings = settings
            yabaiSettings = settings
            hasUnsavedYabaiChanges = false
            isSavingYabaiSettings = false

            if yabaiInstalled {
                restartYabai()
            } else {
                refreshYabaiStatus()
            }
        } catch {
            print("Failed to save yabai settings: \(error)")
            isSavingYabaiSettings = false
        }
    }

    private func writeDock(_ value: Any, forKey key: String) {
        dockDefaults?.set(value, forKey: key)
        dockDefaults?.synchronize()
        restart(processName: "Dock")
    }

    private func writeWindowManager(_ value: Any, forKey key: String) {
        windowManagerDefaults?.set(value, forKey: key)
        windowManagerDefaults?.synchronize()
        restart(processName: "WindowManager")
    }

    private func restart(processName: String) {
        guard !isApplying else { return }
        isApplying = true

        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            task.arguments = [processName]

            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                print("Failed to restart \(processName): \(error)")
            }

            DispatchQueue.main.async {
                self.isApplying = false
            }
        }
    }

    private var repoYabaiConfigURL: URL {
        repoYabaiDirectoryURL.appendingPathComponent("yabairc")
    }

    private var repoYabaiSettingsURL: URL {
        repoYabaiDirectoryURL.appendingPathComponent("settings.json")
    }

    private var repoYabaiGeneratedConfigURL: URL {
        repoYabaiDirectoryURL.appendingPathComponent("generated.yabairc")
    }

    private var liveYabaiConfigURL: URL {
        liveYabaiDirectoryURL.appendingPathComponent("yabairc")
    }

    private var liveYabaiSettingsURL: URL {
        liveYabaiDirectoryURL.appendingPathComponent("settings.json")
    }

    private var liveYabaiGeneratedConfigURL: URL {
        liveYabaiDirectoryURL.appendingPathComponent("generated.yabairc")
    }

    private func loadYabaiSettings() {
        let settings = loadYabaiSettings(from: repoYabaiSettingsURL)
            ?? loadYabaiSettings(from: liveYabaiSettingsURL)
            ?? .default

        persistedYabaiSettings = settings
        yabaiSettings = settings
        hasUnsavedYabaiChanges = false
    }

    private func loadYabaiSettings(from fileURL: URL) -> YabaiManagedSettings? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(YabaiManagedSettings.self, from: data)
    }

    private func writeYabaiManagedFiles(_ settings: YabaiManagedSettings) throws {
        let repoScript = renderYabaiGeneratedConfig(settings)
        let liveScript = repoScript
        let settingsData = try encodedYabaiSettings(settings)
        let repoWrapper = renderYabaiWrapper()
        let liveWrapper = repoWrapper

        try FileManager.default.createDirectory(at: repoYabaiDirectoryURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: liveYabaiDirectoryURL, withIntermediateDirectories: true)

        try settingsData.write(to: repoYabaiSettingsURL, options: .atomic)
        try settingsData.write(to: liveYabaiSettingsURL, options: .atomic)
        try repoScript.write(to: repoYabaiGeneratedConfigURL, atomically: true, encoding: .utf8)
        try liveScript.write(to: liveYabaiGeneratedConfigURL, atomically: true, encoding: .utf8)
        try repoWrapper.write(to: repoYabaiConfigURL, atomically: true, encoding: .utf8)
        try liveWrapper.write(to: liveYabaiConfigURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: repoYabaiGeneratedConfigURL.path)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: liveYabaiGeneratedConfigURL.path)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: repoYabaiConfigURL.path)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: liveYabaiConfigURL.path)
    }

    private func encodedYabaiSettings(_ settings: YabaiManagedSettings) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(settings)
    }

    private func renderYabaiWrapper() -> String {
        """
        #!/usr/bin/env sh

        CONFIG_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
        GENERATED_CONFIG="$CONFIG_DIR/generated.yabairc"

        if [ -f "$GENERATED_CONFIG" ]; then
          . "$GENERATED_CONFIG"
        fi
        """
    }

    private func renderYabaiGeneratedConfig(_ settings: YabaiManagedSettings) -> String {
        let outerPadding = Int(settings.outerPadding.rounded())
        let windowGap = Int(settings.windowGap.rounded())
        let splitRatio = String(format: "%.2f", settings.splitRatio)
        let autoBalance = settings.autoBalance ? "on" : "off"
        let mouseFollowsFocus = settings.mouseFollowsFocus ? "on" : "off"
        let focusFollowsMouse = settings.focusFollowsMouse ? "on" : "off"

        var lines = [
            "#!/usr/bin/env sh",
            "",
            "YABAI_BIN=\"${YABAI_BIN:-$(command -v yabai || true)}\"",
            "",
            "if [ -z \"$YABAI_BIN\" ]; then",
            "  exit 0",
            "fi",
            "",
            "\"$YABAI_BIN\" -m config layout \(settings.layout.rawValue)",
            "\"$YABAI_BIN\" -m config auto_balance \(autoBalance)",
            "\"$YABAI_BIN\" -m config split_ratio \(splitRatio)",
            "\"$YABAI_BIN\" -m config window_placement \(settings.windowPlacement.rawValue)",
            "\"$YABAI_BIN\" -m config mouse_follows_focus \(mouseFollowsFocus)",
            "\"$YABAI_BIN\" -m config focus_follows_mouse \(focusFollowsMouse)",
            "",
            "\"$YABAI_BIN\" -m config mouse_modifier \(settings.mouseModifier.rawValue)",
            "\"$YABAI_BIN\" -m config mouse_action1 move",
            "\"$YABAI_BIN\" -m config mouse_action2 resize",
            "\"$YABAI_BIN\" -m config mouse_drop_action swap",
            "",
            "\"$YABAI_BIN\" -m config top_padding \(outerPadding)",
            "\"$YABAI_BIN\" -m config bottom_padding \(outerPadding)",
            "\"$YABAI_BIN\" -m config left_padding \(outerPadding)",
            "\"$YABAI_BIN\" -m config right_padding \(outerPadding)",
            "\"$YABAI_BIN\" -m config window_gap \(windowGap)"
        ]

        if settings.floatSystemSettings || settings.floatFinder || settings.floatActivityMonitor || settings.floatArchiveUtility {
            lines.append("")
            if settings.floatSystemSettings {
                lines.append("\"$YABAI_BIN\" -m rule --add app=\"^System Settings$\" manage=off")
            }
            if settings.floatFinder {
                lines.append("\"$YABAI_BIN\" -m rule --add app=\"^Finder$\" manage=off")
            }
            if settings.floatActivityMonitor {
                lines.append("\"$YABAI_BIN\" -m rule --add app=\"^Activity Monitor$\" manage=off")
            }
            if settings.floatArchiveUtility {
                lines.append("\"$YABAI_BIN\" -m rule --add app=\"^Archive Utility$\" manage=off")
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private func refreshYabaiStatus() {
        let fileManager = FileManager.default
        let candidatePaths = [
            "/run/current-system/sw/bin/yabai",
            "/opt/homebrew/bin/yabai",
            "/usr/local/bin/yabai",
            "\(fileManager.homeDirectoryForCurrentUser.path)/.nix-profile/bin/yabai"
        ]

        if let resolvedPath = candidatePaths.first(where: { fileManager.isExecutableFile(atPath: $0) }) {
            yabaiInstalled = true
            yabaiBinaryPath = resolvedPath
        } else {
            yabaiInstalled = false
            yabaiBinaryPath = nil
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", "pgrep -x yabai >/dev/null 2>&1"]

        do {
            try process.run()
            process.waitUntilExit()
            yabaiRunning = process.terminationStatus == 0
        } catch {
            yabaiRunning = false
        }

        if !yabaiInstalled {
            yabaiStatusMessage = "Not installed"
        } else if yabaiRunning {
            yabaiStatusMessage = "Running"
        } else {
            yabaiStatusMessage = "Installed, not running"
        }
    }

    private func runYabaiCommand(_ command: String) {
        guard !isRunningYabaiCommand else { return }
        isRunningYabaiCommand = true

        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            task.arguments = ["-lc", "export PATH=\"/run/current-system/sw/bin:/opt/homebrew/bin:/usr/local/bin:$PATH\"; \(command)"]

            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                print("Failed to run yabai command: \(error)")
            }

            DispatchQueue.main.async {
                self.isRunningYabaiCommand = false
                self.refreshYabaiStatus()
            }
        }
    }
}

struct WindowsScreen: View {
    @StateObject private var controller = WindowSettingsController()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                screenHeader(title: "Windows", subtitle: "macOS window-management settings backed by Dock and WindowManager defaults.")
                overviewSection
                minimizeSection
                missionControlSection
                stageManagerSection
                tilingSection
                yabaiConfigurationSection
                yabaiRulesSection
                yabaiSection
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            controller.load()
        }
    }

    private var overviewSection: some View {
        MacSettingsSection(title: "Overview") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Window Manager")
                            .font(.headline)
                        Text("These controls map to `com.apple.dock` and `com.apple.WindowManager`.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    MacMetricPill(value: controller.isApplying ? "Busy" : "Ready", label: "Status")
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stage Manager")
                            .font(.headline)
                        Text("Current workspace focus mode for app windows.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    MacMetricPill(value: controller.stageManagerEnabled ? "On" : "Off", label: "Mode")
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spaces Order")
                            .font(.headline)
                        Text("Whether Spaces follow recent usage order.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    MacMetricPill(value: controller.rearrangeSpaces ? "Recent" : "Fixed", label: "Sort")
                }
            }
        }
    }

    private var minimizeSection: some View {
        MacSettingsSection(title: "Minimize") {
            VStack(spacing: 0) {
                WindowsToggleRow(
                    title: "Minimize windows into application icon",
                    description: "Keep minimized windows grouped under the app icon instead of separate thumbnails.",
                    isOn: Binding(
                        get: { controller.minimizeToApplication },
                        set: { controller.applyMinimizeToApplication($0) }
                    )
                )

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Minimize Effect")
                            .font(.headline)
                        Text("Choose the animation used when a window is minimized.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.minimizeEffect },
                        set: { controller.applyMinimizeEffect($0) }
                    )) {
                        ForEach(WindowSettingsController.MinimizeEffect.allCases) { effect in
                            Text(effect.title).tag(effect)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
            }
        }
    }

    private var missionControlSection: some View {
        MacSettingsSection(title: "Mission Control") {
            WindowsToggleRow(
                title: "Rearrange Spaces based on most recent use",
                description: "Keep the Space order adaptive instead of preserving a fixed sequence.",
                isOn: Binding(
                    get: { controller.rearrangeSpaces },
                    set: { controller.applyRearrangeSpaces($0) }
                ),
                showsDivider: false
            )
        }
    }

    private var stageManagerSection: some View {
        MacSettingsSection(title: "Stage Manager") {
            VStack(spacing: 0) {
                WindowsToggleRow(
                    title: "Enable Stage Manager",
                    description: "Turn Stage Manager on or off for the current user.",
                    isOn: Binding(
                        get: { controller.stageManagerEnabled },
                        set: { controller.applyStageManagerEnabled($0) }
                    )
                )

                WindowsToggleRow(
                    title: "Show recent apps",
                    description: "Keep the recent-app strip visible while Stage Manager is active.",
                    isOn: Binding(
                        get: { controller.stageManagerShowsRecentApps },
                        set: { controller.applyStageManagerShowsRecentApps($0) }
                    )
                )

                WindowsToggleRow(
                    title: "Show desktop items",
                    description: "Expose files and folders on the desktop while Stage Manager is active.",
                    isOn: Binding(
                        get: { controller.stageManagerShowsDesktopItems },
                        set: { controller.applyStageManagerShowsDesktopItems($0) }
                    )
                )

                WindowsToggleRow(
                    title: "Show widgets on desktop",
                    description: "Keep desktop widgets visible during normal window management.",
                    isOn: Binding(
                        get: { controller.showDesktopWidgets },
                        set: { controller.applyShowDesktopWidgets($0) }
                    )
                )

                WindowsToggleRow(
                    title: "Show widgets in Stage Manager",
                    description: "Keep desktop widgets visible while Stage Manager is active.",
                    isOn: Binding(
                        get: { controller.showWidgetsInStageManager },
                        set: { controller.applyShowWidgetsInStageManager($0) }
                    )
                )

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Show windows from an application")
                            .font(.headline)
                        Text("Choose whether Stage Manager reveals one window or every window for the selected app.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.stageWindowGrouping },
                        set: { controller.applyStageWindowGrouping($0) }
                    )) {
                        ForEach(WindowSettingsController.StageWindowGrouping.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }
            }
        }
    }

    private var tilingSection: some View {
        MacSettingsSection(title: "Tiled Windows") {
            WindowsToggleRow(
                title: "Add margins around tiled windows",
                description: "Leave visible gaps between snapped windows instead of letting them touch.",
                isOn: Binding(
                    get: { controller.tiledWindowMargins },
                    set: { controller.applyTiledWindowMargins($0) }
                ),
                showsDivider: false
            )
        }
    }

    private var yabaiSection: some View {
        MacSettingsSection(title: "Yabai") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.headline)
                        Text(controller.yabaiBinaryPath ?? "No `yabai` binary found in the managed PATH.")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } trailing: {
                    HStack(spacing: 10) {
                        MacMetricPill(value: controller.hasUnsavedYabaiChanges ? "Dirty" : "Synced", label: "Config")
                        MacMetricPill(value: controller.yabaiStatusMessage, label: "Service")
                    }
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Managed Settings")
                            .font(.headline)
                        Text(controller.repoSettingsPath)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } trailing: {
                    Button("Reveal") {
                        controller.revealRepoSettings()
                    }
                    .buttonStyle(MacSecondaryButtonStyle())
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Generated Live Script")
                            .font(.headline)
                        Text(controller.liveGeneratedConfigPath)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } trailing: {
                    HStack(spacing: 10) {
                        MacMetricPill(value: controller.yabaiConfigExists ? "Present" : "Missing", label: "File")

                        Button("Reveal") {
                            controller.revealLiveGeneratedConfig()
                        }
                        .buttonStyle(MacSecondaryButtonStyle())
                    }
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Actions")
                            .font(.headline)
                        Text("Save the managed profile, then control the service or open Accessibility permissions.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) {
                            Button(controller.isSavingYabaiSettings ? "Saving..." : (controller.yabaiInstalled ? "Save & Reload" : "Save Config")) {
                                controller.saveYabaiSettings()
                            }
                            .buttonStyle(MacPrimaryButtonStyle())
                            .disabled(controller.isSavingYabaiSettings || !controller.hasUnsavedYabaiChanges)

                            Button("Reset") {
                                controller.resetYabaiSettings()
                            }
                            .buttonStyle(MacSecondaryButtonStyle())
                            .disabled(controller.isSavingYabaiSettings)

                            Button(controller.isRunningYabaiCommand ? "Working..." : "Start") {
                                controller.startYabai()
                            }
                            .buttonStyle(MacSecondaryButtonStyle())
                            .disabled(controller.isRunningYabaiCommand || !controller.yabaiInstalled)

                            Button("Restart") {
                                controller.restartYabai()
                            }
                            .buttonStyle(MacSecondaryButtonStyle())
                            .disabled(controller.isRunningYabaiCommand || !controller.yabaiInstalled)

                            Button("Stop") {
                                controller.stopYabai()
                            }
                            .buttonStyle(MacSecondaryButtonStyle())
                            .disabled(controller.isRunningYabaiCommand || !controller.yabaiInstalled)

                            Button("Accessibility") {
                                controller.openAccessibilitySettings()
                            }
                            .buttonStyle(MacSecondaryButtonStyle())
                        }

                        VStack(alignment: .trailing, spacing: 10) {
                            Button(controller.isSavingYabaiSettings ? "Saving..." : (controller.yabaiInstalled ? "Save & Reload" : "Save Config")) {
                                controller.saveYabaiSettings()
                            }
                            .buttonStyle(MacPrimaryButtonStyle())
                            .disabled(controller.isSavingYabaiSettings || !controller.hasUnsavedYabaiChanges)

                            Button("Reset") {
                                controller.resetYabaiSettings()
                            }
                            .buttonStyle(MacSecondaryButtonStyle())
                            .disabled(controller.isSavingYabaiSettings)

                            Button(controller.isRunningYabaiCommand ? "Working..." : "Start") {
                                controller.startYabai()
                            }
                            .buttonStyle(MacSecondaryButtonStyle())
                            .disabled(controller.isRunningYabaiCommand || !controller.yabaiInstalled)

                            Button("Restart") {
                                controller.restartYabai()
                            }
                            .buttonStyle(MacSecondaryButtonStyle())
                            .disabled(controller.isRunningYabaiCommand || !controller.yabaiInstalled)

                            Button("Stop") {
                                controller.stopYabai()
                            }
                            .buttonStyle(MacSecondaryButtonStyle())
                            .disabled(controller.isRunningYabaiCommand || !controller.yabaiInstalled)

                            Button("Accessibility") {
                                controller.openAccessibilitySettings()
                            }
                            .buttonStyle(MacSecondaryButtonStyle())
                        }
                    }
                }
            }
        }
    }

    private var yabaiConfigurationSection: some View {
        MacSettingsSection(title: "Yabai Configuration") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Layout")
                            .font(.headline)
                        Text("Choose the base tiling mode used when yabai manages a space.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.layout },
                        set: { controller.yabaiSettings.layout = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.Layout.allCases) { layout in
                            Text(layout.title).tag(layout)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Window Placement")
                            .font(.headline)
                        Text("Control whether new splits attach as the first or second child in the tree.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.windowPlacement },
                        set: { controller.yabaiSettings.windowPlacement = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.WindowPlacement.allCases) { placement in
                            Text(placement.title).tag(placement)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }

                WindowsToggleRow(
                    title: "Auto balance",
                    description: "Automatically rebalance the split tree when windows are inserted or removed.",
                    isOn: Binding(
                        get: { controller.yabaiSettings.autoBalance },
                        set: { controller.yabaiSettings.autoBalance = $0 }
                    )
                )

                WindowsSliderRow(
                    title: "Split Ratio",
                    description: "Default split ratio for newly created containers.",
                    value: Binding(
                        get: { controller.yabaiSettings.splitRatio },
                        set: { controller.yabaiSettings.splitRatio = $0 }
                    ),
                    range: 0.10...0.90,
                    valueLabel: String(format: "%.2f", controller.yabaiSettings.splitRatio)
                )

                WindowsSliderRow(
                    title: "Outer Padding",
                    description: "Apply the same padding to the top, bottom, left, and right edges of each managed space.",
                    value: Binding(
                        get: { controller.yabaiSettings.outerPadding },
                        set: { controller.yabaiSettings.outerPadding = $0 }
                    ),
                    range: 0...40,
                    valueLabel: "\(Int(controller.yabaiSettings.outerPadding.rounded())) px"
                )

                WindowsSliderRow(
                    title: "Window Gap",
                    description: "Set the spacing between tiled windows.",
                    value: Binding(
                        get: { controller.yabaiSettings.windowGap },
                        set: { controller.yabaiSettings.windowGap = $0 }
                    ),
                    range: 0...40,
                    valueLabel: "\(Int(controller.yabaiSettings.windowGap.rounded())) px"
                )

                WindowsToggleRow(
                    title: "Mouse follows focus",
                    description: "Move the pointer to the focused window when focus changes.",
                    isOn: Binding(
                        get: { controller.yabaiSettings.mouseFollowsFocus },
                        set: { controller.yabaiSettings.mouseFollowsFocus = $0 }
                    )
                )

                WindowsToggleRow(
                    title: "Focus follows mouse",
                    description: "Focus a window when the pointer moves across it.",
                    isOn: Binding(
                        get: { controller.yabaiSettings.focusFollowsMouse },
                        set: { controller.yabaiSettings.focusFollowsMouse = $0 }
                    )
                )

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mouse Modifier")
                            .font(.headline)
                        Text("Choose the modifier key used for pointer-driven move and resize actions.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.mouseModifier },
                        set: { controller.yabaiSettings.mouseModifier = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.MouseModifier.allCases) { modifier in
                            Text(modifier.title).tag(modifier)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 110)
                }
            }
        }
    }

    private var yabaiRulesSection: some View {
        MacSettingsSection(title: "Yabai Floating Rules") {
            VStack(spacing: 0) {
                WindowsToggleRow(
                    title: "Float System Settings",
                    description: "Keep System Settings unmanaged by yabai.",
                    isOn: Binding(
                        get: { controller.yabaiSettings.floatSystemSettings },
                        set: { controller.yabaiSettings.floatSystemSettings = $0 }
                    )
                )

                WindowsToggleRow(
                    title: "Float Finder",
                    description: "Keep Finder windows unmanaged by yabai.",
                    isOn: Binding(
                        get: { controller.yabaiSettings.floatFinder },
                        set: { controller.yabaiSettings.floatFinder = $0 }
                    )
                )

                WindowsToggleRow(
                    title: "Float Activity Monitor",
                    description: "Keep Activity Monitor windows unmanaged by yabai.",
                    isOn: Binding(
                        get: { controller.yabaiSettings.floatActivityMonitor },
                        set: { controller.yabaiSettings.floatActivityMonitor = $0 }
                    )
                )

                WindowsToggleRow(
                    title: "Float Archive Utility",
                    description: "Keep Archive Utility dialogs unmanaged by yabai.",
                    isOn: Binding(
                        get: { controller.yabaiSettings.floatArchiveUtility },
                        set: { controller.yabaiSettings.floatArchiveUtility = $0 }
                    ),
                    showsDivider: false
                )
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
}

private struct WindowsToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    var showsDivider = true

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Text(description)
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 12)

                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Text(description)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Spacer(minLength: 0)
                        Toggle("", isOn: $isOn)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            if showsDivider {
                MacSettingsDivider()
            }
        }
    }
}

private struct WindowsSliderRow: View {
    let title: String
    let description: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let valueLabel: String
    var showsDivider = true

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Text(description)
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 12)

                    Text(valueLabel)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Slider(value: $value, in: range)
                    .tint(Color(red: 0.39, green: 0.76, blue: 0.27))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            if showsDivider {
                MacSettingsDivider()
            }
        }
    }
}

#Preview {
    WindowsScreen()
        .frame(width: 1000, height: 700)
}
