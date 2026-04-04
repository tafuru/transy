# Translation Model Routing & System UI Dismiss Issue

**Created:** 2026-04-04
**Priority:** Medium
**Target:** Next milestone after v0.5.0

## Context

Two related findings from investigation:

### 1. Traditional vs Apple Intelligence Model Routing

The Translation framework (`TranslationSession`) always uses on-device downloaded language pack models. There is **no developer API to select between language pack model and Apple Intelligence model** — the OS routes internally based on system language/Apple Intelligence configuration.

Observed behavior:
- macOS English + Apple Intelligence set to English → system appears to route through Apple Intelligence translation model (better quality, different behavior)
- macOS English + Apple Intelligence set to Japanese → system falls back to language pack model

**Current status:** Not controllable via public API as of macOS 15. May become configurable in macOS 26+.

**Action items to revisit:**
- Check if macOS 26 Translation framework adds model selection API
- Evaluate whether the quality difference is significant enough to document for users
- Consider adding a settings note about Apple Intelligence language configuration affecting translation quality

### 2. System Download Prompt Dismisses NSPanel

When `.translationTask` triggers Apple's system UI (language download prompt or "not supported" notification), the NSPanel (translation popup) dismisses due to NSPanel's `becomesKeyOnlyIfNeeded` focus-yielding behavior.

**Impact:** User clicks the system download prompt and can no longer see the translation result.

**Investigated approaches:**
- Raising NSWindow level: won't prevent system UI from covering panel
- `userCancelled` retry: functional but loses original translation context
- **Best approach**: Show inline message inside popup instead of letting system UI appear — avoids the problem entirely

**Action items to revisit:**
- Implement inline "language not available — open Settings to download" UX inside popup
- Suppress system download prompt by handling `unsupportedLanguage` / `serviceUnavailable` errors before `.translationTask` fires system UI
- Test behavior on macOS 26 to see if system UI presentation is less disruptive

## References

- Phase 13 implemented the download UI guidance sheet — this is related
- `.translationTask` modifier is what triggers the system UI presentation
- `NSPanel.becomesKeyOnlyIfNeeded` is the root cause of popup dismiss
