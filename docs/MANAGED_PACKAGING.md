## Managed Packaging (2GP) — Maintainer Guide

This project supports second‑generation managed packaging (2GP). Follow these steps from a Dev Hub org. Do not include secrets in the repo.

Prerequisites
- Dev Hub enabled org and namespace reserved (Setup → Dev Hub; Setup → Package Manager → Namespace)
- Salesforce CLI (`sf`), authenticated to Dev Hub alias (e.g., `devhub`)

1) Project setup
- `sfdx-project.json` includes a `packageDirectories` entry with:
  - `package`: "Apex Error Logger"
  - `versionName`: e.g., `1.0.0`
  - `versionNumber`: `1.0.0.NEXT`
- Leave `namespace` empty here unless you’re building namespaced metadata locally.

2) Create the package (run once)
```bash
sf package create \
  --name "Apex Error Logger" \
  --package-type Managed \
  --path force-app \
  --target-dev-hub devhub
```
Copy the returned 0Ho… Package Id and add it to `packageAliases` (local or commit if non‑secret):
```json
"packageAliases": {
  "Apex Error Logger": "0HoXXXXXXXXXXXX"
}
```

3) Create a package version
```bash
sf package version create \
  --package "Apex Error Logger" \
  --installation-key-bypass \
  --code-coverage \
  --target-dev-hub devhub \
  --wait 120
```
Capture the 04t… Version Id.

4) Promote the version (for production install)
```bash
sf package version promote --package 04tXXXXXXXXXXXX --target-dev-hub devhub --noprompt
```

5) Install
- Production/Developer: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04tXXXXXXXXXXXX`
- Sandbox: `https://test.salesforce.com/packaging/installPackage.apexp?p0=04tXXXXXXXXXXXX`

Notes
- Tests in this repo cover the package classes. Target org must still meet 75% aggregate coverage for production installs.
- Keep Dev Hub auth, install keys, and any private scripts in a local, git‑ignored folder (see `.gitignore`).

