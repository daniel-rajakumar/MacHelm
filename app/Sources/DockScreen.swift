import SwiftUI

@MainActor
final class DockSettingsController: ObservableObject {
    enum Position: String, CaseIterable, Identifiable {
        case bottom
        case left
        case right

        var id: String { rawValue }

        var title: String {
            rawValue.capitalized
        }
    }

    enum MinimizeEffect: String, CaseIterable, Identifiable {
        case genie
        case scale

        var id: String { rawValue }

        var title: String {
            rawValue.capitalized
        }
    }

    enum HotCornerAction: Int, CaseIterable, Identifiable {
        case none = 0
        case missionControl = 2
        case appWindows = 3
        case desktop = 4
        case startScreenSaver = 5
        case disableScreenSaver = 6
        case sleepDisplay = 10
        case launchpad = 11
        case notificationCenter = 12
        case lockScreen = 13
        case quickNote = 14

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .none:
                return "Off"
            case .missionControl:
                return "Mission Control"
            case .appWindows:
                return "Application Windows"
            case .desktop:
                return "Desktop"
            case .startScreenSaver:
                return "Start Screen Saver"
            case .disableScreenSaver:
                return "Disable Screen Saver"
            case .sleepDisplay:
                return "Put Display to Sleep"
            case .launchpad:
                return "Launchpad"
            case .notificationCenter:
                return "Notification Center"
            case .lockScreen:
                return "Lock Screen"
            case .quickNote:
                return "Quick Note"
            }
        }
    }

    enum HotCornerModifier: Int, CaseIterable, Identifiable {
        case none = 0
        case command = 1_048_576
        case option = 524_288
        case control = 262_144
        case shift = 131_072

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .none:
                return "No Modifier"
            case .command:
                return "Command"
            case .option:
                return "Option"
            case .control:
                return "Control"
            case .shift:
                return "Shift"
            }
        }
    }

    @Published var autoHide = false
    @Published var magnification = false
    @Published var showRecentApps = false
    @Published var minimizeToApplication = false
    @Published var showHiddenApps = false
    @Published var showProcessIndicators = true
    @Published var showOnlyRunningApps = false
    @Published var scrollToOpenStacks = false
    @Published var launchAnimation = true
    @Published var disableBouncing = false
    @Published var iconSize: Double = 48
    @Published var magnifiedSize: Double = 64
    @Published var autoHideDelay: Double = 0
    @Published var autoHideTimeModifier: Double = 0.5
    @Published var position: Position = .bottom
    @Published var minimizeEffect: MinimizeEffect = .genie
    @Published var topLeftCorner: HotCornerAction = .none
    @Published var topRightCorner: HotCornerAction = .none
    @Published var bottomLeftCorner: HotCornerAction = .none
    @Published var bottomRightCorner: HotCornerAction = .none
    @Published var topLeftModifier: HotCornerModifier = .none
    @Published var topRightModifier: HotCornerModifier = .none
    @Published var bottomLeftModifier: HotCornerModifier = .none
    @Published var bottomRightModifier: HotCornerModifier = .none
    @Published var pinnedAppNames: [String] = []
    @Published var pinnedOtherNames: [String] = []
    @Published var recentAppCount = 0
    @Published var isApplying = false

    private let dockDefaults = UserDefaults(suiteName: "com.apple.dock")

    var activeHotCornerCount: Int {
        [topLeftCorner, topRightCorner, bottomLeftCorner, bottomRightCorner]
            .filter { $0 != .none }
            .count
    }

    func load() {
        autoHide = boolValue(forKey: "autohide", default: false)
        magnification = boolValue(forKey: "magnification", default: false)
        showRecentApps = boolValue(forKey: "show-recents", default: true)
        minimizeToApplication = boolValue(forKey: "minimize-to-application", default: false)
        showHiddenApps = boolValue(forKey: "showhidden", default: false)
        showProcessIndicators = boolValue(forKey: "show-process-indicators", default: true)
        showOnlyRunningApps = boolValue(forKey: "static-only", default: false)
        scrollToOpenStacks = boolValue(forKey: "scroll-to-open", default: false)
        launchAnimation = boolValue(forKey: "launchanim", default: true)
        disableBouncing = boolValue(forKey: "no-bouncing", default: false)

        iconSize = numericValue(forKey: "tilesize", default: 48)
        magnifiedSize = numericValue(forKey: "largesize", default: 64)
        autoHideDelay = numericValue(forKey: "autohide-delay", default: 0)
        autoHideTimeModifier = numericValue(forKey: "autohide-time-modifier", default: 0.5)

        if let orientation = dockDefaults?.string(forKey: "orientation"),
           let position = Position(rawValue: orientation) {
            self.position = position
        } else {
            position = .bottom
        }

        if let effect = dockDefaults?.string(forKey: "mineffect"),
           let minimizeEffect = MinimizeEffect(rawValue: effect) {
            self.minimizeEffect = minimizeEffect
        } else {
            minimizeEffect = .genie
        }

        topLeftCorner = hotCornerAction(forKey: "wvous-tl-corner")
        topRightCorner = hotCornerAction(forKey: "wvous-tr-corner")
        bottomLeftCorner = hotCornerAction(forKey: "wvous-bl-corner")
        bottomRightCorner = hotCornerAction(forKey: "wvous-br-corner")
        topLeftModifier = hotCornerModifier(forKey: "wvous-tl-modifier")
        topRightModifier = hotCornerModifier(forKey: "wvous-tr-modifier")
        bottomLeftModifier = hotCornerModifier(forKey: "wvous-bl-modifier")
        bottomRightModifier = hotCornerModifier(forKey: "wvous-br-modifier")

        pinnedAppNames = dockTileNames(forKey: "persistent-apps")
        pinnedOtherNames = dockTileNames(forKey: "persistent-others")
        recentAppCount = (dockDefaults?.array(forKey: "recent-apps") ?? []).count
    }

    func applyAutoHide(_ value: Bool) {
        autoHide = value
        write(value, forKey: "autohide")
    }

    func applyMagnification(_ value: Bool) {
        magnification = value
        write(value, forKey: "magnification")
    }

    func applyShowRecentApps(_ value: Bool) {
        showRecentApps = value
        write(value, forKey: "show-recents")
    }

    func applyMinimizeToApplication(_ value: Bool) {
        minimizeToApplication = value
        write(value, forKey: "minimize-to-application")
    }

    func applyShowHiddenApps(_ value: Bool) {
        showHiddenApps = value
        write(value, forKey: "showhidden")
    }

    func applyShowProcessIndicators(_ value: Bool) {
        showProcessIndicators = value
        write(value, forKey: "show-process-indicators")
    }

    func applyShowOnlyRunningApps(_ value: Bool) {
        showOnlyRunningApps = value
        write(value, forKey: "static-only")
    }

    func applyScrollToOpenStacks(_ value: Bool) {
        scrollToOpenStacks = value
        write(value, forKey: "scroll-to-open")
    }

    func applyLaunchAnimation(_ value: Bool) {
        launchAnimation = value
        write(value, forKey: "launchanim")
    }

    func applyDisableBouncing(_ value: Bool) {
        disableBouncing = value
        write(value, forKey: "no-bouncing")
    }

    func applyPosition(_ value: Position) {
        position = value
        write(value.rawValue, forKey: "orientation")
    }

    func applyMinimizeEffect(_ value: MinimizeEffect) {
        minimizeEffect = value
        write(value.rawValue, forKey: "mineffect")
    }

    func applyIconSize(_ value: Double) {
        iconSize = value
        write(Int(value.rounded()), forKey: "tilesize")
    }

    func applyMagnifiedSize(_ value: Double) {
        magnifiedSize = value
        write(Int(value.rounded()), forKey: "largesize")
    }

    func applyAutoHideDelay(_ value: Double) {
        autoHideDelay = value
        write(value, forKey: "autohide-delay")
    }

    func applyAutoHideTimeModifier(_ value: Double) {
        autoHideTimeModifier = value
        write(value, forKey: "autohide-time-modifier")
    }

    func applyHotCorner(_ corner: DockCorner, action: HotCornerAction) {
        switch corner {
        case .topLeft:
            topLeftCorner = action
        case .topRight:
            topRightCorner = action
        case .bottomLeft:
            bottomLeftCorner = action
        case .bottomRight:
            bottomRightCorner = action
        }

        write(action.rawValue, forKey: corner.actionKey)
    }

    func applyHotCornerModifier(_ corner: DockCorner, modifier: HotCornerModifier) {
        switch corner {
        case .topLeft:
            topLeftModifier = modifier
        case .topRight:
            topRightModifier = modifier
        case .bottomLeft:
            bottomLeftModifier = modifier
        case .bottomRight:
            bottomRightModifier = modifier
        }

        write(modifier.rawValue, forKey: corner.modifierKey)
    }

    func action(for corner: DockCorner) -> HotCornerAction {
        switch corner {
        case .topLeft:
            return topLeftCorner
        case .topRight:
            return topRightCorner
        case .bottomLeft:
            return bottomLeftCorner
        case .bottomRight:
            return bottomRightCorner
        }
    }

    func modifier(for corner: DockCorner) -> HotCornerModifier {
        switch corner {
        case .topLeft:
            return topLeftModifier
        case .topRight:
            return topRightModifier
        case .bottomLeft:
            return bottomLeftModifier
        case .bottomRight:
            return bottomRightModifier
        }
    }

    private func write(_ value: Any, forKey key: String) {
        dockDefaults?.set(value, forKey: key)
        dockDefaults?.synchronize()
        restartDock()
    }

    private func boolValue(forKey key: String, default fallback: Bool) -> Bool {
        guard dockDefaults?.object(forKey: key) != nil else {
            return fallback
        }

        return dockDefaults?.bool(forKey: key) ?? fallback
    }

    private func numericValue(forKey key: String, default fallback: Double) -> Double {
        if let value = dockDefaults?.object(forKey: key) as? Double {
            return value
        }

        if let value = dockDefaults?.object(forKey: key) as? Int {
            return Double(value)
        }

        if let value = dockDefaults?.object(forKey: key) as? NSNumber {
            return value.doubleValue
        }

        return fallback
    }

    private func integerValue(forKey key: String, default fallback: Int) -> Int {
        if let value = dockDefaults?.object(forKey: key) as? Int {
            return value
        }

        if let value = dockDefaults?.object(forKey: key) as? NSNumber {
            return value.intValue
        }

        return fallback
    }

    private func hotCornerAction(forKey key: String) -> HotCornerAction {
        HotCornerAction(rawValue: integerValue(forKey: key, default: 0)) ?? .none
    }

    private func hotCornerModifier(forKey key: String) -> HotCornerModifier {
        HotCornerModifier(rawValue: integerValue(forKey: key, default: 0)) ?? .none
    }

    private func dockTileNames(forKey key: String) -> [String] {
        guard let tiles = dockDefaults?.array(forKey: key) as? [[String: Any]] else {
            return []
        }

        return tiles.compactMap { tile in
            guard let tileData = tile["tile-data"] as? [String: Any],
                  let label = tileData["file-label"] as? String,
                  !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }

            return label
        }
    }

    private func restartDock() {
        guard !isApplying else { return }
        isApplying = true

        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            task.arguments = ["Dock"]

            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                print("Failed to restart Dock: \(error)")
            }

            DispatchQueue.main.async {
                self.isApplying = false
                self.load()
            }
        }
    }
}

