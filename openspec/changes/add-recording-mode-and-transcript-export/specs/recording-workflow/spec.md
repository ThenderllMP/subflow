## Purpose

This capability lets users capture a recording session together with SubFlow's bilingual subtitles and keep the session artifacts organized under a user-configurable folder. It preserves the session as a reviewable meeting record after recording ends.

## ADDED Requirements

### Requirement: Recording control supports two capture modes
The system MUST provide a recording control that lets the user start a session in either screen-recording mode or audio-only mode.
Screen-recording mode MUST capture the current screen plus system audio.
Audio-only mode MUST capture system audio without screen video.
The selected mode MUST remain fixed for the duration of the session.

#### Scenario: Start a screen recording session
- **WHEN** the user starts recording in screen-recording mode
- **THEN** the session captures screen video and system audio together
- **AND** the chosen mode remains unchanged until the session ends

#### Scenario: Start an audio-only session
- **WHEN** the user starts recording in audio-only mode
- **THEN** the session captures system audio only
- **AND** no screen video is recorded for that session

### Requirement: Recording output root is configurable
The system MUST allow the user to configure a recording output root path in settings.
The configured path MUST exist and be writable before a recording session starts.
If the configured path is invalid or not writable, the system MUST block the recording start and surface a user-visible error.

#### Scenario: Save a valid output root
- **WHEN** the user selects a writable folder as the recording output root
- **THEN** the system stores that folder as the active root path
- **AND** future sessions use that root path

#### Scenario: Reject an invalid output root
- **WHEN** the user selects a path that does not exist or cannot be written
- **THEN** the system MUST not start recording
- **AND** the system MUST show an error explaining that the output location is unavailable

### Requirement: Each recording session creates its own session folder
When a recording session starts, the system MUST create a unique session folder beneath the configured output root.
All files produced for that session, including recording artifacts and transcript files, MUST be placed inside that session folder.
If the session folder cannot be created, the system MUST not start recording.

#### Scenario: Create a new session folder
- **WHEN** the user starts a recording session
- **THEN** the system creates a new folder under the configured recording root
- **AND** all session artifacts are written inside that folder

#### Scenario: Block start on folder creation failure
- **WHEN** the system cannot create the session folder
- **THEN** recording does not start
- **AND** the user sees an error instead of a partial session

### Requirement: Optional transcript document captures bilingual captions
The system MUST provide a switch that controls whether subtitle content is also written to a transcript document.
When the switch is enabled, the system MUST append completed subtitle entries to a transcript document in the active session folder.
Each appended entry MUST contain the original subtitle text and its translation.
When the switch is disabled, the system MUST not create a transcript document for that session.

#### Scenario: Export transcript while recording
- **WHEN** transcript export is enabled and subtitles are produced during a recording session
- **THEN** the system appends the bilingual caption content to the session transcript document
- **AND** the transcript remains available after recording stops

#### Scenario: Keep transcript export off
- **WHEN** transcript export is disabled for a session
- **THEN** the system does not create a transcript document
- **AND** the session still proceeds normally

### Requirement: Ending a recording finalizes the session output
When the user stops recording, the system MUST finalize the active session outputs and leave them in the session folder.
The transcript document, if present, MUST be complete and readable after recording stops.
If recording is interrupted unexpectedly, the system SHOULD preserve any already written session artifacts rather than deleting them.

#### Scenario: Stop recording normally
- **WHEN** the user stops an active recording session
- **THEN** the session output is finalized
- **AND** the recording artifacts remain in the session folder

#### Scenario: Preserve partial output after interruption
- **WHEN** a recording session ends unexpectedly
- **THEN** any already written transcript content remains in the session folder
- **AND** the system does not delete the session artifacts
