MacHelm reads and writes app data in this directory.

Each user gets their own folder:
- `data/<username>/metadata.json`
- `data/<username>/apps.json`
- `data/<username>/deleted-apps.json`
- `data/<username>/homebrew-casks.json`
- `data/<username>/scan-paths.json`
- `data/<username>/terminal-tools.json`
- `data/<username>/homebrew-formulae.json`
- `data/<username>/homebrew-manual-formulae.json`
- `data/<username>/homebrew-dependency-formulae.json`
- `data/<username>/nix-tools.json`
- `data/<username>/third-party-tools.json`
- `data/<username>/shell-paths.json`
- `data/<username>/filesystem-binaries.json`
- `data/<username>/binary-scan-roots.json`

The frontend should treat `data/<username>/` as its repo-local data source and update these files when state changes.
