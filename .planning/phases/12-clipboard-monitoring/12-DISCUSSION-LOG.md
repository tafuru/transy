# Phase 12: Clipboard Monitoring - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-31
**Phase:** 12-clipboard-monitoring
**Areas discussed:** Polling Strategy, Mode Switching UX, Content Filtering, Self-Write Prevention

---

## Polling Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| 500ms interval | Fast enough to feel instant, minimal CPU overhead | ✓ |
| 250ms interval | Faster response but higher battery consumption | |
| 1 second interval | Most energy efficient but perceptible delay | |

**User's choice:** 500ms interval
**Notes:** Good balance of responsiveness and efficiency

---

| Option | Description | Selected |
|--------|-------------|----------|
| Timer.scheduledTimer | RunLoop-based, simple App Nap handling | ✓ |
| DispatchSourceTimer | GCD-based, more precise but App Nap risk | |

**User's choice:** Timer.scheduledTimer (RunLoop-based)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Disable App Nap during monitoring only | NSProcessInfo.beginActivity scoped to clipboard monitoring mode | ✓ |
| Always disable App Nap | Disable for entire app lifecycle | |

**User's choice:** Monitoring-scoped only
**Notes:** Preserves system energy savings when monitoring is not active

---

| Option | Description | Selected |
|--------|-------------|----------|
| Scoped to monitoring mode | beginActivity only while clipboard monitoring is active | ✓ |
| Always disabled | App-wide App Nap suppression | |

**User's choice:** Scoped to monitoring mode

---

## Mode Switching UX

| Option | Description | Selected |
|--------|-------------|----------|
| Picker (dropdown) | Standard macOS Picker to select trigger mode | |
| Toggle switch | Clipboard monitoring ON/OFF, default to Double ⌘C when OFF | |
| Remove Double ⌘C entirely | Clipboard monitoring only, no mode switching needed | ✓ |

**User's choice:** Remove Double ⌘C entirely — clipboard monitoring is the sole trigger mode
**Notes:** Major architectural decision. Eliminates Accessibility permission requirement entirely. Simplifies onboarding to zero-setup. All HotkeyMonitor, DoublePressDetector, and AX permission code will be deleted.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Delete old trigger code | Remove HotkeyMonitor, DoublePressDetector, Guidance UI, and related tests | ✓ |
| Keep old code | Preserve for potential future reintroduction | |

**User's choice:** Delete old code — keep codebase clean

---

| Option | Description | Selected |
|--------|-------------|----------|
| Default enabled | Clipboard monitoring starts automatically on app launch | ✓ |
| Require activation | User must enable monitoring in Settings first | |

**User's choice:** Default enabled — works immediately after install

---

## Content Filtering

| Option | Description | Selected |
|--------|-------------|----------|
| Text only (.string type, no concealed) | Trigger only when plain text is available and not concealed | ✓ |
| Text + URL | Also translate URL content | |

**User's choice:** Text only — .string type present AND concealed type absent

---

| Option | Description | Selected |
|--------|-------------|----------|
| No minimum length | Even 1 character triggers translation | ✓ |
| Minimum 2 characters | Skip single characters and numbers | |

**User's choice:** No minimum — all text triggers translation

---

| Option | Description | Selected |
|--------|-------------|----------|
| Skip duplicate text | Don't re-translate identical consecutive text | ✓ |
| Always translate | Translate even if same text is copied again | |

**User's choice:** Skip duplicates — same text consecutively is not re-translated

---

## Self-Write Prevention

| Option | Description | Selected |
|--------|-------------|----------|
| changeCount flag | Record changeCount after own writes, skip if next poll matches | ✓ |
| Bool flag | Set ignoring flag during writes, pause monitoring | |
| Agent's discretion | Let implementation decide | |

**User's choice:** changeCount flag — record the value after Transy's clipboard writes, skip processing when poll finds that exact changeCount

---

## Agent's Discretion

- Timer lifecycle management (start/stop with app lifecycle)
- Exact implementation of concealed type detection
- Integration details with existing ClipboardManager and translation pipeline

## Deferred Ideas

- Translation model install guidance (Phase 13)
- Translation cancellation latency tracking (separate concern)
