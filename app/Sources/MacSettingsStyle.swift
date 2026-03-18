import SwiftUI

struct MacSettingsPage<Content: View>: View {
    let title: String
    let subtitle: String
    let symbol: String
    let symbolColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .top, spacing: 16) {
                    SettingsSidebarIcon(symbol: symbol, color: symbolColor, size: 44)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 28, weight: .semibold))
                        Text(subtitle)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                content
            }
            .frame(maxWidth: 920, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 40)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct MacSettingsIntroCard: View {
    let symbol: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 18) {
            SettingsSidebarIcon(symbol: symbol, color: color, size: 72)

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 34, weight: .semibold))
                Text(description)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 620)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

struct MacSettingsSection<Content: View>: View {
    let title: String
    var footer: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
            )

            if let footer, !footer.isEmpty {
                Text(footer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }
}

struct MacSettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

struct MacSettingsStatGrid: View {
    let items: [MacSettingsStatItem]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
            ForEach(items) { item in
                MacSettingsCard {
                    Label(item.title, systemImage: item.symbol)
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(item.value)
                        .font(.system(size: 30, weight: .semibold))

                    Text(item.subtitle)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct MacSettingsStatItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String
    let symbol: String
}

struct MacSettingsRow<Leading: View, Trailing: View>: View {
    let showsDivider: Bool
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    init(
        showsDivider: Bool = true,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.showsDivider = showsDivider
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                leading
                Spacer(minLength: 16)
                trailing
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            if showsDivider {
                Divider()
                    .padding(.leading, 20)
            }
        }
    }
}

struct SettingsSidebarIcon: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.9), color.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: symbol)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

struct MacSettingsSidebarLabel: View {
    let title: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            SettingsSidebarIcon(symbol: symbol, color: color, size: 28)

            Text(title)
                .font(.system(size: 15, weight: .medium))
        }
    }
}

struct MacSettingsEmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 34))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
