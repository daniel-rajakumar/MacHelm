import SwiftUI

@MainActor
final class AppearanceSettingsController: ObservableObject {
    enum InterfaceMode: String, CaseIterable, Identifiable {
        case auto
        case light
        case dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .auto:
                return "Auto"
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            }
        }
    }

    enum AccentColorOption: String, CaseIterable, Identifiable {
        case multicolor
        case red
        case orange
        case yellow
        case green
        case blue
        case purple
        case pink
        case graphite

        var id: String { rawValue }

        var title: String {
            switch self {
            case .multicolor:
                return "Multicolor"
            case .red:
                return "Red"
            case .orange:
                return "Orange"
            case .yellow:
                return "Yellow"
            case .green:
                return "Green"
            case .blue:
                return "Blue"
            case .purple:
                return "Purple"
            case .pink:
                return "Pink"
            case .graphite:
                return "Graphite"
            }
        }

        var systemValue: Int? {
            switch self {
            case .multicolor:
                return nil
            case .red:
                return 0
            case .orange:
                return 1
            case .yellow:
                return 2
            case .green:
                return 3
            case .blue:
                return 4
            case .purple:
                return 5
            case .pink:
                return 6
            case .graphite:
                return -1
            }
        }

        var color: Color {
            switch self {
            case .multicolor:
                return .white
            case .red:
                return Color(red: 0.98, green: 0.35, blue: 0.29)
            case .orange:
                return Color(red: 0.96, green: 0.58, blue: 0.23)
            case .yellow:
                return Color(red: 0.90, green: 0.75, blue: 0.18)
            case .green:
                return Color(red: 0.28, green: 0.69, blue: 0.29)
            case .blue:
                return Color(red: 0.21, green: 0.52, blue: 0.96)
            case .purple:
                return Color(red: 0.60, green: 0.38, blue: 0.87)
            case .pink:
                return Color(red: 0.94, green: 0.34, blue: 0.62)
            case .graphite:
                return Color(red: 0.52, green: 0.54, blue: 0.58)
            }
        }

        static func fromSystemValue(_ value: Int?) -> AccentColorOption {
            switch value {
            case .none:
                return .multicolor
            case .some(-1):
                return .graphite
            case .some(0):
                return .red
            case .some(1):
                return .orange
            case .some(2):
                return .yellow
            case .some(3):
                return .green
            case .some(4):
                return .blue
            case .some(5):
                return .purple
            case .some(6):
                return .pink
            default:
                return .multicolor
            }
        }
    }

    enum HighlightColorOption: String, CaseIterable, Identifiable {
        case accent
        case blue
        case purple
        case pink
        case red
        case orange
        case yellow
        case green
        case graphite

        var id: String { rawValue }

        var title: String {
            switch self {
            case .accent:
                return "Accent Default"
            case .blue:
                return "Blue"
            case .purple:
                return "Purple"
            case .pink:
                return "Pink"
            case .red:
                return "Red"
            case .orange:
                return "Orange"
            case .yellow:
                return "Yellow"
            case .green:
                return "Green"
            case .graphite:
                return "Graphite"
            }
        }

        var systemValue: String? {
            switch self {
            case .accent:
                return nil
            case .blue:
                return "0.698039 0.843137 1.000000 Blue"
            case .purple:
                return "0.968627 0.831373 1.000000 Purple"
            case .pink:
                return "1.000000 0.749020 0.823529 Pink"
            case .red:
                return "1.000000 0.733333 0.721569 Red"
            case .orange:
                return "1.000000 0.874510 0.701961 Orange"
            case .yellow:
                return "1.000000 0.937255 0.690196 Yellow"
            case .green:
                return "0.752941 0.964706 0.678431 Green"
            case .graphite:
                return "0.847059 0.847059 0.862745 Graphite"
            }
        }

        static func fromSystemValue(_ value: String?) -> HighlightColorOption {
            guard let value else {
                return .accent
            }

            let normalized = value.lowercased()
            if normalized.contains("blue") {
                return .blue
            }
            if normalized.contains("purple") {
                return .purple
            }
            if normalized.contains("pink") {
                return .pink
            }
            if normalized.contains("red") {
                return .red
            }
            if normalized.contains("orange") {
                return .orange
            }
            if normalized.contains("yellow") {
                return .yellow
            }
            if normalized.contains("green") {
                return .green
            }
            if normalized.contains("graphite") {
                return .graphite
            }

            return .accent
        }
    }

    enum SidebarIconSize: Int, CaseIterable, Identifiable {
        case small = 1
        case medium = 2
        case large = 3

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .small:
                return "Small"
            case .medium:
                return "Medium"
            case .large:
                return "Large"
            }
        }
    }

    enum FontSmoothing: Int, CaseIterable, Identifiable {
        case off = 0
        case light = 1
        case standard = 2
        case strong = 3

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .off:
                return "Off"
            case .light:
                return "Light"
            case .standard:
                return "Standard"
            case .strong:
                return "Strong"
            }
        }
    }

    @Published var interfaceMode: InterfaceMode = .light
    @Published var accentColor: AccentColorOption = .multicolor
    @Published var highlightColor: HighlightColorOption = .accent
    @Published var sidebarIconSize: SidebarIconSize = .medium
    @Published var fontSmoothing: FontSmoothing = .standard
    @Published var reduceTransparency = false
    @Published var increaseContrast = false
    @Published var reduceDesktopTinting = false
    @Published var isApplying = false

    private let userFontsDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Fonts")
    private let localFontsDirectoryURL = URL(fileURLWithPath: "/Library/Fonts")
    private let systemFontsDirectoryURL = URL(fileURLWithPath: "/System/Library/Fonts")

    var userFontsDirectoryPath: String {
        userFontsDirectoryURL.path
    }

    var localFontsDirectoryPath: String {
        localFontsDirectoryURL.path
    }

    var systemFontsDirectoryPath: String {
        systemFontsDirectoryURL.path
    }

    var enabledAppearanceTweaks: Int {
        [
            reduceTransparency,
            increaseContrast,
            reduceDesktopTinting,
            interfaceMode == .dark
        ]
        .filter { $0 }
        .count
    }

    func load() {
        let globalDomain = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain) ?? [:]
        let accessibilityDomain = UserDefaults.standard.persistentDomain(forName: "com.apple.universalaccess") ?? [:]

        interfaceMode = interfaceMode(from: globalDomain)
        accentColor = AccentColorOption.fromSystemValue(integerValue(forKey: "AppleAccentColor", in: globalDomain))
        highlightColor = HighlightColorOption.fromSystemValue(globalDomain["AppleHighlightColor"] as? String)
        sidebarIconSize = SidebarIconSize(rawValue: integerValue(forKey: "NSTableViewDefaultSizeMode", in: globalDomain) ?? 2) ?? .medium
        fontSmoothing = FontSmoothing(rawValue: integerValue(forKey: "AppleFontSmoothing", in: globalDomain) ?? 2) ?? .standard
        reduceDesktopTinting = boolValue(forKey: "AppleReduceDesktopTinting", in: globalDomain, default: false)
        reduceTransparency = boolValue(forKey: "reduceTransparency", in: accessibilityDomain, default: false)
        increaseContrast = boolValue(forKey: "increaseContrast", in: accessibilityDomain, default: false)
    }

    func applyInterfaceMode(_ mode: InterfaceMode) {
        interfaceMode = mode

        switch mode {
        case .auto:
            performUpdate(
                commands: [
                    "defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool true",
                    "defaults delete -g AppleInterfaceStyle >/dev/null 2>&1 || true"
                ],
                restartProcesses: ["SystemUIServer"]
            )
        case .light:
            performUpdate(
                commands: [
                    "defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool false",
                    "defaults delete -g AppleInterfaceStyle >/dev/null 2>&1 || true"
                ],
                restartProcesses: ["SystemUIServer"]
            )
        case .dark:
            performUpdate(
                commands: [
                    "defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool false",
                    "defaults write -g AppleInterfaceStyle -string Dark"
                ],
                restartProcesses: ["SystemUIServer"]
            )
        }
    }

    func applyAccentColor(_ option: AccentColorOption) {
        accentColor = option

        if let value = option.systemValue {
            performUpdate(
                commands: ["defaults write -g AppleAccentColor -int \(value)"],
                restartProcesses: ["SystemUIServer"]
            )
        } else {
            performUpdate(
                commands: ["defaults delete -g AppleAccentColor >/dev/null 2>&1 || true"],
                restartProcesses: ["SystemUIServer"]
            )
        }
    }

    func applyHighlightColor(_ option: HighlightColorOption) {
        highlightColor = option

        if let value = option.systemValue {
            performUpdate(
                commands: ["defaults write -g AppleHighlightColor -string '\(value)'"],
                restartProcesses: ["SystemUIServer"]
            )
        } else {
            performUpdate(
                commands: ["defaults delete -g AppleHighlightColor >/dev/null 2>&1 || true"],
                restartProcesses: ["SystemUIServer"]
            )
        }
    }

    func applySidebarIconSize(_ size: SidebarIconSize) {
        sidebarIconSize = size
        performUpdate(
            commands: ["defaults write -g NSTableViewDefaultSizeMode -int \(size.rawValue)"],
            restartProcesses: ["Finder"]
        )
    }

    func applyFontSmoothing(_ smoothing: FontSmoothing) {
        fontSmoothing = smoothing
        performUpdate(
            commands: ["defaults write -g AppleFontSmoothing -int \(smoothing.rawValue)"],
            restartProcesses: ["SystemUIServer"]
        )
    }

    func applyReduceTransparency(_ value: Bool) {
        reduceTransparency = value
        performUpdate(
            commands: ["defaults write com.apple.universalaccess reduceTransparency -bool \(value ? "true" : "false")"],
            restartProcesses: ["SystemUIServer"]
        )
    }

    func applyIncreaseContrast(_ value: Bool) {
        increaseContrast = value
        performUpdate(
            commands: ["defaults write com.apple.universalaccess increaseContrast -bool \(value ? "true" : "false")"],
            restartProcesses: ["SystemUIServer"]
        )
    }

    func applyReduceDesktopTinting(_ value: Bool) {
        reduceDesktopTinting = value
        performUpdate(
            commands: ["defaults write -g AppleReduceDesktopTinting -bool \(value ? "true" : "false")"],
            restartProcesses: ["Finder", "SystemUIServer"]
        )
    }

    func revealUserFontsDirectory() {
        NSWorkspace.shared.activateFileViewerSelecting([userFontsDirectoryURL])
    }

    func revealLocalFontsDirectory() {
        NSWorkspace.shared.activateFileViewerSelecting([localFontsDirectoryURL])
    }

    func revealSystemFontsDirectory() {
        NSWorkspace.shared.activateFileViewerSelecting([systemFontsDirectoryURL])
    }

    func openSystemSettings() {
        let appURL = URL(fileURLWithPath: "/System/Applications/System Settings.app")
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration)
    }

    private func interfaceMode(from domain: [String: Any]) -> InterfaceMode {
        let autoEnabled = boolValue(forKey: "AppleInterfaceStyleSwitchesAutomatically", in: domain, default: false)
        if autoEnabled {
            return .auto
        }

        if let style = domain["AppleInterfaceStyle"] as? String,
           style.caseInsensitiveCompare("Dark") == .orderedSame {
            return .dark
        }

        return .light
    }

    private func integerValue(forKey key: String, in domain: [String: Any]) -> Int? {
        if let value = domain[key] as? Int {
            return value
        }
        if let value = domain[key] as? NSNumber {
            return value.intValue
        }
        return nil
    }

    private func boolValue(forKey key: String, in domain: [String: Any], default fallback: Bool) -> Bool {
        guard let value = domain[key] else {
            return fallback
        }

        if let bool = value as? Bool {
            return bool
        }

        if let number = value as? NSNumber {
            return number.boolValue
        }

        return fallback
    }

    private func performUpdate(commands: [String], restartProcesses: [String]) {
        guard !isApplying else { return }
        isApplying = true

        DispatchQueue.global(qos: .userInitiated).async {
            let shellScript = """
            set -e
            \(commands.joined(separator: "\n"))
            \(restartProcesses.map { "killall '\($0)' >/dev/null 2>&1 || true" }.joined(separator: "\n"))
            """

            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            task.arguments = ["-lc", shellScript]

            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                print("Failed to apply appearance setting: \(error)")
            }

            DispatchQueue.main.async {
                self.isApplying = false
                self.load()
            }
        }
    }
}

