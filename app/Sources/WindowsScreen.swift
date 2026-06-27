import SwiftUI

private extension String {
    var yabaiTitle: String {
        replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    var slugified: String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        let lowered = lowercased().replacingOccurrences(of: " ", with: "-")
        let scalars = lowered.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        return String(scalars)
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

struct YabaiManagedSettings: Codable, Equatable {
    struct RuleConfig: Codable, Equatable, Identifiable {
        var id: String { label }
        var label: String
        var name: String
        var appPattern: String
        var titlePattern = ""
        var manage = false
        var enabled = true

        var ruleDefinition: YabaiRuleDefinition? {
            let trimmedAppPattern = appPattern.trimmingCharacters(in: .whitespacesAndNewlines)
            guard enabled, !trimmedAppPattern.isEmpty else { return nil }
            let trimmedTitlePattern = titlePattern.trimmingCharacters(in: .whitespacesAndNewlines)
            return YabaiRuleDefinition(
                label: label,
                appPattern: trimmedAppPattern,
                titlePattern: trimmedTitlePattern.isEmpty ? nil : trimmedTitlePattern,
                manage: manage
            )
        }
    }

    struct CustomRule: Codable, Equatable, Identifiable {
        var id: String
        var label: String
        var name = ""
        var appPattern = ""
        var titlePattern = ""
        var manage = false
        var enabled = true

        init(
            id: String = UUID().uuidString,
            label: String? = nil,
            name: String = "",
            appPattern: String = "",
            titlePattern: String = "",
            manage: Bool = false,
            enabled: Bool = true
        ) {
            self.id = id
            self.label = label ?? "machelm-custom-rule-\(id)"
            self.name = name
            self.appPattern = appPattern
            self.titlePattern = titlePattern
            self.manage = manage
            self.enabled = enabled
        }

        var ruleDefinition: YabaiRuleDefinition? {
            let trimmedAppPattern = appPattern.trimmingCharacters(in: .whitespacesAndNewlines)
            guard enabled, !trimmedAppPattern.isEmpty else { return nil }

            let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedTitlePattern = titlePattern.trimmingCharacters(in: .whitespacesAndNewlines)

            return YabaiRuleDefinition(
                label: trimmedLabel.isEmpty ? "machelm-custom-rule-\(id)" : trimmedLabel,
                appPattern: trimmedAppPattern,
                titlePattern: trimmedTitlePattern.isEmpty ? nil : trimmedTitlePattern,
                manage: manage
            )
        }
    }

    enum ExternalBarMode: String, CaseIterable, Identifiable, Codable {
        case off
        case main
        case all

        var id: String { rawValue }
        var title: String { rawValue.yabaiTitle }
    }

    enum FocusFollowsMouseMode: String, CaseIterable, Identifiable, Codable {
        case off
        case autofocus
        case autoraise

        var id: String { rawValue }
        var title: String { rawValue.yabaiTitle }
    }

    enum DisplayArrangementOrder: String, CaseIterable, Identifiable, Codable {
        case `default`
        case vertical
        case horizontal

        var id: String { rawValue }
        var title: String { rawValue.yabaiTitle }
    }

    enum WindowOriginDisplay: String, CaseIterable, Identifiable, Codable {
        case `default`
        case focused
        case cursor

        var id: String { rawValue }
        var title: String { rawValue.yabaiTitle }
    }

    enum Layout: String, CaseIterable, Identifiable, Codable {
        case bsp
        case stack
        case float

        var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }

    enum WindowPlacement: String, CaseIterable, Identifiable, Codable {
        case firstChild = "first_child"
        case secondChild = "second_child"

        var id: String { rawValue }
        var title: String { rawValue.yabaiTitle }
    }

    enum WindowInsertionPoint: String, CaseIterable, Identifiable, Codable {
        case focused
        case first
        case last

        var id: String { rawValue }
        var title: String { rawValue.yabaiTitle }
    }

    enum WindowShadowMode: String, CaseIterable, Identifiable, Codable {
        case on
        case off
        case float

        var id: String { rawValue }
        var title: String { rawValue.yabaiTitle }
    }

    enum WindowAnimationEasing: String, CaseIterable, Identifiable, Codable {
        case easeInSine = "ease_in_sine"
        case easeOutSine = "ease_out_sine"
        case easeInOutSine = "ease_in_out_sine"
        case easeInQuad = "ease_in_quad"
        case easeOutQuad = "ease_out_quad"
        case easeInOutQuad = "ease_in_out_quad"
        case easeInCubic = "ease_in_cubic"
        case easeOutCubic = "ease_out_cubic"
        case easeInOutCubic = "ease_in_out_cubic"
        case easeInQuart = "ease_in_quart"
        case easeOutQuart = "ease_out_quart"
        case easeInOutQuart = "ease_in_out_quart"
        case easeInQuint = "ease_in_quint"
        case easeOutQuint = "ease_out_quint"
        case easeInOutQuint = "ease_in_out_quint"
        case easeInExpo = "ease_in_expo"
        case easeOutExpo = "ease_out_expo"
        case easeInOutExpo = "ease_in_out_expo"
        case easeInCirc = "ease_in_circ"
        case easeOutCirc = "ease_out_circ"
        case easeInOutCirc = "ease_in_out_circ"

        var id: String { rawValue }
        var title: String { rawValue.yabaiTitle }
    }

    enum AutoBalanceMode: String, CaseIterable, Identifiable, Codable {
        case off
        case on
        case xAxis = "x-axis"
        case yAxis = "y-axis"

        var id: String { rawValue }
        var title: String { rawValue.yabaiTitle }
    }

    enum SplitType: String, CaseIterable, Identifiable, Codable {
        case vertical
        case horizontal
        case auto

        var id: String { rawValue }
        var title: String { rawValue.yabaiTitle }
    }

    enum MouseModifier: String, CaseIterable, Identifiable, Codable {
        case fn
        case alt
        case shift
        case ctrl
        case cmd

        var id: String { rawValue }
        var title: String { rawValue == "cmd" ? "Cmd" : rawValue.capitalized }
    }

    enum MouseAction: String, CaseIterable, Identifiable, Codable {
        case move
        case resize

        var id: String { rawValue }
        var title: String { rawValue.yabaiTitle }
    }

    enum MouseDropAction: String, CaseIterable, Identifiable, Codable {
        case swap
        case stack

        var id: String { rawValue }
        var title: String { rawValue.yabaiTitle }
    }

    var debugOutput = false
    var externalBarMode: ExternalBarMode = .off
    var externalBarTopPadding: Double = 0
    var externalBarBottomPadding: Double = 0
    var menubarOpacity: Double = 1.0
    var mouseFollowsFocus = false
    var focusFollowsMouse: FocusFollowsMouseMode = .off
    var displayArrangementOrder: DisplayArrangementOrder = .default
    var windowOriginDisplay: WindowOriginDisplay = .default
    var windowPlacement: WindowPlacement = .secondChild
    var windowInsertionPoint: WindowInsertionPoint = .focused
    var windowZoomPersist = false
    var windowShadow: WindowShadowMode = .on
    var windowOpacity = false
    var windowOpacityDuration: Double = 0.0
    var activeWindowOpacity: Double = 1.0
    var normalWindowOpacity: Double = 0.9
    var windowAnimationDuration: Double = 0.0
    var windowAnimationEasing: WindowAnimationEasing = .easeOutExpo
    var insertFeedbackColor = "0xffd75f5f"
    var splitRatio: Double = 0.5
    var mouseModifier: MouseModifier = .fn
    var mouseAction1: MouseAction = .move
    var mouseAction2: MouseAction = .resize
    var mouseDropAction: MouseDropAction = .swap
    var layout: Layout = .bsp
    var splitType: SplitType = .auto
    var topPadding: Double = 12
    var bottomPadding: Double = 12
    var leftPadding: Double = 12
    var rightPadding: Double = 12
    var windowGap: Double = 10
    var autoBalance: AutoBalanceMode = .off
    var systemSettingsRule = RuleConfig(label: "machelm-float-system-settings", name: "System Settings", appPattern: "^System Settings$", manage: false, enabled: true)
    var finderRule = RuleConfig(label: "machelm-float-finder", name: "Finder", appPattern: "^Finder$", manage: false, enabled: true)
    var activityMonitorRule = RuleConfig(label: "machelm-float-activity-monitor", name: "Activity Monitor", appPattern: "^Activity Monitor$", manage: false, enabled: true)
    var archiveUtilityRule = RuleConfig(label: "machelm-float-archive-utility", name: "Archive Utility", appPattern: "^Archive Utility$", manage: false, enabled: true)
    var customRules: [CustomRule] = []

    init() {}

    private enum CodingKeys: String, CodingKey {
        case debugOutput
        case externalBarMode
        case externalBarTopPadding
        case externalBarBottomPadding
        case menubarOpacity
        case mouseFollowsFocus
        case focusFollowsMouse
        case displayArrangementOrder
        case windowOriginDisplay
        case windowPlacement
        case windowInsertionPoint
        case windowZoomPersist
        case windowShadow
        case windowOpacity
        case windowOpacityDuration
        case activeWindowOpacity
        case normalWindowOpacity
        case windowAnimationDuration
        case windowAnimationEasing
        case insertFeedbackColor
        case splitRatio
        case mouseModifier
        case mouseAction1
        case mouseAction2
        case mouseDropAction
        case layout
        case splitType
        case topPadding
        case bottomPadding
        case leftPadding
        case rightPadding
        case windowGap
        case autoBalance
        case outerPadding
        case systemSettingsRule
        case finderRule
        case activityMonitorRule
        case archiveUtilityRule
        case floatSystemSettings
        case floatFinder
        case floatActivityMonitor
        case floatArchiveUtility
        case customRules
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyOuterPadding = try container.decodeIfPresent(Double.self, forKey: .outerPadding) ?? 12

        debugOutput = try container.decodeIfPresent(Bool.self, forKey: .debugOutput) ?? false
        externalBarMode = try container.decodeIfPresent(ExternalBarMode.self, forKey: .externalBarMode) ?? .off
        externalBarTopPadding = try container.decodeIfPresent(Double.self, forKey: .externalBarTopPadding) ?? 0
        externalBarBottomPadding = try container.decodeIfPresent(Double.self, forKey: .externalBarBottomPadding) ?? 0
        menubarOpacity = try container.decodeIfPresent(Double.self, forKey: .menubarOpacity) ?? 1.0
        mouseFollowsFocus = try container.decodeIfPresent(Bool.self, forKey: .mouseFollowsFocus) ?? false

        if let focusMode = try container.decodeIfPresent(FocusFollowsMouseMode.self, forKey: .focusFollowsMouse) {
            focusFollowsMouse = focusMode
        } else if (try container.decodeIfPresent(Bool.self, forKey: .focusFollowsMouse)) == true {
            focusFollowsMouse = .autofocus
        } else {
            focusFollowsMouse = .off
        }

        displayArrangementOrder = try container.decodeIfPresent(DisplayArrangementOrder.self, forKey: .displayArrangementOrder) ?? .default
        windowOriginDisplay = try container.decodeIfPresent(WindowOriginDisplay.self, forKey: .windowOriginDisplay) ?? .default
        windowPlacement = try container.decodeIfPresent(WindowPlacement.self, forKey: .windowPlacement) ?? .secondChild
        windowInsertionPoint = try container.decodeIfPresent(WindowInsertionPoint.self, forKey: .windowInsertionPoint) ?? .focused
        windowZoomPersist = try container.decodeIfPresent(Bool.self, forKey: .windowZoomPersist) ?? false
        windowShadow = try container.decodeIfPresent(WindowShadowMode.self, forKey: .windowShadow) ?? .on
        windowOpacity = try container.decodeIfPresent(Bool.self, forKey: .windowOpacity) ?? false
        windowOpacityDuration = try container.decodeIfPresent(Double.self, forKey: .windowOpacityDuration) ?? 0.0
        activeWindowOpacity = try container.decodeIfPresent(Double.self, forKey: .activeWindowOpacity) ?? 1.0
        normalWindowOpacity = try container.decodeIfPresent(Double.self, forKey: .normalWindowOpacity) ?? 0.9
        windowAnimationDuration = try container.decodeIfPresent(Double.self, forKey: .windowAnimationDuration) ?? 0.0
        windowAnimationEasing = try container.decodeIfPresent(WindowAnimationEasing.self, forKey: .windowAnimationEasing) ?? .easeOutExpo
        insertFeedbackColor = try container.decodeIfPresent(String.self, forKey: .insertFeedbackColor) ?? "0xffd75f5f"
        splitRatio = try container.decodeIfPresent(Double.self, forKey: .splitRatio) ?? 0.5
        mouseModifier = try container.decodeIfPresent(MouseModifier.self, forKey: .mouseModifier) ?? .fn
        mouseAction1 = try container.decodeIfPresent(MouseAction.self, forKey: .mouseAction1) ?? .move
        mouseAction2 = try container.decodeIfPresent(MouseAction.self, forKey: .mouseAction2) ?? .resize
        mouseDropAction = try container.decodeIfPresent(MouseDropAction.self, forKey: .mouseDropAction) ?? .swap
        layout = try container.decodeIfPresent(Layout.self, forKey: .layout) ?? .bsp
        splitType = try container.decodeIfPresent(SplitType.self, forKey: .splitType) ?? .auto
        topPadding = try container.decodeIfPresent(Double.self, forKey: .topPadding) ?? legacyOuterPadding
        bottomPadding = try container.decodeIfPresent(Double.self, forKey: .bottomPadding) ?? legacyOuterPadding
        leftPadding = try container.decodeIfPresent(Double.self, forKey: .leftPadding) ?? legacyOuterPadding
        rightPadding = try container.decodeIfPresent(Double.self, forKey: .rightPadding) ?? legacyOuterPadding
        windowGap = try container.decodeIfPresent(Double.self, forKey: .windowGap) ?? 10

        if let autoBalanceMode = try container.decodeIfPresent(AutoBalanceMode.self, forKey: .autoBalance) {
            autoBalance = autoBalanceMode
        } else if (try container.decodeIfPresent(Bool.self, forKey: .autoBalance)) == true {
            autoBalance = .on
        } else {
            autoBalance = .off
        }

        let legacyFloatSystemSettings = try container.decodeIfPresent(Bool.self, forKey: .floatSystemSettings) ?? true
        let legacyFloatFinder = try container.decodeIfPresent(Bool.self, forKey: .floatFinder) ?? true
        let legacyFloatActivityMonitor = try container.decodeIfPresent(Bool.self, forKey: .floatActivityMonitor) ?? true
        let legacyFloatArchiveUtility = try container.decodeIfPresent(Bool.self, forKey: .floatArchiveUtility) ?? true

        systemSettingsRule = try container.decodeIfPresent(RuleConfig.self, forKey: .systemSettingsRule)
            ?? RuleConfig(label: "machelm-float-system-settings", name: "System Settings", appPattern: "^System Settings$", manage: false, enabled: legacyFloatSystemSettings)
        finderRule = try container.decodeIfPresent(RuleConfig.self, forKey: .finderRule)
            ?? RuleConfig(label: "machelm-float-finder", name: "Finder", appPattern: "^Finder$", manage: false, enabled: legacyFloatFinder)
        activityMonitorRule = try container.decodeIfPresent(RuleConfig.self, forKey: .activityMonitorRule)
            ?? RuleConfig(label: "machelm-float-activity-monitor", name: "Activity Monitor", appPattern: "^Activity Monitor$", manage: false, enabled: legacyFloatActivityMonitor)
        archiveUtilityRule = try container.decodeIfPresent(RuleConfig.self, forKey: .archiveUtilityRule)
            ?? RuleConfig(label: "machelm-float-archive-utility", name: "Archive Utility", appPattern: "^Archive Utility$", manage: false, enabled: legacyFloatArchiveUtility)
        customRules = try container.decodeIfPresent([CustomRule].self, forKey: .customRules) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(debugOutput, forKey: .debugOutput)
        try container.encode(externalBarMode, forKey: .externalBarMode)
        try container.encode(externalBarTopPadding, forKey: .externalBarTopPadding)
        try container.encode(externalBarBottomPadding, forKey: .externalBarBottomPadding)
        try container.encode(menubarOpacity, forKey: .menubarOpacity)
        try container.encode(mouseFollowsFocus, forKey: .mouseFollowsFocus)
        try container.encode(focusFollowsMouse, forKey: .focusFollowsMouse)
        try container.encode(displayArrangementOrder, forKey: .displayArrangementOrder)
        try container.encode(windowOriginDisplay, forKey: .windowOriginDisplay)
        try container.encode(windowPlacement, forKey: .windowPlacement)
        try container.encode(windowInsertionPoint, forKey: .windowInsertionPoint)
        try container.encode(windowZoomPersist, forKey: .windowZoomPersist)
        try container.encode(windowShadow, forKey: .windowShadow)
        try container.encode(windowOpacity, forKey: .windowOpacity)
        try container.encode(windowOpacityDuration, forKey: .windowOpacityDuration)
        try container.encode(activeWindowOpacity, forKey: .activeWindowOpacity)
        try container.encode(normalWindowOpacity, forKey: .normalWindowOpacity)
        try container.encode(windowAnimationDuration, forKey: .windowAnimationDuration)
        try container.encode(windowAnimationEasing, forKey: .windowAnimationEasing)
        try container.encode(insertFeedbackColor, forKey: .insertFeedbackColor)
        try container.encode(splitRatio, forKey: .splitRatio)
        try container.encode(mouseModifier, forKey: .mouseModifier)
        try container.encode(mouseAction1, forKey: .mouseAction1)
        try container.encode(mouseAction2, forKey: .mouseAction2)
        try container.encode(mouseDropAction, forKey: .mouseDropAction)
        try container.encode(layout, forKey: .layout)
        try container.encode(splitType, forKey: .splitType)
        try container.encode(topPadding, forKey: .topPadding)
        try container.encode(bottomPadding, forKey: .bottomPadding)
        try container.encode(leftPadding, forKey: .leftPadding)
        try container.encode(rightPadding, forKey: .rightPadding)
        try container.encode(windowGap, forKey: .windowGap)
        try container.encode(autoBalance, forKey: .autoBalance)
        try container.encode(systemSettingsRule, forKey: .systemSettingsRule)
        try container.encode(finderRule, forKey: .finderRule)
        try container.encode(activityMonitorRule, forKey: .activityMonitorRule)
        try container.encode(archiveUtilityRule, forKey: .archiveUtilityRule)
        try container.encode(customRules, forKey: .customRules)
    }

    static let `default` = YabaiManagedSettings()
}

struct YabaiRuleDefinition: Equatable {
    let label: String
    let appPattern: String
    let titlePattern: String?
    let manage: Bool
}

private struct YabaiLiveRule: Decodable {
    let index: Int
    let label: String
    let app: String
    let title: String
}

struct YabaiRuleEntry: Identifiable, Equatable {
    let id: String
    let name: String
    let appPattern: String
    let titlePattern: String?
    let manage: Bool
    let source: String
}

private enum YabaiLiveOperation: Equatable {
    case config(String)
    case replaceRule(old: YabaiRuleDefinition?, new: YabaiRuleDefinition?)
    case replaceCustomRules(old: [YabaiRuleDefinition], new: [YabaiRuleDefinition])
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
    private var suppressAutomaticYabaiSync = false
    private var yabaiSyncWorkItem: DispatchWorkItem?
    private var isEditingYabaiSlider = false
    private var pendingYabaiLiveOperations: [YabaiLiveOperation] = []
    @Published var yabaiSettings = YabaiManagedSettings.default {
        didSet {
            hasUnsavedYabaiChanges = yabaiSettings != persistedYabaiSettings
            pendingYabaiLiveOperations = liveYabaiOperationsForChange(from: oldValue, to: yabaiSettings)
            guard hasUnsavedYabaiChanges, !suppressAutomaticYabaiSync, !isEditingYabaiSlider else { return }
            scheduleYabaiSettingsSync(delay: 0.05, liveOperations: pendingYabaiLiveOperations)
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
    private static let customRuleLabelPrefix = "machelm-custom-rule-"
    private static let defaultSystemSettingsRule = YabaiManagedSettings.RuleConfig(label: "machelm-float-system-settings", name: "System Settings", appPattern: "^System Settings$", manage: false, enabled: true)
    private static let defaultFinderRule = YabaiManagedSettings.RuleConfig(label: "machelm-float-finder", name: "Finder", appPattern: "^Finder$", manage: false, enabled: true)
    private static let defaultActivityMonitorRule = YabaiManagedSettings.RuleConfig(label: "machelm-float-activity-monitor", name: "Activity Monitor", appPattern: "^Activity Monitor$", manage: false, enabled: true)
    private static let defaultArchiveUtilityRule = YabaiManagedSettings.RuleConfig(label: "machelm-float-archive-utility", name: "Archive Utility", appPattern: "^Archive Utility$", manage: false, enabled: true)

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

    var liveConfigPath: String {
        liveYabaiConfigURL.path
    }

    var yabaiConfigExists: Bool {
        FileManager.default.fileExists(atPath: liveYabaiConfigURL.path)
    }

    func revealRepoConfig() {
        NSWorkspace.shared.activateFileViewerSelecting([repoYabaiConfigURL])
    }

    func revealRepoSettings() {
        NSWorkspace.shared.activateFileViewerSelecting([repoYabaiSettingsURL])
    }

    func revealLiveConfig() {
        NSWorkspace.shared.activateFileViewerSelecting([liveYabaiConfigURL])
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

    func addYabaiCustomRule() {
        yabaiSettings.customRules.append(.init())
    }

    func removeYabaiCustomRule(id: String) {
        yabaiSettings.customRules.removeAll { $0.id == id }
    }

    var activeYabaiRules: [YabaiRuleEntry] {
        activeYabaiRules(from: yabaiSettings)
    }

    func setYabaiSliderEditing(_ isEditing: Bool) {
        isEditingYabaiSlider = isEditing

        if isEditing {
            yabaiSyncWorkItem?.cancel()
        } else if hasUnsavedYabaiChanges {
            scheduleYabaiSettingsSync(delay: 0.05, liveOperations: pendingYabaiLiveOperations)
        }
    }

    func setYabaiGapEditing(_ isEditing: Bool) {
        isEditingYabaiSlider = isEditing

        if isEditing {
            yabaiSyncWorkItem?.cancel()
        } else if hasUnsavedYabaiChanges {
            scheduleYabaiSettingsSync(delay: 0.05, liveOperations: pendingYabaiLiveOperations)
        }
    }

    private func saveYabaiSettings(liveOperations: [YabaiLiveOperation] = []) {
        guard !isSavingYabaiSettings else { return }
        isSavingYabaiSettings = true
        yabaiSyncWorkItem?.cancel()
        let settings = yabaiSettings

        do {
            try writeYabaiManagedFiles(settings)
            persistedYabaiSettings = settings
            suppressAutomaticYabaiSync = true
            yabaiSettings = settings
            suppressAutomaticYabaiSync = false
            hasUnsavedYabaiChanges = false
            isSavingYabaiSettings = false

            if !liveOperations.isEmpty {
                applyLiveYabaiOperations(liveOperations)
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
        let settings = loadYabaiRules(into: loadYabaiSettings(from: repoYabaiSettingsURL)
            ?? loadYabaiSettings(from: liveYabaiSettingsURL)
            ?? .default)

        yabaiSyncWorkItem?.cancel()
        suppressAutomaticYabaiSync = true
        persistedYabaiSettings = settings
        yabaiSettings = settings
        hasUnsavedYabaiChanges = false
        pendingYabaiLiveOperations = []
        suppressAutomaticYabaiSync = false
    }

    private func loadYabaiSettings(from fileURL: URL) -> YabaiManagedSettings? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(YabaiManagedSettings.self, from: data)
    }

    private func loadYabaiRules(into settings: YabaiManagedSettings) -> YabaiManagedSettings {
        let parsedRules = parseYabaiRules(from: repoYabaiConfigURL)
            ?? parseYabaiRules(from: liveYabaiConfigURL)

        guard let parsedRules else { return settings }

        var mergedSettings = settings
        mergedSettings.systemSettingsRule = Self.defaultSystemSettingsRule
        mergedSettings.systemSettingsRule.enabled = false
        mergedSettings.finderRule = Self.defaultFinderRule
        mergedSettings.finderRule.enabled = false
        mergedSettings.activityMonitorRule = Self.defaultActivityMonitorRule
        mergedSettings.activityMonitorRule.enabled = false
        mergedSettings.archiveUtilityRule = Self.defaultArchiveUtilityRule
        mergedSettings.archiveUtilityRule.enabled = false
        mergedSettings.customRules = []

        for rule in parsedRules {
            if rule.label == Self.defaultSystemSettingsRule.label || rule.appPattern == Self.defaultSystemSettingsRule.appPattern {
                mergedSettings.systemSettingsRule = ruleConfig(from: rule, fallback: Self.defaultSystemSettingsRule)
            } else if rule.label == Self.defaultFinderRule.label || rule.appPattern == Self.defaultFinderRule.appPattern {
                mergedSettings.finderRule = ruleConfig(from: rule, fallback: Self.defaultFinderRule)
            } else if rule.label == Self.defaultActivityMonitorRule.label || rule.appPattern == Self.defaultActivityMonitorRule.appPattern {
                mergedSettings.activityMonitorRule = ruleConfig(from: rule, fallback: Self.defaultActivityMonitorRule)
            } else if rule.label == Self.defaultArchiveUtilityRule.label || rule.appPattern == Self.defaultArchiveUtilityRule.appPattern {
                mergedSettings.archiveUtilityRule = ruleConfig(from: rule, fallback: Self.defaultArchiveUtilityRule)
            } else {
                mergedSettings.customRules.append(customRule(from: rule))
            }
        }

        return mergedSettings
    }

    private func customRule(from rule: YabaiRuleDefinition) -> YabaiManagedSettings.CustomRule {
        let trimmedLabel = rule.label.trimmingCharacters(in: .whitespacesAndNewlines)
        let defaultName = trimmedLabel.isEmpty ? rule.appPattern : trimmedLabel
        return YabaiManagedSettings.CustomRule(
            label: trimmedLabel.isEmpty ? nil : trimmedLabel,
            name: defaultName,
            appPattern: rule.appPattern,
            titlePattern: rule.titlePattern ?? "",
            manage: rule.manage,
            enabled: true
        )
    }

    private func ruleConfig(from rule: YabaiRuleDefinition, fallback: YabaiManagedSettings.RuleConfig) -> YabaiManagedSettings.RuleConfig {
        YabaiManagedSettings.RuleConfig(
            label: rule.label,
            name: fallback.name,
            appPattern: rule.appPattern,
            titlePattern: rule.titlePattern ?? "",
            manage: rule.manage,
            enabled: true
        )
    }

    private func activeYabaiRules(from settings: YabaiManagedSettings) -> [YabaiRuleEntry] {
        var rules: [YabaiRuleEntry] = []

        [settings.systemSettingsRule, settings.finderRule, settings.activityMonitorRule, settings.archiveUtilityRule]
            .compactMap(\.ruleDefinition)
            .forEach { definition in
                let name = [settings.systemSettingsRule, settings.finderRule, settings.activityMonitorRule, settings.archiveUtilityRule]
                    .first(where: { $0.label == definition.label })?.name ?? definition.appPattern
                rules.append(ruleEntry(name: name, source: "Built-in", definition: definition))
            }

        rules.append(contentsOf: settings.customRules.compactMap { rule in
            guard let definition = rule.ruleDefinition else { return nil }
            let trimmedName = rule.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return ruleEntry(
                name: trimmedName.isEmpty ? definition.appPattern : trimmedName,
                source: "Custom",
                definition: definition
            )
        })

        return rules
    }

    private func ruleEntry(name: String, source: String, definition: YabaiRuleDefinition) -> YabaiRuleEntry {
        YabaiRuleEntry(
            id: definition.label,
            name: name,
            appPattern: definition.appPattern,
            titlePattern: definition.titlePattern,
            manage: definition.manage,
            source: source
        )
    }

    private func parseYabaiRules(from fileURL: URL) -> [YabaiRuleDefinition]? {
        guard let script = try? String(contentsOf: fileURL, encoding: .utf8) else { return nil }

        let parsedRules = script
            .split(whereSeparator: \.isNewline)
            .compactMap { parseYabaiRuleLine(String($0)) }

        return parsedRules.isEmpty ? [] : parsedRules
    }

    private func parseYabaiRuleLine(_ line: String) -> YabaiRuleDefinition? {
        guard line.contains("rule --add") else { return nil }
        guard let appPattern = ruleArgument(named: "app", in: line) else { return nil }

        let label = ruleArgument(named: "label", in: line) ?? "\(Self.customRuleLabelPrefix)\(UUID().uuidString)"
        let titlePattern = ruleArgument(named: "title", in: line)
        let manageValue = ruleArgument(named: "manage", in: line) ?? "off"

        return YabaiRuleDefinition(
            label: label,
            appPattern: appPattern,
            titlePattern: titlePattern,
            manage: manageValue == "on"
        )
    }

    private func ruleArgument(named name: String, in line: String) -> String? {
        let pattern = "\(name)=(?:\\\"([^\\\"]*)\\\"|'([^']*)'|([^\\s]+))"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, options: [], range: range) else { return nil }

        for groupIndex in 1..<match.numberOfRanges {
            let groupRange = match.range(at: groupIndex)
            guard groupRange.location != NSNotFound,
                  let swiftRange = Range(groupRange, in: line)
            else { continue }
            return String(line[swiftRange])
        }

        return nil
    }

    private func writeYabaiManagedFiles(_ settings: YabaiManagedSettings) throws {
        let repoScript = renderYabaiGeneratedConfig(settings)
        let liveScript = repoScript
        let settingsData = try encodedYabaiSettings(settings)

        try FileManager.default.createDirectory(at: repoYabaiDirectoryURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: liveYabaiDirectoryURL, withIntermediateDirectories: true)

        try settingsData.write(to: repoYabaiSettingsURL, options: .atomic)
        try settingsData.write(to: liveYabaiSettingsURL, options: .atomic)
        try repoScript.write(to: repoYabaiConfigURL, atomically: true, encoding: .utf8)
        try liveScript.write(to: liveYabaiConfigURL, atomically: true, encoding: .utf8)
        try repoScript.write(to: repoYabaiGeneratedConfigURL, atomically: true, encoding: .utf8)
        try liveScript.write(to: liveYabaiGeneratedConfigURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: repoYabaiConfigURL.path)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: liveYabaiConfigURL.path)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: repoYabaiGeneratedConfigURL.path)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: liveYabaiGeneratedConfigURL.path)
    }

    private func encodedYabaiSettings(_ settings: YabaiManagedSettings) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(settings)
    }

    private func yabaiBool(_ value: Bool) -> String {
        value ? "on" : "off"
    }

    private func yabaiFloat(_ value: Double, precision: Int = 2) -> String {
        String(format: "%.\(precision)f", value)
    }

    private func externalBarSpec(_ settings: YabaiManagedSettings) -> String {
        let top = Int(settings.externalBarTopPadding.rounded())
        let bottom = Int(settings.externalBarBottomPadding.rounded())
        return "\(settings.externalBarMode.rawValue):\(top):\(bottom)"
    }

    private func ruleCommandLine(for rule: YabaiRuleDefinition) -> String {
        var components = [
            "\"$YABAI_BIN\" -m rule --add",
            "label=\(rule.label)",
            "app=\"\(rule.appPattern)\""
        ]

        if let titlePattern = rule.titlePattern {
            components.append("title=\"\(titlePattern)\"")
        }

        components.append("manage=\(yabaiBool(rule.manage))")
        return components.joined(separator: " ")
    }

    private func liveOperation(from oldRule: YabaiRuleDefinition?, to newRule: YabaiRuleDefinition?) -> YabaiLiveOperation {
        .replaceRule(old: oldRule, new: newRule)
    }

    private func renderYabaiGeneratedConfig(_ settings: YabaiManagedSettings) -> String {
        let topPadding = Int(settings.topPadding.rounded())
        let bottomPadding = Int(settings.bottomPadding.rounded())
        let leftPadding = Int(settings.leftPadding.rounded())
        let rightPadding = Int(settings.rightPadding.rounded())
        let windowGap = Int(settings.windowGap.rounded())

        var lines = [
            "#!/usr/bin/env sh",
            "",
            "YABAI_BIN=\"${YABAI_BIN:-$(command -v yabai || true)}\"",
            "",
            "if [ -z \"$YABAI_BIN\" ]; then",
            "  exit 0",
            "fi",
            "",
            "\"$YABAI_BIN\" -m config debug_output \(yabaiBool(settings.debugOutput))",
            "\"$YABAI_BIN\" -m config external_bar \(externalBarSpec(settings))",
            "\"$YABAI_BIN\" -m config menubar_opacity \(yabaiFloat(settings.menubarOpacity))",
            "\"$YABAI_BIN\" -m config mouse_follows_focus \(yabaiBool(settings.mouseFollowsFocus))",
            "\"$YABAI_BIN\" -m config focus_follows_mouse \(settings.focusFollowsMouse.rawValue)",
            "\"$YABAI_BIN\" -m config display_arrangement_order \(settings.displayArrangementOrder.rawValue)",
            "\"$YABAI_BIN\" -m config window_origin_display \(settings.windowOriginDisplay.rawValue)",
            "\"$YABAI_BIN\" -m config window_placement \(settings.windowPlacement.rawValue)",
            "\"$YABAI_BIN\" -m config window_insertion_point \(settings.windowInsertionPoint.rawValue)",
            "\"$YABAI_BIN\" -m config window_zoom_persist \(yabaiBool(settings.windowZoomPersist))",
            "\"$YABAI_BIN\" -m config window_shadow \(settings.windowShadow.rawValue)",
            "\"$YABAI_BIN\" -m config window_opacity \(yabaiBool(settings.windowOpacity))",
            "\"$YABAI_BIN\" -m config window_opacity_duration \(yabaiFloat(settings.windowOpacityDuration))",
            "\"$YABAI_BIN\" -m config active_window_opacity \(yabaiFloat(settings.activeWindowOpacity))",
            "\"$YABAI_BIN\" -m config normal_window_opacity \(yabaiFloat(settings.normalWindowOpacity))",
            "\"$YABAI_BIN\" -m config window_animation_duration \(yabaiFloat(settings.windowAnimationDuration))",
            "\"$YABAI_BIN\" -m config window_animation_easing \(settings.windowAnimationEasing.rawValue)",
            "\"$YABAI_BIN\" -m config insert_feedback_color \(settings.insertFeedbackColor)",
            "\"$YABAI_BIN\" -m config layout \(settings.layout.rawValue)",
            "\"$YABAI_BIN\" -m config split_type \(settings.splitType.rawValue)",
            "\"$YABAI_BIN\" -m config auto_balance \(settings.autoBalance.rawValue)",
            "\"$YABAI_BIN\" -m config split_ratio \(yabaiFloat(settings.splitRatio))",
            "",
            "\"$YABAI_BIN\" -m config mouse_modifier \(settings.mouseModifier.rawValue)",
            "\"$YABAI_BIN\" -m config mouse_action1 \(settings.mouseAction1.rawValue)",
            "\"$YABAI_BIN\" -m config mouse_action2 \(settings.mouseAction2.rawValue)",
            "\"$YABAI_BIN\" -m config mouse_drop_action \(settings.mouseDropAction.rawValue)",
            "",
            "\"$YABAI_BIN\" -m config top_padding \(topPadding)",
            "\"$YABAI_BIN\" -m config bottom_padding \(bottomPadding)",
            "\"$YABAI_BIN\" -m config left_padding \(leftPadding)",
            "\"$YABAI_BIN\" -m config right_padding \(rightPadding)",
            "\"$YABAI_BIN\" -m config window_gap \(windowGap)"
        ]

        let builtInRules = [
            settings.systemSettingsRule.ruleDefinition,
            settings.finderRule.ruleDefinition,
            settings.activityMonitorRule.ruleDefinition,
            settings.archiveUtilityRule.ruleDefinition
        ].compactMap { $0 }
        let customRules = settings.customRules.compactMap(\.ruleDefinition)
        let allRules = builtInRules + customRules

        if !allRules.isEmpty {
            lines.append("")
            lines.append(contentsOf: allRules.map(ruleCommandLine))
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private func refreshYabaiStatus() {
        let fileManager = FileManager.default
        if let resolvedPath = currentYabaiExecutablePath(fileManager: fileManager) {
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

    private func applyLiveYabaiOperations(_ operations: [YabaiLiveOperation]) {
        guard yabaiRunning, let executablePath = currentYabaiExecutablePath(fileManager: .default) else {
            refreshYabaiStatus()
            return
        }

        let existingRules = currentYabaiRules(executablePath: executablePath)
        let command = buildLiveYabaiCommand(executablePath: executablePath, operations: operations, existingRules: existingRules)
        guard !command.isEmpty else {
            refreshYabaiStatus()
            return
        }
        runYabaiCommand(command)
    }

    private func runYabaiCommand(_ command: String) {
        guard !isRunningYabaiCommand else { return }
        isRunningYabaiCommand = true

        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            task.arguments = ["-lc", "export PATH=\"\(RepoConfig.commandSearchPathString()):$PATH\"; \(command)"]

            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                print("Failed to run yabai command: \(error)")
            }

            DispatchQueue.main.async {
                self.isRunningYabaiCommand = false
                self.refreshYabaiStatus()

                if self.hasUnsavedYabaiChanges {
                    self.scheduleYabaiSettingsSync(delay: 0.2, liveOperations: self.pendingYabaiLiveOperations)
                }
            }
        }
    }

    private func yabaiCandidatePaths(for fileManager: FileManager) -> [String] {
        _ = fileManager
        return RepoConfig.yabaiExecutableCandidates()
    }

    private func currentYabaiExecutablePath(fileManager: FileManager) -> String? {
        if let runningPath = runningYabaiExecutablePath(), fileManager.isExecutableFile(atPath: runningPath) {
            return runningPath
        }

        let candidatePaths = yabaiCandidatePaths(for: fileManager)
        return candidatePaths.first(where: { fileManager.isExecutableFile(atPath: $0) })
    }

    private func runningYabaiExecutablePath() -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-lc", "ps -p \"$(pgrep -x yabai | head -n1)\" -o args= 2>/dev/null | awk '{print $1}'"]

        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            guard task.terminationStatus == 0 else { return nil }
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (output?.isEmpty == false) ? output : nil
        } catch {
            return nil
        }
    }

