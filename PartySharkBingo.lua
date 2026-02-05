local addonName, ns = ...

local FONT_PATH = "Interface\\AddOns\\PartySharkBingo\\media\\fonts\\PTSansNarrow-Bold.ttf"

local Bingo = {
    ADDON_NAME = addonName,
    BingoButtons = {},
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
            TitleSize = 18,
            FontSize = 16,
            FreeSpace = "Free",
            FreeSpaceSize = 14,
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
            Size8 = 12,
            [9] = "Shut up Grun",
            [10] = "Rezy Get's Bullied",
            [11] = "Rez Dissar",
            Size11 = 16,
            [12] = "Missed Consumes",
            Size12 = 12,
            [13] = "Addon Out of Date",
            [14] = "Vibekiller Enters the Chat",
            Size14 = 14,
            [15] = "Yuhbarrel Speaks at 2.5x",
            Size15 = 13,
            [16] = "Bug Mentioned",
            Size16 = 12,
            [17] = "Tenc Stalks",
            [18] = "Muted",
            Size18 = 16,
            [19] = "Raidlead Hijacked",
            Size19 = 14,
            [20] = "Braainss' Vacation",
            Size20 = 14,
            [21] = "Last Pull Magic",
            [22] = "Substances Mentioned",
            Size22 = 10,
            [23] = "Tenc 'Inspiring' Speech",
            Size23 = 12,
            [24] = "Soak",
            Size24 = 20,
            [25] = "Pull Jinxed",
            [26] = "Don't Die to X; Dies to X",
            Size26 = 11,
        }
    }
end

function Bingo.EventHandler(_, event, addon_name)
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
    self.BingoFrameCloseButton:SetPoint("TOPRIGHT", -2, -2)
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

    -- Add reset all button to the main frame
    self.ResetAllButton = CreateFrame("Button", "BingoResetAllButton", self.BingoFrame, "UIPanelButtonTemplate")
    self.ResetAllButton:SetSize(70, 25)
    self.ResetAllButton:SetPoint("TOPLEFT", 15, -15)
    self.ResetAllButton:SetText("Reset All")
    self.ResetAllButton:SetScript("OnClick", function()
        StaticPopup_Show("BINGO_RESETALL_DIALOG")
    end)

    -- Add import button to the main frame
    self.ImportButton = CreateFrame("Button", "BingoImportButton", self.BingoFrame, "UIPanelButtonTemplate")
    self.ImportButton:SetSize(70, 25)
    self.ImportButton:SetPoint("TOPLEFT", 90, -15)
    self.ImportButton:SetText("Import")
    self.ImportButton:SetScript("OnClick", function()
        self.BingoEditBox:SetText("")
        self.BingoSaveButton:Show()
        self.BingoSelectAllButton:Hide()
        self.BingoFrame:Hide()
        self.BingoEditFrame:Show()
    end)

    -- Add export button to the main frame
    self.ExportButton = CreateFrame("Button", "BingoExportButton", self.BingoFrame, "UIPanelButtonTemplate")
    self.ExportButton:SetSize(70, 25)
    self.ExportButton:SetPoint("TOPLEFT", 165, -15)
    self.ExportButton:SetText("Export")
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

    -- Add shuffle button to the main frame
    self.ShuffleButton = CreateFrame("Button", "BingoShuffleButton", self.BingoFrame, "UIPanelButtonTemplate")
    self.ShuffleButton:SetSize(70, 25)
    self.ShuffleButton:SetPoint("TOPLEFT", 240, -15)
    self.ShuffleButton:SetText("Shuffle")
    self.ShuffleButton:SetScript("OnClick", function()
        StaticPopup_Show("BINGO_SHUFFLE_DIALOG")
    end)

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
        {name = "Diagonal ╲ ", indices = {1, 7, 13, 19, 25}},
        {name = "Diagonal ╱ ", indices = {5, 9, 13, 17, 21}},
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

Bingo:Init()
