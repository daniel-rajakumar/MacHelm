import SwiftUI

@MainActor
final class KeyboardSettingsController: ObservableObject {
    @Published var keyRepeat: Double = 2
    @Published var initialKeyRepeat: Double = 25
    @Published var pressAndHoldEnabled = false
    @Published var fullKeyboardAccess = false
    @Published var useStandardFunctionKeys = false
    @Published var automaticSpellingCorrection = true
    @Published var automaticCapitalization = true
    @Published var automaticPeriodSubstitution = true
    @Published var automaticQuoteSubstitution = true
    @Published var automaticDashSubstitution = true

    @Published var karabinerInstalled = false
    @Published var karabinerRunning = false
    @Published var karabinerVersion = "Unavailable"
    @Published var karabinerProfiles: [String] = []
    @Published var karabinerSelectedProfile = ""
    @Published var karabinerProfileToApply = ""
    @Published var karabinerDevices: [KarabinerConnectedDevice] = []
    @Published var karabinerSnapshot: KarabinerConfigSnapshot?
    @Published var karabinerConfigSource = "Unavailable"
    @Published var karabinerConfigState = "Missing"
    @Published var karabinerError: String?
    @Published var isApplyingKarabinerProfile = false

    private let globalDefaults = UserDefaults(suiteName: "NSGlobalDomain")
    private let fileManager = FileManager.default

    func load() {
        keyRepeat = Double(integerValue(forKey: "KeyRepeat", default: 2))
        initialKeyRepeat = Double(integerValue(forKey: "InitialKeyRepeat", default: 25))
        pressAndHoldEnabled = boolValue(forKey: "ApplePressAndHoldEnabled", default: false)
        fullKeyboardAccess = integerValue(forKey: "AppleKeyboardUIMode", default: 0) > 0
        useStandardFunctionKeys = boolValue(forKey: "com.apple.keyboard.fnState", default: false)
        automaticSpellingCorrection = boolValue(forKey: "NSAutomaticSpellingCorrectionEnabled", default: true)
        automaticCapitalization = boolValue(forKey: "NSAutomaticCapitalizationEnabled", default: true)
        automaticPeriodSubstitution = boolValue(forKey: "NSAutomaticPeriodSubstitutionEnabled", default: true)
        automaticQuoteSubstitution = boolValue(forKey: "NSAutomaticQuoteSubstitutionEnabled", default: true)
        automaticDashSubstitution = boolValue(forKey: "NSAutomaticDashSubstitutionEnabled", default: true)

        loadKarabiner()
    }

    func applyKeyRepeat(_ value: Double) {
        keyRepeat = value.rounded()
        write(Int(keyRepeat), forKey: "KeyRepeat")
    }

    func applyInitialKeyRepeat(_ value: Double) {
        initialKeyRepeat = value.rounded()
        write(Int(initialKeyRepeat), forKey: "InitialKeyRepeat")
    }

    func applyPressAndHoldEnabled(_ value: Bool) {
        pressAndHoldEnabled = value
        write(value, forKey: "ApplePressAndHoldEnabled")
    }

    func applyFullKeyboardAccess(_ value: Bool) {
        fullKeyboardAccess = value
        write(value ? 2 : 0, forKey: "AppleKeyboardUIMode")
    }

    func applyUseStandardFunctionKeys(_ value: Bool) {
        useStandardFunctionKeys = value
        write(value, forKey: "com.apple.keyboard.fnState")
    }

    func applyAutomaticSpellingCorrection(_ value: Bool) {
        automaticSpellingCorrection = value
        write(value, forKey: "NSAutomaticSpellingCorrectionEnabled")
    }

    func applyAutomaticCapitalization(_ value: Bool) {
        automaticCapitalization = value
        write(value, forKey: "NSAutomaticCapitalizationEnabled")
    }

    func applyAutomaticPeriodSubstitution(_ value: Bool) {
        automaticPeriodSubstitution = value
        write(value, forKey: "NSAutomaticPeriodSubstitutionEnabled")
    }

    func applyAutomaticQuoteSubstitution(_ value: Bool) {
        automaticQuoteSubstitution = value
        write(value, forKey: "NSAutomaticQuoteSubstitutionEnabled")
    }

    func applyAutomaticDashSubstitution(_ value: Bool) {
        automaticDashSubstitution = value
        write(value, forKey: "NSAutomaticDashSubstitutionEnabled")
    }

