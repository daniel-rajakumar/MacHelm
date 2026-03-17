#!/usr/bin/env bash
set -euo pipefail

# MacHelm Rebuild Dashboard

# Source UI library
source "$(dirname "$0")/ui-lib.sh"

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

run_darwin_rebuild() {
    local darwin_rebuild_bin
    darwin_rebuild_bin="$(command -v darwin-rebuild || true)"

    if [ -z "$darwin_rebuild_bin" ]; then
        print_status "darwin-rebuild is not available in PATH." "error"
        return 1
    fi

    local rebuild_command
    rebuild_command="cd '$REPO_ROOT' && '$darwin_rebuild_bin' switch --flake '$REPO_ROOT#macbook'"

    if [ "${EUID}" -eq 0 ]; then
        /bin/bash -lc "$rebuild_command"
        return 0
    fi

    if [ -t 0 ]; then
        sudo /bin/bash -lc "$rebuild_command"
        return 0
    fi

    print_status "Requesting administrator privileges..." "info"
    local escaped_command
    escaped_command="$(printf '%s' "$rebuild_command" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    /usr/bin/osascript -e "do shell script \"$escaped_command\" with administrator privileges"
}

# Parse arguments
DEBUG=false
for arg in "$@"; do
    if [ "$arg" == "--debug" ]; then
        DEBUG=true
    fi
done

if [ "$DEBUG" = true ]; then
    print_status "Debug mode enabled" "warn"
fi

print_header "System Rebuild Control"

# Step 1: Flake Update
print_status "Updating Nix Flake..." "info"
# nix flake update --commit-lock-file

# Step 2: Apply Configuration
print_status "Applying Darwin configuration..." "info"
run_darwin_rebuild

# Step 3: Success
print_status "System rebuild complete!" "success"
print_footer
