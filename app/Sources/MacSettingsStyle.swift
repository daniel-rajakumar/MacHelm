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
                content
            }
            .frame(maxWidth: 920, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 30)
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
        HStack(alignment: .top, spacing: 14) {
            SettingsSidebarIcon(symbol: symbol, color: color, size: 44)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 24, weight: .semibold))
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
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
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
            )

            if let footer, !footer.isEmpty {
                Text(footer)
                    .font(.system(size: 12.5))
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
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
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
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text(item.value)
                        .font(.system(size: 26, weight: .semibold))

                    Text(item.subtitle)
                        .font(.system(size: 12.5))
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
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 16) {
                    leading
                    Spacer(minLength: 16)
                    trailing
                }

                VStack(alignment: .leading, spacing: 12) {
                    leading

                    HStack {
                        Spacer(minLength: 0)
                        trailing
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

struct MacSettingsDivider: View {
    var leading: CGFloat = 16

    var body: some View {
        Divider()
            .overlay(Color.white.opacity(0.05))
            .padding(.leading, leading)
    }
}

struct MacMetricPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .semibold))
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }
}

struct MacSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.1 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
    }
}

struct MacPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color(red: 0.39, green: 0.76, blue: 0.27).opacity(configuration.isPressed ? 0.85 : 1))
            )
    }
}

struct MacDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Color(red: 1, green: 0.45, blue: 0.45))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.red.opacity(configuration.isPressed ? 0.16 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Color.red.opacity(0.14), lineWidth: 1)
            )
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

struct MacInlineSearchField: View {
    let prompt: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