    func refreshKarabiner() {
        loadKarabiner()
    }

    func applyKarabinerProfileSelection() {
        let target = karabinerProfileToApply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard karabinerInstalled, !target.isEmpty, target != karabinerSelectedProfile else { return }

        isApplyingKarabinerProfile = true
        karabinerError = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let result = Self.runKarabinerCLI(arguments: ["--select-profile", target])

            DispatchQueue.main.async {
                self.isApplyingKarabinerProfile = false
                if result.status == 0 {
                    self.loadKarabiner()
                } else {
                    self.karabinerError = result.output.isEmpty ? "Failed to change Karabiner profile." : result.output
                }
            }
        }
    }

    var enabledSmartTypingCount: Int {
        [
            automaticSpellingCorrection,
            automaticCapitalization,
            automaticPeriodSubstitution,
            automaticQuoteSubstitution,
            automaticDashSubstitution
        ]
        .filter { $0 }
        .count
    }

    var repeatSummary: String {
        speedLabel(for: Int(keyRepeat))
    }

    var delaySummary: String {
        delayLabel(for: Int(initialKeyRepeat))
    }

    var karabinerProfileSummary: String {
        karabinerSelectedProfile.isEmpty ? "Unavailable" : karabinerSelectedProfile
    }

    var karabinerRuleCount: Int {
        karabinerSnapshot?.selectedProfile?.complex_modifications.rules.count ?? 0
    }

    var karabinerSimpleModificationCount: Int {
        karabinerSnapshot?.selectedProfile?.simple_modifications.count ?? 0
    }

    var karabinerKeyboardDeviceCount: Int {
        karabinerDevices.filter { $0.device_identifiers.is_keyboard == true || $0.device_identifiers.is_virtual_device == true }.count
    }

    var karabinerActiveConfigURL: URL? {
        if let liveURL = liveKarabinerConfigURL(), fileManager.fileExists(atPath: liveURL.path) {
            return liveURL
        }

        return latestKarabinerBackupURL()
    }

    private func loadKarabiner() {
        karabinerInstalled = karabinerCLIAvailable()
        karabinerRunning = karabinerServicesRunning()
        karabinerError = nil

        guard karabinerInstalled else {
            karabinerVersion = "Unavailable"
            karabinerProfiles = []
            karabinerSelectedProfile = ""
            karabinerProfileToApply = ""
            karabinerDevices = []
            karabinerSnapshot = nil
            karabinerConfigSource = "Unavailable"
            karabinerConfigState = "Missing"
            return
        }

        let versionResult = Self.runKarabinerCLI(arguments: ["--version-number"])
        if versionResult.status == 0 {
            karabinerVersion = versionResult.output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } else {
            karabinerVersion = "Unavailable"
        }

        let profilesResult = Self.runKarabinerCLI(arguments: ["--list-profile-names"])
        if profilesResult.status == 0 {
            karabinerProfiles = profilesResult.output
                .split(whereSeparator: { $0.isNewline })
                .map { String($0).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        } else {
            karabinerProfiles = []
            karabinerError = profilesResult.output
        }

        let currentProfileResult = Self.runKarabinerCLI(arguments: ["--show-current-profile-name"])
        if currentProfileResult.status == 0 {
            karabinerSelectedProfile = currentProfileResult.output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if karabinerProfileToApply.isEmpty || !karabinerProfiles.contains(karabinerProfileToApply) {
                karabinerProfileToApply = karabinerSelectedProfile
            }
        } else {
            karabinerSelectedProfile = ""
            karabinerProfileToApply = ""
            karabinerError = currentProfileResult.output
        }

        let deviceResult = Self.runKarabinerCLI(arguments: ["--list-connected-devices"])
        if deviceResult.status == 0 {
            karabinerDevices = decodeDevices(from: deviceResult.output)
        } else {
            karabinerDevices = []
            karabinerError = deviceResult.output
        }

        loadKarabinerConfigSnapshot()
    }

    private func loadKarabinerConfigSnapshot() {
        guard let configURL = karabinerActiveConfigURL else {
            karabinerSnapshot = nil
            karabinerConfigSource = "Unavailable"
            karabinerConfigState = "Missing"
            return
        }

        do {
            let data = try Data(contentsOf: configURL)
            let snapshot = try JSONDecoder().decode(KarabinerConfigSnapshot.self, from: data)
            karabinerSnapshot = snapshot

            if liveKarabinerConfigURL()?.path == configURL.path {
                karabinerConfigSource = "Live Config"
                karabinerConfigState = "Writable"
            } else {
                karabinerConfigSource = "Latest Backup"
                karabinerConfigState = "Read-Only"
            }
        } catch {
            karabinerSnapshot = nil
            karabinerConfigSource = "Unreadable"
            karabinerConfigState = "Error"
            karabinerError = error.localizedDescription
        }
    }

    private func decodeDevices(from output: String) -> [KarabinerConnectedDevice] {
        guard let data = output.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([KarabinerConnectedDevice].self, from: data)) ?? []
    }

    private func karabinerCLIAvailable() -> Bool {
        let result = Self.runProcess(
            executablePath: "/usr/bin/env",
            arguments: ["sh", "-lc", "command -v karabiner_cli >/dev/null 2>&1"]
        )
        return result.status == 0
    }

    private func karabinerServicesRunning() -> Bool {
        let result = Self.runProcess(
            executablePath: "/usr/bin/env",
            arguments: [
                "sh",
                "-lc",
                "pgrep -f 'Karabiner-Core-Service|karabiner_console_user_server|Karabiner-Menu' >/dev/null 2>&1"
            ]
        )
        return result.status == 0
    }

    private func liveKarabinerConfigURL() -> URL? {
        let path = NSHomeDirectory() + "/.config/karabiner/karabiner.json"
        return URL(fileURLWithPath: path)
    }

    private func latestKarabinerBackupURL() -> URL? {
        let backupDirectory = URL(fileURLWithPath: NSHomeDirectory() + "/.config/karabiner/automatic_backups", isDirectory: true)
        guard let urls = try? fileManager.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        return urls
            .filter { $0.pathExtension == "json" }
            .sorted { lhs, rhs in
                let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return lhsDate > rhsDate
            }
            .first
    }

    nonisolated private static func runKarabinerCLI(arguments: [String]) -> CommandResult {
        runProcess(executablePath: "/usr/bin/env", arguments: ["karabiner_cli"] + arguments)
    }

    nonisolated private static func runProcess(executablePath: String, arguments: [String]) -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return CommandResult(status: process.terminationStatus, output: output)
        } catch {
            return CommandResult(status: -1, output: error.localizedDescription)
        }
    }

    private func write(_ value: Any, forKey key: String) {
        globalDefaults?.set(value, forKey: key)
        globalDefaults?.synchronize()
    }

    private func integerValue(forKey key: String, default fallback: Int) -> Int {
        if let value = globalDefaults?.object(forKey: key) as? Int {
            return value
        }

        if let value = globalDefaults?.object(forKey: key) as? Double {
            return Int(value)
        }

        if let value = globalDefaults?.string(forKey: key), let integer = Int(value) {
            return integer
        }

        return fallback
    }

    private func boolValue(forKey key: String, default fallback: Bool) -> Bool {
        if let value = globalDefaults?.object(forKey: key) as? Bool {
            return value
        }

        if let value = globalDefaults?.object(forKey: key) as? Int {
            return value != 0
        }

        if let value = globalDefaults?.object(forKey: key) as? Double {
            return value != 0
        }

        return fallback
    }

    private func speedLabel(for value: Int) -> String {
        switch value {
        case ...3:
            return "Very Fast"
        case 4...12:
            return "Fast"
        case 13...30:
            return "Balanced"
        case 31...60:
            return "Slow"
        default:
            return "Very Slow"
        }
    }

    private func delayLabel(for value: Int) -> String {
        switch value {
        case ...18:
            return "Short"
        case 19...35:
            return "Balanced"
        case 36...60:
            return "Long"
        default:
            return "Very Long"
        }
    }
}

