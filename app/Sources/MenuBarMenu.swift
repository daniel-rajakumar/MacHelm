import SwiftUI

struct MenuBarMenu: View {
    @State private var statusMessage = "System Ready"
    @State private var isRunning = false

    var body: some View {
        VStack(spacing: 16) {
            HeaderView()

            StatusIndicator(message: statusMessage, isRunning: isRunning)

            Divider()

            ActionButtons(isRunning: $isRunning, statusMessage: $statusMessage)

            Divider()

            QuickLinks()
        }
        .padding()
        .frame(width: 300)
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "steeringwheel")
                .font(.title)
                .foregroundColor(.blue)
            Text("MacHelm")
                .font(.headline)
            Spacer()
        }
    }
}

struct StatusIndicator: View {
    let message: String
    let isRunning: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(isRunning ? Color.yellow : Color.green)
                .frame(width: 10, height: 10)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

struct ActionButtons: View {
    @Binding var isRunning: Bool
    @Binding var statusMessage: String

    var body: some View {
        VStack(spacing: 8) {
            Button(action: runRebuild) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Run Rebuild")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)

            Button(action: updateFlake) {
                HStack {
                    Image(systemName: "arrow.down.circle")
                    Text("Update Flake")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isRunning)
        }
    }

    func runRebuild() {
        isRunning = true
        statusMessage = "Rebuilding System..."
        
        var args: [String] = []
        #if DEBUG
        args.append("--debug")
        #endif
        
        NixRunner.runScript(named: "rebuild-dashboard.sh", arguments: args) { success in
            isRunning = false
            statusMessage = success ? "Rebuild Complete" : "Rebuild Failed"
        }
    }

    func updateFlake() {
        // Implement flake update logic
    }
}

struct QuickLinks: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Quick Links")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LinkRow(title: "Open System Data", icon: "laptopcomputer")
            LinkRow(title: "Open User Data", icon: "person.circle")
        }
    }
}

struct LinkRow: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
