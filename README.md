# Transy

Transy is a Swift-native macOS menu bar translator for fast selected-text translation.

Select text in another app, press `Command+C` twice, and Transy shows a lightweight popup without stealing focus from the current app.

## Current Status

Transy is in active development.

Today, the app includes:

- a menu bar app shell with no Dock icon
- a global double-`Command+C` trigger
- Accessibility permission guidance when monitoring is unavailable
- clipboard-safe selected-text capture
- a lightweight popup that shows the source text immediately and dismisses with `Escape` or outside click

Still in progress:

- on-device translation via Apple's Translation framework
- target language settings and model download guidance

## Development Snapshot

The current implementation covers Phase 1 and Phase 2 of the roadmap. The core popup shell and trigger flow are working; the translation result itself is planned for Phase 3.

## Target Platform

- macOS 15+

## License

Apache-2.0
