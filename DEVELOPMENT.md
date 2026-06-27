# Graveyard Slide — Developer Notes

This is the dev-facing companion to README.md (which is for players). Keep
this file out of anything players would see — it documents how the app is
built and how to ship updates, not how to play it.

## Project layout

```
dist/                  ← the actual game (untouched gameplay code)
  index.html
  favicon.ico
  msc/                 ← music files
src-tauri/
  Cargo.toml           ← Rust dependencies
  tauri.conf.json       ← window, bundle, installer, and updater config
  capabilities/
    default.json       ← frontend permissions for the updater/window plugins
  dmg-images/           ← macOS DMG background + dmgbuild script
  icons/                ← app icon (all platform formats)
  installer/            ← Windows NSIS installer header/sidebar images
  src/main.rs           ← native menu, console-window fix, plugin setup
scripts/
  build-dmg.sh          ← builds the styled macOS DMG (replaces Tauri's
                          built-in DMG step, which doesn't apply custom
                          backgrounds reliably)
.github/workflows/
  build.yml             ← CI: builds + signs both platforms, publishes
                          releases, rebuilds the DMG with the custom
                          background afterward
```

## One-time setup per machine

**Both platforms need:** Rust (rustup.rs) and Node.js (nodejs.org).
**Windows also needs:** Visual Studio Build Tools, "Desktop development with
C++" workload.
**macOS also needs:** Xcode Command Line Tools (`xcode-select --install`),
Homebrew Python 3.12 (`brew install python@3.12`) for the DMG build script.

```bash
npm install
```

On Mac, the signing key also needs to be available in your shell (already
set up via `~/.zshrc` if you followed the original setup):

```bash
export TAURI_SIGNING_PRIVATE_KEY="$(cat ~/.tauri/graveyardslide.key)"
export TAURI_SIGNING_PRIVATE_KEY_PASSWORD="your_password"
```

## Day to day

```bash
npm run tauri dev      # test in a window, hot-reloads on save
npm run tauri build    # produce the real installer
```

Output lands in `src-tauri/target/release/bundle/`:
- macOS → `macos/Graveyard Slide.app` and `dmg/*.dmg`
- Windows → `nsis/*-setup.exe` and `msi/*.msi`

On Mac, the plain `npm run tauri build` DMG won't have the custom
background applied (a known Tauri limitation on newer macOS). To get the
styled version locally:

```bash
npm run tauri build -- --bundles app
./scripts/build-dmg.sh
```

This isn't needed for real releases — GitHub Actions runs this
automatically as part of the publish workflow.

## Working across two machines — use git, not zip files

```bash
git pull            # before you start working
# ...make changes...
git add .
git commit -m "describe what changed"
git push            # before you switch machines
```

`node_modules/`, `src-tauri/target/`, and `.dmg-venv/` are gitignored on
purpose — each machine regenerates those locally. Everything that actually
matters (config, Rust source, the game files) is tracked.

---

## 🚀 Shipping an update — the routine

Follow this every time, in order.

### 1. Test locally first
```bash
npm run tauri dev
```
Confirm the change actually works before bumping anything.

### 2. Bump the version (both files, must match exactly)

`src-tauri/tauri.conf.json`:
```json
"version": "0.1.8",   →   "version": "0.1.9",
```

`src-tauri/Cargo.toml`:
```toml
version = "0.1.8"   →   version = "0.1.9"
```

### 3. Commit and push
```bash
git add .
git commit -m "v0.1.9: describe what changed"
git push
```

### 4. Tag and push the tag — this triggers the actual build
```bash
git tag v0.1.9
git push origin v0.1.9
```

### 5. Watch the build
Repo → **Actions** tab → find the run for your tag → wait for both
`build (macos-latest)` ✅ and `build (windows-latest)` ✅.

### 6. Write real release notes, then publish
Repo → **Releases** tab → find the new **Draft** release.

**Important:** click the ✏️ edit icon and actually type release notes into
the description box here. Your git commit message does NOT become the
release notes — they're two completely separate things. The in-app "What's
New" screen players see after updating pulls directly from whatever you
write in this box.

Confirm the release has all 8 expected assets (`.dmg`, `.exe`, `.msi`, both
`.sig` files, `.app.tar.gz`, `.app.tar.gz.sig`, `latest.json`), then click
**Publish release**.

### 7. Done
- New players download directly from the Releases page.
- Existing players get a native in-game "Update available" prompt next
  time they open the app, with your real release notes shown automatically
  once the update finishes.

---

## Troubleshooting

- **"Resource not accessible by integration" during build** → Settings →
  Actions → General → Workflow permissions → "Read and write permissions"
  → Save → re-run the failed job (no new tag needed).
- **Local build error: "public key found but no private key"** → re-export
  the signing env vars (see setup section above).
- **Divergent branches on `git push`** → `git pull` first (choose merge if
  prompted: `git config pull.rebase false`), resolve, then push again.
- **DMG background missing/blank on a local build** → known issue with
  Tauri's built-in DMG step on newer macOS. Use `scripts/build-dmg.sh`
  instead (see "Day to day" above). Not an issue on real published
  releases, since CI handles this automatically.
