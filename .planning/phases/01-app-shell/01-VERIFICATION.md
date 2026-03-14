---
phase: 01-app-shell
verified: 2026-03-14T06:10:00Z
status: passed
score: 4/4 must-haves verified
re_verification: false
---

# Phase 1: App Shell Verification Report

**Phase Goal:** Transy runs as a persistent macOS menu bar resident with no Dock presence, correct sandbox/entitlement configuration, and the project structure ready for feature code
**Verified:** 2026-03-14T06:10:00Z
**Status:** ✅ PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (from ROADMAP.md Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Transy appears in the macOS menu bar and can be opened/quit from its menu | ✓ VERIFIED | `MenuBarExtra("Transy", systemImage: "character.bubble")` + `.menuBarExtraStyle(.menu)` in TransyApp.swift; MenuBarView has Settings… + Quit buttons; human smoke test approved all 13 items |
| 2 | Transy has no icon in the Dock and does not appear in the Cmd+Tab app switcher | ✓ VERIFIED | `LSUIElement = <true/>` in Info.plist; `LSUIElement: true` in project.yml; `NSApp.setActivationPolicy(.accessory)` in AppDelegate; human confirmed no Dock icon and absent from Cmd+Tab |
| 3 | The app launches on macOS 15+ without sandbox violations or entitlement errors | ✓ VERIFIED | `ENABLE_APP_SANDBOX: NO` + `CODE_SIGN_ENTITLEMENTS: ""` in project.yml; no `.entitlements` file present; human confirmed no Console.app errors on launch |
| 4 | Project compiles cleanly with SPM dependencies resolved and folder structure matching the architecture | ✓ VERIFIED | All 9 source files present in correct directories; commits cd9dedd + 14cbb04 + 29c5437 + 48ae4f1 + bd9e03a verified in repo; SUMMARY reports BUILD SUCCEEDED + TEST SUCCEEDED; no SPM dependencies needed at Phase 1 |

**Score: 4/4 truths verified**

---

### Required Artifacts

| Artifact | Provides | Exists | Substantive | Wired | Status |
|----------|----------|--------|-------------|-------|--------|
| `project.yml` | xcodegen spec — source of truth for Xcode project | ✓ | ✓ (65 lines, 3 targets, LSUIElement, no sandbox) | ✓ (xcodeproj generated from it) | ✓ VERIFIED |
| `Transy/Info.plist` | LSUIElement=YES and bundle metadata | ✓ | ✓ (`<key>LSUIElement</key><true/>` present) | ✓ (linked via `INFOPLIST_FILE` build setting) | ✓ VERIFIED |
| `Transy/TransyApp.swift` | @main App with MenuBarExtra + Settings scenes + @NSApplicationDelegateAdaptor | ✓ | ✓ (MenuBarExtra + .menuBarExtraStyle(.menu) + Settings scene) | ✓ (entry point via @main) | ✓ VERIFIED |
| `Transy/AppDelegate.swift` | NSApplicationDelegate stub with activation policy | ✓ | ✓ (@MainActor, setActivationPolicy(.accessory), Phase 2 hooks commented) | ✓ (wired via @NSApplicationDelegateAdaptor in TransyApp) | ✓ VERIFIED |
| `Transy/AppState.swift` | @Observable coordinator; empty in Phase 1 | ✓ | ✓ (@MainActor @Observable, Phase 2–4 hook comments) | ⚠️ ORPHANED (not yet injected into environment — correct for Phase 1; not consumed by any view) | ✓ VERIFIED (intentionally orphaned in Phase 1 per plan) |
| `Transy/MenuBar/MenuBarView.swift` | SwiftUI menu content: Settings… (Cmd+,) + Divider + Quit Transy (Cmd+Q) | ✓ | ✓ (NSApp.activate() + openSettings() + keyboard shortcuts + Divider + Quit) | ✓ (used in MenuBarExtra content closure in TransyApp) | ✓ VERIFIED |
| `Transy/Settings/SettingsView.swift` | 320×120 placeholder window: 'Transy' headline + secondary note | ✓ | ✓ (VStack 320×120, "Transy" headline, placeholder secondary text) | ✓ (used in Settings scene in TransyApp) | ✓ VERIFIED |
| `TransyTests/TransyTests.swift` | XCTest unit-test target stub | ✓ | ✓ (Swift Testing struct, placeholder comment per Phase 1 spec) | ✓ (target registered in project.yml) | ✓ VERIFIED |
| `TransyUITests/TransyUITests.swift` | XCTest UI-test target stub | ✓ | ✓ (XCTestCase class, placeholder comment per Phase 1 spec) | ✓ (target registered in project.yml) | ✓ VERIFIED |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `project.yml` | `Transy.xcodeproj` | `xcodegen generate` | ✓ WIRED | `Transy.xcodeproj/project.pbxproj` exists; last regenerated at commit `29c5437` (GENERATE_INFOPLIST_FILE fix) |
| `Transy/Info.plist` | NSApplication activation | `LSUIElement = <true/>` | ✓ WIRED | `<key>LSUIElement</key><true/>` on line 25–26 of Info.plist; runtime confirmed: no Dock icon |
| `MenuBarView` | `SettingsView` | `@Environment(\.openSettings)` action | ✓ WIRED | `NSApp.activate()` + `openSettings()` on lines 8–9 of MenuBarView.swift; Settings window confirmed surfacing correctly |
| `TransyApp` | `MenuBarView` | `MenuBarExtra` content closure + `.menuBarExtraStyle(.menu)` | ✓ WIRED | Line 8–11 of TransyApp.swift; native dropdown confirmed at runtime |
| `AppDelegate.applicationDidFinishLaunching` | NSApp activation policy | `NSApp.setActivationPolicy(.accessory)` | ✓ WIRED | Line 7 of AppDelegate.swift; wired via `@NSApplicationDelegateAdaptor(AppDelegate.self)` in TransyApp |

---

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| **APP-01** | 01-01, 01-02 | User can access Transy from the macOS menu bar without a Dock icon | ✓ SATISFIED | LSUIElement=YES + .accessory policy (no Dock); MenuBarExtra icon + dropdown (menu bar access); human smoke test approved |

No orphaned requirements: REQUIREMENTS.md maps only APP-01 to Phase 1, and both plans claim it. All 12 v1 requirements are accounted for across phases; none are orphaned.

---

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `TransyTests/TransyTests.swift` | `// Placeholder — unit tests added in Phase 2+` | ℹ️ Info | Intentional Phase 1 stub per plan spec; not a blocker |
| `TransyUITests/TransyUITests.swift` | `// Placeholder — UI tests added in Phase 2+` | ℹ️ Info | Intentional Phase 1 stub per plan spec; not a blocker |
| `Transy/AppState.swift` | Commented-out Phase 2–4 properties | ℹ️ Info | Intentional design — documenting future attachment points; not a blocker |
| `Transy/AppDelegate.swift` | `// Phase 2: attach HotkeyMonitor here` comments | ℹ️ Info | Intentional hook documentation; not a blocker |

**No blockers. No warnings.** All info-level items are explicitly planned Phase 1 stubs.

---

### Deviation Tracking

Two deviations occurred during execution, both auto-fixed and committed:

| Plan | Deviation | Fix | Commit | Impact |
|------|-----------|-----|--------|--------|
| 01-01 | Test targets lacked `GENERATE_INFOPLIST_FILE`; code-signing failed on `xcodebuild test` | Added `GENERATE_INFOPLIST_FILE: YES` to both test targets in `project.yml`, regenerated xcodeproj | `29c5437` | Minimal; test targets now compile and sign correctly |
| 01-02 | Settings window opened silently behind other windows on macOS 15 without app activation | Added `NSApp.activate(ignoringOtherApps: true)` before `openSettings()` in MenuBarView | `bd9e03a` | Essential UX fix; pattern documented for Phase 2+ settings-triggering code |

Both deviations were caught, fixed, and verified within their respective plans before human checkpoint.

---

### Human Verification

**Status: Completed and approved.** The Plan 01-02 Task 2 runtime smoke test was a blocking human-verify checkpoint. The user ran all 13 checklist items and responded `approved`.

Items confirmed by user:
- ✓ `character.bubble` icon visible in menu bar after launch
- ✓ No Dock icon on launch
- ✓ Transy absent from Cmd+Tab switcher
- ✓ Native dropdown (not floating panel) on icon click
- ✓ Exactly: `Settings…` (Cmd+,) + Divider + `Quit Transy` (Cmd+Q) — no extra items
- ✓ Settings window opens with "Transy" headline + short secondary note (single instance)
- ✓ No Dock icon while Settings window is open
- ✓ Settings window closes without Dock appearance
- ✓ Cmd+, shortcut opens Settings
- ✓ Quit exits cleanly, menu bar icon disappears
- ✓ No sandbox violations in Console.app

---

## Summary

Phase 1 goal is **fully achieved**. All four ROADMAP success criteria are satisfied:

1. **Menu bar presence + interactivity** — `MenuBarExtra` with `.menuBarExtraStyle(.menu)`, Settings… and Quit confirmed working at runtime.
2. **No Dock / no Cmd+Tab** — `LSUIElement=YES` in Info.plist + `.accessory` activation policy in AppDelegate, belt-and-suspenders, confirmed by user.
3. **No sandbox violations** — `ENABLE_APP_SANDBOX: NO`, no `.entitlements` file, Console.app clean on launch.
4. **Clean compile + correct structure** — xcodegen-driven project, 9 source files in correct directories, Swift 6, macOS 15.0 target, BUILD SUCCEEDED + TEST SUCCEEDED per summaries and 5 verified commits.

The only pending item (AppState orphan) is an intentional Phase 1 design decision — it grows in Phase 2 and will be injected into the environment then.

**Phase 2 can proceed.** AppDelegate hook comments are in place, sandbox is disabled, and the menu bar shell is stable.

---

_Verified: 2026-03-14T06:10:00Z_
_Verifier: Claude (gsd-verifier)_
