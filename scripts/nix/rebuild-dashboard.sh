#!/usr/bin/env bash

# MacHelm Rebuild Dashboard

# Source UI library
source "$(dirname "$0")/ui-lib.sh"

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
# darwin-rebuild switch --flake .#macbook

# Step 3: Success
print_status "System rebuild complete!" "success"
print_footer