    private func currentYabaiRules(executablePath: String) -> [YabaiLiveRule] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-lc", "\"\(executablePath)\" -m rule --list 2>/dev/null"]

        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            guard task.terminationStatus == 0 else { return [] }
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            return (try? JSONDecoder().decode([YabaiLiveRule].self, from: data)) ?? []
        } catch {
            return []
        }
    }

    private func liveYabaiOperationsForChange(from oldSettings: YabaiManagedSettings, to newSettings: YabaiManagedSettings) -> [YabaiLiveOperation] {
        var commands: [YabaiLiveOperation] = []

        if oldSettings.debugOutput != newSettings.debugOutput {
            commands.append(.config("config debug_output \(yabaiBool(newSettings.debugOutput))"))
        }

        if oldSettings.externalBarMode != newSettings.externalBarMode ||
            oldSettings.externalBarTopPadding != newSettings.externalBarTopPadding ||
            oldSettings.externalBarBottomPadding != newSettings.externalBarBottomPadding {
            commands.append(.config("config external_bar \(externalBarSpec(newSettings))"))
        }

        if oldSettings.menubarOpacity != newSettings.menubarOpacity {
            commands.append(.config("config menubar_opacity \(yabaiFloat(newSettings.menubarOpacity))"))
        }

        if oldSettings.mouseFollowsFocus != newSettings.mouseFollowsFocus {
            commands.append(.config("config mouse_follows_focus \(yabaiBool(newSettings.mouseFollowsFocus))"))
        }

        if oldSettings.focusFollowsMouse != newSettings.focusFollowsMouse {
            commands.append(.config("config focus_follows_mouse \(newSettings.focusFollowsMouse.rawValue)"))
        }

        if oldSettings.displayArrangementOrder != newSettings.displayArrangementOrder {
            commands.append(.config("config display_arrangement_order \(newSettings.displayArrangementOrder.rawValue)"))
        }

        if oldSettings.windowOriginDisplay != newSettings.windowOriginDisplay {
            commands.append(.config("config window_origin_display \(newSettings.windowOriginDisplay.rawValue)"))
        }

        if oldSettings.windowPlacement != newSettings.windowPlacement {
            commands.append(.config("config window_placement \(newSettings.windowPlacement.rawValue)"))
        }

        if oldSettings.windowInsertionPoint != newSettings.windowInsertionPoint {
            commands.append(.config("config window_insertion_point \(newSettings.windowInsertionPoint.rawValue)"))
        }

        if oldSettings.windowZoomPersist != newSettings.windowZoomPersist {
            commands.append(.config("config window_zoom_persist \(yabaiBool(newSettings.windowZoomPersist))"))
        }

        if oldSettings.windowShadow != newSettings.windowShadow {
            commands.append(.config("config window_shadow \(newSettings.windowShadow.rawValue)"))
        }

        if oldSettings.windowOpacity != newSettings.windowOpacity {
            commands.append(.config("config window_opacity \(yabaiBool(newSettings.windowOpacity))"))
        }

        if oldSettings.windowOpacityDuration != newSettings.windowOpacityDuration {
            commands.append(.config("config window_opacity_duration \(yabaiFloat(newSettings.windowOpacityDuration))"))
        }

        if oldSettings.activeWindowOpacity != newSettings.activeWindowOpacity {
            commands.append(.config("config active_window_opacity \(yabaiFloat(newSettings.activeWindowOpacity))"))
        }

        if oldSettings.normalWindowOpacity != newSettings.normalWindowOpacity {
            commands.append(.config("config normal_window_opacity \(yabaiFloat(newSettings.normalWindowOpacity))"))
        }

        if oldSettings.windowAnimationDuration != newSettings.windowAnimationDuration {
            commands.append(.config("config window_animation_duration \(yabaiFloat(newSettings.windowAnimationDuration))"))
        }

        if oldSettings.windowAnimationEasing != newSettings.windowAnimationEasing {
            commands.append(.config("config window_animation_easing \(newSettings.windowAnimationEasing.rawValue)"))
        }

        if oldSettings.insertFeedbackColor != newSettings.insertFeedbackColor {
            commands.append(.config("config insert_feedback_color \(newSettings.insertFeedbackColor)"))
        }

        if oldSettings.layout != newSettings.layout {
            commands.append(.config("config layout \(newSettings.layout.rawValue)"))
        }

        if oldSettings.splitType != newSettings.splitType {
            commands.append(.config("config split_type \(newSettings.splitType.rawValue)"))
        }

        if oldSettings.autoBalance != newSettings.autoBalance {
            commands.append(.config("config auto_balance \(newSettings.autoBalance.rawValue)"))
        }

        if oldSettings.splitRatio != newSettings.splitRatio {
            commands.append(.config("config split_ratio \(yabaiFloat(newSettings.splitRatio))"))
        }

        if oldSettings.topPadding != newSettings.topPadding {
            commands.append(.config("config top_padding \(Int(newSettings.topPadding.rounded()))"))
        }

        if oldSettings.bottomPadding != newSettings.bottomPadding {
            commands.append(.config("config bottom_padding \(Int(newSettings.bottomPadding.rounded()))"))
        }

        if oldSettings.leftPadding != newSettings.leftPadding {
            commands.append(.config("config left_padding \(Int(newSettings.leftPadding.rounded()))"))
        }

        if oldSettings.rightPadding != newSettings.rightPadding {
            commands.append(.config("config right_padding \(Int(newSettings.rightPadding.rounded()))"))
        }

        if oldSettings.windowGap != newSettings.windowGap {
            commands.append(.config("config window_gap \(Int(newSettings.windowGap.rounded()))"))
        }

        if oldSettings.mouseModifier != newSettings.mouseModifier {
            commands.append(.config("config mouse_modifier \(newSettings.mouseModifier.rawValue)"))
        }

        if oldSettings.mouseAction1 != newSettings.mouseAction1 {
            commands.append(.config("config mouse_action1 \(newSettings.mouseAction1.rawValue)"))
        }

        if oldSettings.mouseAction2 != newSettings.mouseAction2 {
            commands.append(.config("config mouse_action2 \(newSettings.mouseAction2.rawValue)"))
        }

        if oldSettings.mouseDropAction != newSettings.mouseDropAction {
            commands.append(.config("config mouse_drop_action \(newSettings.mouseDropAction.rawValue)"))
        }

        if oldSettings.systemSettingsRule != newSettings.systemSettingsRule {
            commands.append(liveOperation(from: oldSettings.systemSettingsRule.ruleDefinition, to: newSettings.systemSettingsRule.ruleDefinition))
        }

        if oldSettings.finderRule != newSettings.finderRule {
            commands.append(liveOperation(from: oldSettings.finderRule.ruleDefinition, to: newSettings.finderRule.ruleDefinition))
        }

        if oldSettings.activityMonitorRule != newSettings.activityMonitorRule {
            commands.append(liveOperation(from: oldSettings.activityMonitorRule.ruleDefinition, to: newSettings.activityMonitorRule.ruleDefinition))
        }

        if oldSettings.archiveUtilityRule != newSettings.archiveUtilityRule {
            commands.append(liveOperation(from: oldSettings.archiveUtilityRule.ruleDefinition, to: newSettings.archiveUtilityRule.ruleDefinition))
        }

        if oldSettings.customRules != newSettings.customRules {
            commands.append(.replaceCustomRules(
                old: oldSettings.customRules.compactMap(\.ruleDefinition),
                new: newSettings.customRules.compactMap(\.ruleDefinition)
            ))
        }

        return commands
    }

    private func buildLiveYabaiCommand(executablePath: String, operations: [YabaiLiveOperation], existingRules: [YabaiLiveRule]) -> String {
        let quotedExecutable = shellQuoted(executablePath)
        var mutableRules = existingRules
        var commands: [String] = []

        for operation in operations {
            switch operation {
            case let .config(subcommand):
                commands.append("\(quotedExecutable) -m \(subcommand)")
            case let .replaceRule(oldRule, newRule):
                let rulesToRemove = matchingLiveRules(
                    in: mutableRules,
                    matchingAnyOf: [oldRule, newRule].compactMap { $0 }
                )

                for existingRule in rulesToRemove {
                    commands.append("\(quotedExecutable) -m rule --remove \(existingRule.index)")
                }

                if !rulesToRemove.isEmpty {
                    let indexes = Set(rulesToRemove.map(\.index))
                    mutableRules.removeAll { indexes.contains($0.index) }
                }

                if let newRule {
                    commands.append(buildLiveRuleAddCommand(executablePath: executablePath, rule: newRule))
                }
            case let .replaceCustomRules(old, new):
                let rulesToRemove = matchingLiveRules(
                    in: mutableRules,
                    matchingAnyOf: old + new
                )

                for existingRule in rulesToRemove {
                    commands.append("\(quotedExecutable) -m rule --remove \(existingRule.index)")
                }

                if !rulesToRemove.isEmpty {
                    let indexes = Set(rulesToRemove.map(\.index))
                    mutableRules.removeAll { indexes.contains($0.index) }
                }

                commands.append(contentsOf: new.map { buildLiveRuleAddCommand(executablePath: executablePath, rule: $0) })
            }
        }

        return commands.joined(separator: "; ")
    }

    private func matchingLiveRules(in existingRules: [YabaiLiveRule], matchingAnyOf definitions: [YabaiRuleDefinition]) -> [YabaiLiveRule] {
        guard !definitions.isEmpty else { return [] }

        return existingRules
            .filter { existingRule in
                definitions.contains { definition in
                    existingRule.label == definition.label ||
                    (
                        existingRule.app == definition.appPattern &&
                        normalizedRuleTitle(existingRule.title) == normalizedRuleTitle(definition.titlePattern)
                    )
                }
            }
            .sorted { $0.index > $1.index }
    }

    private func normalizedRuleTitle(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func buildLiveRuleAddCommand(executablePath: String, rule: YabaiRuleDefinition) -> String {
        let quotedExecutable = shellQuoted(executablePath)
        var components = [
            "\(quotedExecutable) -m rule --add",
            "label=\(shellQuoted(rule.label))",
            "app=\(shellQuoted(rule.appPattern))"
        ]

        if let titlePattern = rule.titlePattern {
            components.append("title=\(shellQuoted(titlePattern))")
        }

        components.append("manage=\(rule.manage ? "on" : "off")")
        return components.joined(separator: " ")
    }

    private func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private func scheduleYabaiSettingsSync(delay: TimeInterval = 0.35, liveOperations: [YabaiLiveOperation] = []) {
        yabaiSyncWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.saveYabaiSettings(liveOperations: liveOperations)
            }
        }

        yabaiSyncWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
}

