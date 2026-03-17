 Nix-Darwin System Configuration

This repository contains a declarative macOS system configuration using `nix-darwin` and `home-manager`. It is designed to be fully reproducible by an AI or developer.

## 🛠 System Architecture

- **Flake-based**: The entire system is defined in `flake.nix`.
- **Host Configuration**: Main system settings are in `hosts/macbook.nix`.
- **User Configuration**: User-specific settings (dotfiles, apps) are managed via `hosts/daniel.nix`.
- **Automation**: Custom bash scripts in `scripts/nix/` handle rebuilds, updates, and UI formatting.

## 🚀 Bootstrapping the System

To reproduce this system on a fresh macOS installation:

1. **Install Nix**:
   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

2. **Clone this Repository**:
   ```bash
   git clone <repository-url> ~/nix
   cd ~/nix
   ```

3. **Inital Rebuild**:
   Use the provided wrapper script to apply the configuration:
   ```bash
   ./scripts/nix/darwin-rebuild.sh
   ```

## 🖥 Terminal Dashboard & UI

The system includes a custom terminal-based dashboard for managing rebuilds with "premium" visual feedback.

- **Main Dashboard**: `scripts/nix/rebuild-dashboard.sh`
  - Runs `nix flake update`.
  - Syncs configuration to Git.
  - Applies `darwin-rebuild` with semantic colorization.
- **UI Library**: `scripts/nix/ui-lib.sh` provides consistent headers, footers, and status indicators.
- **Semantic Colorizer**: `scripts/nix/semantic-colorizer.sh` transforms raw Nix output into a readable, highlighted format.

## 📁 Project Structure

```text
.
├── flake.nix              # Main entry point
├── hosts/
│   ├── macbook.nix        # System-level configuration
│   └── daniel.nix        # Home-manager/User configuration
├── scripts/nix/           # Automation & UI scripts
│   ├── rebuild-dashboard.sh  # Main rebuild entry point
│   └── semantic-colorizer.sh # Output formatter
└── app/                   # (Optional) Native Swift Dashboard source
```

## ⚙️ Key Manual Settings
Some settings are not yet fully declartive and require manual intervention:
- Font size adjustments
- Night Shift configuration
- Removing Spotlight default keybind (`Cmd + Space`)
- Changing system accent color to Green
- Adding Home/HardDrive folders to Finder sidebar