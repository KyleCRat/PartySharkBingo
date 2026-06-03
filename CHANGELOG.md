# Changelog

All notable changes to Party Shark Bingo will be documented in this file.

## [12.0.7-13] - 2026-06-03

### Fixes
- Fix repeated session start/end loops in raids by separating group management permissions from the active session owner.
- Restrict session coordination messages (`JOIN`, `LEAVE`, `NOSESSION`, `UNLOCK`, and `SHUFFLE`) to the player who started the active session.
- Normalize player names for session ownership checks so same-realm and cross-realm addon messages compare consistently.
- Restore the ability to leave an active session while solo or when not the session owner.

## [12.0.7-12] - 2026-06-02
- Add version display
- Fix corrupt reset not working
- Session leader defined by lead / assist
- Fix to work in parties
- Remove hidden import / export
- Refactor into files focused around concerns
- Update Data.lua
- No need for hard coded indicies
- Add scale popup slider
- Autosize entries
- Add test tile list
- Refactor saved vars and event handling
- Update to Lura Prog Card
