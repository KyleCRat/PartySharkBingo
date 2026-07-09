# Changelog

All notable changes to Party Shark Bingo will be documented in this file.

## [12.0.7-14] - 2026-07-08

### Changes
- Restore the default Party Shark raid week bingo card data in place of the Lura progression-focused card.

## [12.0.7-13] - 2026-06-03

### Fixes
- Fix repeated session start/end loops in raids by separating group management permissions from the active session owner.
- Restrict session coordination messages (`JOIN`, `LEAVE`, `NOSESSION`, `UNLOCK`, and `SHUFFLE`) to the player who started the active session.
- Normalize player names for session ownership checks so same-realm and cross-realm addon messages compare consistently.
- Restore the ability to leave an active session while solo or when not the session owner.