struct CommandResult {
    let status: Int32
    let output: String
}

struct KarabinerConfigSnapshot: Decodable {
    struct GlobalSettings: Decodable {
        let show_profile_name_in_menu_bar: Bool?
    }

    struct Profile: Decodable, Identifiable {
        struct VirtualHIDKeyboard: Decodable {
            let keyboard_type_v2: String?
        }

        let id = UUID()
        let name: String
        let selected: Bool?
        let simple_modifications: [KarabinerSimpleModification]
        let complex_modifications: KarabinerComplexModifications
        let virtual_hid_keyboard: VirtualHIDKeyboard?
        let devices: [KarabinerProfileDevice]

        private enum CodingKeys: String, CodingKey {
            case name
            case selected
            case simple_modifications
            case complex_modifications
            case virtual_hid_keyboard
            case devices
        }
    }

    let global: GlobalSettings?
    let profiles: [Profile]

    var selectedProfile: Profile? {
        profiles.first(where: { $0.selected == true }) ?? profiles.first
    }
}

struct KarabinerSimpleModification: Decodable, Identifiable {
    struct KeyReference: Decodable {
        let key_code: String?
    }

    struct ToKeyReference: Decodable {
        let key_code: String?
    }

    var id = UUID()
    let from: KeyReference
    let to: [ToKeyReference]
}

