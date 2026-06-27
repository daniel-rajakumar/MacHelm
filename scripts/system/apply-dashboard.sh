#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/ui-lib.sh"

DEBUG=false
for arg in "$@"; do
    if [ "$arg" = "--debug" ]; then
        DEBUG=true
    fi
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

print_header "Workspace Apply Control"
bash "$SCRIPT_DIR/apply-yabai.sh"
bash "$SCRIPT_DIR/apply-macos.sh"
print_status "Workspace apply complete." "success"
print_footer
