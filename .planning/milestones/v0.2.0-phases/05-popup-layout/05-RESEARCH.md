# Phase 5: Popup Layout — Research

**Researched:** 2026-03-16
**Domain:** SwiftUI text layout, ScrollView, fixed-size containers with scrollable content in NSPanel
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| POP-04 | Popup displays translated text with word wrapping instead of single-line truncation | Remove `.lineLimit(4)` or set to `nil`; SwiftUI Text wraps by default when no lineLimit is set |
| POP-05 | Popup supports vertical scrolling when translated text exceeds the visible area | Wrap Text in `ScrollView(.vertical)` with fixed `.frame(maxHeight:)` on container |

</phase_requirements>

---

## Summary

Phase 5 transforms the popup from a fixed 4-line truncating card into a scrollable multi-line container. The implementation is straightforward in SwiftUI: remove the `.lineLimit(4)` constraint to enable unlimited wrapping, then wrap the text in a `ScrollView` with a fixed maximum height. The popup retains its fixed width (380pt) and adds a maximum height constraint (e.g., 400pt), with ScrollView automatically appearing when content exceeds the visible area.

The three key changes are: (1) **Text wrapping** — remove or set `.lineLimit(nil)` to allow natural multi-line wrapping within the fixed 380pt width; (2) **Vertical scrolling** — wrap content in `ScrollView(.vertical, showsIndicators: true)` and apply `.frame(maxHeight: 400)` to the container; (3) **Dynamic sizing** — the popup should size to content up to the max height, not always render at max height for short text.

The architecture is entirely in `PopupView.swift`'s `PopupText` view. No changes to `PopupController.swift` are needed — NSPanel contentView sizing adapts automatically when SwiftUI's intrinsic content size changes (up to the maxHeight constraint). This phase has zero impact on trigger logic, clipboard management, or translation flow.

**Primary recommendation:** In `PopupText` body, remove `.lineLimit(4)` and `.truncationMode(.tail)`, wrap the Text in `ScrollView(.vertical)`, constrain container to `.frame(maxHeight: 400)`, keep fixed width at 380pt.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI `Text` | macOS 15+ | Display translated text with natural wrapping | Built-in; wraps automatically when no lineLimit set; respects `.multilineTextAlignment` and container width |
| SwiftUI `ScrollView` | macOS 15+ | Enable vertical scrolling for overflow content | Built-in; automatically shows/hides scrollbar based on content size vs frame; `.vertical` axis for text overflow |
| `.frame(maxHeight:)` | SwiftUI (macOS 15+) | Constrain scrollable region to fixed maximum height | Standard sizing modifier; content sizes naturally up to max, then ScrollView activates |
| `NSHostingView` | SwiftUI/AppKit bridge (macOS 15+) | Host SwiftUI content in NSPanel | Established in Phase 2; no changes needed — intrinsic size updates propagate to panel |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `.lineLimit(nil)` | SwiftUI (macOS 15+) | Explicitly disable line limit | Optional; Text wraps by default when lineLimit is unset, but explicit `nil` documents intent |
| `.scrollIndicators(.visible)` | SwiftUI (macOS 15+) | Force scrollbar visibility | Optional; default `.automatic` behavior (show on hover/scroll) is standard on macOS |
| `.fixedSize(horizontal: false, vertical: true)` | SwiftUI (macOS 15+) | Let vertical size grow to content before scrolling | Optional; may help with dynamic sizing but can conflict with maxHeight; test if needed |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `ScrollView` | `List` with single item | List adds unnecessary visual chrome (separators, selection); ScrollView is the semantic fit for free-form text |
| `ScrollView` | `TextEditor` | TextEditor is for editable text; read-only translation display should use Text + ScrollView |
| `.frame(maxHeight:)` | `.frame(height:)` fixed | Fixed height wastes space for short translations; maxHeight sizes to content up to limit |
| `.lineLimit(nil)` | `.lineLimit(100)` | Arbitrary high limit is semantically wrong and could theoretically cap very long translations; nil is correct |

**Installation:** No new dependencies — pure SwiftUI changes to existing `PopupView.swift`.

---

## Architecture Patterns

### Current Structure (Phase 2-4)

```
Transy/
├── Popup/
│   ├── PopupController.swift   (NSPanel host — no changes in Phase 5)
│   └── PopupView.swift          (SwiftUI content — modify PopupText here)
```

### Pattern 1: Remove Line Limit for Natural Wrapping

**What:** SwiftUI `Text` wraps by default when placed in a width-constrained container. The current `.lineLimit(4)` artificially caps wrapping. Removing this constraint allows unlimited lines.

