## Context

See `proposal.md - Why`. The app already has several user-facing surfaces, including Settings, the menu bar popover, the main transcript window, and the first-launch download progress window.

## Goals / Non-Goals

**Goals:**
- Add a runtime language preference for Chinese and English.
- Keep the selected language stable across relaunches.
- Update the visible app surfaces when the preference changes.

**Non-Goals:**
- No system-wide language override.
- No redesign of the existing UI layout.
- No translation of third-party or OS-provided UI outside the app's own surfaces.

## Decisions

- Store UI language as a first-class user preference alongside the other settings. This keeps language selection consistent with the rest of the app's persisted configuration.
- Drive app copy from a central localization helper keyed by the selected language. This avoids needing a restart to reload a bundle-localization table and keeps runtime updates predictable across SwiftUI and AppKit surfaces.
- Update existing window titles and status text when the language preference changes instead of recreating windows. This keeps the current app state intact and minimizes visible churn.
- Keep product names and technical model identifiers stable. Only app-owned UI labels and messages are localized.

## Risks / Trade-offs

- [Risk] Some text may remain untranslated if it is not routed through the shared localization helper. → Mitigation: centralize app-visible copy in the helper and add targeted tests for representative labels.
- [Risk] AppKit window titles and menu surfaces can lag behind SwiftUI views if they are set only once. → Mitigation: observe the preference and refresh titles in place.
- [Risk] A hand-written localization table can drift over time. → Mitigation: keep the table small, reuse it across surfaces, and extend tests when new strings are added.

## Migration Plan

1. Add the persisted language preference with a default that preserves the current app experience.
2. Introduce localized rendering for existing UI surfaces.
3. Verify the app can relaunch with the selected language and that open windows update live.

## Open Questions

None.
