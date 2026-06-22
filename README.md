# Graveyard Slide — Desktop App (Tauri)

This is the canonical, single source of truth for the Windows + macOS desktop
build. Both platforms build from this exact same folder — platform-specific
settings (macOS title bar, Windows installer branding, etc.) live side by
side in the same config files and just get ignored on the platform they
don't apply to.

## Project layout

```
dist/                  ← the actual game (untouched gameplay code)
  index.html
  favicon.ico
  msc/                 ← music files
src-tauri/
  Cargo.toml           ← Rust dependencies
  tauri.conf.json      ← window, bundle, installer, and updater config
  capabilities/
    default.json       ← frontend permissions for the updater/dialog plugins
  icons/                ← app icon (all platform formats)
  installer/            ← Windows NSIS installer header/sidebar images
  src/main.rs           ← native menu, console-window fix, plugin setup
.github/workflows/
  build.yml             ← CI: builds + signs both platforms, publishes releases
```

## One-time setup per machine

**Both platforms need:** Rust (rustup.rs) and Node.js (nodejs.org).
**Windows also needs:** Visual Studio Build Tools, "Desktop development with
C++" workload.
**macOS also needs:** Xcode Command Line Tools (`xcode-select --install`).

```bash
npm install
```

## Day to day

```bash
npm run tauri dev      # test in a window, hot-reloads on save
npm run tauri build    # produce the real installer
```

Output lands in `src-tauri/target/release/bundle/`:
- macOS → `macos/Graveyard Slide.app` and `dmg/*.dmg`
- Windows → `nsis/*-setup.exe` and `msi/*.msi`

## Working across two machines - use git, not zip files

Don't hand-copy the folder between Mac and Windows anymore - that's what
caused the drift we just cleaned up. Instead:

```bash
git pull            # before you start working
# ...make changes...
git add .
git commit -m "describe what changed"
git push            # before you switch machines
```

`node_modules/` and `src-tauri/target/` are gitignored on purpose - each
machine regenerates those locally via `npm install` / the build itself.
Everything that actually matters (config, Rust source, the game files) is
tracked, so both machines always converge to the same state.

## Auto-updates

The app checks GitHub Releases on launch for a newer version and prompts to
install it automatically - no manual redownloading needed for users who
already have it installed. To ship an update:

1. Bump `"version"` in `src-tauri/tauri.conf.json`.
2. `git add . && git commit -m "vX.Y.Z" && git push`
3. `git tag vX.Y.Z && git push origin vX.Y.Z`
4. GitHub Actions builds, signs, and drafts a release with both installers
   plus the `latest.json` manifest the updater reads.
5. Publish the draft release (un-draft it).

This requires the signing keypair generated via `npx tauri signer generate`
and two GitHub repo secrets: `TAURI_SIGNING_PRIVATE_KEY` and
`TAURI_SIGNING_PRIVATE_KEY_PASSWORD`. The public key half lives in
`tauri.conf.json` under `plugins.updater.pubkey`.

## Known placeholders to swap for your own content eventually

- `src-tauri/icons/` - currently a generated tombstone+moon placeholder
- `src-tauri/installer/` - matching placeholder header/sidebar images
- `plugins.updater.endpoints` in `tauri.conf.json` - needs your actual
  GitHub username/repo
- `plugins.updater.pubkey` - needs your actual generated public key
