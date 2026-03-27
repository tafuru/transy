# Release Automation Research: DMG Creation & GitHub Releases

**Project:** Transy (macOS menu-bar translator)
**Researched:** 2025-07-18
**Overall confidence:** HIGH

---

## Overview

When a git tag (e.g., `v0.4.0`) is pushed, a GitHub Actions workflow should build a release `.app`, package it into a DMG with a drag-to-Applications layout, and create a GitHub Release with the DMG attached. No code signing or notarization is required at this stage.

---

## 1. Release Build Strategy

### xcodebuild for Release Builds

Two approaches for creating a release `.app`:

#### Option A: `xcodebuild build` with Release configuration (recommended for unsigned)

```bash
xcodebuild build \
  -scheme Transy \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

The built `.app` is located at:
```
./DerivedData/Build/Products/Release/Transy.app
```

**Pros:** Simple, straightforward. No need for export options plist.
**Cons:** No `.xcarchive` artifact for future signing.

#### Option B: `xcodebuild archive` + `xcodebuild -exportArchive`

```bash
# Step 1: Archive
xcodebuild archive \
  -scheme Transy \
  -destination 'platform=macOS' \
  -archivePath ./build/Transy.xcarchive \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Step 2: Export (requires ExportOptions.plist)
xcodebuild -exportArchive \
  -archivePath ./build/Transy.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./build/export
```

**Pros:** Proper archive pipeline, easy to add signing later.
**Cons:** Requires `ExportOptions.plist`. Overkill for unsigned distribution.

**Recommendation:** Use **Option A** for now. When code signing and notarization are added later, switch to Option B. The `.app` output is identical for an unsigned build.

### Extracting Version from Git Tag

Transy already has a post-build script in `project.yml` that sets `CFBundleShortVersionString` from `git describe --tags`. This runs automatically during `xcodebuild build`, so the `.app` will have the correct version.

For the workflow itself, extract the version from the tag:

```yaml
- name: Extract version
  id: version
  run: echo "version=${GITHUB_REF_NAME#v}" >> "$GITHUB_OUTPUT"
  # Tag "v0.4.0" → version "0.4.0"
```

---

## 2. DMG Creation

### Tool Comparison

| Tool | Language | Install | Features | Complexity |
|------|----------|---------|----------|------------|
| **create-dmg** | Shell | `brew install create-dmg` | Background image, icon layout, Applications link, volume icon | Low |
| **hdiutil** (raw) | Built-in | Pre-installed | Full control, no dependencies | High (manual AppleScript for layout) |
| **dmgbuild** | Python | `pip install dmgbuild` | Programmatic config, JSON/Python DSL | Medium |
| **node-appdmg** | Node.js | `npm install appdmg` | JSON config, background support | Medium |

**Recommendation:** Use **`create-dmg`**. It's a pure shell script with no runtime dependencies (macOS only), installable via Homebrew, and provides the drag-to-Applications layout with a single command. It's the most popular tool for this purpose in the macOS open-source community.

### create-dmg Usage

```bash
brew install create-dmg

create-dmg \
  --volname "Transy" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Transy.app" 150 190 \
  --hide-extension "Transy.app" \
  --app-drop-link 450 190 \
  --no-internet-enable \
  "Transy-${VERSION}.dmg" \
  ./dmg-source/
```

**Key options:**
- `--volname "Transy"` — volume name shown in Finder
- `--window-size 600 400` — DMG window size when opened
- `--icon "Transy.app" 150 190` — position the app icon on the left
- `--app-drop-link 450 190` — "Applications" alias icon on the right
- `--hide-extension "Transy.app"` — cleaner appearance
- `--no-internet-enable` — skip deprecated internet-enable feature

### Directory Setup Before DMG Creation

```bash
# Create staging directory
mkdir -p dmg-source

# Copy the built .app
cp -R ./DerivedData/Build/Products/Release/Transy.app ./dmg-source/
```

### CI Gotcha: Finder AppleScript

`create-dmg` uses AppleScript to set window positions and icon arrangements via Finder. On CI runners without a GUI session, this can fail. The `--skip-jenkins` flag exists for this:

```bash
create-dmg \
  --volname "Transy" \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Transy.app" 150 190 \
  --hide-extension "Transy.app" \
  --app-drop-link 450 190 \
  --no-internet-enable \
  --skip-jenkins \
  "Transy-${VERSION}.dmg" \
  ./dmg-source/