struct KarabinerComplexModifications: Decodable {
    let rules: [KarabinerComplexRule]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decoded = try? container.decode([String: [KarabinerComplexRule]].self)
        rules = decoded?["rules"] ?? []
    }
}

struct KarabinerComplexRule: Decodable, Identifiable {
    var id = UUID()
    let description: String
}

struct KarabinerProfileDevice: Decodable, Identifiable {
    struct Identifiers: Decodable {
        let is_keyboard: Bool?
        let product_id: Int?
        let vendor_id: Int?
    }

    var id = UUID()
    let identifiers: Identifiers?
    let treat_as_built_in_keyboard: Bool?
}

struct KarabinerConnectedDevice: Decodable, Identifiable {
    struct Identifiers: Decodable {
        let is_keyboard: Bool?
        let is_pointing_device: Bool?
        let is_consumer: Bool?
        let is_virtual_device: Bool?
        let product_id: Int?
        let vendor_id: Int?
    }

    let device_id: Int64?
    let device_identifiers: Identifiers
    let is_apple: Bool?
    let is_built_in_keyboard: Bool?
    let is_built_in_pointing_device: Bool?
    let manufacturer: String?
    let product: String?
    let transport: String?
    let serial_number: String?

    var id: String {
        if let device_id {
            return String(device_id)
        }

        return [manufacturer, product, serial_number, transport]
            .compactMap { $0 }
            .joined(separator: ":")
    }
}

