## Why

SubFlow currently ships with a mostly single-language interface, which makes the app less comfortable for users who prefer English or Chinese. Adding an in-app UI language switch lets the app match the user's working language without changing the system language or restarting into a different build.

## What Changes

- Add a settings control for switching the app UI between Chinese and English.
- Persist the selected UI language so it survives relaunches.
- Apply the selected language across the app's visible interface, including settings, menu bar actions, window titles, and progress/error messages.
- Keep existing recording, transcription, and translation behavior unchanged.

## Capabilities

### New Capabilities
- `ui/localization`: in-app UI language selection, persistence, and localized presentation of the app interface.

### Modified Capabilities

- None

## Impact

Affected areas include the settings UI, menu bar UI, window titles, and shared text used by the app's main screens and status messages. This also introduces new persisted user preference state for the chosen UI language.
