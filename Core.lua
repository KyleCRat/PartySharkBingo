local addonName, ns = ...

local FONT_PATH = "Interface\\AddOns\\PartySharkBingo\\media\\fonts\\PTSansNarrow-Bold.ttf"
local ADDON_MSG_PREFIX = "PSBINGO"

ns.FONT_PATH = FONT_PATH
ns.ADDON_MSG_PREFIX = ADDON_MSG_PREFIX

local Bingo

local function GetCurrentRealmName()
    local realm = GetNormalizedRealmName and GetNormalizedRealmName()
    if realm and realm ~= "" then
        return realm
    end

    realm = GetRealmName and GetRealmName()
    if realm and realm ~= "" then
        return realm:gsub("%s+", "")
    end

    return nil
end

local function NormalizeFullName(name)
    if not name or name == "" then
        return nil
    end

    if name:find("-", 1, true) then
        return name
    end

    local realm = GetCurrentRealmName()
    if realm and realm ~= "" then
        return name .. "-" .. realm
    end

    return name
end

-- Helper to get full name with realm (always includes realm for consistency)
local function GetFullUnitName(unit)
    local name, realm = UnitName(unit)
    if not name then return nil end
    if realm and realm ~= "" then
        return name .. "-" .. realm
    end
    return NormalizeFullName(name)
end

-- Check if any player name from a list is in the current group
local function IsAnyPlayerInGroup(players)
    if not IsInGroup() then
        return true
    end

    local playerName = UnitName("player")
    for _, name in ipairs(players) do
        if name == playerName then
            return true
        end
    end

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local memberName = UnitName("raid" .. i)
            if memberName then
                for _, name in ipairs(players) do
                    if name == memberName then
                        return true
                    end
                end
            end
        end
    else
        for i = 1, GetNumGroupMembers() - 1 do
            local memberName = UnitName("party" .. i)
            if memberName then
                for _, name in ipairs(players) do
                    if name == memberName then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function CanManageSession()
    if IsInRaid() then
        return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    end

    if IsInGroup() then
        return UnitIsGroupLeader("player")
    end

    return false
end

local function IsSessionOwner()
    local settings = Bingo and Bingo:GetSettings()
    local isLocked = Bingo and Bingo.IsSessionLocked
    local lockedBy = Bingo and Bingo.SessionLockedBy

    if settings then
        isLocked = isLocked or settings.IsSessionLocked
        lockedBy = lockedBy or settings.SessionLockedBy
    end

    if not isLocked or not lockedBy then
        return false
    end

    return NormalizeFullName(lockedBy) == GetFullUnitName("player")
end

local function GetGroupAddonChannel()
    if IsInRaid() then
        return "RAID"
    end

    if IsInGroup() then
        return "PARTY"
    end

    return nil
end

ns.GetFullUnitName = GetFullUnitName
ns.NormalizeFullName = NormalizeFullName
ns.CanManageSession = CanManageSession
ns.IsSessionOwner = IsSessionOwner

local DEFAULT_SETTINGS = {
    PrintVersionOnLoad = false,
    Scale = 1,
    DefaultCard = "Default",
    IsSessionLocked = false,
}

Bingo = {
    ADDON_NAME = addonName,
    BingoButtons = {},
    IsSessionLocked = false,
    SessionLockedBy = nil,
    SessionPlayers = {},
    WasInGroup = false,
    DefaultBackdrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileEdge = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    }
}

ns.Bingo = Bingo

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

local function BackfillDefaults(target, defaults)
    for key, defaultValue in pairs(defaults) do
        if target[key] == nil then
            target[key] = CopyDefaultValue(defaultValue)
        elseif type(target[key]) == "table" and type(defaultValue) == "table" then
            BackfillDefaults(target[key], defaultValue)
        end
    end
end

local function GetEntryValue(entry)
    if type(entry) == "table" then
        return entry.value
    end

    return entry
end

