#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
YABAI_CONFIG_DIR="$HOME/.config/yabai"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/ui-lib.sh"

link_file() {
    local source_path=$1
    local target_path=$2

    mkdir -p "$(dirname "$target_path")"
    ln -sfn "$source_path" "$target_path"
}

print_status "Linking Yabai config into the home directory..." "info"
mkdir -p "$YABAI_CONFIG_DIR"

link_file "$REPO_ROOT/config/yabai/yabairc" "$YABAI_CONFIG_DIR/yabairc"
chmod +x "$REPO_ROOT/config/yabai/yabairc"

link_file "$REPO_ROOT/config/yabai/generated.yabairc" "$YABAI_CONFIG_DIR/generated.yabairc"
chmod +x "$REPO_ROOT/config/yabai/generated.yabairc"

link_file "$REPO_ROOT/config/yabai/settings.json" "$YABAI_CONFIG_DIR/settings.json"

cat > "$HOME/.yabairc" <<'EOF'
#!/usr/bin/env sh
exec "$HOME/.config/yabai/yabairc"
EOF
chmod +x "$HOME/.yabairc"
