# Feature Research

**Domain:** macOS menu-bar selected-text translation utility (Japanese/English reading assistance)
**Researched:** 2025-01-30
**Confidence:** HIGH — domain is well-understood; competitors (DeepL for Mac, Bob, PopClip + translation plugins, Elytra) are established reference points

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| System-wide selected-text capture | Core mechanic — must work in every app (Safari, PDF viewer, terminal, IDE) | MEDIUM | Requires a validated system-wide monitoring approach plus safe clipboard capture after the copy event. The exact permission model depends on the chosen monitoring API. |
| Auto source-language detection | Users never want to specify "Japanese" — it's obvious from the characters | LOW | All major translation APIs (DeepL, OpenAI, Google) detect source automatically. Just don't expose source language selection in the UI. |
| Configurable target language | Users translate into different languages; must be changeable | LOW | Single preference in a settings panel. Store in `UserDefaults`. |
| Transient, non-focus-stealing popup | Must not break the reading app's focus — user is still in another window | MEDIUM | Use `NSPanel` with `.nonactivatingPanel` behavior, or a borderless `NSWindow` with `NSWindowLevel.floating`. Do NOT use a standard `NSWindow` that steals key focus. |
| Keyboard dismissal (Escape) | macOS convention for all transient UI — popups dismissed by Escape | LOW | Monitor `keyDown` on the floating panel. Auto-dismiss on click-outside is also expected. |
| Menu bar residence, no Dock icon | Fundamental to the "ambient tool" contract — this is a utility, not an app | LOW | `LSUIElement = YES` in Info.plist. `NSStatusItem` for menu bar icon. |
| Launch at Login option | Menu bar utilities are expected to survive reboots without user intervention | LOW | Use `SMAppService.mainApp` (macOS 13+) or `LaunchAgent` plist. |
| At least one high-quality translation provider | The translation must actually be good — poor MT quality is an instant uninstall | LOW-MEDIUM | Apple Translation is the chosen v1 backend for speed and native integration. External providers remain a future fallback if quality or language coverage becomes a problem. |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Double-Cmd+C as trigger | Zero new muscle memory — reuses the copy gesture everyone already performs; fastest possible activation path | MEDIUM | Detect two `Command+C` events within ~400ms threshold using the validated system-wide monitoring approach. Must NOT conflict with apps that legitimately use double-copy (e.g., some terminal emulators). Add a debounce. |
| Source text as skeleton/loading placeholder | Preserves reading context while API call is in-flight; makes latency feel designed rather than broken; distinguishes from competitors who show blank-then-result | MEDIUM | Show original clipboard text styled as a muted/skeleton treatment on popup open. Replace with translated text when response arrives. Animated shimmer optional but polished. |
| Speed-first architecture | The stated reason this product exists — DeepL for Mac is "too slow" | MEDIUM | Minimize: popup open latency (pre-warm the window), model-availability surprises, and render time (no heavy framework). Show popup immediately on trigger, don't wait for translation. |
| Copy translation button | After reading the translation, user often wants to paste it somewhere | LOW | Single button or Cmd+C on the popup copies translated text. Clear visual affordance. |
| Popup positioning near context | Appearing close to where the user was reading keeps their eye from traveling far | HIGH | Requires `AXUIElement` Accessibility API to get selection bounds — non-trivial. Fallback: fixed position (bottom-right of current screen). Flag for phase-specific research. |
| Provider selection in settings | Power users want DeepL vs OpenAI vs Google choice based on content type | LOW-MEDIUM | Simple enum picker in settings if provider fallback is added later. Abstract translation behind a protocol so providers are interchangeable. |
| Streaming translation display | For longer text, show tokens appearing progressively instead of a long blank wait | MEDIUM-HIGH | OpenAI and DeepL v3 support streaming. Requires async streaming parser and incremental UI updates. Reduces perceived latency for multi-sentence input significantly. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Translation history / log | "I want to see what I translated earlier" | Fundamentally changes the product from ambient to database. Privacy exposure (logging private documents). Clutters UI. Directly contradicts "glance and continue" intent. Out of scope per PROJECT.md. | Don't build it. If user needs history, they can paste into a notes app after translation. |
| Manual text input box in popup | "What if I can't select text?" | Contradicts the entire UX philosophy. Adds UI weight to a popup that should be minimal. Invites "full app" scope creep. Different modality (compose vs translate) belongs in a different tool. | Power users can use a full translation app or website for edge cases. Keep Transy opinionated. |
| OCR / screenshot translation | Competitive with apps like Bob — "can you translate text in images?" | Extremely high complexity (AVFoundation + Vision framework + layout detection). Different trigger model. Different UX. Would double the codebase scope for a secondary use case. | Scope to v2+ only if the core loop proves out. Bob already does this well. |
| Multiple simultaneous provider results | "Show me DeepL and Google side by side" | Doubles API latency, doubles cost, makes popup 2× taller, dilutes trust in any single result. Adds provider comparison UX that breaks the "glance" pattern. | Keep Apple Translation as the default in v1. Allow provider fallback later if it proves necessary. |
| Shortcut remapping UI | "I want to use Option+T instead of double-Cmd+C" | Shortcut conflict detection is hard. Custom key capture UI is fiddle-prone. Not needed for a personal tool. Premature generalization. | Hard-code double-Cmd+C for v1. Add remapping only if real user demand surfaces after launch. |
| Pronunciation / furigana rendering | Useful for Japanese learners — "show me how to read this kanji" | Different product (reading assistant vs translator). Requires separate API or MeCab/ICU integration. Adds UI complexity. Translation is the core value. | Out of scope. Anki, Yomichan/Yomitan, or dedicated Japanese tools do this better. |
| Notification Center alerts | "Notify me when translation is ready" | Users are staring at the selection they just copied — a notification is the wrong feedback channel and adds OS-level clutter. | The popup IS the notification. |
| Auto-copy translated text to clipboard | "Automatically replace clipboard with translation" | Silently destroys the user's original copied text, which they may still need. Creates invisible state mutations. Confusing when pasting elsewhere yields unexpected text. | Provide an explicit "copy translation" button in the popup. User opts in. |