local function HasCardEntryValue(card, value)
    if value == nil then
        return false
    end

    for index, entry in pairs(card) do
        if type(index) == "number" and GetEntryValue(entry) == value then
            return true
        end
    end

    return false
end

local function GetNextCardIndex(card)
    local maxIndex = 0

    for index in pairs(card) do
        if type(index) == "number" and index > maxIndex then
            maxIndex = index
        end
    end

    return maxIndex + 1
end

local function BackfillBingoCard(card, defaultCard)
    for key, defaultValue in pairs(defaultCard) do
        if type(key) ~= "number" and key ~= "persisted" and card[key] == nil then
            card[key] = CopyDefaultValue(defaultValue)
        end
    end

    local nextIndex = GetNextCardIndex(card)
    for _, defaultEntry in ipairs(defaultCard) do
        if not HasCardEntryValue(card, GetEntryValue(defaultEntry)) then
            card[nextIndex] = CopyDefaultValue(defaultEntry)
            nextIndex = nextIndex + 1
        end
    end
end

function Bingo:Init()
    self.VERSION = C_AddOns.GetAddOnMetadata(self.ADDON_NAME, "Version")
    self.WasShownBeforeCombat = false
    self.currentCardName = nil

    self:CreateFrames()
    self:CreateButtons()
    self.BingoFrame:Show()
end

function Bingo.LoadDefaultSettings()
    BingoSettings = CopyDefaultValue(DEFAULT_SETTINGS)
    Bingo.Settings = BingoSettings

    return BingoSettings
end

function Bingo:EnsureSettings()
    if not BingoSettings then
        return Bingo.LoadDefaultSettings()
    end

    BackfillDefaults(BingoSettings, DEFAULT_SETTINGS)
    self.Settings = BingoSettings

    return BingoSettings
end

function Bingo:GetSettings()
    if BingoSettings then
        return BingoSettings
    end

    return DEFAULT_SETTINGS
end

function Bingo:EnsureBingoCards()
    if not BingoCards then
        return self.LoadDefaultBingoCards()
    end

    self.Cards = BingoCards

    if not self.GetDefaultBingoCards then
        return BingoCards
    end

    local defaultCards = self.GetDefaultBingoCards()
    for cardName, defaultCard in pairs(defaultCards) do
        if not BingoCards[cardName] then
            BingoCards[cardName] = CopyDefaultValue(defaultCard)
        else
            BackfillBingoCard(BingoCards[cardName], defaultCard)
        end
    end

    return BingoCards
end

function Bingo:GetCards()
    return BingoCards or self.Cards or {}
end

local function OnChatMessageAddon(_, prefix, message, channel, sender)
    if prefix == ADDON_MSG_PREFIX then
        Bingo:HandleAddonMessage(message, sender)
    end
end

local function OnEncounterStart()
    Bingo.InEncounter = true
    Bingo.WasShownBeforeCombat = Bingo.BingoFrame:IsShown()
    if Bingo.WasShownBeforeCombat then
        Bingo.BingoFrame:Hide()
    end
end

local function OnEncounterEnd()
    Bingo.InEncounter = false
    -- PLAYER_REGEN_ENABLED restores the frame once combat fully drops.
end

local function RestoreAfterCombat()
    if Bingo.WasShownBeforeCombat and not Bingo.InEncounter then
        Bingo.BingoFrame:Show()
        Bingo.WasShownBeforeCombat = false
    end
end

local function OnGroupRosterUpdate()
    Bingo:OnGroupRosterUpdate()
end

