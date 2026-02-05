# Session State Flows

This document describes all possible session state scenarios and how the addon handles them.

## Leader Scenarios

| # | Scenario | Leader State | Action | Expected Behavior | Status |
|---|----------|--------------|--------|-------------------|--------|
| L1 | Leader starts session in group | Unlocked → Locked | Clicks "Start" | Sends `LOCK`, followers join session | ✅ OK |
| L2 | Leader ends session in group | Locked → Unlocked | Clicks "End" | Sends `UNLOCK`, followers released | ✅ OK |
| L3 | Leader ends session solo | Locked → Unlocked | Clicks "End" | Ends locally (no message needed) | ✅ OK |
| L4 | Leader joins group with session | Locked | Joins group | Sends `PING` to get follower status | ✅ OK |
| L5 | Leader joins group without session | Unlocked | Joins group | Sends `UNLOCK` to release any followers | ✅ OK |
| L6 | Leader leaves group with session | Locked | Leaves group | Session persists locally | ✅ OK |
| L7 | Leader leaves group without session | Unlocked | Leaves group | No action needed | ✅ OK |
| L8 | Leader starts session solo | Unlocked | N/A | Start button hidden when not in group | ✅ OK |

## Follower Scenarios

| # | Scenario | Follower State | Action | Expected Behavior | Status |
|---|----------|----------------|--------|-------------------|--------|
| F1 | Follower receives LOCK | Unlocked → Locked | Leader starts session | Locks session, sends `JOIN` | ✅ OK |
| F2 | Follower receives UNLOCK | Locked → Unlocked | Leader ends session | Unlocks session | ✅ OK |
| F3 | Follower joins group with session | Locked | Joins group | Sends `JOIN` to confirm | ✅ OK |
| F4 | Follower joins group without session | Unlocked | Joins group | Sends `NOSESSION` | ✅ OK |
| F5 | Follower leaves group with session | Locked | Leaves group | Session persists locally | ✅ OK |
| F6 | Follower leaves group without session | Unlocked | Leaves group | No action needed | ✅ OK |
| F7 | Follower clicks "Leave" in group | Locked → Unlocked | Clicks "Leave" | Sends `LEAVE`, unlocks locally | ✅ OK |
| F8 | Follower clicks "Leave" solo | Locked → Unlocked | Clicks "Leave" | Unlocks locally (no message needed) | ✅ OK |
| F9 | Follower receives LOCK while already locked | Locked | Leader sends `LOCK` (re-add players) | Re-confirms with `JOIN` | ✅ OK |
| F10 | Follower receives UNLOCK while already unlocked | Unlocked | Leader sends `UNLOCK` | No-op, already unlocked | ✅ OK |

## Cross-State Scenarios (Mismatches)

| # | Scenario | States | Trigger | Expected Behavior | Status |
|---|----------|--------|---------|-------------------|--------|
| X1 | Leader has no session, follower joins with session | L: Unlocked, F: Locked | Follower joins, sends `JOIN` | Leader sends `UNLOCK` to release follower | ✅ OK |
| X2 | Leader has session, follower joins without session (was in session) | L: Locked, F: Unlocked | Follower joins, sends `NOSESSION` | Leader sees warning player left session, removes from list | ✅ OK |
| X3 | Leader has session, follower reloads UI | L: Locked, F: Locked | Follower reloads, sends `JOIN` | Leader adds to session (no duplicate announce) | ✅ OK |
| X4 | Leader reloads UI with session | L: Locked | Leader reloads | Sends `PING`, followers respond with current state | ✅ OK |
| X5 | Follower left session while out of group | L: Locked, F: Unlocked | Follower rejoins, sends `NOSESSION` | Leader sees warning player left session, removes from list | ✅ OK |
| X6 | New follower joins during active session | L: Locked, F: Unlocked | Follower joins, sends `NOSESSION` | Leader sees message new player joined without session (can use "Add Players") | ✅ OK |

## Combat Scenarios

| # | Scenario | State | Action | Expected Behavior | Status |
|---|----------|-------|--------|-------------------|--------|
| C1 | Leader tries to start session in combat | Unlocked | Clicks "Start" | Blocked with message (UI restriction) | ✅ OK |
| C2 | Leader tries to end session in combat | Locked | Clicks "End" | Blocked with message (UI restriction) | ✅ OK |
| C3 | Follower tries to leave session in combat | Locked | Clicks "Leave" | Blocked with message (UI restriction) | ✅ OK |
| C4 | Follower in combat receives LOCK | Unlocked → Locked | Leader starts session | Processes normally, locks session, sends `JOIN` | ✅ OK |
| C5 | Follower in combat receives UNLOCK | Locked → Unlocked | Leader ends session | Processes normally, unlocks session | ✅ OK |
| C6 | Leader in combat, follower joins with session | L: Unlocked, F: Locked | Follower sends `JOIN` | Leader processes, sends `UNLOCK` to release | ✅ OK |
| C7 | Leader in combat, follower joins without session | L: Locked, F: Unlocked | Follower sends `NOSESSION` | Leader processes, shows appropriate message | ✅ OK |

## Message Types

| Message | Sender | Purpose |
|---------|--------|---------|
| `LOCK` | Leader | Start session or re-add players |
| `UNLOCK` | Leader | End session |
| `JOIN` | Follower | Confirm participation in session |
| `LEAVE` | Follower | Leave session voluntarily |
| `NOSESSION` | Follower | Report not in a session |
| `PING` | Leader | Request status from all followers |

## Notes

- Addon messages work during trash combat but not during boss encounters or M+ runs (Midnight restrictions)
- UI buttons are blocked during any combat (`InCombatLockdown()`) but messaging system operates freely
- Session state persists across reloads via `BingoSettings`
- Leader is determined by character name (hardcoded as `IS_SESSION_LEADER`)