enum DockCorner: CaseIterable, Identifiable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    var id: String { title }

    var title: String {
        switch self {
        case .topLeft:
            return "Top Left"
        case .topRight:
            return "Top Right"
        case .bottomLeft:
            return "Bottom Left"
        case .bottomRight:
            return "Bottom Right"
        }
    }

    var description: String {
        switch self {
        case .topLeft:
            return "Pointer to the upper-left corner."
        case .topRight:
            return "Pointer to the upper-right corner."
        case .bottomLeft:
            return "Pointer to the lower-left corner."
        case .bottomRight:
            return "Pointer to the lower-right corner."
        }
    }

    var actionKey: String {
        switch self {
        case .topLeft:
            return "wvous-tl-corner"
        case .topRight:
            return "wvous-tr-corner"
        case .bottomLeft:
            return "wvous-bl-corner"
        case .bottomRight:
            return "wvous-br-corner"
        }
    }

    var modifierKey: String {
        switch self {
        case .topLeft:
            return "wvous-tl-modifier"
        case .topRight:
            return "wvous-tr-modifier"
        case .bottomLeft:
            return "wvous-bl-modifier"
        case .bottomRight:
            return "wvous-br-modifier"
        }
    }
}

struct DockScreen: View {
    @StateObject private var controller = DockSettingsController()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                screenHeader(title: "Dock", subtitle: "Common and advanced Dock preferences backed by the live `com.apple.dock` domain.")
                overviewSection
                layoutSection
                behaviorSection
                animationSection
                hotCornersSection
                contentsSection
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
                        Text("System Dock")
                            .font(.headline)
                        Text("Changes here are written to `com.apple.dock` and applied live.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    MacMetricPill(value: controller.isApplying ? "Busy" : "Ready", label: "Status")
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Layout")
                            .font(.headline)
                        Text("Position, pinned items, and active hot corners.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    HStack(spacing: 10) {
                        MacMetricPill(value: controller.position.title, label: "Edge")
                        MacMetricPill(value: "\(controller.pinnedAppNames.count)", label: "Apps")
                        MacMetricPill(value: "\(controller.activeHotCornerCount)", label: "Corners")
                    }
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pinned Content")
                            .font(.headline)
                        Text("Dock apps, folders, and recent-app strip state.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    HStack(spacing: 10) {
                        MacMetricPill(value: "\(controller.pinnedOtherNames.count)", label: "Folders")
                        MacMetricPill(value: "\(controller.recentAppCount)", label: "Recent")
                    }
                }
            }
        }
    }

    private var layoutSection: some View {
        MacSettingsSection(title: "Layout") {
            VStack(spacing: 0) {
                DockMenuRow(
                    title: "Dock Position",
                    description: "Choose which screen edge the Dock should attach to.",
                    selection: Binding(
                        get: { controller.position },
                        set: { controller.applyPosition($0) }
                    ),
                    options: DockSettingsController.Position.allCases,
                    titleForOption: { $0.title },
                    width: 110
                )

                DockSliderRow(
                    title: "Icon Size",
                    description: "Adjust the base size of Dock app icons.",
                    value: Binding(
                        get: { controller.iconSize },
                        set: { controller.iconSize = $0 }
                    ),
                    range: 16...128,
                    valueLabel: "\(Int(controller.iconSize.rounded())) px",
                    onEditingChanged: { editing in
                        if !editing {
                            controller.applyIconSize(controller.iconSize)
                        }
                    }
                )

                DockSliderRow(
                    title: "Magnification Size",
                    description: "Set the maximum icon size used when magnification is enabled.",
                    value: Binding(
                        get: { controller.magnifiedSize },
                        set: { controller.magnifiedSize = $0 }
                    ),
                    range: 16...160,
                    valueLabel: "\(Int(controller.magnifiedSize.rounded())) px",
                    showsDivider: false,
                    onEditingChanged: { editing in
                        if !editing {
                            controller.applyMagnifiedSize(controller.magnifiedSize)
                        }
                    }
                )
            }
        }
    }

    private var behaviorSection: some View {
        MacSettingsSection(title: "Behavior") {
            VStack(spacing: 0) {
                DockToggleRow(
                    title: "Automatically hide and show the Dock",
                    description: "Hide the Dock until the pointer reaches the configured edge.",
                    isOn: Binding(
                        get: { controller.autoHide },
                        set: { controller.applyAutoHide($0) }
                    )
                )

                DockToggleRow(
                    title: "Magnification",
                    description: "Enlarge Dock icons when the pointer moves over them.",
                    isOn: Binding(
                        get: { controller.magnification },
                        set: { controller.applyMagnification($0) }
                    )
                )

                DockToggleRow(
                    title: "Show suggested and recent apps",
                    description: "Display recently used applications in the Dock.",
                    isOn: Binding(
                        get: { controller.showRecentApps },
                        set: { controller.applyShowRecentApps($0) }
                    )
                )

                DockToggleRow(
                    title: "Show running indicators",
                    description: "Display the active-app dots beneath running applications.",
                    isOn: Binding(
                        get: { controller.showProcessIndicators },
                        set: { controller.applyShowProcessIndicators($0) }
                    )
                )

                DockToggleRow(
                    title: "Dim hidden applications",
                    description: "Fade app icons when their windows are hidden.",
                    isOn: Binding(
                        get: { controller.showHiddenApps },
                        set: { controller.applyShowHiddenApps($0) }
                    )
                )

                DockToggleRow(
                    title: "Minimize windows into application icon",
                    description: "Keep minimized windows grouped under their app icon instead of separate thumbnails.",
                    isOn: Binding(
                        get: { controller.minimizeToApplication },
                        set: { controller.applyMinimizeToApplication($0) }
                    )
                )

                DockToggleRow(
                    title: "Show only open applications",
                    description: "Hide pinned-but-not-running apps from the Dock.",
                    isOn: Binding(
                        get: { controller.showOnlyRunningApps },
                        set: { controller.applyShowOnlyRunningApps($0) }
                    )
                )

                DockToggleRow(
                    title: "Scroll to open folders and stacks",
                    description: "Allow trackpad or mouse-wheel scrolling to open stack previews.",
                    isOn: Binding(
                        get: { controller.scrollToOpenStacks },
                        set: { controller.applyScrollToOpenStacks($0) }
                    )
                )

                DockToggleRow(
                    title: "Animate opening applications",
                    description: "Show the launch bounce animation when an app opens.",
                    isOn: Binding(
                        get: { controller.launchAnimation },
                        set: { controller.applyLaunchAnimation($0) }
                    )
                )

                DockToggleRow(
                    title: "Disable bouncing app icons",
                    description: "Suppress alert and attention bouncing in the Dock.",
                    isOn: Binding(
                        get: { controller.disableBouncing },
                        set: { controller.applyDisableBouncing($0) }
                    )
                )

                DockMenuRow(
                    title: "Minimize Effect",
                    description: "Choose the window minimize animation.",
                    selection: Binding(
                        get: { controller.minimizeEffect },
                        set: { controller.applyMinimizeEffect($0) }
                    ),
                    options: DockSettingsController.MinimizeEffect.allCases,
                    titleForOption: { $0.title },
                    width: 120,
                    showsDivider: false
                )
            }
        }
    }

    private var animationSection: some View {
        MacSettingsSection(title: "Animation") {
            VStack(spacing: 0) {
                DockSliderRow(
                    title: "Auto-hide reveal delay",
                    description: "Delay before the Dock reappears when auto-hide is enabled.",
                    value: Binding(
                        get: { controller.autoHideDelay },
                        set: { controller.autoHideDelay = $0 }
                    ),
                    range: 0...2,
                    valueLabel: dockSeconds(controller.autoHideDelay),
                    onEditingChanged: { editing in
                        if !editing {
                            controller.applyAutoHideDelay(controller.autoHideDelay)
                        }
                    }
                )

                DockSliderRow(
                    title: "Auto-hide animation duration",
                    description: "How fast the Dock animates in and out.",
                    value: Binding(
                        get: { controller.autoHideTimeModifier },
                        set: { controller.autoHideTimeModifier = $0 }
                    ),
                    range: 0...2,
                    valueLabel: dockSeconds(controller.autoHideTimeModifier),
                    showsDivider: false,
                    onEditingChanged: { editing in
                        if !editing {
                            controller.applyAutoHideTimeModifier(controller.autoHideTimeModifier)
                        }
                    }
                )
            }
        }
    }

    private var hotCornersSection: some View {
        MacSettingsSection(title: "Hot Corners", footer: "Hot corners are stored in the Dock domain too, so they fit naturally on this screen.") {
            VStack(spacing: 0) {
                ForEach(Array(DockCorner.allCases.enumerated()), id: \.element.id) { index, corner in
                    DockHotCornerRow(
                        title: corner.title,
                        description: corner.description,
                        action: Binding(
                            get: { controller.action(for: corner) },
                            set: { controller.applyHotCorner(corner, action: $0) }
                        ),
                        modifier: Binding(
                            get: { controller.modifier(for: corner) },
                            set: { controller.applyHotCornerModifier(corner, modifier: $0) }
                        ),
                        showsDivider: index != DockCorner.allCases.count - 1
                    )
                }
            }
        }
    }

    private var contentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MacSettingsSection(title: "Dock Contents") {
                VStack(spacing: 0) {
                    MacSettingsRow {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pinned Applications")
                                .font(.headline)
                            Text("Applications currently pinned on the left side of the Dock.")
                                .foregroundColor(.secondary)
                        }
                    } trailing: {
                        MacMetricPill(value: "\(controller.pinnedAppNames.count)", label: "Pinned")
                    }

                    MacSettingsRow {
                        Text(controller.pinnedAppNames.isEmpty ? "No pinned applications found." : controller.pinnedAppNames.joined(separator: ", "))
                            .font(.system(size: 12.5))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } trailing: {
                        EmptyView()
                    }

                    MacSettingsRow {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Folders and Stacks")
                                .font(.headline)
                            Text("Items pinned on the trailing side of the Dock.")
                                .foregroundColor(.secondary)
                        }
                    } trailing: {
                        MacMetricPill(value: "\(controller.pinnedOtherNames.count)", label: "Pinned")
                    }

                    MacSettingsRow {
                        Text(controller.pinnedOtherNames.isEmpty ? "No pinned folders or stacks found." : controller.pinnedOtherNames.joined(separator: ", "))
                            .font(.system(size: 12.5))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } trailing: {
                        EmptyView()
                    }

                    MacSettingsRow(showsDivider: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recent App Strip")
                                .font(.headline)
                            Text("Live count of the recent-app entries Dock is tracking right now.")
                                .foregroundColor(.secondary)
                        }
                    } trailing: {
                        MacMetricPill(value: "\(controller.recentAppCount)", label: "Entries")
                    }
                }
            }
        }
    }

    private func dockSeconds(_ value: Double) -> String {
        String(format: "%.2f s", value)
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

private struct DockToggleRow: View {
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

private struct DockSliderRow: View {
    let title: String
    let description: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let valueLabel: String
    var showsDivider = true
    let onEditingChanged: (Bool) -> Void

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

                Slider(value: $value, in: range, onEditingChanged: onEditingChanged)
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

private struct DockMenuRow<Option: Hashable>: View {
    let title: String
    let description: String
    @Binding var selection: Option
    let options: [Option]
    let titleForOption: (Option) -> String
    var width: CGFloat = 140
    var showsDivider = true

    var body: some View {
        VStack(spacing: 0) {
            MacSettingsRow(showsDivider: showsDivider) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .foregroundColor(.secondary)
                }
            } trailing: {
                Picker("", selection: $selection) {
                    ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                        Text(titleForOption(option)).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: width)
            }
        }
    }
}

private struct DockHotCornerRow: View {
    let title: String
    let description: String
    @Binding var action: DockSettingsController.HotCornerAction
    @Binding var modifier: DockSettingsController.HotCornerModifier
    var showsDivider = true

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Text(description)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    hotCornerControlStack(compact: false)
                        .frame(width: 248, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Text(description)
                            .foregroundColor(.secondary)
                    }

                    hotCornerControlStack(compact: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            if showsDivider {
                MacSettingsDivider()
            }
        }
    }

    @ViewBuilder
    private func hotCornerControlStack(compact: Bool) -> some View {
        if compact {
            VStack(alignment: .leading, spacing: 12) {
                hotCornerPickerField(
                    title: "Action",
                    compact: true,
                    picker: { actionPicker }
                )

                hotCornerPickerField(
                    title: "Modifier",
                    compact: true,
                    picker: { modifierPicker }
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                hotCornerPickerField(
                    title: "Action",
                    compact: false,
                    picker: { actionPicker }
                )

                hotCornerPickerField(
                    title: "Modifier",
                    compact: false,
                    picker: { modifierPicker }
                )
            }
        }
    }

    private func hotCornerPickerField<PickerView: View>(
        title: String,
        compact: Bool,
        @ViewBuilder picker: () -> PickerView
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundColor(.secondary)

            picker()
                .frame(maxWidth: compact ? .infinity : 248, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionPicker: some View {
        Picker("", selection: $action) {
            ForEach(DockSettingsController.HotCornerAction.allCases) { option in
                Text(option.title).tag(option)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }

    private var modifierPicker: some View {
        Picker("", selection: $modifier) {
            ForEach(DockSettingsController.HotCornerModifier.allCases) { option in
                Text(option.title).tag(option)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }
}

#Preview {
    DockScreen()
        .frame(width: 1000, height: 700)
}
