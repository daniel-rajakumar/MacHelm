MacHelm reads and writes app data in this directory.

Each user gets their own folder:
- `data/<username>/metadata.json`
- `data/<username>/apps.json`
- `data/<username>/deleted-apps.json`
- `data/<username>/homebrew-casks.json`
- `data/<username>/scan-paths.json`

The frontend should treat `data/<username>/` as its repo-local data source and update these files when state changes.
