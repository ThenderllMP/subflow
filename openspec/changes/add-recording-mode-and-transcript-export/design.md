## Context

CapiX already has a live subtitle pipeline, a floating subtitle window, model loading, and a settings surface for display and translation choices. See `proposal.md - Why` for the user need; the main constraint here is to add recording and file output without disturbing the existing streaming subtitle behavior.

## Goals / Non-Goals

**Goals:**
- Add a user-facing recording entry point with screen and audio-only modes.
- Persist each recording run in its own session folder under a configurable root path.
- Optionally write bilingual subtitle pairs into a session transcript document while recording.
- Keep the current live subtitle overlay and translation flow intact.

**Non-Goals:**
- Speaker diarization or per-speaker attribution.
- Cloud sync, sharing, or multi-device session history.
- Editing or annotating the transcript after recording ends.
- Reworking the existing transcription model pipeline.

## Decisions

- Use a settings-backed recording root folder rather than asking for a path on every run.
  - Rationale: this keeps the flow fast and makes session outputs predictable.
  - Alternative considered: prompt for a path every time. Rejected because it adds friction and is easy to misconfigure.
- Create one session folder per run with all outputs stored beneath it.
  - Rationale: this keeps video/audio assets, transcript text, and metadata together and makes cleanup or archiving straightforward.
  - Alternative considered: write into a shared flat directory with timestamped filenames. Rejected because related files would be easier to separate by accident.
- Treat recording mode as a pre-start choice that stays fixed for the session.
  - Rationale: changing capture shape mid-session complicates the output set and the user mental model.
  - Alternative considered: allow switching between screen and audio-only while recording. Rejected for complexity and unclear UX.
- Write the transcript as a text-based document in the session folder.
  - Rationale: the subtitle stream is already textual and a text document is easy to append, inspect, and archive.
  - Alternative considered: generate a Word document immediately. Rejected because it adds heavier document handling without changing the user outcome.
- Append transcript entries from completed subtitle pairs, not live preview text.
  - Rationale: completed lines are stable and match the meeting record users expect.
  - Alternative considered: persist every streaming fragment. Rejected because it would create noisy, duplicate output.

## Risks / Trade-offs

- [System permission failure] Screen recording and audio capture can fail if the user has not granted the required macOS permissions → surface the error early and do not start a partial session.
- [Partial transcript on crash] A session may end before the transcript is fully finalized → preserve already written artifacts and finalize on stop whenever possible.
- [Storage growth] Recording sessions can generate large folders quickly → keep all outputs under one user-managed root so the user can prune old sessions easily.
- [UI complexity] Adding mode selection and export settings increases the settings surface → keep the controls grouped under one recording section to limit clutter.

## Migration Plan

1. Add the new recording controls and settings with safe defaults so existing users keep the current subtitle experience.
2. Default new sessions into a user-managed recording root that can be created automatically if missing.
3. Keep all new artifacts self-contained in per-session folders so rollback only requires hiding the new UI and leaving old sessions untouched.
