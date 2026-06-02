local _, ns = ...
local Bingo = ns.Bingo

--[[
    Bingo Card Format
    =================

    Required Fields:
        Title           - Card title displayed at top (string)
        [1] to [N]      - Bingo square entries (need at least 24), each a table:
                          { value = "Text", size = 14 }
                          value (required) - text shown on the square
                          size  (optional) - font size override for this square

    Optional Fields:
        TitleSize       - Font size for title (default: 20)
        FontSize        - Default font size for all squares (default: 10)
        FreeSpace       - Text for center free space (default: "Free Space")
        FreeSpaceSize   - Font size for free space (default: FontSize)
]]
function Bingo.LoadDefaultBingoCards()
    BingoCards = {
        Default = {
            Title = "Party Shark 25k Raid Week Bingo",
            TitleSize = 24,
            FontSize = 18,
            FreeSpace = "Free",
            FreeSpaceSize = 26,
            [46] = { value = "BoE!",                       size = 24 },
             [2] = { value = "Muted",                      size = 23 },
             [3] = { value = "REPAIR",                     size = 22 },
            [47] = { value = "Déjà Vu",                    size = 21 },
             [4] = { value = "Doooomin",                   size = 16 },
            [48] = { value = "Fake Win",                   size = 20 },
             [5] = { value = "Corruption",                 size = 13 },
             [1] = { value = "Giga Parse",                 size = 20 },
             [6] = { value = "Early Pull",                 size = 18 },
             [7] = { value = "Game Crash",                 size = 18 },
             [8] = { value = "Other Right",                size = 18 },
             [9] = { value = "Clear Comms",                size = 18 },
            [10] = { value = "Pull Jinxed",                size = 18 },
            [11] = { value = "Timezone War",               size = 15 },
            [12] = { value = "IRL Aggro",                  size = 18 },
            [13] = { value = "<Vod Review>",               size = 14 },
            [14] = { value = "HR Requested",               size = 14 },
            [15] = { value = "Tech Support" },
            [49] = { value = "No Soulstone",               size = 15 },
            [50] = { value = "Not Prepared",               size = 15 },
            [17] = { value = "Bug Mentioned",              size = 12 },
            [18] = { value = "Blue Bar Boss" },
            [19] = { value = "Wiped to Trash" },
            [20] = { value = "Late from break",            size = 14 },
            [21] = { value = "Missed Consumes",            size = 13 },
            [22] = { value = "Last Pull Magic" },
            [23] = { value = "Healer Rez Race" },
            [24] = { value = "Name Said Wrong" },
            [25] = { value = "Rich People Talk" },
            [26] = { value = "Poor People Talk" },
            [27] = { value = "Skill Not on Bar" },
            [51] = { value = "Check the @Pings",           size = 15 },
            [28] = { value = "Addon Out of Date" },
            [29] = { value = "Mage Table Please" },
            [30] = { value = "Bingo Tile Fishing",         size = 16 },
            [31] = { value = "Substances Mentioned",       size = 12 },
            [32] = { value = "Don't Die to X; Dies to X",  size = 14 },
            [33] = { value = "Rez Dissar",                 size = 20, players = { "Dìssar" }},
            [34] = { value = "Tenc Stalks",                size = 20, players = { "Tencarus", "Tencdh" }},
            [35] = { value = "Where's Pin?",               size = 16, players = { "Pinsassin" }},
            [36] = { value = "Shut Up Grun",               size = 19, players = { "Grunmore" }},
            [16] = { value = "Xäku Unhinged",              size = 16, players = {"Xäku"}},
            [37] = { value = "Rezy Gets Bullied",          size = 17, players = { "Rezy" }},
            [38] = { value = "Plane Delays Nash",          size = 17, players = { "Nashou" }},
            [39] = { value = "Braainss' Vacation",         size = 15, players = { "Braainss" }},
            [40] = { value = "Keize Wasn't Healed",        size = 15, players = { "Keize" }},
            [41] = { value = "Braainss' Jeeves, Eww",      size = 15, players = { "Braainss" }},
            [43] = { value = "Tenc 'Inspiring' Speech",    size = 14, players = { "Tencarus", "Tencdh" }},
            [44] = { value = "Yuhbarrel Speaks at 2.5x",   size = 14, players = { "Yvairel", "Yvauras" }},
            [45] = { value = "Vibekiller Enters the Chat", size = 13, players = { "Tencarus", "Tencdh" }},
        }
    }
end