**When to use:** Any time you want text to wrap naturally to multiple lines without truncation.

**Current code (PopupView.swift, line 75-86):**

```swift
private struct PopupText: View {
    let text: String
    let isMuted: Bool

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(isMuted ? .secondary : .primary)
            .lineLimit(4)                              // ← REMOVE THIS
            .truncationMode(.tail)                     // ← REMOVE THIS
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(width: 380, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
```

**Updated pattern:**

```swift
Text(text)
    .font(.body)
    .foregroundStyle(isMuted ? .secondary : .primary)
    .multilineTextAlignment(.leading)
    // lineLimit and truncationMode removed — text wraps naturally
```

**Why this works:** Text inside a `.frame(width: 380)` container wraps automatically to fit the width. With no lineLimit, it grows vertically to show all content.

---

### Pattern 2: Wrap Content in ScrollView with Max Height

**What:** Wrap the text content in `ScrollView(.vertical)` and apply `.frame(maxHeight:)` to the scrollable region. SwiftUI shows scrollbars automatically when content exceeds the frame.

**When to use:** Any time you have potentially unbounded vertical content that should scroll within a fixed-height region.

**Example:**

```swift
ScrollView(.vertical) {
    Text(text)
        .font(.body)
        .foregroundStyle(isMuted ? .secondary : .primary)
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 380, alignment: .leading)
}
.frame(maxHeight: 400)  // Container max height — scrolls if content taller
.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
```

**Layout hierarchy:**

```
PopupText
└── ScrollView (maxHeight: 400)
    └── Text (width: 380, wraps naturally, height: intrinsic)
        ├── padding (.horizontal: 16, .vertical: 12)
        └── background (.regularMaterial, RoundedRectangle)
```

**Why this works:** 
- Text grows vertically to fit wrapped content
- ScrollView sizes to content up to maxHeight (400pt)
- If Text height > 400pt, ScrollView activates vertical scrolling
- If Text height < 400pt, ScrollView sizes to fit (no wasted space)

---

### Pattern 3: Dynamic Container Sizing

**What:** The popup should not always render at 400pt tall. For short translations (e.g., 2 lines), the popup should size to fit content. The `maxHeight` constraint acts as a ceiling, not a fixed size.

**When to use:** Always — users expect compact UI for short content, scrolling only when necessary.

**Key insight:** SwiftUI's `.frame(maxHeight:)` does NOT force the view to that height. It sets an upper bound. The view sizes to its intrinsic content size (text + padding) up to the max.

**Example scenarios:**

| Translation Length | Wrapped Lines | Popup Height | Scroll? |
|--------------------|---------------|--------------|---------|
| "Hello" | 1 line (~20pt) | ~44pt (text + padding) | No |
| Medium paragraph | 5 lines (~100pt) | ~124pt | No |
| Long article | 30 lines (~600pt) | 400pt (capped) | Yes |

**Visual behavior:**
- Short text: Popup is compact, no scrollbar
- Medium text: Popup grows taller (up to 400pt), no scrollbar
- Long text: Popup caps at 400pt, scrollbar appears

---

### Pattern 4: Padding and Background Placement

**What:** Padding and background should apply to the scrollable content, not outside the ScrollView. This ensures the background material and rounded corners frame the visible text area.

**Current pattern (wrong for scrolling):**

```swift
Text(text)
    .padding(...)
    .frame(width: 380)
    .background(...)  // ← Outside ScrollView would not scroll with content
```

**Correct pattern for scrollable content:**

```swift
ScrollView(.vertical) {
    Text(text)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 380, alignment: .leading)
}
.frame(maxHeight: 400)
.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
```

**Why this matters:** Background applied inside ScrollView would scroll with text (wrong). Background applied outside ScrollView frames the fixed viewport (correct).

---

### Anti-Patterns to Avoid

**❌ Using List instead of ScrollView**

```swift
// DON'T DO THIS
List {
    Text(text)
}
```

**Why wrong:** List is for structured data with rows. It adds visual chrome (separators, hover states, selection) inappropriate for free-form text display. ScrollView is the semantic fit.

---

**❌ Fixed height instead of maxHeight**

```swift
// DON'T DO THIS
.frame(height: 400)  // Forces 400pt even for short text
```

**Why wrong:** Wastes space for short translations. Users expect compact UI when content is short.

---

**❌ Arbitrary high lineLimit instead of unlimited**

```swift
// DON'T DO THIS
.lineLimit(100)  // Arbitrary cap
```

