# MacHelm
MacHelm is a macOS system orchestration platform inspired by the concept of a ship’s helm. A central point of control where users can steer their entire macOS, managing applications, automation, and configurations with precision.

## Architecture

- [app/](/Users/danielrajakumar/code/MacHelm/app) contains the Swift app and UI logic.
- [config/](/Users/danielrajakumar/code/MacHelm/config) contains repo-owned configuration sources.
- [scripts/system/](/Users/danielrajakumar/code/MacHelm/scripts/system) contains apply-time execution logic.
- [data/](/Users/danielrajakumar/code/MacHelm/data) contains generated machine snapshots and inventories.

## Config Layout

- [config/macos/defaults.sh](/Users/danielrajakumar/code/MacHelm/config/macos/defaults.sh) is the source of truth for macOS defaults managed by the repo.
- [config/system/app-scan-paths.json](/Users/danielrajakumar/code/MacHelm/config/system/app-scan-paths.json), [config/system/binary-scan-roots.json](/Users/danielrajakumar/code/MacHelm/config/system/binary-scan-roots.json), [config/system/command-search-paths.json](/Users/danielrajakumar/code/MacHelm/config/system/command-search-paths.json), and [config/system/brew-paths.json](/Users/danielrajakumar/code/MacHelm/config/system/brew-paths.json) define machine lookup paths.
- [config/yabai/settings.json](/Users/danielrajakumar/code/MacHelm/config/yabai/settings.json), [config/yabai/yabairc](/Users/danielrajakumar/code/MacHelm/config/yabai/yabairc), and [config/yabai/generated.yabairc](/Users/danielrajakumar/code/MacHelm/config/yabai/generated.yabairc) are the source of truth for Yabai.
- [config/yabai/binary-paths.json](/Users/danielrajakumar/code/MacHelm/config/yabai/binary-paths.json) defines how MacHelm locates the Yabai executable.

## Apply Flow

- [apply-dashboard.sh](/Users/danielrajakumar/code/MacHelm/scripts/system/apply-dashboard.sh) orchestrates the workspace apply process.
- [apply-yabai.sh](/Users/danielrajakumar/code/MacHelm/scripts/system/apply-yabai.sh) links repo-owned Yabai files into the home directory.
- [apply-macos.sh](/Users/danielrajakumar/code/MacHelm/scripts/system/apply-macos.sh) applies macOS defaults from repo config.