struct KeyboardScreen: View {
    @StateObject private var controller = KeyboardSettingsController()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                screenHeader(
                    title: "Keyboard",
                    subtitle: "System-backed keyboard preferences, plus Karabiner-Elements status, profiles, remaps, and device visibility."
                )
                overviewSection
                repeatSection
                keyboardSection
                textInputSection
                karabinerOverviewSection
                karabinerProfilesSection
                karabinerRemapsSection
                karabinerDevicesSection
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
                        Text("System Keyboard")
                            .font(.headline)
                        Text("Changes are written to `NSGlobalDomain`. Some apps may need to be reopened before every text feature reflects the new value.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    MacMetricPill(
                        value: controller.pressAndHoldEnabled ? "Accent Menu" : "Key Repeat",
                        label: "Hold Behavior"
                    )
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Repeat Rate")
                            .font(.headline)
                        Text("macOS stores repeat speed as a numeric preference where smaller values are faster.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    MacMetricPill(value: controller.repeatSummary, label: "Speed")
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Smart Typing")
                            .font(.headline)
                        Text("Quick view of automatic typing assists currently enabled.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    MacMetricPill(value: "\(controller.enabledSmartTypingCount)/5", label: "Enabled")
                }
            }
        }
    }

    private var repeatSection: some View {
        MacSettingsSection(
            title: "Repeat",
            footer: "Lower values are faster for both sliders. `Press and hold for accents` usually replaces continuous key repeat with the accent menu in many apps."
        ) {
            VStack(spacing: 0) {
                KeyboardSliderRow(
                    title: "Key Repeat",
                    description: "Controls how quickly a held key repeats once repeating starts.",
                    value: Binding(
                        get: { controller.keyRepeat },
                        set: { controller.keyRepeat = $0 }
                    ),
                    range: 1...120,
                    step: 1,
                    valueLabel: "\(Int(controller.keyRepeat)) • \(controller.repeatSummary)",
                    onEditingChanged: { editing in
                        if !editing {
                            controller.applyKeyRepeat(controller.keyRepeat)
                        }
                    }
                )

                KeyboardSliderRow(
                    title: "Delay Until Repeat",
                    description: "Controls how long a key must be held before repeating begins.",
                    value: Binding(
                        get: { controller.initialKeyRepeat },
                        set: { controller.initialKeyRepeat = $0 }
                    ),
                    range: 10...120,
                    step: 1,
                    valueLabel: "\(Int(controller.initialKeyRepeat)) • \(controller.delaySummary)",
                    showsDivider: false,
                    onEditingChanged: { editing in
                        if !editing {
                            controller.applyInitialKeyRepeat(controller.initialKeyRepeat)
                        }
                    }
                )
            }
        }
    }

    private var keyboardSection: some View {
        MacSettingsSection(title: "Keyboard") {
            VStack(spacing: 0) {
                KeyboardToggleRow(
                    title: "Press and Hold for Accents",
                    description: "Shows the accent picker when you hold a letter instead of continuously repeating it.",
                    isOn: Binding(
                        get: { controller.pressAndHoldEnabled },
                        set: { controller.applyPressAndHoldEnabled($0) }
                    )
                )

                KeyboardToggleRow(
                    title: "Full Keyboard Navigation",
                    description: "Lets Tab move focus through controls beyond text fields and lists.",
                    isOn: Binding(
                        get: { controller.fullKeyboardAccess },
                        set: { controller.applyFullKeyboardAccess($0) }
                    )
                )

                KeyboardToggleRow(
                    title: "Use Standard Function Keys",
                    description: "Treat F1, F2, and the rest as standard function keys without holding Fn.",
                    isOn: Binding(
                        get: { controller.useStandardFunctionKeys },
                        set: { controller.applyUseStandardFunctionKeys($0) }
                    ),
                    showsDivider: false
                )
            }
        }
    }

    private var textInputSection: some View {
        MacSettingsSection(title: "Text Input") {
            VStack(spacing: 0) {
                KeyboardToggleRow(
                    title: "Correct Spelling Automatically",
                    description: "Uses the system spell checker while typing.",
                    isOn: Binding(
                        get: { controller.automaticSpellingCorrection },
                        set: { controller.applyAutomaticSpellingCorrection($0) }
                    )
                )

                KeyboardToggleRow(
                    title: "Capitalize Words Automatically",
                    description: "Capitalizes words like sentence starts and proper nouns in supported apps.",
                    isOn: Binding(
                        get: { controller.automaticCapitalization },
                        set: { controller.applyAutomaticCapitalization($0) }
                    )
                )

                KeyboardToggleRow(
                    title: "Add Period with Double-Space",
                    description: "Inserts a period when you press Space twice in supported text fields.",
                    isOn: Binding(
                        get: { controller.automaticPeriodSubstitution },
                        set: { controller.applyAutomaticPeriodSubstitution($0) }
                    )
                )

                KeyboardToggleRow(
                    title: "Use Smart Quotes",
                    description: "Substitutes straight quotes with typographic quotes.",
                    isOn: Binding(
                        get: { controller.automaticQuoteSubstitution },
                        set: { controller.applyAutomaticQuoteSubstitution($0) }
                    )
                )

                KeyboardToggleRow(
                    title: "Use Smart Dashes",
                    description: "Substitutes double hyphens and similar patterns with em and en dashes in supported apps.",
                    isOn: Binding(
                        get: { controller.automaticDashSubstitution },
                        set: { controller.applyAutomaticDashSubstitution($0) }
                    ),
                    showsDivider: false
                )
            }
        }
    }

    private var karabinerOverviewSection: some View {
        MacSettingsSection(
            title: "Karabiner-Elements",
            footer: controller.karabinerConfigSource == "Latest Backup"
                ? "No live `karabiner.json` was found, so remap details are loaded from the newest automatic backup. Profile switching still uses `karabiner_cli`."
                : "Karabiner status is loaded from `karabiner_cli`, and remap details are loaded from the active config when available."
        ) {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.headline)
                        Text("Availability of the Karabiner CLI and background services on this Mac.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    HStack(spacing: 8) {
                        MacMetricPill(value: controller.karabinerInstalled ? "Installed" : "Missing", label: "CLI")
                        MacMetricPill(value: controller.karabinerRunning ? "Running" : "Stopped", label: "Service")
                    }
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Profile")
                            .font(.headline)
                        Text("The currently active Karabiner profile reported by the command line utility.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    MacMetricPill(value: controller.karabinerProfileSummary, label: "Active")
                }

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Config Source")
                            .font(.headline)
                        Text(controller.karabinerActiveConfigURL?.path ?? "No Karabiner config snapshot found.")
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                } trailing: {
                    MacMetricPill(value: controller.karabinerConfigState, label: controller.karabinerConfigSource)
                }

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quick Actions")
                            .font(.headline)
                        Text("Open Karabiner apps, reveal the config folder, or refresh this integration.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    HStack(spacing: 8) {
                        Button("Open App") {
                            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/Applications/Karabiner-Elements.app"), configuration: .init()) { _, _ in }
                        }
                        .buttonStyle(MacSecondaryButtonStyle())

                        Button("EventViewer") {
                            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/Applications/Karabiner-EventViewer.app"), configuration: .init()) { _, _ in }
                        }
                        .buttonStyle(MacSecondaryButtonStyle())

                        Button("Reveal") {
                            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: NSHomeDirectory() + "/.config/karabiner")])
                        }
                        .buttonStyle(MacSecondaryButtonStyle())

                        Button("Reload") {
                            controller.refreshKarabiner()
                        }
                        .buttonStyle(MacSecondaryButtonStyle())
                    }
                }
            }
        }
    }

    private var karabinerProfilesSection: some View {
        MacSettingsSection(title: "Karabiner Profiles") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profile Selection")
                            .font(.headline)
                        Text("Switch the active Karabiner profile using `karabiner_cli`.")
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    HStack(spacing: 8) {
                        Picker(
                            "",
                            selection: Binding(
                                get: { controller.karabinerProfileToApply },
                                set: { controller.karabinerProfileToApply = $0 }
                            )
                        ) {
                            if controller.karabinerProfiles.isEmpty {
                                Text("Unavailable").tag("")
                            } else {
                                ForEach(controller.karabinerProfiles, id: \.self) { profile in
                                    Text(profile).tag(profile)
                                }
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 180)
                        .disabled(controller.karabinerProfiles.isEmpty || controller.isApplyingKarabinerProfile)

                        Button(controller.isApplyingKarabinerProfile ? "Applying..." : "Apply") {
                            controller.applyKarabinerProfileSelection()
                        }
                        .buttonStyle(MacPrimaryButtonStyle())
                        .disabled(
                            controller.karabinerProfiles.isEmpty ||
                            controller.karabinerProfileToApply.isEmpty ||
                            controller.karabinerProfileToApply == controller.karabinerSelectedProfile ||
                            controller.isApplyingKarabinerProfile
                        )
                    }
                }

                if let profile = controller.karabinerSnapshot?.selectedProfile {
                    MacSettingsRow {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected Profile Snapshot")
                                .font(.headline)
                            Text("Summary of the selected profile from the available config snapshot.")
                                .foregroundColor(.secondary)
                        }
                    } trailing: {
                        HStack(spacing: 8) {
                            MacMetricPill(value: "\(profile.simple_modifications.count)", label: "Simple")
                            MacMetricPill(value: "\(profile.complex_modifications.rules.count)", label: "Complex")
                            MacMetricPill(value: profile.virtual_hid_keyboard?.keyboard_type_v2?.uppercased() ?? "N/A", label: "Layout")
                        }
                    }
                }

                if let showName = controller.karabinerSnapshot?.global?.show_profile_name_in_menu_bar {
                    MacSettingsRow(showsDivider: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Menu Bar Label")
                                .font(.headline)
                            Text("Whether Karabiner is configured to show the profile name in the menu bar in the loaded snapshot.")
                                .foregroundColor(.secondary)
                        }
                    } trailing: {
                        MacMetricPill(value: showName ? "Shown" : "Hidden", label: "Snapshot")
                    }
                } else {
                    EmptyView()
                }
            }
        }
    }

    private var karabinerRemapsSection: some View {
        MacSettingsSection(title: "Karabiner Remaps") {
            VStack(spacing: 0) {
                if let profile = controller.karabinerSnapshot?.selectedProfile {
                    if profile.simple_modifications.isEmpty {
                        MacSettingsRow {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Simple Modifications")
                                    .font(.headline)
                                Text("No simple key remaps were found in the selected profile snapshot.")
                                    .foregroundColor(.secondary)
                            }
                        } trailing: {
                            MacMetricPill(value: "0", label: "Mappings")
                        }
                    } else {
                        ForEach(Array(profile.simple_modifications.prefix(6).enumerated()), id: \.offset) { index, mapping in
                            MacSettingsRow(showsDivider: index < min(profile.simple_modifications.count, 6) - 1 || !profile.complex_modifications.rules.isEmpty) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(formatSimpleModification(mapping))
                                        .font(.headline)
                                    Text("Simple modification from the selected Karabiner profile snapshot.")
                                        .foregroundColor(.secondary)
                                }
                            } trailing: {
                                MacMetricPill(value: "Simple", label: "Type")
                            }
                        }
                    }

                    if profile.complex_modifications.rules.isEmpty {
                        MacSettingsRow(showsDivider: false) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Complex Modifications")
                                    .font(.headline)
                                Text("No complex modification rules were found in the selected profile snapshot.")
                                    .foregroundColor(.secondary)
                            }
                        } trailing: {
                            MacMetricPill(value: "0", label: "Rules")
                        }
                    } else {
                        ForEach(Array(profile.complex_modifications.rules.prefix(6).enumerated()), id: \.offset) { index, rule in
                            MacSettingsRow(showsDivider: index < min(profile.complex_modifications.rules.count, 6) - 1) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(rule.description)
                                        .font(.headline)
                                    Text("Complex modification rule from the selected Karabiner profile snapshot.")
                                        .foregroundColor(.secondary)
                                }
                            } trailing: {
                                MacMetricPill(value: "Complex", label: "Type")
                            }
                        }
                    }
                } else {
                    MacSettingsRow(showsDivider: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No Remap Snapshot")
                                .font(.headline)
                            Text("MacHelm could not find a live Karabiner config or automatic backup to summarize remaps.")
                                .foregroundColor(.secondary)
                        }
                    } trailing: {
                        MacMetricPill(value: "Unavailable", label: "Snapshot")
                    }
                }
            }
        }
    }

    private var karabinerDevicesSection: some View {
        MacSettingsSection(title: "Karabiner Devices") {
            VStack(spacing: 0) {
                if controller.karabinerDevices.isEmpty {
                    MacSettingsRow(showsDivider: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connected Devices")
                                .font(.headline)
                            Text("No devices were returned by `karabiner_cli --list-connected-devices`.")
                                .foregroundColor(.secondary)
                        }
                    } trailing: {
                        MacMetricPill(value: "0", label: "Devices")
                    }
                } else {
                    ForEach(Array(controller.karabinerDevices.prefix(6).enumerated()), id: \.offset) { index, device in
                        MacSettingsRow(showsDivider: index < min(controller.karabinerDevices.count, 6) - 1) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(device.product ?? device.manufacturer ?? "Unknown Device")
                                    .font(.headline)
                                Text(deviceSubtitle(for: device))
                                    .foregroundColor(.secondary)
                            }
                        } trailing: {
                            MacMetricPill(value: deviceRole(for: device), label: device.transport ?? "Device")
                        }
                    }
                }
            }
        }
    }

    private func formatSimpleModification(_ mapping: KarabinerSimpleModification) -> String {
        let from = prettifyKeyCode(mapping.from.key_code)
        let to = mapping.to.compactMap(\.key_code).map(prettifyKeyCode(_:)).joined(separator: ", ")
        return to.isEmpty ? from : "\(from) -> \(to)"
    }

    private func prettifyKeyCode(_ keyCode: String?) -> String {
        guard let keyCode, !keyCode.isEmpty else { return "Unknown" }
        return keyCode
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private func deviceRole(for device: KarabinerConnectedDevice) -> String {
        if device.device_identifiers.is_virtual_device == true {
            return "Virtual"
        }
        if device.device_identifiers.is_keyboard == true {
            return "Keyboard"
        }
        if device.device_identifiers.is_pointing_device == true {
            return "Pointer"
        }
        if device.device_identifiers.is_consumer == true {
            return "Consumer"
        }
        return "Other"
    }

    private func deviceSubtitle(for device: KarabinerConnectedDevice) -> String {
        let manufacturer = device.manufacturer ?? "Unknown maker"
        let transport = device.transport ?? "Unknown transport"
        let builtIn: String
        if device.is_built_in_keyboard == true || device.is_built_in_pointing_device == true {
            builtIn = "Built-In"
        } else if device.device_identifiers.is_virtual_device == true {
            builtIn = "Virtual HID"
        } else {
            builtIn = "External"
        }

        return "\(manufacturer) • \(transport) • \(builtIn)"
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

private struct KeyboardToggleRow: View {
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

private struct KeyboardSliderRow: View {
    let title: String
    let description: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
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

                Slider(value: $value, in: range, step: step, onEditingChanged: onEditingChanged)
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
    KeyboardScreen()
        .frame(width: 1000, height: 700)
}
