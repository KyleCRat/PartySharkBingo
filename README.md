# <Party Shark> Bingo

Bingo specifically for the guild `<Party Shark> Stormrage`, this addon will not be updated or maintained for anything other than this team.

There is no technical reason why you couldn't use this, but the leader controls are intended for the current party leader, raid leader, or raid assistants.

## Features
- 5x5 bingo board with a persistent checked state.
- Guild-specific default bingo tile data.
- Automatic tile text sizing with whitespace wrapping.
- Local shuffle and reset controls.
- Session sync over party or raid addon messages.
- Global session shuffle for active sessions.
- Board scale control from 50% to 150%.
- Tile preview window for reviewing all configured tile values.

## Session Controls
Party leaders, raid leaders, and raid assistants can start a session. Once a session is active, the player who started it is the session owner and is the only player who can end the session, add players, shuffle all boards, or process session roster updates.

Players who are not the session owner can leave the session from the UI. This also works after leaving the group, when addon messages can no longer be sent.

## Commands
- `/psb` or `/psbingo` - Toggle the bingo card window.
- `/psb show` - Show the bingo card window.
- `/psb hide` - Hide the bingo card window.
- `/psb version` - Print the addon version.
- `/psb scale <0.5-1.5>` - Scale the bingo UI.
- `/psb t [Card Name]` - Preview all tile values for a card.
- `/psb list` - List saved bingo cards.
- `/psb load <Card Name>` - Load a saved bingo card.
- `/psb defaultcard <Card Name>` - Set the default card.
- `/psb resetcards` - Reset saved cards back to defaults.
- `/psb resetsettings` - Reset settings back to defaults.
- `/psb printversion` - Toggle printing the addon version on load.

## Origin and License
This addon is derived from the addon Bingo by Cold-1 and is distributed under the GNU General Public License v3.0, in accordance with Bingo's license.

- Original project: Bingo by Cold-1
- Link to project: https://github.com/Cold-1/Bingo
- License: GPL v3.0