struct WindowsScreen: View {
    private enum YabaiRuleEditorTarget: Equatable {
        case systemSettings
        case finder
        case activityMonitor
        case archiveUtility
        case custom(String)
        case draft
    }

    enum Section: String, CaseIterable, Identifiable {
        enum Group: CaseIterable {
            case macOS
            case yabai

            var title: String {
                switch self {
                case .macOS:
                    return "macOS"
                case .yabai:
                    return "Yabai"
                }
            }
        }

        case overview
        case minimize
        case missionControl
        case stageManager
        case tiledWindows
        case yabaiStatus
        case yabaiGeneral
        case yabaiWindow
        case yabaiAppearance
        case yabaiSpace
        case yabaiRules

        var id: String { rawValue }

        var group: Group {
            switch self {
            case .overview, .minimize, .missionControl, .stageManager, .tiledWindows:
                return .macOS
            case .yabaiStatus, .yabaiGeneral, .yabaiWindow, .yabaiAppearance, .yabaiSpace, .yabaiRules:
                return .yabai
            }
        }

        var title: String {
            switch self {
            case .overview:
                return "Overview"
            case .minimize:
                return "Minimize"
            case .missionControl:
                return "Mission Control"
            case .stageManager:
                return "Stage Manager"
            case .tiledWindows:
                return "Tiled Windows"
            case .yabaiStatus:
                return "Overview"
            case .yabaiGeneral:
                return "General"
            case .yabaiWindow:
                return "Window"
            case .yabaiAppearance:
                return "Appearance"
            case .yabaiSpace:
                return "Space"
            case .yabaiRules:
                return "Rules"
            }
        }