**Why wrong:** Semantically wrong — you want unlimited wrapping, not a specific limit. Could theoretically cap very long translations.

---

**❌ Applying maxHeight to Text instead of ScrollView**

```swift
// DON'T DO THIS
ScrollView {
    Text(text)
        .frame(maxHeight: 400)  // Wrong — constrains text, not scroll region
}
```

**Why wrong:** Constrains the text itself, not the scrollable viewport. Text would be clipped, not scrollable.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Custom scroll indicator | Manual drag gesture + position tracking | SwiftUI `ScrollView` | Handles momentum scrolling, scroll wheel, trackpad gestures, accessibility, indicator auto-hide on macOS |
| Text line wrapping | Manual word-break algorithm | SwiftUI `Text` natural wrap | Complex Unicode word boundaries, hyphenation, right-to-left languages, accessibility |
| Dynamic height calculation | Measure text with `NSAttributedString.boundingRect` | SwiftUI intrinsic sizing | SwiftUI handles layout, font scaling, Dynamic Type, state updates automatically |

**Key insight:** Text layout and scrolling are deceptively complex. Native SwiftUI components handle edge cases (accessibility zoom, Dynamic Type, unusual Unicode, trackpad gestures) that custom implementations miss.

---

## Common Pitfalls

### Pitfall 1: ScrollView Doesn't Scroll (Content Not Constrained)

**What goes wrong:** You wrap Text in ScrollView, but scrollbar never appears because Text grows unbounded vertically and ScrollView grows to fit it.

**Why it happens:** ScrollView only scrolls when its content size exceeds its frame size. Without `.frame(maxHeight:)` on the ScrollView, it has no size constraint and grows to fit content.

**How to avoid:** Always apply `.frame(maxHeight:)` or `.frame(height:)` to the ScrollView itself (not the content).

**Warning signs:** Popup grows extremely tall for long text instead of showing scrollbar.

**Fix:**

```swift
// WRONG
ScrollView {
    Text(text)  // Grows unbounded, ScrollView grows to fit
}

// CORRECT
ScrollView {
    Text(text)
}
.frame(maxHeight: 400)  // Constrains ScrollView, enables scrolling
```

---

### Pitfall 2: Background Doesn't Fill ScrollView Area

**What goes wrong:** Background material is transparent or doesn't cover the entire scrollable area.

**Why it happens:** Background applied to Text scrolls with content, leaving gaps. Background applied to ScrollView might not account for corner radius clipping.

**How to avoid:** Apply `.background(.regularMaterial, in: RoundedRectangle(...))` to the ScrollView (outside), not the Text (inside).

**Warning signs:** Background scrolls with text, or corners of background are not rounded.

**Fix:**

```swift
// WRONG
ScrollView {
    Text(text)
        .background(.regularMaterial)  // Scrolls with text
}

// CORRECT
ScrollView {
    Text(text)
}
.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
```

---

### Pitfall 3: Padding Inside vs Outside ScrollView

**What goes wrong:** Padding applied outside ScrollView is not scrollable, creating fixed margins that waste space. Padding inside scrolls with content (correct for text insets).

**Why it happens:** Confusion about which padding should scroll (content insets) vs stay fixed (container margins).

**How to avoid:** Apply content padding (horizontal/vertical insets around text) to the Text inside ScrollView. Don't add extra padding outside ScrollView.

**Warning signs:** Horizontal padding scrolls away when scrolling vertically (wrong), or fixed vertical padding wastes space.

**Fix:**

```swift
// CORRECT — padding scrolls with text
ScrollView {
    Text(text)
        .padding(.horizontal, 16)  // Insets text from edges
        .padding(.vertical, 12)
}
.frame(maxHeight: 400)
```

---

### Pitfall 4: Forgetting to Remove truncationMode

**What goes wrong:** You remove `.lineLimit(4)` but leave `.truncationMode(.tail)`. Long text wraps but still shows ellipsis.

**Why it happens:** `truncationMode` can apply even without explicit lineLimit if SwiftUI's layout algorithm decides to truncate.

**How to avoid:** Remove both `.lineLimit()` and `.truncationMode()` when enabling unlimited wrapping.

**Warning signs:** Text wraps to multiple lines but still shows "..." at the end.

**Fix:**

```swift
// WRONG
Text(text)
    .truncationMode(.tail)  // Remove this too

// CORRECT
Text(text)
    // No lineLimit, no truncationMode
```

---

### Pitfall 5: NSPanel contentView Sizing Conflicts

**What goes wrong:** NSPanel doesn't resize when SwiftUI content height changes, causing clipping or extra space.

