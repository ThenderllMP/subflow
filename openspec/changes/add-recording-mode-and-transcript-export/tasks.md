## 1. Recording settings and UI

- [x] 1.1 Add recording preferences for output root path, capture mode, and transcript export toggle, and verify the values persist across a relaunch.
- [x] 1.2 Add the recording button and settings controls for mode selection, transcript export, and output folder selection, and verify the controls are visible and update the saved preferences.

## 2. Session lifecycle and capture modes

- [x] 2.1 Implement recording session initialization and output path validation, and verify an invalid or unwritable path blocks recording start with a visible error.
- [x] 2.2 Wire screen-recording and audio-only start/stop behavior into the capture flow, and verify screen mode captures screen plus system audio while audio-only mode captures system audio only.
- [x] 2.3 Create a dedicated session folder for each recording run and verify all generated artifacts are written under that folder.

## 3. Transcript document export

- [x] 3.1 Append completed bilingual subtitle entries into a session transcript document when export is enabled, and verify the document contains the original text, translation, and timestamps.
- [x] 3.2 Finalize transcript output when recording stops and preserve partial session artifacts after an interruption, and verify a stopped session leaves a readable transcript behind.

## 4. Validation

- [x] 4.1 Add or update tests for recording preference persistence, session folder creation, transcript export toggling, and capture-mode gating, and verify `xcodebuild test -project CapiX.xcodeproj -scheme CapiXTests -destination 'platform=macOS'` passes.
- [x] 4.2 Run a clean app build and verify `xcodebuild build -project CapiX.xcodeproj -scheme CapiX -destination 'platform=macOS' -configuration Debug` succeeds.