```

**Important:** `--skip-jenkins` disables the Finder-prettifying AppleScript. The DMG will still work and contain the Applications link, but window positioning/icon arrangement won't be set. For a v1 release workflow, this is acceptable. Most users drag the app from the DMG regardless of cosmetics.

**Alternative without `--skip-jenkins`:** GitHub Actions macOS runners DO have a GUI session available (unlike Linux). The AppleScript usually works, but may occasionally fail with "Can't get disk" errors. If this happens, increase `--applescript-sleep-duration`:

```bash
create-dmg --applescript-sleep-duration 10 ...
```

**Recommendation:** Start without `--skip-jenkins`. If the workflow fails intermittently due to AppleScript issues, add it.

### Fallback: Raw hdiutil (no cosmetics)

If `create-dmg` causes issues, a minimal DMG can be created with just `hdiutil`:

```bash
mkdir -p dmg-source
cp -R ./DerivedData/Build/Products/Release/Transy.app ./dmg-source/
ln -s /Applications ./dmg-source/Applications

hdiutil create \
  -volname "Transy" \
  -srcfolder ./dmg-source \
  -ov \
  -format UDZO \
  "Transy-${VERSION}.dmg"
```

This creates a functional DMG with the app and Applications symlink, but no pretty window layout.

---

## 3. GitHub Release Creation

### Using `gh release create`

The GitHub CLI (`gh`) is pre-installed on all runners (v2.87.3 on `macos-15`). It's the simplest way to create releases.

```yaml
- name: Create GitHub Release
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    gh release create "${{ github.ref_name }}" \
      "Transy-${{ steps.version.outputs.version }}.dmg#Transy ${{ steps.version.outputs.version }} (macOS)" \
      --title "Transy ${{ steps.version.outputs.version }}" \
      --generate-notes \
      --verify-tag
```

**Key flags:**
- `--generate-notes` — auto-generates release notes from PRs/commits since the last tag using GitHub's Release Notes API
- `--verify-tag` — aborts if the tag doesn't exist (safety check)
- `"file.dmg#Display Label"` — uploads the DMG with a human-readable display label

### Authentication

`GITHUB_TOKEN` is automatically available in workflows. No additional secrets needed. Set it via `GH_TOKEN` environment variable (the `gh` CLI reads this).

### Release Notes Options

| Approach | How | Pros | Cons |
|----------|-----|------|------|
| **`--generate-notes`** | Auto-generates from PR titles/commits | Zero effort, consistent | May include noise from deps/CI PRs |
| **`--notes-from-tag`** | Uses annotated tag message | Manual control | Requires annotated tags (`git tag -a`) |
| **`-F CHANGELOG.md`** | Reads from file | Full control, curated | Must maintain CHANGELOG.md |
| **`--notes "text"`** | Inline text | Quick | Hard to maintain |

**Recommendation:** Use `--generate-notes` for now. It's zero-maintenance and produces useful release notes from PR titles. When the project matures and needs curated changelogs, switch to `--notes-from-tag` with annotated tags or a CHANGELOG.md file.

### Optional: `.github/release.yml` for Better Auto-Generated Notes

Create a categorization file to group PRs in auto-generated notes:

```yaml
# .github/release.yml
changelog:
  categories:
    - title: "✨ Features"
      labels: ["enhancement"]
    - title: "🐛 Bug Fixes"
      labels: ["bug"]
    - title: "🔧 Maintenance"
      labels: ["chore", "ci", "dependencies"]
    - title: "📖 Documentation"
      labels: ["documentation"]
    - title: "Other Changes"
      labels: ["*"]