**Why it happens:** NSHostingView propagates intrinsic content size to NSPanel, but if popup is shown before content is fully laid out, size may be stale.

**How to avoid:** Don't override NSPanel's automatic sizing. NSHostingView's `intrinsicContentSize` updates automatically when SwiftUI's layout changes. No manual `setContentSize` needed.

**Warning signs:** Popup is always 80pt tall (hardcoded in `PopupController.makePanel`) even when content is taller/shorter.

**Fix:** PopupController's initial `contentRect` height is just a hint. SwiftUI sizing takes over after `contentView = NSHostingView(...)`. No code changes needed — system handles this automatically.

**Note:** If manual sizing is needed later (unlikely), use:

```swift
// Only if automatic sizing fails (it shouldn't)
panel.setContentSize(hostingView.intrinsicContentSize)
```

---

## Code Examples

Verified patterns from official SwiftUI documentation and macOS 15 API reference.

### Example 1: Updated PopupText with Scrolling

**Source:** SwiftUI documentation (Text, ScrollView, frame modifiers)

Full updated `PopupText` view with wrapping and scrolling:

```swift
private struct PopupText: View {
    let text: String
    let isMuted: Bool

    var body: some View {
        ScrollView(.vertical) {
            Text(text)
                .font(.body)
                .foregroundStyle(isMuted ? .secondary : .primary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(width: 380, alignment: .leading)
        }
        .frame(maxHeight: 400)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
```

**Changes from v0.1.0:**
- Removed `.lineLimit(4)` — enables unlimited wrapping
- Removed `.truncationMode(.tail)` — no truncation
- Wrapped Text in `ScrollView(.vertical)` — enables scrolling
- Moved `.frame(width: 380)` inside ScrollView (on Text) — keeps fixed width
- Applied `.frame(maxHeight: 400)` to ScrollView — caps scrollable region
- Kept `.background(...)` on ScrollView (outside) — fixed backdrop

---

### Example 2: Alternative with Explicit lineLimit(nil)

**Source:** SwiftUI Text documentation

For clarity, you can explicitly set `lineLimit(nil)`:

```swift
Text(text)
    .font(.body)
    .foregroundStyle(isMuted ? .secondary : .primary)
    .lineLimit(nil)  // Explicit unlimited (same as omitting lineLimit)
    .multilineTextAlignment(.leading)
```

**When to use:** Documents intent clearly. Functionally identical to omitting `.lineLimit()` entirely.

---

### Example 3: Optional Scroll Indicator Control

**Source:** SwiftUI ScrollView documentation

Force scrollbar to always show (vs default auto-hide on macOS):

```swift
ScrollView(.vertical, showsIndicators: true) {  // Explicit indicator control
    Text(text)
        ...
}
```

**Default behavior:** macOS shows scrollbars on hover/scroll, hides when idle. Explicit `showsIndicators: true` is rarely needed.

---

### Example 4: Testing Dynamic Sizing Locally

**Source:** SwiftUI preview patterns

Add a preview with multiple text lengths to verify sizing behavior:

```swift
#Preview("Short text") {
    PopupText(text: "Hello", isMuted: false)
}

#Preview("Medium text") {
    PopupText(text: String(repeating: "This is a medium-length translation that wraps across multiple lines. ", count: 3), isMuted: false)
}

#Preview("Long text (scrollable)") {
    PopupText(text: String(repeating: "This is a very long translation that will definitely exceed 400pt height and trigger scrolling. ", count: 20), isMuted: false)
}
```

**Use cases:** Verify popup sizes to content for short/medium text, caps at 400pt with scrollbar for long text.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.lineLimit(4)` with truncation | `.lineLimit(nil)` or omit lineLimit | Standard since SwiftUI 1.0 (2019) | Enables natural wrapping without artificial caps |
| Fixed-height containers | `.frame(maxHeight:)` with ScrollView | Standard since SwiftUI 1.0 | Dynamic sizing — compact for short content, scrollable for long |
| Manual scroll indicators | SwiftUI `ScrollView` auto indicators | SwiftUI 1.0+ | Automatic hover-show/hide on macOS, accessibility support |

**Deprecated/outdated:** None relevant to this phase. SwiftUI's text and scrolling APIs are stable since macOS 11 (SwiftUI 2.0). macOS 15 adds no breaking changes to these patterns.

---

## Open Questions

**None.** Text wrapping and ScrollView patterns in SwiftUI are well-established and stable. No ambiguities for macOS 15 implementation.

---

## Validation Architecture

> Nyquist validation is enabled in `.planning/config.json`.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (macOS 15+) |
| Config file | None — Xcode default, no custom config needed |
| Quick run command | `xcodebuild test -project Transy.xcodeproj -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/PopupTextLayoutTests` |
| Full suite command | `xcodebuild test -project Transy.xcodeproj -scheme Transy -destination 'platform=macOS'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| POP-04 | Text wraps to multiple lines without truncation | unit | `xcodebuild test -only-testing:TransyTests/PopupTextLayoutTests/testTextWrapsWithoutTruncation` | ❌ Wave 0 |
| POP-05 | Vertical scrolling appears when text exceeds max height | unit | `xcodebuild test -only-testing:TransyTests/PopupTextLayoutTests/testScrollViewAppearsForLongText` | ❌ Wave 0 |

