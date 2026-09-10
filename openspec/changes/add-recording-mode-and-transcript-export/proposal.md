## Why

CapiX already produces live bilingual subtitles, but it does not yet preserve a recording session as a structured artifact. This change adds a recording entry point so users can capture a session, keep the generated subtitles together with the recording outputs, and optionally save the bilingual captions as a meeting transcript document.

## What Changes

- Add a dedicated recording button in the app UI.
- Support two recording modes:
  - screen recording with system audio
  - audio-only recording with system audio
- Add an optional switch to export subtitle content into a transcript document while recording.
- Add a translation-only switch that keeps live transcription and translation active without
  creating a recording session, media file, or transcript document.
- Add a configurable root path for recording output.
- Create a new session folder under the chosen root path for every recording run.
- Store all recording-related artifacts for that session inside the session folder.
- Keep the existing live subtitle flow, model loading, and translation behavior intact.

## Capabilities

### New Capabilities
- `recording-workflow`: recording entry point, mode selection, session folder management, and optional transcript document export.

### Modified Capabilities

- None

## Impact

Affected areas include the menu bar UI, settings UI, recording state management, audio/screen capture, subtitle persistence, file system output, and the recording session lifecycle. Translation-only operation also requires a non-persistent capture path that bypasses recording workspace creation while preserving the existing live subtitle pipeline.
