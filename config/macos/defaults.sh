#!/usr/bin/env bash

# Repo-owned macOS defaults. Keep this file declarative and side-effect free
# beyond the defaults it applies so the apply scripts stay thin.

apply_macos_defaults() {
    /usr/bin/defaults write com.apple.dock autohide -bool true
    /usr/bin/defaults write NSGlobalDomain AppleShowAllExtensions -bool true
}

restart_macos_services() {
    /usr/bin/killall Dock >/dev/null 2>&1 || true
    /usr/bin/killall Finder >/dev/null 2>&1 || true
}
