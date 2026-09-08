## Purpose

CapiX needs a built-in way to present the interface in either Chinese or English at runtime so users can work in their preferred language without changing macOS language settings or rebuilding the app.

## ADDED Requirements

### Requirement: User can choose the app UI language
The system MUST provide a settings control that lets the user switch the application UI between Chinese and English.

#### Scenario: User selects English
- **WHEN** the user chooses English in Settings
- **THEN** the app presents supported UI text in English

#### Scenario: User selects Chinese
- **WHEN** the user chooses Chinese in Settings
- **THEN** the app presents supported UI text in Chinese

### Requirement: UI language choice persists across relaunch
The system MUST save the selected UI language and restore it on the next launch.

#### Scenario: App relaunches after a language change
- **WHEN** the user has selected a UI language and quits the app
- **THEN** the app restores that language after relaunch

### Requirement: Visible app surfaces update when the UI language changes
The system MUST refresh the visible app interface to the selected language without requiring the user to restart the app.

#### Scenario: User changes language while windows are open
- **WHEN** the user changes the UI language while Settings, the menu bar popover, or another app window is open
- **THEN** the visible app text updates to the new language
