import Foundation
import AppKit

// MARK: - Data Models

struct DeviceCodeResponse {
    let deviceCode: String
    let userCode: String
    let verificationURI: String
    let verificationURIComplete: String?
    let expiresIn: Int
    let interval: Int
}

struct GitHubUser: Codable {
    let login: String
    let name: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case login
        case name
        case avatarUrl = "avatar_url"
    }
}

struct GitHubGist: Codable {
    let id: String
    let description: String?
    let files: [String: GistFile]
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case description
        case files
        case updatedAt = "updated_at"
    }
}

struct GistFile: Codable {
    let filename: String?
    let content: String?
}

struct SyncPayload: Codable {
    let version: Int
    let updatedAt: String
    let hostName: String
    let yabaiSettings: AnyCodable?
    let preferences: [String: AnyCodable]
    let inventorySnapshot: UserConfigSnapshot?
    let deletedApps: [DeletedApp]
}

/// A type-erased Codable wrapper for storing arbitrary JSON values.
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, .init(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - Sync Manager

class GitHubSyncManager: ObservableObject {
    enum AuthState: Equatable {
        case signedOut
        case authorizing
        case signedIn
    }

    enum SyncState: Equatable {
        case idle
        case syncing
        case success
        case error(String)
    }

    // TODO: Replace with your registered GitHub OAuth App client_id
    // Register at: https://github.com/settings/developers → "New OAuth App"
    // Set the callback URL to: http://localhost (unused for device flow)
    private let clientID = "Ov23liYZppDEJNKwqyWI"
    private let tokenStorageKey = "machelm.github.accessToken"
    private let gistDescription = "MacHelm Sync — managed by MacHelm"
    private let gistFilename = "machelm-sync.json"

    @Published var authState: AuthState = .signedOut
    @Published var syncState: SyncState = .idle
    @Published var username: String?
    @Published var displayName: String?
    @Published var avatarURL: URL?
    @Published var lastSyncDate: Date?
    @Published var deviceCode: DeviceCodeResponse?
    @Published var errorMessage: String?

    private var pollTimer: Timer?
    private var hasAttemptedSessionRestore = false
    private var gistID: String? {
        get { UserDefaults.standard.string(forKey: "machelm.github.gistID") }
        set { UserDefaults.standard.set(newValue, forKey: "machelm.github.gistID") }
    }

    func restoreSessionFromTokenStoreIfNeeded() {
        guard !hasAttemptedSessionRestore, authState == .signedOut else { return }
        hasAttemptedSessionRestore = true

        if let token = loadTokenFromStore() {
            authState = .signedIn
            fetchUserProfile(token: token)
        }
    }

    // MARK: - OAuth Device Flow

    func startDeviceFlow() {
        guard authState == .signedOut else { return }
        authState = .authorizing
        errorMessage = nil
        print("[GitHubSync] Starting device flow with client ID: \(clientID)")

        let url = URL(string: "https://github.com/login/device/code")!
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")

        let body: [String: String] = [
            "client_id": clientID,
            "scope": "gist"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    print("[GitHubSync] startDeviceFlow network error: \(error.localizedDescription)")
                    self.authState = .signedOut
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let data = data else {
                    print("[GitHubSync] startDeviceFlow error: No data received")
                    self.authState = .signedOut
                    self.errorMessage = "No data received"
                    return
                }

                let responseString = String(data: data, encoding: .utf8) ?? ""
                print("[GitHubSync] startDeviceFlow response: \(responseString)")

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let deviceCode = json["device_code"] as? String,
                      let userCode = json["user_code"] as? String,
                      let verificationURI = json["verification_uri"] as? String,
                      let expiresIn = json["expires_in"] as? Int,
                      let interval = json["interval"] as? Int
                else {
                    print("[GitHubSync] startDeviceFlow parsing failed.")
                    self.authState = .signedOut
                    self.errorMessage = "Failed to start device flow. Check your client_id."
                    return
                }

                print("[GitHubSync] startDeviceFlow succeeded. User code: \(userCode)")
                self.deviceCode = DeviceCodeResponse(
                    deviceCode: deviceCode,
                    userCode: userCode,
                    verificationURI: verificationURI,
                    verificationURIComplete: json["verification_uri_complete"] as? String,
                    expiresIn: expiresIn,
                    interval: interval
                )

                self.openDeviceAuthorization()
                self.startPollingForToken(deviceCode: deviceCode, interval: interval)
            }
        }.resume()
    }

    func copyUserCodeToPasteboard() {
        guard let userCode = deviceCode?.userCode else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(userCode, forType: .string)
    }

    func openDeviceAuthorization() {
        guard let deviceCode else { return }

        copyUserCodeToPasteboard()

        let authorizationURL = deviceCode.verificationURIComplete ?? deviceCode.verificationURI
        if let url = URL(string: authorizationURL) {
            NSWorkspace.shared.open(url)
        }
    }

    func cancelDeviceFlow() {
        print("[GitHubSync] Canceling device flow")
        pollTimer?.invalidate()
        pollTimer = nil
        deviceCode = nil
        authState = .signedOut
        errorMessage = nil
    }

    private func startPollingForToken(deviceCode: String, interval: Int) {
        pollTimer?.invalidate()
        let pollInterval = TimeInterval(max(interval, 5))
        print("[GitHubSync] Starting polling timer every \(pollInterval) seconds")

        pollTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] timer in
            self?.pollForAccessToken(deviceCode: deviceCode, timer: timer)
        }
    }

    private func pollForAccessToken(deviceCode: String, timer: Timer) {
        print("[GitHubSync] Polling for access token...")
        let url = URL(string: "https://github.com/login/oauth/access_token")!
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")

        let body: [String: String] = [
            "client_id": clientID,
            "device_code": deviceCode,
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    print("[GitHubSync] Polling network error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    print("[GitHubSync] Polling error: No data received")
                    return
                }

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    print("[GitHubSync] Polling response is not valid JSON")
                    return
                }

                if json["access_token"] != nil {
                    print("[GitHubSync] Polling response: <access token redacted>")
                } else {
                    let responseString = String(data: data, encoding: .utf8) ?? ""
                    print("[GitHubSync] Polling response: \(responseString)")
                }

                if let accessToken = json["access_token"] as? String {
                    print("[GitHubSync] Polling success! Access token retrieved.")
                    timer.invalidate()
                    self.pollTimer = nil
                    self.hasAttemptedSessionRestore = true
                    self.saveTokenToStore(accessToken)
                    self.authState = .signedIn
                    self.deviceCode = nil
                    self.errorMessage = nil
                    self.fetchUserProfile(token: accessToken)
                    return
                }

                if let errorCode = json["error"] as? String {
                    print("[GitHubSync] Polling returned error: \(errorCode)")
                    switch errorCode {
                    case "authorization_pending":
                        break // Continue polling
                    case "slow_down":
                        let nextInterval = json["interval"] as? Int ?? (Int(timer.timeInterval) + 5)
                        timer.invalidate()
                        self.pollTimer = nil
                        self.startPollingForToken(deviceCode: deviceCode, interval: nextInterval)
                    case "expired_token":
                        timer.invalidate()
                        self.pollTimer = nil
                        self.authState = .signedOut
                        self.deviceCode = nil
                        self.errorMessage = "Code expired. Please try again."
                    case "access_denied":
                        timer.invalidate()
                        self.pollTimer = nil
                        self.authState = .signedOut
                        self.deviceCode = nil
                        self.errorMessage = "Access denied by user."
                    default:
                        break
                    }
                }
            }
        }.resume()
    }

    // MARK: - Sign Out

    func signOut() {
        pollTimer?.invalidate()
        pollTimer = nil
        hasAttemptedSessionRestore = true
        deleteTokenFromStore()
        authState = .signedOut
        username = nil
        displayName = nil
        avatarURL = nil
        lastSyncDate = nil
        deviceCode = nil
        gistID = nil
        errorMessage = nil
        syncState = .idle
    }

    // MARK: - User Profile

    func fetchUserProfile(token: String? = nil) {
        let profileToken: String
        if let token {
            profileToken = token
        } else if let storedToken = loadTokenFromStore() {
            profileToken = storedToken
        } else {
            return
        }
        
        var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
        request.setValue("Bearer \(profileToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            DispatchQueue.main.async {
                guard let self = self, let data = data else { return }

                // Check for unauthorized
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    self.signOut()
                    self.errorMessage = "Token expired. Please sign in again."
                    return
                }

                if let user = try? JSONDecoder().decode(GitHubUser.self, from: data) {
                    self.username = user.login
                    self.displayName = user.name
                    if let avatarStr = user.avatarUrl, let url = URL(string: avatarStr) {
                        self.avatarURL = url
                    }
                }
            }
        }.resume()
    }

    // MARK: - Sync Operations

    func sync() {
        guard authState == .signedIn else { return }
        syncState = .syncing
        errorMessage = nil

        findOrCreateGist { [weak self] gistID in
            guard let self = self, let gistID = gistID else {
                DispatchQueue.main.async {
                    self?.syncState = .error("Failed to find or create sync gist.")
                    self?.errorMessage = "Failed to find or create sync gist."
                }
                return
            }

            self.gistID = gistID
            self.pushConfigToGist(gistID: gistID)
        }
    }

    func pullConfig() {
        guard authState == .signedIn else { return }
        syncState = .syncing
        errorMessage = nil

        findOrCreateGist { [weak self] gistID in
            guard let self = self, let gistID = gistID else {
                DispatchQueue.main.async {
                    self?.syncState = .error("Failed to find sync gist.")
                    self?.errorMessage = "Failed to find sync gist."
                }
                return
            }

            self.gistID = gistID
            self.pullConfigFromGist(gistID: gistID)
        }
    }

    func pushConfig() {
        guard authState == .signedIn else { return }
        syncState = .syncing
        errorMessage = nil

        findOrCreateGist { [weak self] gistID in
            guard let self = self, let gistID = gistID else {
                DispatchQueue.main.async {
                    self?.syncState = .error("Failed to find or create sync gist.")
                    self?.errorMessage = "Failed to find or create sync gist."
                }
                return
            }

            self.gistID = gistID
            self.pushConfigToGist(gistID: gistID)
        }
    }

    // MARK: - Gist Operations

    private func findOrCreateGist(completion: @escaping (String?) -> Void) {
        // Try cached gist ID first
        if let cached = gistID {
            completion(cached)
            return
        }

        guard let token = loadTokenFromStore() else {
            completion(nil)
            return
        }

        // Search for existing gist
        var request = URLRequest(url: URL(string: "https://api.github.com/gists?per_page=100")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self = self, let data = data else {
                completion(nil)
                return
            }

            if let gists = try? JSONDecoder().decode([GitHubGist].self, from: data) {
                if let existing = gists.first(where: { $0.files[self.gistFilename] != nil }) {
                    completion(existing.id)
                    return
                }
            }

            // No existing gist found — create one
            self.createGist(token: token, completion: completion)
        }.resume()
    }

    private func createGist(token: String, completion: @escaping (String?) -> Void) {
        var request = URLRequest(url: URL(string: "https://api.github.com/gists")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = buildSyncPayload()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let payloadJSON = (try? encoder.encode(payload)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        let body: [String: Any] = [
            "description": gistDescription,
            "public": false,
            "files": [
                gistFilename: ["content": payloadJSON]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let id = json["id"] as? String
            else {
                completion(nil)
                return
            }
            completion(id)
        }.resume()
    }

    private func pushConfigToGist(gistID: String) {
        guard let token = loadTokenFromStore() else {
            DispatchQueue.main.async { self.syncState = .error("No token") }
            return
        }

        var request = URLRequest(url: URL(string: "https://api.github.com/gists/\(gistID)")!)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = buildSyncPayload()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let payloadJSON = (try? encoder.encode(payload)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        let body: [String: Any] = [
            "files": [
                gistFilename: ["content": payloadJSON]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.syncState = .error(error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                    return
                }

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self.syncState = .success
                    self.lastSyncDate = Date()
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "machelm.github.lastSync")
                } else {
                    self.syncState = .error("Push failed")
                    self.errorMessage = "Failed to push config to GitHub."
                }
            }
        }.resume()
    }

    private func pullConfigFromGist(gistID: String) {
        guard let token = loadTokenFromStore() else {
            DispatchQueue.main.async { self.syncState = .error("No token") }
            return
        }

        var request = URLRequest(url: URL(string: "https://api.github.com/gists/\(gistID)")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.syncState = .error(error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let data = data,
                      let gist = try? JSONDecoder().decode(GitHubGist.self, from: data),
                      let file = gist.files[self.gistFilename],
                      let content = file.content,
                      let contentData = content.data(using: .utf8),
                      let payload = try? JSONDecoder().decode(SyncPayload.self, from: contentData)
                else {
                    self.syncState = .error("Failed to read sync data.")
                    self.errorMessage = "Failed to parse sync gist content."
                    return
                }

                self.applySyncPayload(payload)
                self.syncState = .success
                self.lastSyncDate = Date()
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "machelm.github.lastSync")
            }
        }.resume()
    }

    // MARK: - Payload Building

    private func buildSyncPayload() -> SyncPayload {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        // Read yabai settings
        let yabaiSettingsURL = URL(fileURLWithPath: RepoConfig.repoRoot)
            .appendingPathComponent("config/yabai/settings.json")
        var yabaiSettings: AnyCodable? = nil
        if let data = try? Data(contentsOf: yabaiSettingsURL),
           let json = try? JSONSerialization.jsonObject(with: data) {
            yabaiSettings = AnyCodable(json)
        }

        // Read preferences
        let prefKeys = [
            "machelm.showToolsTab",
            "machelm.showBinariesTab",
            "machelm.autoRefreshToolsOnOpen",
            "machelm.autoRefreshBinariesOnOpen",
            "machelm.sidebar.selection"
        ]
        var preferences: [String: AnyCodable] = [:]
        for key in prefKeys {
            if let value = UserDefaults.standard.object(forKey: key) {
                preferences[key] = AnyCodable(value)
            }
        }

        // Read deleted apps
        let deletedApps = UserConfigExporter.loadDeletedApps()
        let inventorySnapshot = UserConfigExporter.loadSnapshot()

        return SyncPayload(
            version: 2,
            updatedAt: formatter.string(from: Date()),
            hostName: Host.current().localizedName ?? "Unknown Mac",
            yabaiSettings: yabaiSettings,
            preferences: preferences,
            inventorySnapshot: inventorySnapshot,
            deletedApps: deletedApps
        )
    }

    private func applySyncPayload(_ payload: SyncPayload) {
        // Apply yabai settings
        if let yabaiSettings = payload.yabaiSettings {
            let yabaiSettingsURL = URL(fileURLWithPath: RepoConfig.repoRoot)
                .appendingPathComponent("config/yabai/settings.json")
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            if let data = try? encoder.encode(yabaiSettings) {
                try? data.write(to: yabaiSettingsURL, options: .atomic)
            }
        }

        // Apply preferences
        for (key, value) in payload.preferences {
            UserDefaults.standard.set(value.value, forKey: key)
        }

        // Apply deleted apps
        UserConfigExporter.saveDeletedApps(payload.deletedApps)

        // Apply synced inventory for visibility only. This updates repo-backed data files
        // without installing or removing anything on the current Mac.
        if let inventorySnapshot = payload.inventorySnapshot {
            UserConfigExporter.saveSyncedSnapshot(inventorySnapshot)
        }
    }

    // MARK: - Token Storage

    private func saveTokenToStore(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenStorageKey)
    }

    private func loadTokenFromStore() -> String? {
        UserDefaults.standard.string(forKey: tokenStorageKey)
    }

    private func deleteTokenFromStore() {
        UserDefaults.standard.removeObject(forKey: tokenStorageKey)
    }
}