## Feature Dependencies

```
[Double-Cmd+C Trigger]
    └──requires──> [Validated trigger monitor / Clipboard Monitoring]
                       └──requires──> [Accessibility Permission (TCC)]

[Translation Popup]
    └──requires──> [NSPanel / NSWindow (non-activating)]
    └──requires──> [Translation API Integration]
                       └──requires──> [API Key Configuration in Settings]

[Source Text as Skeleton Placeholder]
    └──requires──> [Translation Popup]
    └──requires──> [Clipboard text read before API call]
    └──enhances──> [Speed perception — popup opens immediately]

[Target Language Config]
    └──requires──> [Settings Window]
    └──requires──> [UserDefaults persistence]

[Copy Translation Button]
    └──requires──> [Translation Popup]
    └──requires──> [NSPasteboard write]

[Provider Selection]
    └──requires──> [Settings Window]
    └──requires──> [Translation protocol abstraction]

[Streaming Translation Display]
    └──requires──> [Translation Popup]
    └──requires──> [Streaming API support from chosen provider]
    └──enhances──> [Source text placeholder — transition from skeleton to streaming text]

[Popup Positioning Near Selection]
    └──requires──> [AXUIElement Accessibility API]  ← HIGH complexity, research flag
    └──conflicts──> [Fixed popup position] (use one or the other)

[Launch at Login]
    └──requires──> [SMAppService (macOS 13+) or LaunchAgent]
```

### Dependency Notes

- **Double-Cmd+C trigger requires clear permission handling:** the exact permission path depends on the chosen monitoring API, and Phase 1 must validate and document it clearly for users.
- **Source-as-skeleton requires popup-first architecture:** The popup must open synchronously on trigger (showing original text), with translation filling in asynchronously. If the popup blocks on API response, the skeleton feature is impossible.
- **Streaming enhances skeleton:** The natural progression is: trigger → popup opens with source text skeleton → translation tokens stream in replacing the skeleton. Streaming is an enhancement; without it, skeleton shows until full result arrives.
- **Provider selection requires protocol abstraction:** If translation is hard-coded to one provider, adding selection later requires refactoring. Define a `TranslationProvider` protocol from day one even if only one provider is implemented.
- **Popup positioning conflicts with fixed position:** Decide once. AXUIElement positioning is high-effort and has edge cases (fullscreen apps, multiple monitors, split view). Fixed bottom-right fallback is predictable and fine for v1.

## MVP Definition

### Launch With (v1)

Minimum viable product — what's needed to validate the concept.

