## 1. Core language state

- [x] 1.1 Add a persisted UI language setting and a shared localization helper, then verify the setting round-trips through `CaptionSettings` tests
- [x] 1.2 Add the Settings control for Chinese/English selection and verify the picker updates the stored language

## 2. App-wide localization

- [x] 2.1 Localize the app's visible Settings, menu bar, transcript, model download, and window title text, then verify the language switch updates those surfaces at runtime
- [x] 2.2 Refresh AppKit window titles and other non-SwiftUI surfaces when the language changes, then verify open windows keep their state while switching language

## 3. Validation

- [x] 3.1 Update tests for the new language preference and run `xcodebuild test -project MeetingFlow.xcodeproj -scheme MeetingFlowTests -destination 'platform=macOS'` successfully