local function OnAddonLoaded(frame, loadedAddon)
    if loadedAddon ~= Bingo.ADDON_NAME then
        return
    end

    frame:UnregisterEvent("ADDON_LOADED")

    local settings = Bingo:EnsureSettings()
    Bingo:EnsureBingoCards()
    Bingo:SetScale(settings.Scale)

    if settings.PrintVersionOnLoad then
        print("|cffFFC125" .. Bingo.ADDON_NAME .. "|cffffffff " .. Bingo.VERSION .. "|cff00ff00 Loaded")
    end

    print("|cffFFC125" .. Bingo.ADDON_NAME .. "|cffffffff Loaded. Type /psbingo or /psb to open.")

    Bingo:LoadBingoCard(settings.DefaultCard or "Default")

    if settings.IsSessionLocked then
        if settings.SessionPlayers then
            Bingo.SessionPlayers = settings.SessionPlayers
        end
        Bingo:SetSessionLocked(settings.IsSessionLocked, settings.SessionLockedBy)
        Bingo:UpdateSessionPlayersDisplay()

        if IsSessionOwner() and IsInGroup() then
            Bingo:SendPingMessage()
        end
    elseif CanManageSession() and IsInGroup() and Bingo.StartButton then
        Bingo.StartButton:Show()
    end

    Bingo.WasInGroup = IsInGroup()
    Bingo:UpdateSessionRoleUI()
end

local EVENT_HANDLERS = {
    ADDON_LOADED = OnAddonLoaded,
    CHAT_MSG_ADDON = OnChatMessageAddon,
    ENCOUNTER_START = OnEncounterStart,
    ENCOUNTER_END = OnEncounterEnd,
    GROUP_ROSTER_UPDATE = OnGroupRosterUpdate,
    PLAYER_ALIVE = RestoreAfterCombat,
    PLAYER_REGEN_ENABLED = RestoreAfterCombat,
    PLAYER_UNGHOST = RestoreAfterCombat,
}

function Bingo.EventHandler(frame, event, ...)
    local handler = EVENT_HANDLERS[event]
    if handler then
        handler(frame, ...)
    end
end

function Bingo:ResetBoard()
    for _, b in pairs(self.BingoButtons) do
        self:SetButtonChecked(b, false)
    end

    -- Center free space is always checked and disabled
    self:SetButtonChecked(self.BingoButtons[13], true)
    self.BingoButtons[13]:Disable()

    self:RemoveSavedBingoCard(self.currentCardName)
    self.CurrentBingoCardBingo = false
end

function Bingo:SaveBingoCard(cardName, name, index)
    local cards = self:GetCards()
    if not cards[cardName] then return end

    if not cards[cardName]['persisted'] then
        local persistedBoard = {}

        for i, button in pairs(self.BingoButtons) do
            persistedBoard[i] = {}
            persistedBoard[i]['name'] = button.name
            persistedBoard[i]['enabled'] = not button.isChecked
        end

        cards[cardName]['persisted'] = persistedBoard
    else
        cards[cardName]['persisted'][index]['enabled'] = false
    end
end

function Bingo:RemoveSavedBingoCard(cardName)
    local cards = self:GetCards()
    if cards[cardName] then
        cards[cardName]['persisted'] = nil
    end
end

function Bingo:HasAnySquaresChecked()
    for i, button in pairs(self.BingoButtons) do
        -- Skip the free space (center button)
        if i ~= 13 and button.isChecked then
            return true
        end
    end

    return false
end

