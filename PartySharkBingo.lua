local addonName, ns = ...

local FONT_PATH = "Interface\\AddOns\\PartySharkBingo\\media\\fonts\\PTSansNarrow-Bold.ttf"

-- Feature flags
local SHOW_IMPORT_EXPORT_BUTTONS = false

-- Addon message constants
local ADDON_MSG_PREFIX = "PSBINGO"

-- Session leader is determined by character name
local IS_SESSION_LEADER = (UnitName("player") == "Yvairel")

-- Create a styled button that matches our dark UI theme
local function CreateStyledButton(parent, name, width, height, text)
    local button = CreateFrame("Button", name, parent, BackdropTemplateMixin and "BackdropTemplate")
    button:SetSize(width, height)

    -- Dark background with border
    button:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    button:SetBackdropColor(0.15, 0.15, 0.15, 1)
    button:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    -- Button text
    button.text = button:CreateFontString(nil, "OVERLAY")
    button.text:SetFont(FONT_PATH, 14, "OUTLINE")
    button.text:SetPoint("CENTER", 0, 0)
    button.text:SetText(text)
    button.text:SetTextColor(1, 0.82, 0, 1) -- Gold color

    -- Hover effect
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.25, 0.25, 1)
        self:SetBackdropBorderColor(1, 0.82, 0, 1) -- Gold border on hover
    end)

    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
        self:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end)

    -- Click effect
    button:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.1, 0.1, 0.1, 1)
        self.text:SetPoint("CENTER", 1, -1)
    end)

    button:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(0.25, 0.25, 0.25, 1)
        self.text:SetPoint("CENTER", 0, 0)
    end)

    return button
end

