---
created: 2026-03-15T02:06:07.613Z
title: Add translation model install guidance
area: planning
files:
  - .planning/phases/03-translation-loop/03-02-PLAN.md
  - .planning/ROADMAP.md
  - Transy/Popup/PopupView.swift
  - Transy/Settings/SettingsView.swift
---

## Problem

During Phase 3 live verification, Transy correctly showed the inline error `Translation model not installed.` for a normal Japanese-to-English translation attempt, but there is currently no user-facing guidance explaining where Apple translation models are installed on macOS. This leaves the user stuck at the correct error state without a clear next step, and it blocks completion of the happy-path translation loop until the model is installed out of band.

## Solution

Add a future user-facing guidance path for Apple translation model installation. The likely home is Phase 4 settings/model management, but the exact UX can be decided later. At minimum, capture the install path (`System Settings > General > Language & Region > Translation Languages`) and surface it in a way that fits the quiet Transy UX, ideally without introducing surprise Apple-owned prompts during the normal Phase 3 popup flow.