```

---

## 4. Complete Release Workflow YAML

### Implementation

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write  # Required for creating releases

env:
  HOMEBREW_NO_AUTO_UPDATE: 1
  HOMEBREW_NO_INSTALL_CLEANUP: 1

jobs:
  release:
    name: Build & Release
    runs-on: macos-15
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for git describe

      - name: Extract version from tag
        id: version
        run: echo "version=${GITHUB_REF_NAME#v}" >> "$GITHUB_OUTPUT"

      - name: Install tools
        run: |
          brew install xcodegen create-dmg

      - name: Generate Xcode project
        run: xcodegen generate

      - name: Build Release
        run: |
          xcodebuild build \
            -scheme Transy \
            -configuration Release \
            -destination 'platform=macOS' \
            -derivedDataPath ./DerivedData \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO \
            | xcbeautify --renderer github-actions

      - name: Verify .app exists
        run: |
          APP_PATH="./DerivedData/Build/Products/Release/Transy.app"
          if [ ! -d "$APP_PATH" ]; then
            echo "::error::Transy.app not found at $APP_PATH"
            exit 1
          fi
          echo "✅ Transy.app found"
          # Verify version was set correctly
          VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
          echo "📦 App version: $VERSION"

      - name: Create DMG
        run: |
          mkdir -p dmg-source
          cp -R ./DerivedData/Build/Products/Release/Transy.app ./dmg-source/

          create-dmg \
            --volname "Transy" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --icon "Transy.app" 150 190 \
            --hide-extension "Transy.app" \
            --app-drop-link 450 190 \
            --no-internet-enable \
            "Transy-${{ steps.version.outputs.version }}.dmg" \
            ./dmg-source/

      - name: Create GitHub Release
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh release create "${{ github.ref_name }}" \
            "Transy-${{ steps.version.outputs.version }}.dmg#Transy ${{ steps.version.outputs.version }} (macOS)" \
            --title "Transy ${{ steps.version.outputs.version }}" \
            --generate-notes \
            --verify-tag
```

### How to Trigger a Release

```bash
# Create and push a tag
git tag v0.4.0
git push origin v0.4.0
```

This triggers the workflow, which builds the release, creates the DMG, and publishes a GitHub Release with the DMG attached.

---

## 5. Unsigned App Distribution Considerations

### What Happens Without Signing?

When users download and open an unsigned DMG:

1. **Gatekeeper warning**: macOS will show "Transy can't be opened because Apple cannot check it for malicious software"
2. **Workaround**: Right-click → Open → click "Open" in the dialog
3. **Alternative**: `xattr -cr /Applications/Transy.app` in Terminal

### Communicating to Users

Add installation instructions to the GitHub Release body or README:

```markdown
## Installation

1. Download `Transy-X.Y.Z.dmg`
2. Open the DMG and drag Transy to Applications
3. On first launch, right-click Transy → Open → click "Open"
   (This is needed because the app is not yet code-signed)
```

### Future: Adding Code Signing & Notarization

When ready to add signing, the workflow changes:

1. Store signing certificate in GitHub Secrets (base64-encoded `.p12`)
2. Create a temporary keychain in CI
3. Import the certificate
4. Use `xcodebuild archive` + `-exportArchive` instead of `build`
5. Run `xcrun notarytool submit` to notarize the DMG
6. Staple with `xcrun stapler staple`

This is a significant addition (~50 lines of workflow code). Defer until the app needs broader distribution.

---

## 6. Gotchas & Pitfalls

### Critical

| Gotcha | Detail | Solution |
|--------|--------|----------|
| **create-dmg exit code** | `create-dmg` returns exit code 2 on "DMG created successfully but Finder layout couldn't be set" (common on CI) | Check for this: `create-dmg ... \|\| test $? -eq 2` (treat exit code 2 as success) |
| **App path varies** | Release build output path depends on `-derivedDataPath` | Always specify `-derivedDataPath ./DerivedData` and use `./DerivedData/Build/Products/Release/Transy.app` |
| **Tag must exist before workflow** | `--verify-tag` will fail if the tag doesn't exist | Tags trigger the workflow, so this is always true for `push: tags:` triggers |
| **permissions: contents: write** | `GITHUB_TOKEN` needs write permission to create releases | Set `permissions: contents: write` in the workflow |

### Moderate

