import SwiftUI

struct GitHubSyncScreen: View {
    @ObservedObject var syncManager: GitHubSyncManager
    @State private var isConfirmingPull = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            accountSection

            if syncManager.authState == .authorizing, let code = syncManager.deviceCode {
                deviceFlowSection(code: code)
            }

            if syncManager.authState == .signedIn {
                syncSection
                syncDataSection
            }

            if let error = syncManager.errorMessage {
                errorSection(message: error)
            }
        }
        .onAppear {
            syncManager.restoreSessionFromTokenStoreIfNeeded()
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        SettingsDetailSection(title: "Account") {
            VStack(spacing: 0) {
                if syncManager.authState == .signedIn {
                    signedInRow
                } else if syncManager.authState == .authorizing {
                    authorizingRow
                } else {
                    signedOutRow
                }
            }
        }
    }

    private var signedInRow: some View {
        MacSettingsRow(showsDivider: false) {
            HStack(spacing: 14) {
                if let avatarURL = syncManager.avatarURL {
                    AsyncImage(url: avatarURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        default:
                            avatarPlaceholder
                        }
                    }
                } else {
                    avatarPlaceholder
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(syncManager.username ?? "GitHub User")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Signed in with GitHub")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        } trailing: {
            Button("Sign Out") {
                syncManager.signOut()
            }
            .buttonStyle(MacDestructiveButtonStyle())
        }
    }

    private var authorizingRow: some View {
        MacSettingsRow(showsDivider: false) {
            HStack(spacing: 12) {
                ProgressView()
                    .controlSize(.small)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Waiting for authorization…")
                        .font(.system(size: 15, weight: .semibold))
                    Text("The GitHub page opened and your code is copied.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        } trailing: {
            Button("Cancel") {
                syncManager.cancelDeviceFlow()
            }
            .buttonStyle(MacSecondaryButtonStyle())
        }
    }

    private var signedOutRow: some View {
        MacSettingsRow(showsDivider: false) {
            VStack(alignment: .leading, spacing: 4) {
                Text("GitHub Sync")
                    .font(.system(size: 15, weight: .semibold))
                Text("Sign in to sync your MacHelm configuration across Macs using a private GitHub Gist.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        } trailing: {
            Button(action: { syncManager.startDeviceFlow() }) {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.badge.plus")
                    Text("Sign in with GitHub")
                }
            }
            .buttonStyle(MacPrimaryButtonStyle())
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 40, height: 40)
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.accentColor)
        }
    }

    // MARK: - Device Flow Section

    private func deviceFlowSection(code: DeviceCodeResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AUTHORIZATION")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Finish in GitHub")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Paste the copied code on the GitHub page, then approve MacHelm.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 16)

                Button(action: syncManager.copyUserCodeToPasteboard) {
                    HStack(spacing: 8) {
                        Text(code.userCode)
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(MacSecondaryButtonStyle())

                Button("Open GitHub") {
                    syncManager.openDeviceAuthorization()
                }
                .buttonStyle(MacPrimaryButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        SettingsDetailSection(title: "Sync") {
            VStack(spacing: 0) {
                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Push to GitHub")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Upload your current MacHelm config to your private Gist.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    syncButton(
                        title: "Push",
                        icon: "arrow.up.circle",
                        accessibilityLabel: "Push MacHelm config to GitHub",
                        accessibilityHint: "Uploads this Mac's current MacHelm configuration to your private GitHub Gist.",
                        action: syncManager.pushConfig
                    )
                }
                .accessibilityElement(children: .combine)

                MacSettingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pull from GitHub")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Download and apply config from your private Gist to this Mac.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    syncButton(
                        title: "Pull",
                        icon: "arrow.down.circle",
                        accessibilityLabel: "Pull MacHelm config from GitHub",
                        accessibilityHint: "Downloads your MacHelm configuration from your private GitHub Gist and applies it to this Mac.",
                        action: { isConfirmingPull = true }
                    )
                }
                .accessibilityElement(children: .combine)

                MacSettingsRow(showsDivider: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last synced")
                            .font(.system(size: 15, weight: .semibold))
                        Text(lastSyncText)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                } trailing: {
                    syncStatusBadge
                }
            }
        }
        .alert("Apply GitHub backup to this Mac?", isPresented: $isConfirmingPull) {
            Button("Apply Backup") {
                syncManager.pullConfig()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("MacHelm will download your saved GitHub configuration and apply it to this Mac. This may replace current MacHelm settings.")
        }
    }

    @ViewBuilder
    private func syncButton(
        title: String,
        icon: String,
        accessibilityLabel: String,
        accessibilityHint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if syncManager.syncState == .syncing {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: icon)
                        .accessibilityHidden(true)
                }
                Text(title)
            }
            .frame(minWidth: 86, minHeight: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(MacSecondaryButtonStyle())
        .disabled(syncManager.syncState == .syncing)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(syncManager.syncState == .syncing ? "Sync is already in progress." : accessibilityHint)
        .accessibilityValue(syncManager.syncState == .syncing ? "Syncing" : "Ready")
    }

    private var lastSyncText: String {
        let lastSyncTimestamp = UserDefaults.standard.double(forKey: "machelm.github.lastSync")
        guard lastSyncTimestamp > 0 else { return "Never synced" }

        let date = Date(timeIntervalSince1970: lastSyncTimestamp)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    @ViewBuilder
    private var syncStatusBadge: some View {
        switch syncManager.syncState {
        case .idle:
            statusPill(text: "Ready", color: .secondary)
        case .syncing:
            statusPill(text: "Syncing…", color: .accentColor)
        case .success:
            statusPill(text: "Synced", color: .green)
        case .error:
            statusPill(text: "Error", color: .red)
        }
    }

    private func statusPill(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule(style: .continuous).fill(color))
    }

    // MARK: - Sync Data Section

    private var syncDataSection: some View {
        SettingsDetailSection(title: "What Gets Synced") {
            VStack(spacing: 0) {
                syncDataRow(
                    title: "Yabai window settings",
                    description: "Layout, padding, mouse behavior, and window rules.",
                    icon: "macwindow.on.rectangle"
                )

                syncDataRow(
                    title: "App preferences",
                    description: "Sidebar visibility, auto-refresh settings, and other MacHelm preferences.",
                    icon: "gearshape"
                )

                syncDataRow(
                    title: "Installed apps and packages",
                    description: "App inventory, Homebrew casks, Homebrew formulae, terminal tools, and third-party tools.",
                    icon: "square.grid.2x2.fill"
                )

                syncDataRow(
                    title: "Deleted apps list",
                    description: "Apps you've removed through MacHelm.",
                    icon: "trash",
                    showsDivider: false
                )
            }
        }
    }

    private func syncDataRow(title: String, description: String, icon: String, showsDivider: Bool = true) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if showsDivider {
                MacSettingsDivider()
            }
        }
    }

    // MARK: - Error Section

    private func errorSection(message: String) -> some View {
        SettingsDetailSection(title: "Error") {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// Make SettingsDetailSection accessible from this file
extension SettingsDetailSection: @unchecked Sendable {}
