import SwiftUI

struct MainView: View {
    @State private var selection: SidebarItem = .home

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
        HStack(spacing: 0) {
            MacSidebar(
                selection: $selection,
                items: SidebarItem.allCases
            )
            .frame(width: 215)

            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(red: 0.118, green: 0.118, blue: 0.122))
        .frame(
            minWidth: 720,
            idealWidth: 720,
            maxWidth: 720,
            minHeight: 660,
            idealHeight: 740
        )
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: rebuildAndRestart) {
                    Label("Restart", systemImage: "arrow.triangle.2.circlepath")
                }
                .help("Rebuild & Restart App")
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection {
        case .home:
            HomeScreen()
        case .apps:
            AppsScreen()
        case .tools:
            ToolsScreen()
        case .binaries:
            BinariesScreen()
        case .store:
            StoreScreen()
        case .system:
            SystemScreen()
        case .settings:
            SettingsScreen()
        }
    }
    
    private func rebuildAndRestart() {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "sleep 1 && cd /Users/danielrajakumar/code/MacHelm/app && swift build && .build/arm64-apple-macosx/debug/MacHelm &"]
        
        do {
            try task.run()
            NSApplication.shared.terminate(nil)
        } catch {
            print("Failed to initiate restart: \(error)")
        }
    }
}

private struct MacSidebar: View {
    @Binding var selection: MainView.SidebarItem
    let items: [MainView.SidebarItem]

    var body: some View {
        ZStack {
            Color(red: 0.118, green: 0.118, blue: 0.122)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(red: 0.123, green: 0.123, blue: 0.127))
                .padding(.leading, 8)
                .padding(.top, 8)
                .padding(.bottom, 8)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                .padding(.leading, 8)
                .padding(.top, 8)
                .padding(.bottom, 8)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(items, id: \.self) { item in
                            SidebarNavButton(
                                item: item,
                                isSelected: selection == item
                            ) {
                                selection = item
                            }
                        }
                    }
                    .padding(.top, 56)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
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
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
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
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.96), color.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: symbol)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 24, height: 24)
    }
}

#Preview {
    MainView()
}
