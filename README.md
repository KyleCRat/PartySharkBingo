# __Bingo__

A bingo addon for World of Warcraft. Updated for Party Shark by Yvairel

## __Features__
* Create you own bingo cards to play.
* Import or export bingo cards.

## __Future Features (Maybe)__
* GUI to create and edit bingo cards.
* Share bingo cards ingame with other players (Using a command or button).
* Sync bingo cards with other players (Keep the same spaces marked between all players).

## __Slash Commands__
* __/bingo__ - Toggle the bingo card window.
* __/bingo version__ - Print the addon version.
* __/bingo show__ - Show the bingo card window.
* __/bingo hide__ - Hide the bingo card window.
* __/bingo resetcards__ - Reset all saved cards back to the default.
* __/bingo resetsettings__ - Reset all settings back to the default.
* __/bingo printversion__ - Enable/Disable printing the addon version on load. Default is disabled.
* __/bingo defaultcard &lt;Card Name>__ - Sets the card that will be loaded by default.
* __/bingo scale &lt;Number>__ - Scales the interface by the specified amount. Default is 1. Numbers only, decimals accepted.
* __/bingo list__ - List all the saved bingo cards.
* __/bingo load &lt;Card Name>__ - Loads the specified card, the card name is case-sensitive.

## __Creating your own bingo cards__

Let's use a shortened version of the 'Example' bingo card for this example (You can find the full version included in the addon). 
```
{
	Title = "Example Bingo Card",
	TitleSize = 28,
	FontSize = 12,
	FreeSpace = "This is the Free Space!",
	FreeSpaceSize = 14,
	[1] = "Example Bingo Space 1",
	[10] = "Example Bingo Space 10 with a custom size!",
	Size10 = 10,
	[24] = "Example Bingo Space 24",
	[25] = "This is the Free Space!!!",
	Size25 = 8
}
```

All the following values __(case-sensitive)__ can be omitted and the default value will be used instead.

* __Title__ - Sets the title text that will be displayed on top of the card. _Default: Bingo!_
* __TitleSize__ - Sets the size of the title text. _Default: 20_
* __FontSize__ - Sets the font size for all the spaces with no specific size. _Default: 10_
* __FreeSpace or [25]__ - You can use either to set the text you wish to display on the free space, if both 'FreeSpace' and '[25]' are present 'FreeSpace' will be used. _Default: Free Space_
* __FreeSpaceSize or Size25__ - You can use either to set the size of the free space text, if both 'FreeSpaceSize' and 'Size25' are present 'FreeSpaceSize' will be used. _Default: 10_
* __[1] - [24]__ - The values from 1 to 24 represent the regular spaces on the bingo card you can enter any text here. _Default: 1 - 24_
* __Size1 - Size24__ - Can be used to set a specific text size for that space. _Default: 10_