local Bingo = {
    ADDON_NAME = addonName,
    BingoButtons = {},
    IsSessionLocked = false,
    SessionLockedBy = nil,
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

-- Export Bingo to namespace for other files
ns.Bingo = Bingo

function Bingo:Init()
    self.VERSION = C_AddOns.GetAddOnMetadata(self.ADDON_NAME, "Version")
    self.WasShownBeforeCombat = false
    self.currentCardName = nil

    self:CreateFrames()
    self:CreateButtons()
    self.BingoFrame:Show()
end

function Bingo.LoadDefaultSettings()
    BingoSettings = {
        PrintVersionOnLoad = false,
        Scale = 1,
        DefaultCard = "Default",
        LoadOnImport = true
    }
end

--[[
    Bingo Card Format
    =================

    Required Fields:
        Title           - Card title displayed at top (string)
        [1] to [N]      - Bingo square text entries (need at least 24)

    Optional Fields:
        TitleSize       - Font size for title (default: 20)
        FontSize        - Default font size for all squares (default: 10)
        FreeSpace       - Text for center free space (default: "Free Space")
        FreeSpaceSize   - Font size for free space (default: FontSize)
        Size[N]         - Override font size for specific square N (e.g., Size7 = 14)

    Current Squares:
    ----------------
    1.  Guess Who Died
    2.  Game Crash
    3.  Tech Support
    4.  Clear Comms
    5.  Rich People Talk
    6.  Plane Delays Nash
    7.  <Vod Review>
    8.  HR Requested
    9.  Shut up Grun
    10. Rezy Get's Bullied
    11. Rez Dissar
    12. Missed Consumes
    13. Addon Out of Date
    14. Vibekiller Enters the Chat
    15. Yuhbarrel Speaks at 2.5x
    16. Bug Mentioned
    17. Tenc Stalks
    18. Muted
    19. Raidlead Hijacked
    20. Braainss' Vacation
    21. Last Pull Magic
    22. Substances Mentioned
    23. Tenc 'Inspiring' Speech
    24. Soak
    25. Pull Jinxed
    26. Don't Die to X; Dies to X
]]
function Bingo.LoadDefaultBingoCards()
    BingoCards = {
        Default = {
            Title = "Party Shark 25k Raid Week Bingo",
            TitleSize = 24,
            FontSize = 18,
            FreeSpace = "Free",
            FreeSpaceSize = 26,
            [1] = "Guess Who Died",
            [2] = "Game Crash",
            Size2 = 16,
            [3] = "Tech Support",
            [4] = "Clear Comms",
            [5] = "Rich People Talk",
            [6] = "Plane Delays Nash",
            [7] = "<Vod Review>",
            Size7 = 14,
            [8] = "HR Requested",
            Size8 = 14,
            [9] = "Shut up Grun",
            [10] = "Rezy Get's Bullied",
            [11] = "Rez Dissar",
            Size11 = 20,
            [12] = "Missed Consumes",
            Size12 = 13,
            [13] = "Addon Out of Date",
            [14] = "Vibekiller Enters the Chat",
            Size14 = 14,
            [15] = "Yuhbarrel Speaks at 2.5x",
            Size15 = 13,
            [16] = "Bug Mentioned",
            Size16 = 12,
            [17] = "Tenc Stalks",
            [18] = "Muted",
            Size18 = 24,
            [19] = "Raidlead Hijacked",
            Size19 = 14,
            [20] = "Braainss' Vacation",
            Size20 = 14,
            [21] = "Last Pull Magic",
            [22] = "Substances Mentioned",
            Size22 = 12,
            [23] = "Tenc 'Inspiring' Speech",
            Size23 = 14,
            [24] = "Soak",
            Size24 = 24,
            [25] = "Pull Jinxed",
            [26] = "Don't Die to X; Dies to X",
            Size26 = 14,
        }
    }
end

function Bingo.EventHandler(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix == ADDON_MSG_PREFIX then
            Bingo:HandleAddonMessage(message, sender)
        end
        return
    end

    local addon_name = ...
    if event == "ENCOUNTER_START" then
        Bingo.WasShownBeforeCombat = Bingo.BingoFrame:IsShown()
        if Bingo.WasShownBeforeCombat then
            Bingo.BingoFrame:Hide()
        end

    elseif event == "ENCOUNTER_END" then
        if Bingo.WasShownBeforeCombat and not InCombatLockdown() then
            Bingo.BingoFrame:Show()
            Bingo.WasShownBeforeCombat = false
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended, restore frame if it was hidden during encounter
        if Bingo.WasShownBeforeCombat then
            Bingo.BingoFrame:Show()
            Bingo.WasShownBeforeCombat = false
        end

    elseif event == "ADDON_LOADED" and addon_name == Bingo.ADDON_NAME then
        if not BingoSettings then
            Bingo.LoadDefaultSettings()
        else
            Bingo.BingoFrame:SetScale(BingoSettings.Scale)
        end

        if not BingoCards then
            Bingo.LoadDefaultBingoCards()
        end

        if BingoSettings.PrintVersionOnLoad then
            print("|cffFFC125" .. Bingo.ADDON_NAME .. "|cffffffff " .. Bingo.VERSION .. "|cff00ff00 Loaded")
        end

        print("|cffFFC125" .. Bingo.ADDON_NAME .. "|cffffffff Loaded. Type /psbingo or /psb to open.")

        Bingo:LoadBingoCard(BingoSettings.DefaultCard or "Default")
    end
end

function Bingo:CreateFrames()
    -- Create main bingo frame aka the game frame
    self.BingoFrame = CreateFrame("Frame", "BingoFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    self.BingoFrame:Hide()

    -- Register events
    self.BingoFrame:SetScript("OnEvent", self.EventHandler)
    self.BingoFrame:SetScript("OnDragStart", self.BingoFrame.StartMoving)
    self.BingoFrame:SetScript("OnDragStop", self.BingoFrame.StopMovingOrSizing)
    self.BingoFrame:RegisterEvent("ADDON_LOADED")
    self.BingoFrame:RegisterEvent("ENCOUNTER_START")
    self.BingoFrame:RegisterEvent("ENCOUNTER_END")
    self.BingoFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.BingoFrame:RegisterEvent("CHAT_MSG_ADDON")

    -- Register addon message prefix for session locking
    C_ChatInfo.RegisterAddonMessagePrefix(ADDON_MSG_PREFIX)


    -- Customize main frame
    self.BingoFrame:SetFrameLevel(4)
    self.BingoFrame:SetMovable(true)
    self.BingoFrame:EnableMouse(true)
    self.BingoFrame:RegisterForDrag("LeftButton")

    self.BingoFrame:SetWidth(430)
    self.BingoFrame:SetHeight(500)
    self.BingoFrame:ClearAllPoints()
    self.BingoFrame:SetPoint("CENTER")
    if self.BingoFrame.SetBackdrop then
        self.BingoFrame:SetBackdrop(self.DefaultBackdrop)
        self.BingoFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        self.BingoFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end
    tinsert(UISpecialFrames, self.BingoFrame:GetName())

    -- Add bingo card title text to main frame
    self.BingoFrame.text = self.BingoFrame:CreateFontString(nil, "OVERLAY")
    self.BingoFrame.text:SetFont(FONT_PATH, 32, "OUTLINE")
    self.BingoFrame.text:SetPoint("TOPLEFT", 15, -55)
    self.BingoFrame.text:SetPoint("BOTTOMRIGHT", -15, 430)
    self.BingoFrame.text:SetText("Bingo!")

    -- Add close button to main frame
    self.BingoFrameCloseButton = CreateFrame("Button", "BingoFrameCloseButton", self.BingoFrame, "UIPanelCloseButton")
    self.BingoFrameCloseButton:SetPoint("TOPRIGHT", -6, -6)
    self.BingoFrameCloseButton:SetScript("OnClick", function()
        self.BingoFrame:Hide()
    end)

    -- Create confirmation popup for reset all button
    StaticPopupDialogs["BINGO_RESETALL_DIALOG"] = {
        text = "Are you sure you want to reset the bingo card?",
        button1 = YES,
        button2 = NO,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        enterClicksFirstButton = true,
        OnAccept = function()
            self:ResetBoard()
        end
    }

    -- Create confirmation popup for shuffle button
    StaticPopupDialogs["BINGO_SHUFFLE_DIALOG"] = {
        text = "Shuffling the bingo card will also reset all spaces, do you wish to continue?",
        button1 = YES,
        button2 = NO,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        enterClicksFirstButton = true,
        OnAccept = function()
            Bingo:LoadDefaultBingoCards()
            Bingo:ResetBoard()
            Bingo:LoadBingoCard(Bingo.CurrentBingoCard)
        end
    }

    -- Create toolbar buttons with dynamic positioning
    local BUTTON_WIDTH = 90
    local BUTTON_HEIGHT = 28
    local BUTTON_SPACING = 5
    local BUTTON_START_X = 15
    local BUTTON_Y = -12
    local nextButtonX = BUTTON_START_X

    -- Reset All button (always shown)
    self.ResetAllButton = CreateStyledButton(self.BingoFrame, "BingoResetAllButton", BUTTON_WIDTH, BUTTON_HEIGHT, "Reset All")
    self.ResetAllButton:SetPoint("TOPLEFT", nextButtonX, BUTTON_Y)
    self.ResetAllButton:SetScript("OnClick", function()
        if self:HasAnySquaresChecked() then
            StaticPopup_Show("BINGO_RESETALL_DIALOG")
        end
    end)
    nextButtonX = nextButtonX + BUTTON_WIDTH + BUTTON_SPACING

    -- Import button (controlled by SHOW_IMPORT_EXPORT_BUTTONS flag)
    if SHOW_IMPORT_EXPORT_BUTTONS then
        self.ImportButton = CreateStyledButton(self.BingoFrame, "BingoImportButton", BUTTON_WIDTH, BUTTON_HEIGHT, "Import")
        self.ImportButton:SetPoint("TOPLEFT", nextButtonX, BUTTON_Y)
        self.ImportButton:SetScript("OnClick", function()
            self.BingoEditBox:SetText("")
            self.BingoSaveButton:Show()
            self.BingoSelectAllButton:Hide()
            self.BingoFrame:Hide()
            self.BingoEditFrame:Show()
        end)
        nextButtonX = nextButtonX + BUTTON_WIDTH + BUTTON_SPACING
    end

    -- Export button (controlled by SHOW_IMPORT_EXPORT_BUTTONS flag)
    if SHOW_IMPORT_EXPORT_BUTTONS then
        self.ExportButton = CreateStyledButton(self.BingoFrame, "BingoExportButton", BUTTON_WIDTH, BUTTON_HEIGHT, "Export")
        self.ExportButton:SetPoint("TOPLEFT", nextButtonX, BUTTON_Y)
        self.ExportButton:SetScript("OnClick", function()
            if self.CurrentBingoCard then
                self.BingoEditBox:SetText(ns.serpent.block(BingoCards[self.CurrentBingoCard],
                    { sparse = true, comment = false }))
                self.BingoEditBox:HighlightText()
                self.BingoSaveButton:Hide()
                self.BingoSelectAllButton:Show()
                self.BingoFrame:Hide()
                self.BingoEditFrame:Show()
                self.BingoEditBox:SetFocus(true)
            else
                print("|cffff0000Error!|cffffffff Load a card before trying to export.")
            end
        end)
        nextButtonX = nextButtonX + BUTTON_WIDTH + BUTTON_SPACING
    end

    -- Shuffle button (always shown)
    self.ShuffleButton = CreateStyledButton(self.BingoFrame, "BingoShuffleButton", BUTTON_WIDTH, BUTTON_HEIGHT, "Shuffle")
    self.ShuffleButton:SetPoint("TOPLEFT", nextButtonX, BUTTON_Y)
    self.ShuffleButton:SetScript("OnClick", function()
        -- Check if session is locked
        if self.IsSessionLocked then
            print("|cffFFC125" .. self.ADDON_NAME .. "|cffff6060 Session is locked. Cannot shuffle.")
            return
        end

        if self:HasAnySquaresChecked() then
            StaticPopup_Show("BINGO_SHUFFLE_DIALOG")
        else
            -- No squares checked, shuffle without confirmation
            self:LoadDefaultBingoCards()
            self:ResetBoard()
            self:LoadBingoCard(self.CurrentBingoCard)
        end
    end)
    nextButtonX = nextButtonX + BUTTON_WIDTH + BUTTON_SPACING

    -- Session Lock/Unlock buttons (only for session leader)
    if IS_SESSION_LEADER then
        -- Lock button
        self.LockButton = CreateStyledButton(self.BingoFrame, "BingoLockButton", BUTTON_WIDTH, BUTTON_HEIGHT, "Lock")
        self.LockButton:SetPoint("TOPLEFT", nextButtonX, BUTTON_Y)
        self.LockButton:SetScript("OnClick", function()
            self:SendLockCommand(true)
        end)

        -- Unlock button (same position, initially hidden)
        self.UnlockButton = CreateStyledButton(self.BingoFrame, "BingoUnlockButton", BUTTON_WIDTH, BUTTON_HEIGHT, "Unlock")
        self.UnlockButton:SetPoint("TOPLEFT", nextButtonX, BUTTON_Y)
        self.UnlockButton:Hide()
        self.UnlockButton:SetScript("OnClick", function()
            self:SendLockCommand(false)
        end)
    else
        -- Lock indicator for followers (shown when session is locked)
        self.LockIndicator = self.BingoFrame:CreateFontString(nil, "OVERLAY")
        self.LockIndicator:SetFont(FONT_PATH, 12, "OUTLINE")
        self.LockIndicator:SetPoint("TOPLEFT", nextButtonX, BUTTON_Y - 6)
        self.LockIndicator:SetTextColor(1, 0.3, 0.3, 1)  -- Red color
        self.LockIndicator:SetText("Locked")
        self.LockIndicator:Hide()
    end

    -- Create the import/export frame
    self.BingoEditFrame = CreateFrame("Frame", "BingoEditFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    self.BingoEditFrame:SetScript("OnDragStart", self.BingoEditFrame.StartMoving)
    self.BingoEditFrame:SetScript("OnDragStop", self.BingoEditFrame.StopMovingOrSizing)

    self.BingoEditFrame:SetFrameLevel(40)
    self.BingoEditFrame:SetMovable(true)
    self.BingoEditFrame:EnableMouse(true)
    self.BingoEditFrame:RegisterForDrag("LeftButton")

    self.BingoEditFrame:SetPoint("CENTER")
    self.BingoEditFrame:SetWidth(400)
    self.BingoEditFrame:SetHeight(400)
    self.BingoEditFrame:SetResizable(true)
    if self.BingoEditFrame.SetBackdrop then
        self.BingoEditFrame:SetBackdrop(self.DefaultBackdrop)
        self.BingoEditFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        self.BingoEditFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end
    tinsert(UISpecialFrames, self.BingoEditFrame:GetName())

    -- Add a background for the text input area
    self.BingoEditBoxBackground = CreateFrame("Frame", "BingoEditBoxBackground", self.BingoEditFrame, BackdropTemplateMixin and "BackdropTemplate")
    self.BingoEditBoxBackground:SetPoint("TOPLEFT", 8, -8)
    self.BingoEditBoxBackground:SetPoint("BOTTOMRIGHT", -8, 45)
    self.BingoEditBoxBackground:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    self.BingoEditBoxBackground:SetBackdropColor(0, 0, 0, 1)
    self.BingoEditBoxBackground:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    -- Add a scroll frame to the import/export frame
    self.BingoScrollFrame = CreateFrame("ScrollFrame", "BingoScrollFrame", self.BingoEditBoxBackground,
        "UIPanelScrollFrameTemplate")
    self.BingoScrollFrame:SetPoint("TOPLEFT", 8, -8)
    self.BingoScrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)

    -- Add the edit box to the scroll frame
    self.BingoEditBox = CreateFrame("EditBox", "BingoEditBox", self.BingoScrollFrame)
    self.BingoEditBox:SetMultiLine(true)
    self.BingoEditBox:SetAutoFocus(false)
    self.BingoEditBox:SetFontObject("ChatFontNormal")
    self.BingoEditBox:SetScript("OnEscapePressed", function()
        self.BingoEditBox:ClearFocus()
    end)

    -- Set focus to edit box when user clicks on any part of the scroll frame
    self.BingoScrollFrame:SetScrollChild(self.BingoEditBox)
    self.BingoScrollFrame:SetScript("OnMouseDown", function()
        self.BingoEditBox:SetFocus(true)
    end)

    -- Adjust edit box width when edit frame is shown to make sure text will not go off frame
    self.BingoEditFrame:SetScript("OnShow", function()
        Bingo.BingoEditBox:SetWidth(Bingo.BingoScrollFrame:GetWidth())
    end)

    -- Create enter name popup before saving
    local saveCard = function(self)
        if (Bingo.BingoEditBox:GetText() == "") then
            print("|cffff0000Error!|cffffffff Can't save nothing.")
            return
        end

        local ok, card

        if (string.find(Bingo.BingoEditBox:GetText(), "{") and string.find(Bingo.BingoEditBox:GetText(), "}")) then
            ok, card = ns.serpent.load(Bingo.BingoEditBox:GetText())
        end

        if ok then
            BingoCards[self.EditBox:GetText()] = card
            Bingo.BingoEditFrame:Hide()
            Bingo.BingoFrame:Show()
            print("|cffFFC125" ..
                Bingo.ADDON_NAME .. "|cffffffff card |cffFFFFE0'" .. self.EditBox:GetText() .. "'|cffffffff saved.")
            if BingoSettings.LoadOnImport then
                Bingo.LoadBingoCard(self.EditBox:GetText())
            end
        else
            print("|cffff0000Error!|cffffffff Unable to save card |cffFFFFE0'" ..
                self.EditBox:GetText() .. "'|cffffffff, check the import string is properly formatted.")
        end
    end

    StaticPopupDialogs["BINGO_SAVE_DIALOG"] = {
        text = "Enter a name for this card.\n\n|cffff6060Entering an existing name will overwrite that card",
        button1 = SAVE,
        button2 = CANCEL,
        timeout = 0,
        whileDead = true,
        hasEditBox = true,
        autoFocus = true,
        OnAccept = saveCard,
        OnShow = function(self)
            if self.Buttons[1] then
                self.Buttons[1]:Disable()
            end
        end,
        EditBoxOnTextChanged = function(self)
            if (self:GetText() == "") then
                self:GetParent().Buttons[1]:Disable()
            else
                self:GetParent().Buttons[1]:Enable()
            end
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        EditBoxOnEnterPressed = function(self)
            if self:GetParent().Buttons[1]:IsEnabled() then
                saveCard(self:GetParent())
                self:GetParent():Hide()
            end
        end
    }

    -- Add close button to the import/export frame
    self.BingoCloseButton = CreateFrame("Button", "BingoCloseButton", self.BingoEditFrame, "UIPanelButtonTemplate")
    self.BingoCloseButton:SetSize(75, 20)
    self.BingoCloseButton:SetPoint("BOTTOMRIGHT", -75, 19)
    self.BingoCloseButton:SetText("Close")
    self.BingoCloseButton:SetScript("OnClick", function()
        self.BingoEditFrame:Hide()
        self.BingoFrame:Show()
    end)

    -- Add save button to the import/export frame
    self.BingoSaveButton = CreateFrame("Button", "BingoSaveButton", self.BingoEditFrame, "UIPanelButtonTemplate")
    self.BingoSaveButton:SetSize(75, 20)
    self.BingoSaveButton:SetPoint("BOTTOMLEFT", 75, 19)
    self.BingoSaveButton:SetText(SAVE)
    self.BingoSaveButton:SetScript("OnClick", function()
        self.BingoEditBox:ClearFocus()
        StaticPopup_Show("BINGO_SAVE_DIALOG")
    end)
    self.BingoSaveButton:Hide()

    -- Add select all button to the import/export frame
    self.BingoSelectAllButton = CreateFrame("Button", "BingoSelectAllButton", self.BingoEditFrame,
        "UIPanelButtonTemplate")
    self.BingoSelectAllButton:SetSize(75, 20)
    self.BingoSelectAllButton:SetPoint("BOTTOMLEFT", 75, 19)
    self.BingoSelectAllButton:SetText("Select All")
    self.BingoSelectAllButton:SetScript("OnClick", function()
        self.BingoEditBox:HighlightText()
    end)
    self.BingoSelectAllButton:Hide()

    -- Add resize button to the import/export frame
    self.BingoEditFrameResizeButton = CreateFrame("Button", "BingoEditFrameResizeButton", self.BingoEditFrame)
    self.BingoEditFrameResizeButton:SetSize(16, 16)
    self.BingoEditFrameResizeButton:SetPoint("BOTTOMRIGHT", -9, 8)

    self.BingoEditFrameResizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    self.BingoEditFrameResizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    self.BingoEditFrameResizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    self.BingoEditFrameResizeButton:SetScript("OnMouseDown", function(self, button)
        if (button == "LeftButton") then
            Bingo.BingoEditFrame:StartSizing("BOTTOMRIGHT")
            self:GetHighlightTexture():Hide()
        end
    end)
    self.BingoEditFrameResizeButton:SetScript("OnMouseUp", function(self, button)
        if (button == "LeftButton") then
            self:GetHighlightTexture():Show()
            Bingo.BingoEditFrame:StopMovingOrSizing()
            Bingo.BingoEditBox:SetWidth(Bingo.BingoScrollFrame:GetWidth())
        end
    end)

    -- Create confirmation popup for when game is won
    StaticPopupDialogs["BINGO_WIN_DIALOG"] = {
        text = "|cffFFC125BINGO!|cffffffff Congratulations, you won! Would you like to reset the card?",
        button1 = YES,
        button2 = NO,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        enterClicksFirstButton = true,
        OnAccept = function()
            self:ResetBoard()
        end
    }

    self.CreateFrame = function() end
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
    if not BingoCards[cardName]['persisted'] then
        local persistedBoard = {}

        for i, button in pairs(self.BingoButtons) do
            persistedBoard[i] = {}
            persistedBoard[i]['name'] = button.name
            persistedBoard[i]['enabled'] = not button.isChecked
        end

        BingoCards[cardName]['persisted'] = persistedBoard
    else
        BingoCards[cardName]['persisted'][index]['enabled'] = false
    end
end

function Bingo:RemoveSavedBingoCard(cardName)
    BingoCards[cardName]['persisted'] = nil
end

function Bingo:SetButtonChecked(button, checked)
    button.isChecked = checked
    if checked then
        button:SetNormalTexture("Interface\\AddOns\\PartySharkBingo\\Imgs\\ButtonDisabled.tga")
    else
        button:SetNormalTexture("Interface\\AddOns\\PartySharkBingo\\Imgs\\ButtonNormal.tga")
    end
end

function Bingo:IsButtonChecked(button)
    return button.isChecked
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

function Bingo:CreateButton(x, y, name)
    local bingoButton

    bingoButton = CreateFrame("Button", name, self.BingoFrame, "UIPanelButtonTemplate")
    bingoButton:SetSize(80, 80)
    bingoButton:SetPoint("TOPLEFT", x, y)
    bingoButton.isChecked = false

    bingoButton:SetNormalTexture("Interface\\AddOns\\PartySharkBingo\\Imgs\\ButtonNormal.tga")
    bingoButton:SetPushedTexture("Interface\\AddOns\\PartySharkBingo\\Imgs\\ButtonPushed.tga")
    bingoButton:SetHighlightTexture("Interface\\AddOns\\PartySharkBingo\\Imgs\\ButtonHighlight.tga")
    bingoButton:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)

    bingoButton.text = bingoButton:CreateFontString(nil, "OVERLAY")
    bingoButton.text:SetFont(FONT_PATH, 10, "OUTLINE")
    bingoButton.text:SetPoint("TOPLEFT", 5, -5)
    bingoButton.text:SetPoint("BOTTOMRIGHT", -5, 5)

    bingoButton:SetScript("OnClick", function(self, button)
        if bingoButton.isChecked then
            Bingo:SetButtonChecked(bingoButton, false)
            Bingo.CurrentBingoCardBingo = Bingo:CheckForBingo()
        else
            Bingo:SetButtonChecked(bingoButton, true)
            Bingo:SaveBingoCard(bingoButton.cardName, bingoButton.name, bingoButton.index)
            if not Bingo.CurrentBingoCardBingo then
                if Bingo:CheckForBingo() then
                    StaticPopup_Show("BINGO_WIN_DIALOG")
                end
            end
        end
    end)

    return bingoButton
end

function Bingo:CreateButtons()
    local buttonSize = 80
    local startX = 15
    local startY = -85
    local buttonIndex = 1

    -- Create a 5x5 grid of bingo buttons
    for row = 1, 5 do
        for col = 1, 5 do
            local x = startX + (col - 1) * buttonSize
            local y = startY - (row - 1) * buttonSize

            self.BingoButtons[buttonIndex] = self:CreateButton(x, y, "BingoButton" .. buttonIndex)
            self.BingoButtons[buttonIndex].index = buttonIndex
            buttonIndex = buttonIndex + 1
        end
    end

    self.CreateButton = function() end
    self.CreateButtons = function() end
end

function Bingo:LoadBingoCard(cardName)
    Bingo.currentCardName = cardName

    if BingoCards[cardName] then
        if BingoCards[cardName]['persisted'] then
            for i = 1, 25 do
                if not (i == 13) then
                    if not BingoCards[cardName]['persisted'][i] then
                        self:RemoveSavedBingoCard()
                        self:LoadBingoCard(cardName)
                        print('Saved Bingo Card was corrupt, resetting.')
                    else
                        self:LoadButton(
                            cardName,
                            i,
                            BingoCards[cardName]['persisted'][i]['name'],
                            BingoCards[cardName]['persisted'][i]['enabled']
                        )
                    end
                end
            end
        else
            local bingoSpaces = {}

            -- For each index of type number ([x] = y), add to our list of possible draws
            for index, _ in pairs(BingoCards[cardName]) do
                if type(index) == "number" then
                    tinsert(bingoSpaces, index)
                end
            end

            -- Ensure we have enough Bingo Cards to play
            if #bingoSpaces < 24 then
                print("|cffff6060Not enough bingo cards to generate a board (need 24).|r")
                return
            end

            -- Shuffle the Cards: Fisher–Yates shuffle
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

        -- Load card title
        self.BingoFrame.text:SetFont(FONT_PATH, BingoCards[cardName]["TitleSize"] or 20, "OUTLINE")
        self.BingoFrame.text:SetText(BingoCards[cardName]["Title"] or "Bingo!")

        -- Set center/free button text and size
        self.BingoButtons[13].text:SetText(BingoCards[cardName]["FreeSpace"] or "Free Space")
        self.BingoButtons[13].text:SetFont(FONT_PATH,
            (BingoCards[cardName]["FreeSpaceSize"] or BingoCards[cardName]["Size25"] or BingoCards[cardName]["FontSize"] or 10),
            "OUTLINE")
        self:SetButtonChecked(self.BingoButtons[13], true)
        self.BingoButtons[13]:Disable()

        self.CurrentBingoCard = cardName
        self.CurrentBingoCardBingo = false

        return true
    else
        return false
    end
end

function Bingo:LoadButton(cardName, buttonID, cardID, enabled)
    local text = BingoCards[cardName][cardID]
    if (text and (type(text) == "string")) then
        text = text
    else
        text = cardID
    end

    self.BingoButtons[buttonID].cardName = cardName
    self.BingoButtons[buttonID].name = text

    self.BingoButtons[buttonID].text:SetText(text)
    self.BingoButtons[buttonID].text:SetFont(FONT_PATH,
        (BingoCards[cardName]["Size" .. cardID] or BingoCards[cardName]["FontSize"] or 10), "OUTLINE")
    self:SetButtonChecked(self.BingoButtons[buttonID], not enabled)
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

    for _, index in ipairs(winningIndices) do
        local buttonName = self.BingoButtons[index].name
        if index == 13 then
            -- Use the free space text for the center button
            buttonName = BingoCards[self.CurrentBingoCard]["FreeSpace"] or "Free Space"
        end
        tinsert(cardTexts, buttonName)
    end

    local playerName = UnitName("player")
    local message = playerName .. " got a bingo (" .. lineName .. ") with: " .. table.concat(cardTexts, ", ") .. "!"

    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        SendChatMessage(message, "INSTANCE_CHAT")
    elseif IsInRaid() then
        SendChatMessage(message, "RAID")
    elseif IsInGroup() then
        SendChatMessage(message, "PARTY")
    else
        print("|cffFFC125" .. message)
    end
end

-- Session locking methods
function Bingo:SendLockCommand(locked)
    local message = locked and "LOCK" or "UNLOCK"
    local channel

    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        channel = "INSTANCE_CHAT"
    elseif IsInRaid() then
        channel = "RAID"
    elseif IsInGroup() then
        channel = "PARTY"
    else
        -- Not in a group, just update local state
        return
    end

    C_ChatInfo.SendAddonMessage(ADDON_MSG_PREFIX, message, channel)
end

function Bingo:HandleAddonMessage(message, sender)
    -- Strip realm name from sender if present
    local senderName = strsplit("-", sender)

    if message == "LOCK" then
        self:SetSessionLocked(true, senderName)
    elseif message == "UNLOCK" then
        self:SetSessionLocked(false, nil)
    end
end

function Bingo:SetSessionLocked(locked, lockedBy)
    self.IsSessionLocked = locked
    self.SessionLockedBy = lockedBy
    self:UpdateShuffleButtonState()

    -- Toggle lock/unlock button visibility for leader
    if IS_SESSION_LEADER then
        if locked then
            if self.LockButton then self.LockButton:Hide() end
            if self.UnlockButton then self.UnlockButton:Show() end
        else
            if self.UnlockButton then self.UnlockButton:Hide() end
            if self.LockButton then self.LockButton:Show() end
        end
    end

    if locked then
        print("|cffFFC125" .. self.ADDON_NAME .. "|cffffffff Session locked by " .. (lockedBy or "leader") .. ". Shuffling disabled.")
    else
        print("|cffFFC125" .. self.ADDON_NAME .. "|cffffffff Session unlocked. Shuffling enabled.")
    end
end

function Bingo:UpdateShuffleButtonState()
    if not self.ShuffleButton then return end

    if self.IsSessionLocked then
        self.ShuffleButton:Disable()
        self.ShuffleButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        self.ShuffleButton.text:SetTextColor(0.5, 0.5, 0.5, 1)

        -- Show lock indicator (for non-leaders)
        if self.LockIndicator then
            self.LockIndicator:Show()
            self.LockIndicator:SetText("Locked by " .. (self.SessionLockedBy or "leader"))
        end
    else
        self.ShuffleButton:Enable()
        self.ShuffleButton:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        self.ShuffleButton.text:SetTextColor(1, 0.82, 0, 1)

        -- Hide lock indicator
        if self.LockIndicator then
            self.LockIndicator:Hide()
        end
    end
end

Bingo:Init()
