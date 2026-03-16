# Transy

A lightweight macOS menu bar translator. Select text in any app, press **⌘C** twice, and get an instant translation popup — without leaving your current window.

Built with SwiftUI and Apple's on-device [Translation framework](https://developer.apple.com/documentation/translation).

## Features

- **Menu bar app** — runs as a status-bar accessory with no Dock icon
- **Double ⌘C trigger** — captures selected text from any app and translates it instantly
- **Floating popup** — shows the translation result without stealing focus
- **Clipboard-safe** — saves and restores the original clipboard after capture
- **Target language picker** — choose your preferred translation target in Settings
- **Model download guidance** — detects missing translation models and guides you to System Settings
- **Accessibility permission flow** — prompts for Accessibility access on first launch with a guided walkthrough
- **Fully on-device** — all translation happens locally via Apple Translation; no network required

## Requirements

- macOS 15.0 (Sequoia) or later
- Accessibility permission (required for global hotkey monitoring)
- Apple Translation language models (downloaded via System Settings → General → Language & Region)

## Installation

### Prerequisites

- Xcode 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```sh
brew install xcodegen
```

### Build

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

### Run tests

```sh
xcodebuild test -scheme Transy -destination 'platform=macOS'
```

## Usage

1. Launch Transy — it appears as a bubble icon (💬) in the menu bar
2. Grant Accessibility permission when prompted
3. Select text in any app and press **⌘C** twice quickly
4. A popup appears near the cursor with the translated text
5. Press **Escape** or click outside to dismiss

To change the target language, click the menu bar icon → **Settings…**.

## Architecture

```
Transy/
├── TransyApp.swift            # @main entry point (SwiftUI App + MenuBarExtra)
├── AppDelegate.swift          # Orchestrates trigger → capture → translate → popup flow
├── MenuBar/                   # Menu bar dropdown UI
├── Settings/                  # Target language picker and model guidance
├── Translation/               # TranslationCoordinator, availability checks, error mapping
├── Popup/                     # Floating popup window and view
├── Trigger/                   # Double ⌘C detection, clipboard capture/restore
└── Permissions/               # Accessibility permission guidance
```

**Key technologies:** SwiftUI · AppKit · Translation.framework · UserDefaults · NSPasteboard · CGEvent

## License

[Apache-2.0](LICENSE)