- [ ] **Double-Cmd+C trigger via a validated system-wide monitoring approach** — without the trigger, there is no product
- [ ] **Privacy-permission onboarding on first launch** — must clearly guide the user through the permissions required by the chosen monitoring approach
- [ ] **Non-activating floating popup** — must not steal focus from the reading app
- [ ] **Source text displayed as loading placeholder** — core UX differentiator; establishes the "designed latency" experience
- [ ] **Translation result via Apple Translation framework** — on-device translation is the chosen v1 backend for speed, privacy, and native integration
- [ ] **Auto source-language detection** — no manual source language picker
- [ ] **Target language selection in settings window** — project's stated requirement
- [ ] **Escape / click-outside dismissal** — macOS convention; feels broken without this
- [ ] **Menu bar icon, no Dock presence** — `LSUIElement`, `NSStatusItem`

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] **Copy translation button in popup** — trigger: users will immediately want to paste the translation; add when core loop is validated
- [ ] **External-provider fallback / selection** — trigger: if Apple Translation quality or language coverage is insufficient for some use cases
- [ ] **Launch at Login toggle** — trigger: if the app becomes part of the user's everyday workflow and should survive restarts
- [ ] **Double-Cmd+C timing threshold setting** — trigger: user complaints about false triggers or missed triggers

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Popup positioning near selection (AXUIElement)** — high complexity, marginal gain for v1; fixed position is acceptable
- [ ] **Custom trigger shortcut** — defer until there's actual demand; personal tool doesn't need this
- [ ] **OCR / screenshot translation** — different modality, much higher complexity; only if core loop proves broadly useful

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Double-Cmd+C trigger | HIGH | MEDIUM | P1 |
| Non-activating popup | HIGH | MEDIUM | P1 |
| Source text as skeleton placeholder | HIGH | LOW | P1 |
| Apple Translation framework translation | HIGH | LOW | P1 |
| Auto language detection | HIGH | LOW | P1 |
| Target language config (settings) | HIGH | LOW | P1 |
| Escape / click-outside dismiss | HIGH | LOW | P1 |
| Menu bar only / no Dock | HIGH | LOW | P1 |
| Launch at Login | MEDIUM | LOW | P2 |
| Privacy-permission onboarding | HIGH | LOW | P1 — required for trigger to work |
| Copy translation button | MEDIUM | LOW | P2 |
| Provider selection | MEDIUM | MEDIUM | P2 |
| Popup positioning near selection | MEDIUM | HIGH | P3 |
| Custom trigger shortcut | LOW | HIGH | P3 |
| OCR translation | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | DeepL for Mac | Bob (macOS) | PopClip + plugin | Transy approach |
|---------|---------------|-------------|------------------|-----------------|
| Trigger mechanism | Menu bar → "Translate Clipboard" or global hotkey | Global hotkey (configurable) | Appears on any text selection via OS text selection popup | Double-Cmd+C — reuses copy gesture, zero config |
| Popup style | Full DeepL app window (heavy, takes focus) | Floating panel, native-ish | Compact horizontal bar near selection | Minimal floating panel, non-activating |
| Source-as-placeholder | No (blank while loading) | No (blank or spinner) | No | Yes — core differentiator |
| Speed to result | Slow (app launch + API) | Fast (pre-warmed window) | Fast (pre-warmed PopClip) | Target: fast (pre-warm panel + immediate open) |
| Auto language detect | Yes | Yes | Yes (provider-dependent) | Yes |
| Translation providers | DeepL only | DeepL, OpenAI, Google, many more | Provider-dependent extension | Apple Translation as default; protocol for extensibility |
| macOS-native feel | Medium (Electron-adjacent) | Medium-High | High (OS-level) | Target: High (pure SwiftUI/AppKit) |
| OCR translation | No | Yes | No | No — out of scope |
| Translation history | Yes | Yes | No | No — out of scope |
| Dock icon | No (menu bar) | No (menu bar) | N/A (PopClip extension) | No — LSUIElement |
| Shortcut customization | Yes | Yes | Via PopClip settings | No for v1 |
| Free tier | Yes (limited) | Freemium | Paid (PopClip itself) | Self-hosted API key |

## Sources

- DeepL for Mac: direct product analysis — https://www.deepl.com/en/macos-app
- Bob (macOS translation utility): https://bobtranslate.com — direct product analysis; closest functional competitor to Transy
- PopClip with translation extensions: https://www.popclip.app — selected-text popup pattern reference
- macOS Human Interface Guidelines — transient panels, menu bar extras, focus behavior
- NSEvent / event-monitoring documentation (Apple Developer): candidate APIs for global key event observation
- SMAppService documentation (Apple Developer, macOS 13+): modern launch-at-login API
- DeepL API documentation: https://developers.deepl.com/docs — language detection, streaming support
- OpenAI API (GPT-4o): streaming translation capability reference

---
*Feature research for: macOS selected-text translation utility (Japanese/English reading assistant)*
*Researched: 2025-01-30*
