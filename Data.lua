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
            { value = "BoE!",                       size = 24 },
            { value = "Muted",                      size = 23 },
            { value = "REPAIR",                     size = 22 },
            { value = "Déjà Vu",                    size = 21 },
            { value = "Doooomin",                   size = 16 },
            { value = "Fake Win",                   size = 20 },
            { value = "Corruption",                 size = 13 },
            { value = "Giga Parse",                 size = 20 },
            { value = "Early Pull",                 size = 18 },
            { value = "Game Crash",                 size = 18 },
            { value = "Other Right",                size = 18 },
            { value = "Clear Comms",                size = 18 },
            { value = "Pull Jinxed",                size = 18 },
            { value = "Timezone War",               size = 15 },
            { value = "IRL Aggro",                  size = 18 },
            { value = "<Vod Review>",               size = 14 },
            { value = "HR Requested",               size = 14 },
            { value = "Tech Support" },
            { value = "No Soulstone",               size = 15 },
            { value = "Not Prepared",               size = 15 },
            { value = "Bug Mentioned",              size = 12 },
            { value = "Blue Bar Boss" },
            { value = "Wiped to Trash" },
            { value = "Late from break",            size = 14 },
            { value = "Missed Consumes",            size = 13 },
            { value = "Last Pull Magic" },
            { value = "Healer Rez Race" },
            { value = "Name Said Wrong" },
            { value = "Rich People Talk" },
            { value = "Poor People Talk" },
            { value = "Skill Not on Bar" },
            { value = "Check the @Pings",           size = 15 },
            { value = "Addon Out of Date" },
            { value = "Mage Table Please" },
            { value = "Bingo Tile Fishing",         size = 16 },
            { value = "Substances Mentioned",       size = 12 },
            { value = "Don't Die to X; Dies to X",  size = 14 },
            { value = "Rez Dissar",                 size = 20, players = { "Dìssar" }},
            { value = "Tenc Stalks",                size = 20, players = { "Tencarus", "Tencdh" }},
            { value = "Where's Pin?",               size = 16, players = { "Pinsassin" }},
            { value = "Shut Up Grun",               size = 19, players = { "Grunmore" }},
            { value = "Xäku Unhinged",              size = 16, players = {"Xäku"}},
            { value = "Rezy Gets Bullied",          size = 17, players = { "Rezy" }},
            { value = "Plane Delays Nash",          size = 17, players = { "Nashou" }},
            { value = "Braainss' Vacation",         size = 15, players = { "Braainss" }},
            { value = "Keize Wasn't Healed",        size = 15, players = { "Keize" }},
            { value = "Braainss' Jeeves, Eww",      size = 15, players = { "Braainss" }},
            { value = "Tenc 'Inspiring' Speech",    size = 14, players = { "Tencarus", "Tencdh" }},
            { value = "Yuhbarrel Speaks at 2.5x",   size = 14, players = { "Yvairel", "Yvauras" }},
            { value = "Vibekiller Enters the Chat", size = 13, players = { "Tencarus", "Tencdh" }},
        }
    }
end
