import SwiftUI

struct HomeScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to MacHelm")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Your Declarative macOS System")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                .padding(.horizontal, 32)
                
                // Content Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 24)], spacing: 24) {
                    // System Status Card
                    StatCard(
                        title: "System Status",
                        icon: "checkmark.seal.fill",
                        iconColor: .green,
                        value: "Healthy",
                        subtitle: "Last rebuild: 2 hours ago"
                    )
                    
                    // Configuration Card
                    StatCard(
                        title: "Configuration",
                        icon: "doc.text.fill",
                        iconColor: .blue,
                        value: "flake.nix",
                        subtitle: "3 pending changes"
                    )
                    
                    // Updates Card
                    StatCard(
                        title: "Updates",
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: .orange,
                        value: "Available",
                        subtitle: "Nixpkgs unstable needs update"
                    )
                }
                .padding(.horizontal, 32)
                
                // Quick Actions Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        ActionButton(title: "Run Rebuild", icon: "hammer.fill", color: .blue) {
                            // TODO: Trigger rebuild
                        }
                        
                        ActionButton(title: "Update Flake", icon: "arrow.down.doc.fill", color: .purple) {
                            // TODO: Trigger flake update
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
                
                Spacer()
            }
        }
    }
}

// Reusable Native-Looking Card
struct StatCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let value: String
    let subtitle: String
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label {
                    Text(title)
                        .font(.headline)
                } icon: {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// Reusable Action Button
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.headline)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeScreen()
        .frame(width: 800, height: 600)
}