function Bingo:LoadBingoCard(cardName)
    Bingo.currentCardName = cardName
    local cards = self:GetCards()

    if cards[cardName] then
        if cards[cardName]['persisted'] then
            for i = 1, 25 do
                if not (i == 13) then
                    if not cards[cardName]['persisted'][i] then
                        print('Saved Bingo Card was corrupt, resetting.')
                        self:RemoveSavedBingoCard(cardName)
                        return self:LoadBingoCard(cardName)
                    else
                        local persisted = cards[cardName]['persisted'][i]
                        self:LoadButton(
                            cardName,
                            i,
                            persisted['name'],
                            persisted['enabled']
                        )
                    end
                end
            end
        else
            local bingoSpaces = {}

            -- For each index of type number ([x] = y), add to our list of possible draws
            -- Skip player-specific tiles if none of their players are in the group
            for index, entry in pairs(cards[cardName]) do
                if type(index) == "number" then
                    if not entry.players or IsAnyPlayerInGroup(entry.players) then
                        tinsert(bingoSpaces, index)
                    end
                end
            end

            -- Ensure we have enough Bingo Cards to play
            if #bingoSpaces < 24 then
                print("|cffff6060Not enough bingo cards to generate a board (need 24).|r")
                return
            end

            -- Shuffle the Cards: Fisher-Yates shuffle
            for i = #bingoSpaces, 2, -1 do
                local j = math.random(i)
                bingoSpaces[i], bingoSpaces[j] = bingoSpaces[j], bingoSpaces[i]
            end

            local cardIndex = 1
            for i = 1, 25 do
                if i ~= 13 then
                    self:LoadButton(cardName, i, bingoSpaces[cardIndex], true)
                    cardIndex = cardIndex + 1
                end
            end
        end

        self:SetCardTitle(cardName)
        self:SetFreeSpace(cardName)

        self.CurrentBingoCard = cardName
        self.CurrentBingoCardBingo = false

        return true
    else
        return false
    end
end

function Bingo:CheckLine(indices)
    for _, index in ipairs(indices) do
        if not self.BingoButtons[index].isChecked then
            return false
        end
    end
    return true
end

function Bingo:CheckForBingo()
    local lines = {
        -- Horizontal lines
        {name = "Row 1", indices = {1, 2, 3, 4, 5}},
        {name = "Row 2", indices = {6, 7, 8, 9, 10}},
        {name = "Row 3", indices = {11, 12, 13, 14, 15}},
        {name = "Row 4", indices = {16, 17, 18, 19, 20}},
        {name = "Row 5", indices = {21, 22, 23, 24, 25}},
        -- Vertical lines
        {name = "Column 1", indices = {1, 6, 11, 16, 21}},
        {name = "Column 2", indices = {2, 7, 12, 17, 22}},
        {name = "Column 3", indices = {3, 8, 13, 18, 23}},
        {name = "Column 4", indices = {4, 9, 14, 19, 24}},
        {name = "Column 5", indices = {5, 10, 15, 20, 25}},
        -- Diagonal lines
        {name = "Diagonal \\ ", indices = {1, 7, 13, 19, 25}},
        {name = "Diagonal / ", indices = {5, 9, 13, 17, 21}},
        -- Four corners
        {name = "Four Corners", indices = {1, 5, 21, 25}},
    }

    for _, line in ipairs(lines) do
        if self:CheckLine(line.indices) then
            self.CurrentBingoCardBingo = true
            self:AnnounceBingo(line.indices, line.name)
            return true
        end
    end

    return false
end

function Bingo:AnnounceBingo(winningIndices, lineName)
    local cardTexts = {}
    local cards = self:GetCards()

    for _, index in ipairs(winningIndices) do
        local buttonName = self.BingoButtons[index].name
        if index == 13 then
            -- Use the free space text for the center button
            local card = cards[self.CurrentBingoCard] or {}
            buttonName = card["FreeSpace"] or "Free Space"
        end
        tinsert(cardTexts, buttonName)
    end

    local playerName = UnitName("player")
    local message = playerName .. " got a bingo (" .. lineName .. ") with: " .. table.concat(cardTexts, ", ") .. "!"

    -- Only announce to group if in a session
    if self.IsSessionLocked then
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            SendChatMessage(message, "INSTANCE_CHAT")
        elseif IsInRaid() then
            SendChatMessage(message, "RAID")
        elseif IsInGroup() then
            SendChatMessage(message, "PARTY")
        end
    end
end

-- Session locking methods
function Bingo:SendLockCommand(locked)
    local message = locked and "LOCK" or "UNLOCK"
    self:SendSessionMessage(message)
end

