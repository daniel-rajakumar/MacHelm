#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_root="$repo_root/app"
configuration="${CONFIGURATION:-debug}"
install_dir="${INSTALL_DIR:-$HOME/Applications}"
bundle_name="MacHelm.app"
bundle_path="$install_dir/$bundle_name"

case "$(uname -m)" in
  arm64) build_triple="arm64-apple-macosx" ;;
  x86_64) build_triple="x86_64-apple-macosx" ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

if [[ "$configuration" == "release" ]]; then
  swift build --package-path "$app_root" -c release
else
  swift build --package-path "$app_root"
fi

binary_path="$app_root/.build/$build_triple/$configuration/MacHelm"
if [[ ! -x "$binary_path" ]]; then
  echo "Built executable not found at $binary_path" >&2
  exit 1
fi

rm -rf "$bundle_path"
mkdir -p "$bundle_path/Contents/MacOS" "$bundle_path/Contents/Resources"
cp "$binary_path" "$bundle_path/Contents/MacOS/MacHelm"
chmod +x "$bundle_path/Contents/MacOS/MacHelm"

cat > "$bundle_path/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MacHelm</string>
    <key>CFBundleIdentifier</key>
    <string>com.machelm.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MacHelm</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
</dict>
</plist>
PLIST

/usr/bin/plutil -lint "$bundle_path/Contents/Info.plist" >/dev/null
/usr/bin/codesign --force --deep --sign - --identifier com.machelm.app "$bundle_path" >/dev/null

if command -v /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister >/dev/null 2>&1; then
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$bundle_path" >/dev/null 2>&1 || true
fi

echo "$bundle_path"
