# Transy

A lightweight macOS menu bar translator. Copy text in any app and get an instant translation popup — without leaving your current window.

Built with SwiftUI and Apple's on-device [Translation framework](https://developer.apple.com/documentation/translation).

## Features

- **Menu bar app** — runs as a status-bar accessory with no Dock icon
- **Clipboard monitoring** — detects copied text automatically and translates it instantly, no extra keystrokes needed
- **No permission required** — works without Accessibility access
- **Floating popup** — shows the translation result without stealing focus
- **Smart popup placement** — popup appears near the cursor and stays fully visible with edge-clamping
- **Word wrapping & scrolling** — long translations wrap naturally and scroll vertically
- **Target language picker** — choose your preferred translation target in Settings
- **Automatic model downloads** — missing translation models are downloaded on-demand by the system
- **Fully on-device** — all translation happens locally via Apple Translation; no network required

## Requirements

- macOS 15.0 (Sequoia) or later
- Apple Translation language models (downloaded automatically on first translation)

## Installation

Download the latest DMG from [Releases](https://github.com/tafuru/transy/releases) and drag Transy.app to your Applications folder.

### Build from source

#### Prerequisites

- Xcode 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```sh
brew install xcodegen
```

#### Build

```sh
git clone https://github.com/tafuru/transy.git
cd transy
xcodegen generate
open Transy.xcodeproj
```

Build and run with **⌘R** in Xcode, or from the command line:

```sh
xcodebuild build -scheme Transy -destination 'platform=macOS'
```

#### Run tests

```sh
xcodebuild test -scheme Transy -destination 'platform=macOS'
```

## Usage

1. Launch Transy — it appears as a bubble icon (💬) in the menu bar
2. Copy text in any app (**⌘C**)
3. A popup appears near the cursor with the translated text
4. Press **Escape** or click outside to dismiss

To change the target language, click the menu bar icon → **Settings…**.

## Architecture

```
Transy/
├── TransyApp.swift            # @main entry point (SwiftUI App + MenuBarExtra)
├── AppDelegate.swift          # Orchestrates clipboard trigger → translate → popup flow
├── MenuBar/                   # Menu bar dropdown UI
├── Settings/                  # Target language picker and app preferences
├── Translation/               # TranslationCoordinator, text normalization, error mapping
├── Popup/                     # Floating popup window and view
└── Trigger/                   # ClipboardMonitor (changeCount polling) and ClipboardManager
```

**Key technologies:** SwiftUI · AppKit · Translation.framework · UserDefaults · NSPasteboard

## License

[Apache-2.0](LICENSE)