        var symbol: String {
            switch self {
            case .overview:
                return "macwindow"
            case .minimize:
                return "arrow.down.right.and.arrow.up.left"
            case .missionControl:
                return "square.3.layers.3d"
            case .stageManager:
                return "rectangle.leadinghalf.inset.filled"
            case .tiledWindows:
                return "square.split.2x2"
            case .yabaiStatus:
                return "macwindow.badge.plus"
            case .yabaiGeneral:
                return "slider.horizontal.3"
            case .yabaiWindow:
                return "macwindow"
            case .yabaiAppearance:
                return "sparkles.rectangle.stack"
            case .yabaiSpace:
                return "rectangle.split.3x1"
            case .yabaiRules:
                return "line.3.horizontal.decrease.circle"
            }
        }

        var screenTitle: String {
            group == .yabai ? "Yabai" : "Windows"
        }

        var subtitle: String {
            switch self {
            case .overview:
                return "Core macOS window-management defaults backed by Dock and WindowManager."
            case .minimize:
                return "Configure minimize behavior and animation for macOS windows."
            case .missionControl:
                return "Control how Spaces are ordered and surfaced in Mission Control."
            case .stageManager:
                return "Tune Stage Manager behavior, recent apps, and desktop visibility."
            case .tiledWindows:
                return "Adjust system-level tiled-window margin behavior."
            case .yabaiStatus:
                return "Yabai service status, managed config files, and control actions."
            case .yabaiGeneral:
                return "Global Yabai settings such as logging, external bar padding, and display ordering."
            case .yabaiWindow:
                return "Yabai window behavior, focus behavior, placement, and mouse actions."
            case .yabaiAppearance:
                return "Yabai appearance, opacity, animation, and insert feedback settings."
            case .yabaiSpace:
                return "Default Yabai space layout, padding, gap, and balancing settings."
            case .yabaiRules:
                return "Yabai floating rules for unmanaged applications."
            }
        }
    }

