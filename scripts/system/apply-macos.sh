#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/ui-lib.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/config/macos/defaults.sh"

print_status "Applying macOS defaults from repo config..." "info"
apply_macos_defaults
restart_macos_services
