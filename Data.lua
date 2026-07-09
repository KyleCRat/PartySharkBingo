local _, ns = ...
local Bingo = ns.Bingo

local function CopyDefaultValue(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = CopyDefaultValue(nestedValue)
    end

    return copy
end

--[[
    Bingo Card Format
    =================

    Required Fields:
        Title           - Card title displayed at top (string)
        [1] to [N]      - Bingo square entries (need at least 24), each a table:
                          { value = "Text" }
                          value (required) - text shown on the square
                          players (optional) - only include this tile when one of these players is grouped

    Optional Fields:
        TitleSize       - Font size for title (default: 20)
        FreeSpace       - Text for center free space (default: "Free Space")

    Bingo square text is sized automatically to fit the tile. Legacy size,
    FontSize, and FreeSpaceSize fields are ignored.
]]
local DEFAULT_BINGO_CARDS = {
    Default = {
        Title = "Party Shark 25k Raid Week Bingo",
        TitleSize = 24,
        FreeSpace = "Free",
        { value = "BoE!" },
        { value = "Muted" },
        { value = "REPAIR" },
        { value = "Déjà Vu" },
        { value = "Doooomin" },
        { value = "Fake Win" },
        { value = "Corruption" },
        { value = "Giga Parse" },
        { value = "Early Pull" },
        { value = "Game Crash" },
        { value = "Other Right" },
        { value = "Clear Comms" },
        { value = "Pull Jinxed" },
        { value = "Timezone War" },
        { value = "IRL Aggro" },
        { value = "<Vod Review>" },
        { value = "HR Requested" },
        { value = "Tech Support" },
        { value = "No Soulstone" },
        { value = "Not Prepared" },
        { value = "Bug Mentioned" },
        { value = "Blue Bar Boss" },
        { value = "Wiped to Trash" },
        { value = "Late from break" },
        { value = "Missed Consumes" },
        { value = "Last Pull Magic" },
        { value = "Healer Rez Race" },
        { value = "Name Said Wrong" },
        { value = "Rich People Talk" },
        { value = "Poor People Talk" },
        { value = "Skill Not on Bar" },
        { value = "Check the @Pings" },
        { value = "Addon Out of Date" },
        { value = "Mage Table Please" },
        { value = "Bingo Tile Fishing" },
        { value = "Substances Mentioned" },
        { value = "Don't Die to X; Dies to X" },
        { value = "Rez Dissar", players = { "Dìssar" }},
        { value = "Tenc Stalks", players = { "Tencarus", "Tencdh" }},
        { value = "Where's Pin?", players = { "Pinsassin" }},
        { value = "Shut Up Grun", players = { "Grunmore" }},
        { value = "Xäku Unhinged", players = {"Xäku"}},
        { value = "Rezy Gets Bullied", players = { "Rezy" }},
        { value = "Plane Delays Nash", players = { "Nashou" }},
        { value = "Braainss' Vacation", players = { "Braainss" }},
        { value = "Keize Wasn't Healed", players = { "Keize" }},
        { value = "Braainss' Jeeves, Eww", players = { "Braainss" }},
        { value = "Tenc 'Inspiring' Speech", players = { "Tencarus", "Tencdh" }},
        { value = "Yuhbarrel Speaks at 2.5x", players = { "Yvairel", "Yvauras" }},
        { value = "Vibekiller Enters the Chat", players = { "Tencarus", "Tencdh" }},
    },
    -- Lura = {
    --     Title = "Party Shark Lura Bingo",
    --     TitleSize = 24,
    --     FreeSpace = "Wipe",
    --     { value = "Fully Buffed" },
    --     { value = "<Vod Review>" },
    --     { value = "Healer Rez Race" },
    --     { value = "Progression Question Asked" },
    --     { value = "Giga Play" },
    --     { value = "Giga Shard Soak Save" },
    --     { value = "Successful 1st Memory Game" },
    --     { value = "Successful 2nd Memory Game" },
    --     { value = "Successful 3rd Memory Game" },
    --     { value = "See I1" },
    --     { value = "See P2" },
    --     { value = "See P3" },
    --     { value = "See P4" },
    --     { value = "20 Alive in I1" },
    --     { value = "20 Alive in P2" },
    --     { value = "20 Alive in P3" },
    --     { value = "20 Alive in P4" },
    --     { value = "Boss Under 75%" },
    --     { value = "Boss Under 50%" },
    --     { value = "Boss Under 25%" },
    --     { value = "Boss Is Killable" },
    --     { value = "Cutting Deadge" },
    --     { value = "New Best Pull" },
    --     { value = "Moved Lust to Kill Point" },
    --     -- { value = "Healing CD's Adjusted" },
    --     -- { value = "Callout Saved Pull" },
    --     -- { value = "Brez Available for Prog" },
    -- }
}

function Bingo.GetDefaultBingoCards()
    return DEFAULT_BINGO_CARDS
end

function Bingo.LoadDefaultBingoCards()
    BingoCards = CopyDefaultValue(DEFAULT_BINGO_CARDS)
    Bingo.Cards = BingoCards

    return BingoCards
end
