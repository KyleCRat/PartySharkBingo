local _, ns = ...
local Bingo = ns.Bingo

-- Helper function to parse command arguments
local function ParseArgs(message)
    local args = {}
    for arg in string.gmatch(message, "%S+") do
        args[#args + 1] = arg
    end
    return args
end

-- Helper function to get remaining args as a single string (for card names with spaces)
local function GetRemainingArgs(args, startIndex)
    local result = ""
    for i = startIndex, #args do
        result = result .. args[i] .. " "
    end
    return strtrim(result)
end

-- Command handlers table
local Commands = {}

function Commands.help()
    print("|cff00ccff#####|cffFFC125 " .. Bingo.ADDON_NAME .. "|cffffffff Help |cff00ccff#####")
    print("|cffFFFFE0/psb |cffffffff- Toggle the bingo card window.")
    print("|cffFFFFE0/psb |cffADFF2Fversion |cffffffff- Print the addon version.")
    print("|cffFFFFE0/psb |cffADFF2Fshow |cffffffff- Show the bingo card window.")
    print("|cffFFFFE0/psb |cffADFF2Fhide |cffffffff- Hide the bingo card window.")
    print("|cffFFFFE0/psb |cffADFF2Fresetcards |cffffffff- Reset all saved cards back to the default.")
    print("|cffFFFFE0/psb |cffADFF2Fresetsettings |cffffffff- Reset all settings back to the default.")
    print("|cffFFFFE0/psb |cffADFF2Fprintversion |cffffffff- Enable/Disable printing the addon version on load.")
    print("|cffFFFFE0/psb |cffADFF2Fdefaultcard |cff71C671<Card Name> |cffffffff- Sets the default card to load.")
    print("|cffFFFFE0/psb |cffADFF2Fscale |cff71C671<Number> |cffffffff- Scales the interface (default: 1).")
    print("|cffFFFFE0/psb |cffADFF2Flist |cffffffff- List all saved bingo cards.")
    print("|cffFFFFE0/psb |cffADFF2Fload |cff71C671<Card Name> |cffffffff- Load a card (case-sensitive).")
end

function Commands.load(args)
    if not args[2] then
        print("|cffff0000Error!|cffffffff You must specify a card name.|cff00ccff Example:|cffffffff '/psb load Default'")
        return
    end

    local cardName = GetRemainingArgs(args, 2)

    if Bingo:LoadBingoCard(cardName) then
        if not InCombatLockdown() then
            Bingo.BingoFrame:Show()
        end
    else
        print("|cffff0000Error!|cffffffff Card |cffFFFFE0'" .. cardName .. "'|cffffffff not found. Use '/psb list' to see available cards.")
    end
end

function Commands.list()
    print("|cffFFC125Bingo cards:")
    for name in pairs(BingoCards) do
        print("  - " .. name)
    end
end

function Commands.scale(args)
    local value = args[2]

    if not value or not value:match("%d+") then
        print("|cffff0000Error!|cffffffff Invalid scale value.|cff00ccff Example:|cffffffff '/psb scale 1.5'")
        return
    end

    BingoSettings.Scale = tonumber(value)
    Bingo.BingoFrame:SetScale(BingoSettings.Scale)
    print("|cffFFC125Bingo:|cffffffff Scale set to " .. value)
end

function Commands.printversion()
    BingoSettings.PrintVersionOnLoad = not BingoSettings.PrintVersionOnLoad
    local status = BingoSettings.PrintVersionOnLoad and "|cff00ff00Enabled" or "|cffff0000Disabled"
    print("|cffFFC125Bingo:|cffffffff Print version on load " .. status)
end

function Commands.defaultcard(args)
    if not args[2] then
        print("|cffff0000Error!|cffffffff You must specify a card name.|cff00ccff Example:|cffffffff '/psb defaultcard Default'")
        return
    end

    local cardName = args[2]

    if BingoCards[cardName] then
        BingoSettings.DefaultCard = cardName
        print("|cffFFC125Bingo:|cffffffff Default card set to |cffFFFFE0'" .. cardName .. "'")
    else
        print("|cffff0000Error!|cffffffff Card |cffFFFFE0'" .. cardName .. "'|cffffffff not found. Use '/psb list' to see available cards.")
    end
end

function Commands.resetcards()
    Bingo.LoadDefaultBingoCards()
    print("|cffff6060Bingo cards have been reset.")
end

function Commands.resetsettings()
    Bingo.LoadDefaultSettings()
    Bingo.BingoFrame:SetScale(BingoSettings.Scale)
    print("|cffff6060Bingo settings have been reset.")
end

function Commands.show()
    if InCombatLockdown() then
        print("|cffff0000Error!|cffffffff Cannot show bingo frame during combat.")
        return
    end
    Bingo.BingoFrame:Show()
end

function Commands.hide()
    if InCombatLockdown() then
        print("|cffff0000Error!|cffffffff Cannot hide bingo frame during combat.")
        return
    end
    Bingo.BingoFrame:Hide()
end

function Commands.version()
    print("|cffFFC125" .. Bingo.ADDON_NAME .. "|cffffffff version: " .. Bingo.VERSION)
end

-- Main slash command handler
local function SlashCmdHandler(message)
    local args = ParseArgs(strtrim(message or ""))
    local cmd = strlower(args[1] or "")

    if cmd == "" then
        -- Toggle visibility
        if InCombatLockdown() then
            print("|cffff0000Error!|cffffffff Cannot toggle bingo frame during combat.")
            return
        end

        if Bingo.BingoFrame:IsShown() then
            Bingo.BingoFrame:Hide()
        else
            Bingo.BingoFrame:Show()
        end
    elseif Commands[cmd] then
        Commands[cmd](args)
    else
        print("|cffff0000Error!|cffffffff Unknown command |cffFFFFE0'" .. cmd .. "'|cffffffff. Use '/psb help' for a list of commands.")
    end
end

-- Register slash commands
SlashCmdList[strupper(Bingo.ADDON_NAME)] = SlashCmdHandler
SLASH_PARTYSHARKBINGO1 = "/psbingo"
SLASH_PARTYSHARKBINGO2 = "/psb"
