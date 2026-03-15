---
created: 2026-03-15T03:32:49.361Z
title: Track translation cancellation latency
area: planning
files:
  - .planning/phases/03-translation-loop/03-02-PLAN.md
  - .planning/ROADMAP.md
  - Transy/Popup/PopupView.swift
  - Transy/Popup/PopupController.swift
---

## Problem

During Phase 3 execution, stale-result correctness was fixed, but a separate latency issue remained: when a long translation request A is followed by a short request B, B can still feel delayed even after the popup is dismissed and rebuilt. We verified and fixed several app-side lifecycle issues (retrigger teardown, dismiss teardown, hosted SwiftUI subtree replacement), and we also tried a Tahoe-only `TranslationSession.cancel()` path behind `if #available(macOS 26.0, *)`, but the user did not observe a meaningful improvement.

This makes the remaining delay a likely Translation framework limitation or implementation detail outside the app's direct control on current OS/runtime behavior. The app now handles visible correctness correctly (no stale overwrite, no late reappearance after dismiss), but it does not guarantee that a new short request will always feel independent from a previously started long request.

## Solution

Treat this as a known limitation for now and revisit it later with fresh Apple framework/runtime behavior. Future investigation should focus on:

- retesting on newer macOS / Xcode / Translation framework versions
- checking whether Apple changes session-cancellation semantics in practice
- evaluating whether a different translation-task orchestration model becomes viable without violating the view-scoped session guidance
- deciding whether to surface this limitation in product/docs if it remains user-visible