| Gotcha | Detail | Solution |
|--------|--------|----------|
| **DMG file size** | Unsigned apps can be large with debug symbols | Release configuration strips debug symbols by default. ~5-15 MB expected for Transy. |
| **Duplicate release** | Pushing the same tag twice will fail on `gh release create` | Tags should be unique. If re-releasing, delete the old release first. |
| **Version mismatch** | Tag version vs. app version could diverge | Transy's post-build script reads from git tag. As long as `fetch-depth: 0`, they're in sync. |
| **Homebrew race condition** | Installing xcodegen + create-dmg in one `brew install` is fine | `brew install xcodegen create-dmg` installs both in one invocation |

### create-dmg Exit Code 2 Handling

This is the most common CI issue with `create-dmg`. The tool returns exit code 2 when it successfully creates the DMG but couldn't apply Finder cosmetics (window position, icon arrangement). Handle it:

```yaml
- name: Create DMG
  run: |
    set +e  # Don't exit on non-zero
    create-dmg \
      --volname "Transy" \
      --window-pos 200 120 \
      --window-size 600 400 \
      --icon-size 100 \
      --icon "Transy.app" 150 190 \
      --hide-extension "Transy.app" \
      --app-drop-link 450 190 \
      --no-internet-enable \
      "Transy-${{ steps.version.outputs.version }}.dmg" \
      ./dmg-source/
    EXIT_CODE=$?
    set -e

    if [ $EXIT_CODE -ne 0 ] && [ $EXIT_CODE -ne 2 ]; then
      echo "::error::create-dmg failed with exit code $EXIT_CODE"
      exit $EXIT_CODE
    fi

    # Verify DMG was created
    ls -la "Transy-${{ steps.version.outputs.version }}.dmg"
    echo "✅ DMG created successfully"
```

---

## 7. Optional Enhancements

### Upload Build Artifact (for debugging)

```yaml
- name: Upload DMG artifact
  uses: actions/upload-artifact@v4
  with:
    name: Transy-${{ steps.version.outputs.version }}
    path: "Transy-${{ steps.version.outputs.version }}.dmg"
    retention-days: 30
```

### Pre-release Support

For beta/RC releases using tags like `v0.4.0-beta.1`:

```yaml
- name: Create GitHub Release
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    PRERELEASE_FLAG=""
    if [[ "${{ github.ref_name }}" == *"-"* ]]; then
      PRERELEASE_FLAG="--prerelease"
    fi

    gh release create "${{ github.ref_name }}" \
      "Transy-${{ steps.version.outputs.version }}.dmg#Transy ${{ steps.version.outputs.version }} (macOS)" \
      --title "Transy ${{ steps.version.outputs.version }}" \
      --generate-notes \
      --verify-tag \
      $PRERELEASE_FLAG
```

### Run Tests Before Release

Add a test step before the release build to catch issues:

```yaml
- name: Test
  run: |
    xcodebuild test \
      -scheme Transy \
      -destination 'platform=macOS' \
      CODE_SIGN_IDENTITY="-" \
      CODE_SIGNING_REQUIRED=NO \
      CODE_SIGNING_ALLOWED=NO \
      | xcbeautify --renderer github-actions
```

---

## 8. Recommendation

1. **Use the workflow from Section 4** as the starting point
2. **Add the exit code 2 handling** from Section 6 for `create-dmg` robustness
3. **Use `--generate-notes`** for automated release notes
4. **Add a `.github/release.yml`** to categorize PRs in release notes
5. **Defer code signing** until the app needs broader distribution
6. **Consider adding a test step** in the release workflow for safety

**Total estimated release workflow time:** ~3-5 minutes (XcodeGen + create-dmg install: ~30s, build: ~60-90s, DMG creation: ~15s, release creation: ~5s).

---

## Sources

| Source | Confidence | What It Provided |
|--------|-----------|-----------------|
| [create-dmg README](https://github.com/create-dmg/create-dmg) | HIGH | DMG creation options, CLI flags, CI considerations |
| [GitHub CLI release docs](https://cli.github.com/manual/gh_release_create) | HIGH | Release creation flags, asset upload syntax |
| [actions/runner-images](https://github.com/actions/runner-images) | HIGH | Pre-installed tools, runner capabilities |
| [GitHub Docs: Automatically generated release notes](https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes) | HIGH | `.github/release.yml` format |
| Transy `project.yml` post-build script | HIGH | Version injection mechanism from git tags |