    @Binding var selectedSection: Section
    @StateObject private var controller = WindowSettingsController()
    @State private var draftYabaiRule: YabaiManagedSettings.CustomRule?
    @State private var editingYabaiRule: YabaiRuleEditorTarget?
    @State private var editingStoredYabaiRuleDraft: YabaiManagedSettings.RuleConfig?
    @State private var editingCustomYabaiRuleDraft: YabaiManagedSettings.CustomRule?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                screenHeader(title: selectedSection.screenTitle, subtitle: selectedSection.subtitle)
                sectionContent
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            controller.load()
        }
        .onChange(of: selectedSection) { _, newValue in
            guard newValue != .yabaiRules else { return }
            clearYabaiRuleEditorState()
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .overview:
            overviewSection
        case .minimize:
            minimizeSection
        case .missionControl:
            missionControlSection
        case .stageManager:
            stageManagerSection
        case .tiledWindows:
            tilingSection
        case .yabaiStatus:
            yabaiSection
        case .yabaiGeneral:
            yabaiGeneralSection
        case .yabaiWindow:
            yabaiWindowSection
        case .yabaiAppearance:
            yabaiAppearanceSection
        case .yabaiSpace:
            yabaiSpaceSection
        case .yabaiRules:
            yabaiRulesSection
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
                        MacMetricPill(
                            value: controller.isSavingYabaiSettings ? "Applying" : (controller.hasUnsavedYabaiChanges ? "Pending" : "Live"),
                            label: "Config"
                        )
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
                        Text("Repo Config")
                            .font(.headline)
                        Text(controller.repoConfigPath)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } trailing: {
                    Button("Reveal") {
                        controller.revealRepoConfig()
                    }
                    .buttonStyle(MacSecondaryButtonStyle())
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Live Config")
                            .font(.headline)
                        Text(controller.liveConfigPath)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } trailing: {
                    HStack(spacing: 10) {
                        MacMetricPill(value: controller.yabaiConfigExists ? "Present" : "Missing", label: "File")

                        Button("Reveal") {
                            controller.revealLiveConfig()
                        }
                        .buttonStyle(MacSecondaryButtonStyle())
                    }
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Actions")
                            .font(.headline)
                        Text("Changes auto-apply after a short pause. Use the service controls if you need to force a relaunch or open Accessibility permissions.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) {
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

    private var yabaiGeneralSection: some View {
        MacSettingsSection(title: "Yabai General") {
            VStack(spacing: 0) {
                WindowsToggleRow(
                    title: "Debug output",
                    description: "Enable verbose Yabai logging to stdout.",
                    isOn: Binding(
                        get: { controller.yabaiSettings.debugOutput },
                        set: { controller.yabaiSettings.debugOutput = $0 }
                    )
                )

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("External Bar")
                            .font(.headline)
                        Text("Reserve padding for a custom bar on the main display, all displays, or disable it.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.externalBarMode },
                        set: { controller.yabaiSettings.externalBarMode = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.ExternalBarMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }

                WindowsSliderRow(
                    title: "External Bar Top Padding",
                    description: "Top padding reserved for the external bar.",
                    value: Binding(
                        get: { controller.yabaiSettings.externalBarTopPadding },
                        set: { controller.yabaiSettings.externalBarTopPadding = $0 }
                    ),
                    range: 0...80,
                    valueLabel: "\(Int(controller.yabaiSettings.externalBarTopPadding.rounded())) px",
                    onEditingChanged: controller.setYabaiSliderEditing
                )

                WindowsSliderRow(
                    title: "External Bar Bottom Padding",
                    description: "Bottom padding reserved for the external bar.",
                    value: Binding(
                        get: { controller.yabaiSettings.externalBarBottomPadding },
                        set: { controller.yabaiSettings.externalBarBottomPadding = $0 }
                    ),
                    range: 0...80,
                    valueLabel: "\(Int(controller.yabaiSettings.externalBarBottomPadding.rounded())) px",
                    onEditingChanged: controller.setYabaiSliderEditing
                )

                WindowsSliderRow(
                    title: "Menubar Opacity",
                    description: "Adjust how transparent the macOS menubar becomes.",
                    value: Binding(
                        get: { controller.yabaiSettings.menubarOpacity },
                        set: { controller.yabaiSettings.menubarOpacity = $0 }
                    ),
                    range: 0...1,
                    valueLabel: String(format: "%.2f", controller.yabaiSettings.menubarOpacity),
                    onEditingChanged: controller.setYabaiSliderEditing
                )

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Display Arrangement Order")
                            .font(.headline)
                        Text("Choose how Yabai orders displays when resolving display selectors.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.displayArrangementOrder },
                        set: { controller.yabaiSettings.displayArrangementOrder = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.DisplayArrangementOrder.allCases) { order in
                            Text(order.title).tag(order)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Window Origin Display")
                            .font(.headline)
                        Text("Choose which display receives a newly created managed window.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.windowOriginDisplay },
                        set: { controller.yabaiSettings.windowOriginDisplay = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.WindowOriginDisplay.allCases) { display in
                            Text(display.title).tag(display)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }
            }
        }
    }

    private var yabaiWindowSection: some View {
        MacSettingsSection(title: "Yabai Window Behavior") {
            VStack(spacing: 0) {
                WindowsToggleRow(
                    title: "Mouse follows focus",
                    description: "Move the pointer to the focused window when focus changes.",
                    isOn: Binding(
                        get: { controller.yabaiSettings.mouseFollowsFocus },
                        set: { controller.yabaiSettings.mouseFollowsFocus = $0 }
                    )
                )

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Focus follows mouse")
                            .font(.headline)
                        Text("Set whether the pointer autofocuses a window, raises it, or does nothing.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.focusFollowsMouse },
                        set: { controller.yabaiSettings.focusFollowsMouse = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.FocusFollowsMouseMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
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

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Window Insertion Point")
                            .font(.headline)
                        Text("Choose where a newly managed window is inserted in the current tree.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.windowInsertionPoint },
                        set: { controller.yabaiSettings.windowInsertionPoint = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.WindowInsertionPoint.allCases) { point in
                            Text(point.title).tag(point)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }

                WindowsToggleRow(
                    title: "Persist zoom state",
                    description: "Keep a window's zoom state when layout changes happen.",
                    isOn: Binding(
                        get: { controller.yabaiSettings.windowZoomPersist },
                        set: { controller.yabaiSettings.windowZoomPersist = $0 }
                    )
                )

                MacSettingsRow {
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

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Primary Mouse Action")
                            .font(.headline)
                        Text("Set what the first pointer gesture does while the modifier key is held.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.mouseAction1 },
                        set: { controller.yabaiSettings.mouseAction1 = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.MouseAction.allCases) { action in
                            Text(action.title).tag(action)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Secondary Mouse Action")
                            .font(.headline)
                        Text("Set what the second pointer gesture does while the modifier key is held.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.mouseAction2 },
                        set: { controller.yabaiSettings.mouseAction2 = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.MouseAction.allCases) { action in
                            Text(action.title).tag(action)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mouse Drop Action")
                            .font(.headline)
                        Text("Choose how yabai handles a managed window when you drop it onto another tile.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.mouseDropAction },
                        set: { controller.yabaiSettings.mouseDropAction = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.MouseDropAction.allCases) { action in
                            Text(action.title).tag(action)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
            }
        }
    }

    private var yabaiAppearanceSection: some View {
        MacSettingsSection(title: "Yabai Appearance") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Window Shadow")
                            .font(.headline)
                        Text("Control shadow rendering for windows managed by Yabai.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.windowShadow },
                        set: { controller.yabaiSettings.windowShadow = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.WindowShadowMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }

                WindowsToggleRow(
                    title: "Window Opacity",
                    description: "Enable opacity transitions between focused and unfocused windows.",
                    isOn: Binding(
                        get: { controller.yabaiSettings.windowOpacity },
                        set: { controller.yabaiSettings.windowOpacity = $0 }
                    )
                )

                WindowsSliderRow(
                    title: "Opacity Transition Duration",
                    description: "Duration of the active versus normal opacity transition.",
                    value: Binding(
                        get: { controller.yabaiSettings.windowOpacityDuration },
                        set: { controller.yabaiSettings.windowOpacityDuration = $0 }
                    ),
                    range: 0...1,
                    valueLabel: String(format: "%.2f", controller.yabaiSettings.windowOpacityDuration),
                    onEditingChanged: controller.setYabaiSliderEditing
                )

                WindowsSliderRow(
                    title: "Active Window Opacity",
                    description: "Opacity used for the focused window.",
                    value: Binding(
                        get: { controller.yabaiSettings.activeWindowOpacity },
                        set: { controller.yabaiSettings.activeWindowOpacity = $0 }
                    ),
                    range: 0...1,
                    valueLabel: String(format: "%.2f", controller.yabaiSettings.activeWindowOpacity),
                    onEditingChanged: controller.setYabaiSliderEditing
                )

                WindowsSliderRow(
                    title: "Normal Window Opacity",
                    description: "Opacity used for unfocused windows.",
                    value: Binding(
                        get: { controller.yabaiSettings.normalWindowOpacity },
                        set: { controller.yabaiSettings.normalWindowOpacity = $0 }
                    ),
                    range: 0...1,
                    valueLabel: String(format: "%.2f", controller.yabaiSettings.normalWindowOpacity),
                    onEditingChanged: controller.setYabaiSliderEditing
                )

                WindowsSliderRow(
                    title: "Animation Duration",
                    description: "Duration of window frame animation when resizing or rearranging.",
                    value: Binding(
                        get: { controller.yabaiSettings.windowAnimationDuration },
                        set: { controller.yabaiSettings.windowAnimationDuration = $0 }
                    ),
                    range: 0...1,
                    valueLabel: String(format: "%.2f", controller.yabaiSettings.windowAnimationDuration),
                    onEditingChanged: controller.setYabaiSliderEditing
                )

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Animation Easing")
                            .font(.headline)
                        Text("Choose the easing function used for frame animation.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.windowAnimationEasing },
                        set: { controller.yabaiSettings.windowAnimationEasing = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.WindowAnimationEasing.allCases) { easing in
                            Text(easing.title).tag(easing)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 170)
                }

                WindowsTextFieldRow(
                    title: "Insert Feedback Color",
                    description: "ARGB hex color used for insert previews and mouse-drag feedback.",
                    text: Binding(
                        get: { controller.yabaiSettings.insertFeedbackColor },
                        set: { controller.yabaiSettings.insertFeedbackColor = $0 }
                    ),
                    placeholder: "0xAARRGGBB",
                    showsDivider: false
                )
            }
        }
    }

    private var yabaiSpaceSection: some View {
        MacSettingsSection(title: "Yabai Space Defaults") {
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
                        Text("Split Type")
                            .font(.headline)
                        Text("Choose whether new splits are vertical, horizontal, or decided automatically.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.splitType },
                        set: { controller.yabaiSettings.splitType = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.SplitType.allCases) { splitType in
                            Text(splitType.title).tag(splitType)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Auto Balance")
                            .font(.headline)
                        Text("Choose how the tree rebalances when windows are inserted or removed.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    Picker("", selection: Binding(
                        get: { controller.yabaiSettings.autoBalance },
                        set: { controller.yabaiSettings.autoBalance = $0 }
                    )) {
                        ForEach(YabaiManagedSettings.AutoBalanceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 130)
                }

                WindowsSliderRow(
                    title: "Split Ratio",
                    description: "Default split ratio for newly created containers.",
                    value: Binding(
                        get: { controller.yabaiSettings.splitRatio },
                        set: { controller.yabaiSettings.splitRatio = $0 }
                    ),
                    range: 0.01...1,
                    valueLabel: String(format: "%.2f", controller.yabaiSettings.splitRatio),
                    onEditingChanged: controller.setYabaiSliderEditing
                )

                WindowsSliderRow(
                    title: "Top Padding",
                    description: "Padding added at the upper side of the selected space.",
                    value: Binding(
                        get: { controller.yabaiSettings.topPadding },
                        set: { controller.yabaiSettings.topPadding = $0 }
                    ),
                    range: 0...80,
                    valueLabel: "\(Int(controller.yabaiSettings.topPadding.rounded())) px",
                    onEditingChanged: controller.setYabaiSliderEditing
                )

                WindowsSliderRow(
                    title: "Bottom Padding",
                    description: "Padding added at the lower side of the selected space.",
                    value: Binding(
                        get: { controller.yabaiSettings.bottomPadding },
                        set: { controller.yabaiSettings.bottomPadding = $0 }
                    ),
                    range: 0...80,
                    valueLabel: "\(Int(controller.yabaiSettings.bottomPadding.rounded())) px",
                    onEditingChanged: controller.setYabaiSliderEditing
                )

                WindowsSliderRow(
                    title: "Left Padding",
                    description: "Padding added at the left side of the selected space.",
                    value: Binding(
                        get: { controller.yabaiSettings.leftPadding },
                        set: { controller.yabaiSettings.leftPadding = $0 }
                    ),
                    range: 0...80,
                    valueLabel: "\(Int(controller.yabaiSettings.leftPadding.rounded())) px",
                    onEditingChanged: controller.setYabaiSliderEditing
                )

                WindowsSliderRow(
                    title: "Right Padding",
                    description: "Padding added at the right side of the selected space.",
                    value: Binding(
                        get: { controller.yabaiSettings.rightPadding },
                        set: { controller.yabaiSettings.rightPadding = $0 }
                    ),
                    range: 0...80,
                    valueLabel: "\(Int(controller.yabaiSettings.rightPadding.rounded())) px",
                    onEditingChanged: controller.setYabaiSliderEditing
                )

                WindowsSliderRow(
                    title: "Window Gap",
                    description: "Set the spacing between tiled windows.",
                    value: Binding(
                        get: { controller.yabaiSettings.windowGap },
                        set: { controller.yabaiSettings.windowGap = $0 }
                    ),
                    range: 0...80,
                    valueLabel: "\(Int(controller.yabaiSettings.windowGap.rounded())) px",
                    showsDivider: false,
                    onEditingChanged: controller.setYabaiGapEditing
                )
            }
        }
    }

    private var yabaiRulesSection: some View {
        Group {
            if let editingYabaiRule {
                yabaiRuleEditorPage(for: editingYabaiRule)
            } else {
                yabaiRuleListPage
            }
        }
    }

    private func addDraftYabaiRule() {
        guard let draftYabaiRule else { return }
        let trimmedAppPattern = draftYabaiRule.appPattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAppPattern.isEmpty else { return }

        var committedRule = draftYabaiRule
        committedRule.appPattern = trimmedAppPattern
        committedRule.name = committedRule.name.trimmingCharacters(in: .whitespacesAndNewlines)
        committedRule.titlePattern = committedRule.titlePattern.trimmingCharacters(in: .whitespacesAndNewlines)

        controller.yabaiSettings.customRules.append(committedRule)
        self.draftYabaiRule = nil
        editingYabaiRule = nil
    }

    private var yabaiRuleListPage: some View {
        MacSettingsSection(title: "Rules") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Select a rule to edit it on a dedicated page. New rules are only created after you press Done.")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 2)

                VStack(spacing: 12) {
                    YabaiRuleSummaryCard(
                        title: controller.yabaiSettings.systemSettingsRule.name,
                        appPattern: controller.yabaiSettings.systemSettingsRule.appPattern,
                        titlePattern: controller.yabaiSettings.systemSettingsRule.titlePattern,
                        isEnabled: controller.yabaiSettings.systemSettingsRule.enabled,
                        isManaged: controller.yabaiSettings.systemSettingsRule.manage,
                        onEdit: { beginEditingYabaiRule(.systemSettings) }
                    )

                    YabaiRuleSummaryCard(
                        title: controller.yabaiSettings.finderRule.name,
                        appPattern: controller.yabaiSettings.finderRule.appPattern,
                        titlePattern: controller.yabaiSettings.finderRule.titlePattern,
                        isEnabled: controller.yabaiSettings.finderRule.enabled,
                        isManaged: controller.yabaiSettings.finderRule.manage,
                        onEdit: { beginEditingYabaiRule(.finder) }
                    )

                    YabaiRuleSummaryCard(
                        title: controller.yabaiSettings.activityMonitorRule.name,
                        appPattern: controller.yabaiSettings.activityMonitorRule.appPattern,
                        titlePattern: controller.yabaiSettings.activityMonitorRule.titlePattern,
                        isEnabled: controller.yabaiSettings.activityMonitorRule.enabled,
                        isManaged: controller.yabaiSettings.activityMonitorRule.manage,
                        onEdit: { beginEditingYabaiRule(.activityMonitor) }
                    )

                    YabaiRuleSummaryCard(
                        title: controller.yabaiSettings.archiveUtilityRule.name,
                        appPattern: controller.yabaiSettings.archiveUtilityRule.appPattern,
                        titlePattern: controller.yabaiSettings.archiveUtilityRule.titlePattern,
                        isEnabled: controller.yabaiSettings.archiveUtilityRule.enabled,
                        isManaged: controller.yabaiSettings.archiveUtilityRule.manage,
                        onEdit: { beginEditingYabaiRule(.archiveUtility) }
                    )

                    ForEach(controller.yabaiSettings.customRules) { rule in
                        YabaiRuleSummaryCard(
                            title: rule.name,
                            appPattern: rule.appPattern,
                            titlePattern: rule.titlePattern,
                            isEnabled: rule.enabled,
                            isManaged: rule.manage,
                            onEdit: { beginEditingYabaiRule(.custom(rule.id)) },
                            onRemove: {
                                controller.removeYabaiCustomRule(id: rule.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)

                Button("Add") {
                    beginEditingYabaiRule(.draft)
                }
                .buttonStyle(MacSecondaryButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    @ViewBuilder
    private func yabaiRuleEditorPage(for target: YabaiRuleEditorTarget) -> some View {
        switch target {
        case .systemSettings:
            yabaiStoredRuleEditorPage(
                title: editingStoredYabaiRuleDraft?.name ?? controller.yabaiSettings.systemSettingsRule.name,
                subtitle: "Edit this Yabai rule, then press Done to apply changes and go back.",
                rule: Binding(
                    get: { editingStoredYabaiRuleDraft ?? controller.yabaiSettings.systemSettingsRule },
                    set: { editingStoredYabaiRuleDraft = $0 }
                ),
                doneDisabled: !canCommitStoredYabaiRuleDraft,
                onDone: commitEditedYabaiRule,
                onBack: discardEditedYabaiRule
            )
        case .finder:
            yabaiStoredRuleEditorPage(
                title: editingStoredYabaiRuleDraft?.name ?? controller.yabaiSettings.finderRule.name,
                subtitle: "Edit this Yabai rule, then press Done to apply changes and go back.",
                rule: Binding(
                    get: { editingStoredYabaiRuleDraft ?? controller.yabaiSettings.finderRule },
                    set: { editingStoredYabaiRuleDraft = $0 }
                ),
                doneDisabled: !canCommitStoredYabaiRuleDraft,
                onDone: commitEditedYabaiRule,
                onBack: discardEditedYabaiRule
            )
        case .activityMonitor:
            yabaiStoredRuleEditorPage(
                title: editingStoredYabaiRuleDraft?.name ?? controller.yabaiSettings.activityMonitorRule.name,
                subtitle: "Edit this Yabai rule, then press Done to apply changes and go back.",
                rule: Binding(
                    get: { editingStoredYabaiRuleDraft ?? controller.yabaiSettings.activityMonitorRule },
                    set: { editingStoredYabaiRuleDraft = $0 }
                ),
                doneDisabled: !canCommitStoredYabaiRuleDraft,
                onDone: commitEditedYabaiRule,
                onBack: discardEditedYabaiRule
            )
        case .archiveUtility:
            yabaiStoredRuleEditorPage(
                title: editingStoredYabaiRuleDraft?.name ?? controller.yabaiSettings.archiveUtilityRule.name,
                subtitle: "Edit this Yabai rule, then press Done to apply changes and go back.",
                rule: Binding(
                    get: { editingStoredYabaiRuleDraft ?? controller.yabaiSettings.archiveUtilityRule },
                    set: { editingStoredYabaiRuleDraft = $0 }
                ),
                doneDisabled: !canCommitStoredYabaiRuleDraft,
                onDone: commitEditedYabaiRule,
                onBack: discardEditedYabaiRule
            )
        case let .custom(id):
            if editingCustomYabaiRuleDraft != nil || controller.yabaiSettings.customRules.contains(where: { $0.id == id }) {
                yabaiCustomRuleEditorPage
            } else {
                yabaiRuleListPage
            }
        case .draft:
            if draftYabaiRule != nil {
                yabaiDraftRuleEditorPage
            } else {
                yabaiRuleListPage
            }
        }
    }

    private func yabaiStoredRuleEditorPage(
        title: String,
        subtitle: String,
        rule: Binding<YabaiManagedSettings.RuleConfig>,
        doneDisabled: Bool,
        onDone: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) -> some View {
        MacSettingsSection(title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Rule" : title) {
            VStack(alignment: .leading, spacing: 14) {
                yabaiRuleEditorHeader(subtitle: subtitle, doneDisabled: doneDisabled, onBack: onBack, onDone: onDone)

                YabaiStoredRuleEditor(rule: rule)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
    }

    private var yabaiDraftRuleEditorPage: some View {
        MacSettingsSection(title: draftRulePageTitle) {
            VStack(alignment: .leading, spacing: 14) {
                yabaiRuleEditorHeader(
                    subtitle: "Fill out this rule, then press Done to create it and go back.",
                    doneDisabled: !canCommitDraftYabaiRule,
                    onBack: discardEditedYabaiRule,
                    onDone: addDraftYabaiRule
                )

                YabaiDraftRuleEditor(
                    rule: Binding(
                        get: { draftYabaiRule ?? .init() },
                        set: { draftYabaiRule = $0 }
                    )
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private var draftRulePageTitle: String {
        let trimmedName = draftYabaiRule?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "New Rule" : trimmedName
    }

    private var yabaiCustomRuleEditorPage: some View {
        MacSettingsSection(title: customRulePageTitle) {
            VStack(alignment: .leading, spacing: 14) {
                yabaiRuleEditorHeader(
                    subtitle: "Edit this Yabai rule, then press Done to apply changes and go back.",
                    doneDisabled: !canCommitCustomYabaiRuleDraft,
                    onBack: discardEditedYabaiRule,
                    onDone: commitEditedYabaiRule
                )

                YabaiCustomRuleEditor(
                    rule: Binding(
                        get: { editingCustomYabaiRuleDraft ?? .init() },
                        set: { editingCustomYabaiRuleDraft = $0 }
                    ),
                    onRemove: {
                        guard let removedId = editingCustomYabaiRuleDraft?.id else { return }
                        controller.removeYabaiCustomRule(id: removedId)
                        clearYabaiRuleEditorState()
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private func yabaiRuleEditorHeader(
        subtitle: String,
        doneDisabled: Bool,
        onBack: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Button("Back", action: onBack)
                    .buttonStyle(MacSecondaryButtonStyle())

                Button("Done", action: onDone)
                    .buttonStyle(MacSecondaryButtonStyle())
                    .disabled(doneDisabled)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 2)

            Text(subtitle)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
        }
    }

    private var customRulePageTitle: String {
        let trimmedName = editingCustomYabaiRuleDraft?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedName.isEmpty ? "Rule" : trimmedName
    }

    private var canCommitDraftYabaiRule: Bool {
        !(draftYabaiRule?.appPattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private var canCommitStoredYabaiRuleDraft: Bool {
        !(editingStoredYabaiRuleDraft?.appPattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private var canCommitCustomYabaiRuleDraft: Bool {
        !(editingCustomYabaiRuleDraft?.appPattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private func beginEditingYabaiRule(_ target: YabaiRuleEditorTarget) {
        switch target {
        case .systemSettings:
            editingStoredYabaiRuleDraft = controller.yabaiSettings.systemSettingsRule
        case .finder:
            editingStoredYabaiRuleDraft = controller.yabaiSettings.finderRule
        case .activityMonitor:
            editingStoredYabaiRuleDraft = controller.yabaiSettings.activityMonitorRule
        case .archiveUtility:
            editingStoredYabaiRuleDraft = controller.yabaiSettings.archiveUtilityRule
        case let .custom(id):
            editingCustomYabaiRuleDraft = controller.yabaiSettings.customRules.first(where: { $0.id == id })
        case .draft:
            draftYabaiRule = .init()
        }

        editingYabaiRule = target
    }

    private func discardEditedYabaiRule() {
        clearYabaiRuleEditorState()
    }

    private func commitEditedYabaiRule() {
        guard let editingYabaiRule else { return }

        switch editingYabaiRule {
        case .systemSettings:
            if let draft = editingStoredYabaiRuleDraft {
                controller.yabaiSettings.systemSettingsRule = sanitized(draft)
            }
        case .finder:
            if let draft = editingStoredYabaiRuleDraft {
                controller.yabaiSettings.finderRule = sanitized(draft)
            }
        case .activityMonitor:
            if let draft = editingStoredYabaiRuleDraft {
                controller.yabaiSettings.activityMonitorRule = sanitized(draft)
            }
        case .archiveUtility:
            if let draft = editingStoredYabaiRuleDraft {
                controller.yabaiSettings.archiveUtilityRule = sanitized(draft)
            }
        case .custom:
            if let draft = editingCustomYabaiRuleDraft,
               let index = controller.yabaiSettings.customRules.firstIndex(where: { $0.id == draft.id }) {
                controller.yabaiSettings.customRules[index] = sanitized(draft)
            }
        case .draft:
            addDraftYabaiRule()
            return
        }

        clearYabaiRuleEditorState()
    }

    private func clearYabaiRuleEditorState() {
        editingYabaiRule = nil
        editingStoredYabaiRuleDraft = nil
        editingCustomYabaiRuleDraft = nil
        draftYabaiRule = nil
    }

    private func sanitized(_ rule: YabaiManagedSettings.RuleConfig) -> YabaiManagedSettings.RuleConfig {
        var sanitizedRule = rule
        sanitizedRule.name = sanitizedRule.name.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitizedRule.appPattern = sanitizedRule.appPattern.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitizedRule.titlePattern = sanitizedRule.titlePattern.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitizedRule.label = sanitizedRule.label.trimmingCharacters(in: .whitespacesAndNewlines)
        return sanitizedRule
    }

    private func sanitized(_ rule: YabaiManagedSettings.CustomRule) -> YabaiManagedSettings.CustomRule {
        var sanitizedRule = rule
        sanitizedRule.name = sanitizedRule.name.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitizedRule.appPattern = sanitizedRule.appPattern.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitizedRule.titlePattern = sanitizedRule.titlePattern.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitizedRule.label = sanitizedRule.label.trimmingCharacters(in: .whitespacesAndNewlines)
        return sanitizedRule
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

private struct WindowsTextFieldRow: View {
    let title: String
    let description: String
    @Binding var text: String
    let placeholder: String
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

                    TextField(placeholder, text: $text)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 180)
                }

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Text(description)
                            .foregroundColor(.secondary)
                    }

                    TextField(placeholder, text: $text)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
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

private struct YabaiRuleSummaryCard: View {
    let title: String
    let appPattern: String
    let titlePattern: String
    let isEnabled: Bool
    let isManaged: Bool
    let onEdit: () -> Void
    var onRemove: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayTitle)
                        .font(.headline)
                    Text("\(isEnabled ? "Enabled" : "Disabled") • \(isManaged ? "Managed" : "Floating")")
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    if let onRemove {
                        Button("Remove", action: onRemove)
                            .buttonStyle(MacSecondaryButtonStyle())
                    }

                    Button("Edit", action: onEdit)
                        .buttonStyle(MacSecondaryButtonStyle())
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(appPattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No app regex" : appPattern)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(appPattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .primary)

                if !titlePattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(titlePattern)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var displayTitle: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? "Rule" : trimmedTitle
    }
}

private struct YabaiStoredRuleEditor: View {
    @Binding var rule: YabaiManagedSettings.RuleConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.headline)

                    Text(rule.enabled ? "Rule enabled for future matching windows." : "Rule disabled.")
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 0)

                Toggle("", isOn: $rule.enabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            HStack(spacing: 12) {
                TextField("Rule Name", text: $rule.name)
                    .textFieldStyle(.roundedBorder)

                Toggle("Manage", isOn: $rule.manage)
                    .toggleStyle(.switch)
                    .labelsHidden()

                Text(rule.manage ? "Managed" : "Floating")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.secondary)
            }

            TextField("App Regex, e.g. ^Finder$", text: $rule.appPattern)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            TextField("Title Regex (Optional)", text: $rule.titlePattern)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            TextField("Rule Label", text: $rule.label)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var displayName: String {
        let trimmedName = rule.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Rule" : trimmedName
    }
}

private struct YabaiDraftRuleEditor: View {
    @Binding var rule: YabaiManagedSettings.CustomRule

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "New Rule" : rule.name)
                    .font(.headline)
                Text("Fill out the rule details, then press Done.")
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                TextField("Rule Name", text: $rule.name)
                    .textFieldStyle(.roundedBorder)
                Toggle("", isOn: $rule.enabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                Toggle("Manage", isOn: $rule.manage)
                    .toggleStyle(.switch)
                    .labelsHidden()
                Text(rule.enabled ? "Enabled" : "Disabled")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.secondary)
                Text(rule.manage ? "Managed" : "Floating")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.secondary)
            }

            TextField("App Regex, e.g. ^Slack$", text: $rule.appPattern)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            TextField("Title Regex (Optional)", text: $rule.titlePattern)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            TextField("Rule Label", text: $rule.label)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct YabaiCustomRuleEditor: View {
    @Binding var rule: YabaiManagedSettings.CustomRule
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "New Rule" : rule.name)
                        .font(.headline)
                    Text(rule.enabled ? "Rule enabled for future matching windows." : "Rule disabled.")
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 0)

                Button("Remove", action: onRemove)
                    .buttonStyle(MacSecondaryButtonStyle())
            }

            HStack(spacing: 12) {
                TextField("Rule Name", text: $rule.name)
                    .textFieldStyle(.roundedBorder)
                Toggle("", isOn: $rule.enabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                Toggle("Manage", isOn: $rule.manage)
                    .toggleStyle(.switch)
                    .labelsHidden()
                Text(rule.enabled ? "Enabled" : "Disabled")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.secondary)
                Text(rule.manage ? "Managed" : "Floating")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.secondary)
            }

            TextField("App Regex, e.g. ^Slack$", text: $rule.appPattern)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            TextField("Title Regex (Optional)", text: $rule.titlePattern)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            TextField("Rule Label", text: $rule.label)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct WindowsSliderRow: View {
    let title: String
    let description: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let valueLabel: String
    var showsDivider = true
    var onEditingChanged: ((Bool) -> Void)? = nil

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

                Slider(value: $value, in: range, onEditingChanged: { editing in
                    onEditingChanged?(editing)
                })
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
    WindowsScreen(selectedSection: .constant(.overview))
        .frame(width: 1000, height: 700)
}