struct AppearanceScreen: View {
    @StateObject private var controller = AppearanceSettingsController()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                screenHeader(
                    title: "Appearance",
                    subtitle: "Theme, color, icon, and text rendering preferences backed by live macOS defaults."
                )
                overviewSection
                themeSection
                colorSection
                chromeSection
                accessibilitySection
                assetsSection
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
                        Text("Appearance Profile")
                            .font(.headline)
                        Text("Global look-and-feel settings for the current macOS user.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    MacMetricPill(value: controller.isApplying ? "Applying" : "Ready", label: "Status")
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Theme")
                            .font(.headline)
                        Text("Current interface mode and accent selection.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    HStack(spacing: 10) {
                        MacMetricPill(value: controller.interfaceMode.title, label: "Mode")
                        MacMetricPill(value: controller.accentColor.title, label: "Accent")
                    }
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Readable UI")
                            .font(.headline)
                        Text("Contrast, transparency, and wallpaper tinting adjustments.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    HStack(spacing: 10) {
                        MacMetricPill(value: "\(controller.enabledAppearanceTweaks)", label: "Tweaks")
                        MacMetricPill(value: controller.sidebarIconSize.title, label: "Sidebar")
                    }
                }
            }
        }
    }

    private var themeSection: some View {
        MacSettingsSection(
            title: "Theme",
            footer: "Theme changes are written to the global defaults domain. Finder or menu bar visuals can take a moment to refresh."
        ) {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Interface Appearance")
                            .font(.headline)
                        Text("Switch between light, dark, or scheduled automatic appearance.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.interfaceMode },
                        set: { controller.applyInterfaceMode($0) }
                    )) {
                        ForEach(AppearanceSettingsController.InterfaceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }
            }
        }
    }

    private var colorSection: some View {
        MacSettingsSection(title: "Colors") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Accent Color")
                            .font(.headline)
                        Text("Controls the tint used for selected controls, buttons, and highlighted interface elements.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    AccentColorMenu(
                        selection: Binding(
                            get: { controller.accentColor },
                            set: { controller.applyAccentColor($0) }
                        )
                    )
                    .frame(width: 160)
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Highlight Color")
                            .font(.headline)
                        Text("Sets the selection highlight used in lists, text views, and table rows.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.highlightColor },
                        set: { controller.applyHighlightColor($0) }
                    )) {
                        ForEach(AppearanceSettingsController.HighlightColorOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 170)
                }
            }
        }
    }

    private var chromeSection: some View {
        MacSettingsSection(
            title: "Icons and Text",
            footer: "Sidebar icon size and font smoothing affect Finder and other macOS apps that honor the shared defaults."
        ) {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sidebar Icon Size")
                            .font(.headline)
                        Text("Adjusts the default icon size used by Finder and other list-style sidebars.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.sidebarIconSize },
                        set: { controller.applySidebarIconSize($0) }
                    )) {
                        ForEach(AppearanceSettingsController.SidebarIconSize.allCases) { size in
                            Text(size.title).tag(size)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 130)
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Font Smoothing")
                            .font(.headline)
                        Text("Tune how aggressively macOS smooths small text across the interface.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.fontSmoothing },
                        set: { controller.applyFontSmoothing($0) }
                    )) {
                        ForEach(AppearanceSettingsController.FontSmoothing.allCases) { smoothing in
                            Text(smoothing.title).tag(smoothing)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }
            }
        }
    }

    private var accessibilitySection: some View {
        MacSettingsSection(
            title: "Contrast and Transparency",
            footer: "These settings write to `com.apple.universalaccess` or the global defaults domain and can briefly refresh `SystemUIServer`."
        ) {
            VStack(spacing: 0) {
                AppearanceToggleRow(
                    title: "Reduce transparency",
                    description: "Replace translucent materials with flatter surfaces across menus, sidebars, and sheets.",
                    isOn: Binding(
                        get: { controller.reduceTransparency },
                        set: { controller.applyReduceTransparency($0) }
                    )
                )

                AppearanceToggleRow(
                    title: "Increase contrast",
                    description: "Strengthen separators and control outlines for clearer visual boundaries.",
                    isOn: Binding(
                        get: { controller.increaseContrast },
                        set: { controller.applyIncreaseContrast($0) }
                    )
                )

                AppearanceToggleRow(
                    title: "Reduce wallpaper tinting in windows",
                    description: "Stops window chrome from borrowing as much color from the desktop wallpaper.",
                    isOn: Binding(
                        get: { controller.reduceDesktopTinting },
                        set: { controller.applyReduceDesktopTinting($0) }
                    ),
                    showsDivider: false
                )
            }
        }
    }

    private var assetsSection: some View {
        MacSettingsSection(title: "Fonts and System Settings") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("User Fonts")
                            .font(.headline)
                        Text(controller.userFontsDirectoryPath)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } trailing: {
                    Button("Reveal") {
                        controller.revealUserFontsDirectory()
                    }
                    .buttonStyle(MacSecondaryButtonStyle())
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Shared Fonts")
                            .font(.headline)
                        Text(controller.localFontsDirectoryPath)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } trailing: {
                    Button("Reveal") {
                        controller.revealLocalFontsDirectory()
                    }
                    .buttonStyle(MacSecondaryButtonStyle())
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Fonts")
                            .font(.headline)
                        Text(controller.systemFontsDirectoryPath)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } trailing: {
                    Button("Reveal") {
                        controller.revealSystemFontsDirectory()
                    }
                    .buttonStyle(MacSecondaryButtonStyle())
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Settings")
                            .font(.headline)
                        Text("Open the full macOS Settings app for wallpapers, lock screen, and any appearance controls that are not safe to rewrite directly.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Button("Open") {
                        controller.openSystemSettings()
                    }
                    .buttonStyle(MacPrimaryButtonStyle())
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
}

private struct AppearanceToggleRow: View {
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

private struct AccentColorMenu: View {
    @Binding var selection: AppearanceSettingsController.AccentColorOption

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(AppearanceSettingsController.AccentColorOption.allCases) { option in
                Label {
                    Text(option.title)
                } icon: {
                    Circle()
                        .fill(option.color)
                        .frame(width: 10, height: 10)
                }
                .tag(option)
            }
        }
        .pickerStyle(.menu)
    }
}

#Preview {
    AppearanceScreen()
        .frame(width: 1000, height: 700)
}