**Note on UI testing:** SwiftUI view tests in this project use Swift Testing with `@Test` and `#expect`. Since PopupText is a pure SwiftUI view (no AppKit dependencies), tests can instantiate and inspect the view hierarchy without running the full app.

**Limitation:** Scroll behavior verification may require manual testing in running app. Unit tests can verify:
- Text view has no lineLimit constraint
- ScrollView is present in view hierarchy  
- Frame maxHeight constraint is applied

Actual scrolling (scrollbar appearance, scroll gestures) is harder to automate without UI tests or preview inspection.

### Sampling Rate

- **Per task commit:** `xcodebuild test -only-testing:TransyTests/PopupTextLayoutTests -quiet`
- **Per wave merge:** Full TransyTests suite
- **Phase gate:** Full suite green + manual verification with long text in running app before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `TransyTests/PopupTextLayoutTests.swift` — covers POP-04 and POP-05
  - Test: Short text (< 4 lines) does not truncate
  - Test: Long text (> 400pt height) triggers ScrollView with maxHeight constraint
  - Test: Text view has no lineLimit or truncationMode set
  - Test: ScrollView is present in view hierarchy for PopupText

**Testing pattern:**

```swift
import Testing
import SwiftUI
@testable import Transy

@Suite("PopupText Layout")
struct PopupTextLayoutTests {
    
    @Test("Short text wraps without truncation")
    func shortTextWraps() {
        let view = PopupText(text: "Short text", isMuted: false)
        // Verify view structure: no lineLimit, no truncationMode
        // (Requires view introspection — SwiftUI testing utilities)
    }
    
    @Test("Long text triggers ScrollView with maxHeight")
    func longTextScrolls() {
        let longText = String(repeating: "Very long text. ", count: 100)
        let view = PopupText(text: longText, isMuted: false)
        // Verify ScrollView present with maxHeight constraint
    }
}
```

**Note:** SwiftUI view introspection is limited in unit tests. Consider supplementing with manual preview testing or snapshot tests if available.

---

## Sources

### Primary (HIGH confidence)

- **SwiftUI Documentation** (Apple Developer):
  - `Text` view reference: https://developer.apple.com/documentation/swiftui/text
  - `ScrollView` reference: https://developer.apple.com/documentation/swiftui/scrollview
  - `frame(maxHeight:)` modifier: https://developer.apple.com/documentation/swiftui/view/frame(maxheight:alignment:)
  - Verified: lineLimit behavior, ScrollView automatic scrollbar management, frame sizing constraints

- **Existing codebase** (Transy v0.1.0):
  - `Transy/Popup/PopupView.swift`: Current PopupText implementation with `.lineLimit(4)` and `.truncationMode(.tail)`
  - `Transy/Popup/PopupController.swift`: NSPanel + NSHostingView integration (no changes needed)
  - `.planning/milestones/v0.1.0-phases/02-trigger-popup/02-RESEARCH.md`: Established NSPanel + SwiftUI patterns

### Secondary (MEDIUM confidence)

- **macOS 15 Release Notes** (Apple):
  - No breaking changes to SwiftUI Text or ScrollView behavior in macOS 15
  - Swift 6.0 mode compatible with existing SwiftUI view APIs

### Tertiary (LOW confidence)

None — all findings based on official documentation and existing codebase.

---

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — SwiftUI Text and ScrollView are built-in, well-documented, stable since macOS 11
- Architecture: **HIGH** — Patterns verified in existing codebase (Phase 2 PopupView), no external dependencies
- Pitfalls: **HIGH** — Based on common SwiftUI layout mistakes documented in Apple forums and project experience

**Research date:** 2026-03-16
**Valid until:** 6+ months (SwiftUI APIs are stable; no rapid churn in text/scroll layout domain)