function Bingo:GetClassColoredName(fullName)
    -- Try to find the player in raid or party
    local unit

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            if GetFullUnitName("raid" .. i) == fullName then
                unit = "raid" .. i
                break
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            if GetFullUnitName("party" .. i) == fullName then
                unit = "party" .. i
                break
            end
        end
    end

    if unit then
        local _, class = UnitClass(unit)
        if class then
            local color = C_ClassColor.GetClassColor(class)
            if color then
                return color:WrapTextInColorCode(fullName)
            end
        end
    end

    return fullName
end

function Bingo:HandleAddonMessage(message, sender)
    local senderFullName = NormalizeFullName(sender)
    if not senderFullName then return end

    local isSessionOwner = IsSessionOwner()
    local isFromSelf = senderFullName == GetFullUnitName("player")
    local isFromCurrentOwner = self.IsSessionLocked and senderFullName == self.SessionLockedBy

    if message == "PING" and not isSessionOwner then
        -- Leader is requesting session status from all players
        if self.IsSessionLocked then
            self:SendJoinMessage()
        else
            self:SendNoSessionMessage()
        end
    elseif message == "LOCK" then
        self:SetSessionLocked(true, senderFullName)
        -- Send JOIN response to the session owner.
        if not isFromSelf then
            self:SendJoinMessage()
        end
    elseif message == "UNLOCK" and isFromCurrentOwner then
        self:SetSessionLocked(false, nil)
    elseif message == "JOIN" and isSessionOwner then
        if not self.IsSessionLocked then
            -- Leader has no active session, send UNLOCK to release the follower
            self:SendLockCommand(false)
            return
        end
        -- Only announce if they weren't already in the session (avoids duplicate messages on reload)
        if self.SessionPlayers[senderFullName] ~= true then
            local coloredName = self:GetClassColoredName(senderFullName)
            print("|cffFFC125" .. self.ADDON_NAME .. "|cffffffff " .. coloredName .. " joined the session.")
        end
        self:AddSessionPlayer(senderFullName)
    elseif message == "LEAVE" and isSessionOwner then
        local coloredName = self:GetClassColoredName(senderFullName)
        print("|cffFFC125" .. self.ADDON_NAME .. "|cffffffff " .. coloredName .. " left the session.")
        self:RemoveSessionPlayer(senderFullName)
    elseif message == "NOSESSION" and isSessionOwner then
        local coloredName = self:GetClassColoredName(senderFullName)
        -- Remove from session if they were in it (they left while out of group)
        if self.SessionPlayers[senderFullName] then
            print("|cffFFC125" .. self.ADDON_NAME .. "|cffff3333 |TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:0|t " .. coloredName .. " is no longer in the session!")
            self:RemoveSessionPlayer(senderFullName)
        elseif self.IsSessionLocked then
            -- Only announce "not in session" if they weren't previously in it
            print("|cffFFC125" .. self.ADDON_NAME .. "|cffffffff " .. coloredName .. " has joined the party and is not in the session!")
        end
    elseif message == "SHUFFLE" and isFromCurrentOwner then
        -- Leader has requested all boards be shuffled
        self:LoadDefaultBingoCards()
        self:ResetBoard()
        self:LoadBingoCard(self.CurrentBingoCard)
        if IsSessionOwner() then
            print("|cffFFC125" .. self.ADDON_NAME .. "|cffffffff Shuffled all boards in the session.")
        else
            print("|cffFFC125" .. self.ADDON_NAME .. "|cffffffff Your board has been shuffled by the session leader.")
        end
    end
end

function Bingo:SendSessionMessage(message)
    local channel = GetGroupAddonChannel()
    if channel then
        C_ChatInfo.SendAddonMessage(ADDON_MSG_PREFIX, message, channel)
    end
end

function Bingo:SendJoinMessage()
    self:SendSessionMessage("JOIN")
end

function Bingo:SendNoSessionMessage()
    self:SendSessionMessage("NOSESSION")
end

function Bingo:SendPingMessage()
    self:SendSessionMessage("PING")
end

function Bingo:SendShuffleMessage()
    self:SendSessionMessage("SHUFFLE")
end

