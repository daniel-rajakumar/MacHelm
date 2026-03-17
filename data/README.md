MacHelm reads and writes app data in this directory.

Current files:
- `<username>.json` for the current machine snapshot, for example `danielrajakumar.json`
- `deleted-apps.json` for the persisted deleted-apps state used by the frontend

The machine snapshot currently includes:
- installed apps detected by MacHelm
- app source classification
- resolved symlink paths when available
- deleted apps tracked by MacHelm
- installed Homebrew cask tokens
- scan paths, username, hostname, and export timestamp

The frontend should treat this folder as its repo-local data source and update these files when state changes.
