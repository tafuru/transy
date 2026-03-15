# Roadmap: Transy

## Overview

Transy is built in four dependency-constrained phases. Phase 1 establishes the menu bar shell — the irreversible configuration decisions (entitlements, LSUIElement, project structure) that everything else depends on. Phase 2 wires up the double-Cmd+C trigger, permissions onboarding, clipboard safety, and the non-activating popup showing source text in a muted loading state. Phase 3 plugs Apple Translation into the coordinator so that source-text placeholder resolves to a real translation. Phase 4 adds the settings window for target-language selection and model management, making the app fully configurable. The core reading-flow loop is complete at the end of Phase 3; Phase 4 is polish that makes it yours.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: App Shell** - Runnable menu bar app with no Dock icon, correct entitlements, and project scaffold (completed 2026-03-14)
- [x] **Phase 2: Trigger & Popup** - Double-Cmd+C fires a non-focus-stealing popup showing source text in a muted loading state (completed 2026-03-14)
- [x] **Phase 3: Translation Loop** - Skeleton resolves to an on-device Apple Translation result in the same popup (completed 2026-03-15)
- [x] **Phase 4: Settings** - Target language and model availability are configurable from a dedicated settings window (completed 2026-03-15)

## Phase Details

### Phase 1: App Shell
**Goal**: Transy runs as a persistent macOS menu bar resident with no Dock presence, correct sandbox/entitlement configuration, and the project structure ready for feature code
**Depends on**: Nothing (first phase)
**Requirements**: APP-01
**Success Criteria** (what must be TRUE):
  1. Transy appears in the macOS menu bar and can be opened/quit from its menu
  2. Transy has no icon in the Dock and does not appear in the Cmd+Tab app switcher
  3. The app launches on macOS 15+ without sandbox violations or entitlement errors
  4. Project compiles cleanly with SPM dependencies resolved and folder structure matching the architecture
**Plans**: 2 plans

Plans:
- [x] 01-01-PLAN.md — Xcode project scaffold: xcodegen spec, macOS 15 target, LSUIElement, no sandbox, Swift 6, folder structure, source stubs, test targets
- [x] 01-02-PLAN.md — Menu bar item: finalize MenuBarExtra icon + dropdown, Settings placeholder window, runtime smoke test

### Phase 2: Trigger & Popup
**Goal**: Pressing Cmd+C twice in any app immediately opens a floating popup that shows the selected source text in a muted loading state, without stealing focus, and restores the clipboard on completion
**Depends on**: Phase 1
**Requirements**: TRIG-01, TRIG-02, TRIG-03, POP-01, POP-02, POP-03
**Success Criteria** (what must be TRUE):
  1. Pressing Cmd+C twice within ~400ms while text is selected in another app opens the translation popup
  2. The popup appears without deactivating the source app (focus remains in the original app)
  3. The selected source text is visible immediately in the popup in a muted loading style
  4. Pressing Escape or clicking outside the popup dismisses it
  5. Any text previously in the clipboard before the trigger is restored after the source text is captured; no clipboard content is lost
  6. When permissions are missing, the user is guided to grant the privacy permissions required by the chosen monitoring approach with clear instructions
**Plans**: 3 plans

Plans:
- [x] 02-01-PLAN.md — Permissions guidance: GuidanceView + GuidanceWindowController, AXIsProcessTrusted() gate, deep-link to Accessibility pane
- [x] 02-02-PLAN.md — Trigger logic: DoublePressDetector (TDD), ClipboardManager (TDD), HotkeyMonitor (NSEvent global monitor, Cmd+C filter, 80ms clipboard delay)
- [x] 02-03-PLAN.md — Popup + wiring: PopupView (muted source text), PopupController (NSPanel .nonActivatingPanel, fade-in, dismiss monitors), AppDelegate full wiring, smoke-test checkpoint

### Phase 3: Translation Loop
**Goal**: The muted source-text placeholder in the popup resolves to a real on-device translation using Apple's Translation framework, with automatic source-language detection and graceful error handling
**Depends on**: Phase 2
**Requirements**: TRAN-01, TRAN-02, TRAN-03
**Success Criteria** (what must be TRUE):
  1. After the skeleton appears, the translated text replaces it in the same popup within a few seconds (on-device, no network required)
  2. The user does not need to select or specify the source language; it is detected automatically
  3. If translation fails or a model is unavailable, the popup shows a readable error state (not a crash or silent blank)
  4. Rapid double-triggers do not display a stale translation from an earlier request (race condition handled)
**Plans**: 2 plans

Plans:
- [x] 03-01-PLAN.md — Translation foundation: normalization, availability preflight, short error mapping, request-scoped coordinator, and Swift Testing coverage
- [x] 03-02-PLAN.md — Popup translation wiring: view-scoped Apple Translation in PopupView, AppDelegate lifecycle integration, accepted live smoke verification, and known-limitation tracking

### Phase 4: Settings
**Goal**: User can choose the target translation language in a dedicated settings window and is guided to download any required on-device Apple Translation models that are not yet available
**Depends on**: Phase 3
**Requirements**: APP-02, APP-03
**Success Criteria** (what must be TRUE):
  1. Opening settings from the menu bar shows a window where the user can select the target translation language
  2. The selected target language persists across app restarts
  3. When a required Apple Translation model for the selected language pair is not downloaded, the user sees a clear prompt guiding them to download it (via Apple's model download flow)
  4. The settings window does not cause the Dock icon to appear or the app to enter the regular activation policy
**Plans**: 2 plans

Plans:
- [x] 04-01-PLAN.md — SettingsStore: defaults-backed target-language store, Settings scene injection, and request-time snapshot wiring
- [x] 04-02-PLAN.md — SettingsWindow: compact SwiftUI settings pane, supported-language picker, conditional model guidance, and manual behavior validation

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. App Shell | 2/2 | Complete   | 2026-03-14 |
| 2. Trigger & Popup | 3/3 | Complete   | 2026-03-14 |
| 3. Translation Loop | 2/2 | Complete | 2026-03-15 |
| 4. Settings | 2/2 | Complete | 2026-03-15 |