function Bingo:ShuffleAllBoards()
    -- Send shuffle message to everyone (including self)
    self:SendShuffleMessage()
end

function Bingo:AddSessionPlayer(name)
    if not IsSessionOwner() then return end

    -- Add to session players list or confirm if pending
    if self.SessionPlayers[name] ~= true then
        self.SessionPlayers[name] = true
        self:EnsureSettings().SessionPlayers = self.SessionPlayers
        self:UpdateSessionPlayersDisplay()
    end
end

function Bingo:RemoveSessionPlayer(name)
    if not IsSessionOwner() then return end

    if self.SessionPlayers[name] then
        self.SessionPlayers[name] = nil
        self:EnsureSettings().SessionPlayers = self.SessionPlayers
        self:UpdateSessionPlayersDisplay()
    end
end

function Bingo:ClearSessionPlayers()
    self.SessionPlayers = {}
    self:EnsureSettings().SessionPlayers = nil
    self:UpdateSessionPlayersDisplay()
end

function Bingo:OnGroupRosterUpdate()
    local isInGroup = IsInGroup()
    local isSessionOwner = IsSessionOwner()
    local canManageSession = CanManageSession()

    -- Detect when we join a group
    if isInGroup and not self.WasInGroup then
        if self.IsSessionLocked and isSessionOwner then
            -- Session owner joined group with active session; get status from all players.
            self:SendPingMessage()
        elseif self.IsSessionLocked then
            -- We are in a session; confirm with the session owner.
            self:SendJoinMessage()
        else
            -- We are not in a session; notify any active owner in the group.
            self:SendNoSessionMessage()
            if canManageSession and self.StartButton then self.StartButton:Show() end
        end
    end

    -- Detect when we leave a group (leader only - hide Start button when solo)
    if not isInGroup and self.WasInGroup then
        if canManageSession and not self.IsSessionLocked then
            if self.StartButton then self.StartButton:Hide() end
        end
    end

    self.WasInGroup = isInGroup
    self:UpdateSessionRoleUI()
end

function Bingo:SetSessionLocked(locked, lockedBy)
    local wasAlreadyLocked = self.IsSessionLocked
    lockedBy = NormalizeFullName(lockedBy)
    local previousLockedBy = NormalizeFullName(self.SessionLockedBy)

    self.IsSessionLocked = locked
    self.SessionLockedBy = lockedBy

    -- Clear session players when ending a session
    if not locked then
        self:ClearSessionPlayers()
    end

    -- Persist lock state to saved variables
    local settings = self:EnsureSettings()
    settings.IsSessionLocked = locked
    settings.SessionLockedBy = lockedBy

    self:UpdateSessionRoleUI()

    if locked then
        if wasAlreadyLocked and previousLockedBy == lockedBy then
            if IsSessionOwner() then
                print("|cffFFC125" .. self.ADDON_NAME .. "|cffffffff Adding players to session.")
            end
        elseif wasAlreadyLocked then
            print("|cffFFC125" .. self.ADDON_NAME .. "|cffffffff Session Started by " .. (lockedBy or "leader") .. ", Boards are locked!")
        else
            print("|cffFFC125" .. self.ADDON_NAME .. "|cffffffff Session Started by " .. (lockedBy or "leader") .. ", Boards are locked!")
        end
    elseif wasAlreadyLocked then
        print("|cffFFC125" .. self.ADDON_NAME .. "|cffffffff Session ended.")
    end
end

function Bingo:LeaveSession()
    -- Notify the session owner when a group channel is available.
    self:SendSessionMessage("LEAVE")

    -- Clear local lock state
    self.IsSessionLocked = false
    self.SessionLockedBy = nil
    self:ClearSessionPlayers()

    -- Persist and hide leave button
    local settings = self:EnsureSettings()
    settings.IsSessionLocked = false
    settings.SessionLockedBy = nil
    self:UpdateSessionRoleUI()

    print("|cffFFC125" .. self.ADDON_NAME .. "|cffffffff You left the session.")
end
