local _, ns = ...
local Bingo = ns.Bingo
local FONT_PATH = ns.FONT_PATH
local ADDON_MSG_PREFIX = ns.ADDON_MSG_PREFIX
local CanManageSession = ns.CanManageSession
local IsSessionOwner = ns.IsSessionOwner

local UI = ns.UI or {}
ns.UI = UI

local SCALE_MIN = 50
local SCALE_MAX = 150
local SCALE_STEP = 5
local SCALE_BUTTON_WIDTH = 90
local SCALE_BUTTON_HEIGHT = 28
local BOARD_LEFT_X = 0
local BINGO_BUTTON_SIZE = 80
local BINGO_BUTTON_SPACING = 1
local BINGO_BOARD_SIZE = BINGO_BUTTON_SIZE * 5 + BINGO_BUTTON_SPACING * 4
local BINGO_FRAME_WIDTH = BINGO_BOARD_SIZE + 30
local BINGO_FRAME_HEIGHT = BINGO_BOARD_SIZE + 100
local BINGO_BUTTON_TEXT_PADDING = 5
local BINGO_BUTTON_MIN_FONT_SIZE = 8
local BINGO_BUTTON_MAX_FONT_SIZE = 28
local BINGO_TILE_FONT_FLAGS = "OUTLINE, SLUG"
local BINGO_TILE_TEXTURES = {
    cell = "Interface\\AddOns\\PartySharkBingo\\Imgs\\Cell.tga",
    glow = "Interface\\AddOns\\PartySharkBingo\\Imgs\\CellOuterGlow.tga",
    mark = "Interface\\AddOns\\PartySharkBingo\\Imgs\\Mark.tga",
}
local FONT_FIT_WIDTH_FUDGE = 6
local FONT_FIT_HEIGHT_FUDGE = 6
local FONT_MEASURE_WIDTH = 10000
local TILE_PREVIEW_COLUMNS = 8
local TILE_PREVIEW_PADDING = 15
local TILE_PREVIEW_SPACING = 7
local TILE_PREVIEW_TITLE_HEIGHT = 42
local FRAME_BORDER_TEXTURE = "Interface\\AddOns\\PartySharkBingo\\Imgs\\9SliceBorder.tga"
local FRAME_BORDER_SOURCE_SIZE = 1254
local FRAME_BORDER_CORNER_SIZE = 24
local FRAME_BACKGROUND_INSET = 8

local function SetupFrameBorderPiece(container, piece, setupInfo, pieceLayout)
    local coords = pieceLayout.texCoords
    piece:SetTexture(FRAME_BORDER_TEXTURE)
    piece:SetTexCoord(
        coords[1] / FRAME_BORDER_SOURCE_SIZE,
        coords[2] / FRAME_BORDER_SOURCE_SIZE,
        coords[3] / FRAME_BORDER_SOURCE_SIZE,
        coords[4] / FRAME_BORDER_SOURCE_SIZE
    )
    piece:SetSize(FRAME_BORDER_CORNER_SIZE, FRAME_BORDER_CORNER_SIZE)
end

-- Source pixel coordinates omit the transparent margin and preserve the corner artwork.
local FRAME_BORDER_LAYOUT = {
    setupPieceVisualsFunction = SetupFrameBorderPiece,
    TopLeftCorner = { texCoords = { 46, 160, 56, 170 } },
    TopRightCorner = { texCoords = { 1094, 1208, 56, 170 } },
    BottomLeftCorner = { texCoords = { 46, 160, 1084, 1198 } },
    BottomRightCorner = { texCoords = { 1094, 1208, 1084, 1198 } },
    TopEdge = { texCoords = { 160, 1094, 56, 170 } },
    BottomEdge = { texCoords = { 160, 1094, 1084, 1198 } },
    LeftEdge = { texCoords = { 46, 160, 170, 1084 } },
    RightEdge = { texCoords = { 1094, 1208, 170, 1084 } },
}

local function GetScalePercent(scale)
    scale = tonumber(scale) or 1

    return math.floor(scale * 100 / SCALE_STEP + 0.5) * SCALE_STEP
end

local function ClampScale(scale)
    local value = GetScalePercent(scale)

    if value < SCALE_MIN then
        return SCALE_MIN / 100
    end

    if value > SCALE_MAX then
        return SCALE_MAX / 100
    end

    return value / 100
end

local function FormatScaleButtonText(value)
    return "Scale: " .. value .. "%"
end

local function PrepareWrappedFontString(fontString)
    if fontString.SetWordWrap then
        fontString:SetWordWrap(true)
    end

    if fontString.SetNonSpaceWrap then
        fontString:SetNonSpaceWrap(false)
    end
end

local function GetFontStringWidth(fontString)
    if fontString.GetUnboundedStringWidth then
        return fontString:GetUnboundedStringWidth()
    end

    return fontString:GetStringWidth()
end

local measureFontStrings = {}

local function GetMeasureFontString(index)
    if not measureFontStrings[index] then
        measureFontStrings[index] = UIParent:CreateFontString(nil, "BACKGROUND")
        measureFontStrings[index]:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, -1000)
        measureFontStrings[index]:SetAlpha(0)
    end

    PrepareWrappedFontString(measureFontStrings[index])

    return measureFontStrings[index]
end

local function GetPositiveDimension(value, fallback)
    if not value or value <= 0 then
        return fallback
    end

    return value
end

function UI.CreateBackdropFrame(frameType, name, parent, backdrop, bgColor, borderColor, template)
    local frame = CreateFrame(frameType or "Frame", name, parent, template or (BackdropTemplateMixin and "BackdropTemplate"))

    if frame.SetBackdrop and backdrop then
        frame:SetBackdrop(backdrop)
        if bgColor then
            frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
        end
        if borderColor then
            frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
        end
    end

    return frame
end

function UI.CreateBingoPanel(name, parent, backgroundAlpha)
    local frame = CreateFrame("Frame", name, parent)
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", FRAME_BACKGROUND_INSET, -FRAME_BACKGROUND_INSET)
    background:SetPoint("BOTTOMRIGHT", -FRAME_BACKGROUND_INSET, FRAME_BACKGROUND_INSET)
    background:SetTexture(Bingo.DefaultBackdrop.bgFile)
    background:SetVertexColor(0.1, 0.1, 0.1, backgroundAlpha)

    NineSliceUtil.ApplyLayout(frame, FRAME_BORDER_LAYOUT)

    return frame
end

function UI.CreateFontString(parent, size, flags, color, text)
    local fontString = parent:CreateFontString(nil, "OVERLAY")
    fontString:SetFont(FONT_PATH, size, flags or "OUTLINE")

    if color then
        fontString:SetTextColor(color[1], color[2], color[3], color[4])
    end
    if text then
        fontString:SetText(text)
    end

    return fontString
end

function UI.FitFontStringToBox(fontString, text, fontPath, fontFlags, maxWidth, maxHeight, minSize, maxSize)
    text = tostring(text or "")
    maxWidth = math.max(1, maxWidth or 1)
    maxHeight = math.max(1, maxHeight or 1)
    minSize = math.floor((minSize or BINGO_BUTTON_MIN_FONT_SIZE) + 0.5)
    maxSize = math.floor((maxSize or BINGO_BUTTON_MAX_FONT_SIZE) + 0.5)

    if maxSize < minSize then
        maxSize = minSize
    end

    PrepareWrappedFontString(fontString)

    local fitWidth = math.max(1, maxWidth - FONT_FIT_WIDTH_FUDGE)
    local fitHeight = math.max(1, maxHeight - FONT_FIT_HEIGHT_FUDGE)
    local bestSize = minSize
    local measure = GetMeasureFontString(1)
    local wordMeasure = GetMeasureFontString(2)

    measure:SetWidth(maxWidth)

    for size = maxSize, minSize, -1 do
        local longestWordFits = true

        wordMeasure:SetWidth(FONT_MEASURE_WIDTH)
        wordMeasure:SetFont(fontPath, size, fontFlags)

        for word in string.gmatch(text, "%S+") do
            wordMeasure:SetText(word)

            if GetFontStringWidth(wordMeasure) > fitWidth then
                longestWordFits = false
                break
            end
        end

        measure:SetFont(fontPath, size, fontFlags)
        measure:SetText(text)

        if longestWordFits and measure:GetStringHeight() <= fitHeight then
            bestSize = size
            break
        end
    end

    fontString:SetWidth(maxWidth)
    fontString:SetFont(fontPath, bestSize, fontFlags)
    fontString:SetText(text)

    return bestSize
end

function UI.CreateStyledButton(parent, name, width, height, text)
    local button = UI.CreateBackdropFrame(
        "Button",
        name,
        parent,
        {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        },
        { 0.15, 0.15, 0.15, 1 },
        { 0.6, 0.6, 0.6, 1 }
    )
    button:SetSize(width, height)

    button.text = UI.CreateFontString(button, 14, "OUTLINE", { 1, 0.82, 0, 1 }, text)
    button.text:SetPoint("CENTER", 0, 0)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.25, 0.25, 1)
        self:SetBackdropBorderColor(1, 0.82, 0, 1)
    end)

    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
        self:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end)

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

function UI.CreatePopupSlider(button, options)
    options = options or {}
    options.font = options.font or FONT_PATH
    options.bgColor = options.bgColor or { r = 0.15, g = 0.15, b = 0.15, a = 0.95 }
    options.trackColor = options.trackColor or { r = 0.5, g = 0.5, b = 0.5, a = 1 }

    return LibStub("LibPopupSlider-1.0"):Create(button, options)
end

function Bingo:SyncScaleControl()
    if not self.ScaleButton then return end

    local settings = self:GetSettings()
    local value = GetScalePercent(ClampScale(settings.Scale or 1))

    self.ScaleButton.text:SetText(FormatScaleButtonText(value))

    if self.ScalePopup then
        self.ScalePopup:SetValue(value, true)
    end
end

function Bingo:SetScale(scale)
    scale = ClampScale(scale)

    self:EnsureSettings().Scale = scale

    if self.BingoFrame then
        self.BingoFrame:SetScale(scale)
    end

    self:SyncScaleControl()
end

function Bingo:CreateFrames()
    self.BingoFrame = UI.CreateBingoPanel("BingoFrame", UIParent, 0.9)
    self.BingoFrame:SetFrameStrata("HIGH")
    self.BingoFrame:Hide()

    -- Register events
    self.BingoFrame:SetScript("OnEvent", self.EventHandler)
    self.BingoFrame:SetScript("OnDragStart", self.BingoFrame.StartMoving)
    self.BingoFrame:SetScript("OnDragStop", self.BingoFrame.StopMovingOrSizing)
    self.BingoFrame:RegisterEvent("ADDON_LOADED")
    self.BingoFrame:RegisterEvent("ENCOUNTER_START")
    self.BingoFrame:RegisterEvent("ENCOUNTER_END")
    self.BingoFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.BingoFrame:RegisterEvent("PLAYER_ALIVE")
    self.BingoFrame:RegisterEvent("PLAYER_UNGHOST")
    self.BingoFrame:RegisterEvent("CHAT_MSG_ADDON")
    self.BingoFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

    C_ChatInfo.RegisterAddonMessagePrefix(ADDON_MSG_PREFIX)

    self.BingoFrame:SetFrameLevel(4)
    self.BingoFrame:SetMovable(true)
    self.BingoFrame:EnableMouse(true)
    self.BingoFrame:RegisterForDrag("LeftButton")

    self.BingoFrame:SetSize(BINGO_FRAME_WIDTH, BINGO_FRAME_HEIGHT)
    self.BingoFrame:ClearAllPoints()
    self.BingoFrame:SetPoint("CENTER")
    tinsert(UISpecialFrames, self.BingoFrame:GetName())

    self.SessionPlayersFrame = UI.CreateBackdropFrame(
        "Frame",
        "BingoSessionPlayersFrame",
        self.BingoFrame,
        self.DefaultBackdrop,
        { 0.1, 0.1, 0.1, 0.9 },
        { 0.6, 0.6, 0.6, 1 }
    )
    self.SessionPlayersFrame:SetWidth(150)
    self.SessionPlayersFrame:SetHeight(BINGO_FRAME_HEIGHT)
    self.SessionPlayersFrame:SetPoint("TOPRIGHT", self.BingoFrame, "TOPLEFT", -5, 0)

    self.SessionPlayersFrame.title = UI.CreateFontString(self.SessionPlayersFrame, 14, "OUTLINE", { 1, 0.82, 0, 1 }, "Session Players")
    self.SessionPlayersFrame.title:SetPoint("TOP", 0, -10)

    self.SessionPlayerNames = {}
    self.SessionPlayersFrame:Hide()

    self.BingoFrame.text = UI.CreateFontString(self.BingoFrame, 32, "OUTLINE", nil, "Bingo!")
    self.BingoFrame.text:SetPoint("TOPLEFT", 15, -55)
    self.BingoFrame.text:SetPoint("BOTTOMRIGHT", -15, BINGO_FRAME_HEIGHT - 70)

    self.BingoFrameCloseButton = CreateFrame("Button", "BingoFrameCloseButton", self.BingoFrame, "UIPanelCloseButton")
    self.BingoFrameCloseButton:SetPoint("TOPRIGHT", -6, -6)
    self.BingoFrameCloseButton:SetScript("OnClick", function()
        self.BingoFrame:Hide()
    end)

    self.BingoFrame.version = UI.CreateFontString(self.BingoFrame, 14, "OUTLINESLUG", { 1, 1, 1, 1 }, C_AddOns.GetAddOnMetadata("PartySharkBingo", "Version"))
    self.BingoFrame.version:SetPoint("TOPRIGHT", self.BingoFrame, "BOTTOMRIGHT", -4, -2)

    self.ScaleButton = UI.CreateStyledButton(self.BingoFrame, "BingoScaleButton", SCALE_BUTTON_WIDTH, SCALE_BUTTON_HEIGHT, "")
    self.ScaleButton:SetPoint("TOPLEFT", self.BingoFrame, "BOTTOMLEFT", BOARD_LEFT_X, -2)

    self.ScalePopup = UI.CreatePopupSlider(self.ScaleButton, {
        minValue = SCALE_MIN,
        maxValue = SCALE_MAX,
        step = SCALE_STEP,
        label = "Scale",
        valueFitText = "150%",

        formatValue = function(value)
            return value .. "%"
        end,

        onValueChanged = function(value)
            Bingo:SetScale(value / 100)
        end,
    })
    self:SyncScaleControl()

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

    StaticPopupDialogs["BINGO_SHUFFLE_ALL_DIALOG"] = {
        text = "This will reset and shuffle everyone's bingo boards in the session. Are you sure?",
        button1 = YES,
        button2 = NO,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        enterClicksFirstButton = true,
        OnAccept = function()
            Bingo:ShuffleAllBoards()
        end
    }

    local BUTTON_WIDTH = 90
    local BUTTON_HEIGHT = 28
    local BUTTON_SPACING = 5
    local BUTTON_START_X = 15
    local BUTTON_Y = -12
    local nextButtonX = BUTTON_START_X

    self.ResetAllButton = UI.CreateStyledButton(self.BingoFrame, "BingoResetAllButton", BUTTON_WIDTH, BUTTON_HEIGHT, "Reset All")
    self.ResetAllButton:SetPoint("TOPLEFT", nextButtonX, BUTTON_Y)
    self.ResetAllButton:SetScript("OnClick", function()
        if self:HasAnySquaresChecked() then
            StaticPopup_Show("BINGO_RESETALL_DIALOG")
        end
    end)
    nextButtonX = nextButtonX + BUTTON_WIDTH + BUTTON_SPACING

    self.ShuffleButton = UI.CreateStyledButton(self.BingoFrame, "BingoShuffleButton", BUTTON_WIDTH, BUTTON_HEIGHT, "Shuffle")
    self.ShuffleButton:SetPoint("TOPLEFT", nextButtonX, BUTTON_Y)
    self.ShuffleButton:SetScript("OnClick", function()
        if self.InEncounter then
            print("|cffFFC125" .. self.ADDON_NAME .. "|cffff6060 |TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:0|t Cannot shuffle during an encounter.")
            return
        end

        if self.IsSessionLocked then
            if IsSessionOwner() then
                StaticPopup_Show("BINGO_SHUFFLE_ALL_DIALOG")
            else
                print("|cffFFC125" .. self.ADDON_NAME .. "|cffff6060 Session is locked. Cannot shuffle.")
            end
            return
        end

        if self:HasAnySquaresChecked() then
            StaticPopup_Show("BINGO_SHUFFLE_DIALOG")
        else
            self:LoadDefaultBingoCards()
            self:ResetBoard()
            self:LoadBingoCard(self.CurrentBingoCard)
        end
    end)
    nextButtonX = nextButtonX + BUTTON_WIDTH + BUTTON_SPACING

    self.StartButton = UI.CreateStyledButton(self.BingoFrame, "BingoStartButton", BUTTON_WIDTH, BUTTON_HEIGHT, "Start")
    self.StartButton:SetPoint("TOPLEFT", nextButtonX, BUTTON_Y)
    self.StartButton:Hide()
    self.StartButton:SetScript("OnClick", function()
        if not CanManageSession() then
            self:UpdateSessionRoleUI()
            return
        end
        if self.InEncounter then
            print("|cffFFC125" .. self.ADDON_NAME .. "|cffff6060 |TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:0|t Cannot start session during an encounter.")
            return
        end
        self:SendLockCommand(true)
    end)
    nextButtonX = nextButtonX + BUTTON_WIDTH + BUTTON_SPACING

    self.AddPlayersButton = UI.CreateStyledButton(self.BingoFrame, "BingoAddPlayersButton", BUTTON_WIDTH, BUTTON_HEIGHT, "Add Players")
    self.AddPlayersButton:SetPoint("TOPLEFT", nextButtonX, BUTTON_Y)
    self.AddPlayersButton:Hide()
    self.AddPlayersButton:SetScript("OnClick", function()
        if not IsSessionOwner() then
            self:UpdateSessionRoleUI()
            return
        end
        if self.InEncounter then
            print("|cffFFC125" .. self.ADDON_NAME .. "|cffff6060 |TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:0|t Cannot add players during an encounter.")
            return
        end
        self:SendAddPlayersMessage()
    end)

    self.EndButton = UI.CreateStyledButton(self.BingoFrame, "BingoEndButton", BUTTON_WIDTH, BUTTON_HEIGHT, "End")
    self.EndButton:SetPoint("TOPLEFT", self.StartButton, "TOPLEFT", 0, 0)
    self.EndButton:Hide()
    self.EndButton:SetScript("OnClick", function()
        if not IsSessionOwner() then
            self:UpdateSessionRoleUI()
            return
        end
        if self.InEncounter then
            print("|cffFFC125" .. self.ADDON_NAME .. "|cffff6060 |TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:0|t Cannot end session during an encounter.")
            return
        end
        if IsInGroup() then
            self:SendLockCommand(false)
        else
            self:SetSessionLocked(false, nil)
        end
    end)

    self.LockIndicator = UI.CreateFontString(self.BingoFrame, 18, "OUTLINE", { 1, 0.82, 0, 1 }, "In session")
    self.LockIndicator:SetPoint("BOTTOM", self.BingoFrame, "TOP", 0, 4)
    self.LockIndicator:Hide()

    StaticPopupDialogs["BINGO_LEAVE_SESSION_DIALOG"] = {
        text = "Leaving the session will remove your chance to win for the week, are you sure you want to leave?",
        button1 = YES,
        button2 = NO,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnAccept = function()
            Bingo:LeaveSession()
        end
    }

    self.LeaveSessionButton = UI.CreateStyledButton(self.BingoFrame, "BingoLeaveSessionButton", BUTTON_WIDTH, BUTTON_HEIGHT, "Leave")
    self.LeaveSessionButton:SetPoint("TOPLEFT", self.StartButton, "TOPLEFT", 0, 0)
    self.LeaveSessionButton:Hide()
    self.LeaveSessionButton:SetScript("OnClick", function()
        if self.InEncounter then
            print("|cffFFC125" .. self.ADDON_NAME .. "|cffff6060 |TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:0|t Cannot leave session during an encounter.")
            return
        end
        StaticPopup_Show("BINGO_LEAVE_SESSION_DIALOG")
    end)

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
end

local function CreateBingoTile(parent, name)
    local tile = CreateFrame("Button", name, parent)
    tile:SetSize(BINGO_BUTTON_SIZE, BINGO_BUTTON_SIZE)
    tile.isChecked = false

    local cell = tile:CreateTexture(nil, "BACKGROUND")
    cell:SetAllPoints()
    cell:SetTexture(BINGO_TILE_TEXTURES.cell)

    tile:SetPushedTexture(BINGO_TILE_TEXTURES.cell)
    local pushed = tile:GetPushedTexture()
    pushed:SetAllPoints()
    pushed:SetDrawLayer("BORDER")
    pushed:SetVertexColor(0.8, 0.8, 0.8)

    tile.mark = tile:CreateTexture(nil, "ARTWORK")
    tile.mark:SetAllPoints()
    tile.mark:SetTexture(BINGO_TILE_TEXTURES.mark)
    tile.mark:Hide()

    tile:SetHighlightTexture(BINGO_TILE_TEXTURES.glow, "BLEND")
    tile:GetHighlightTexture():SetAllPoints()

    tile.text = UI.CreateFontString(tile, 10, BINGO_TILE_FONT_FLAGS)
    tile.text:SetPoint("TOPLEFT", BINGO_BUTTON_TEXT_PADDING, -BINGO_BUTTON_TEXT_PADDING)
    tile.text:SetPoint("BOTTOMRIGHT", -BINGO_BUTTON_TEXT_PADDING, BINGO_BUTTON_TEXT_PADDING)
    tile.text:SetJustifyH("CENTER")
    tile.text:SetJustifyV("MIDDLE")

    return tile
end

function Bingo:SetButtonChecked(button, checked)
    button.isChecked = checked
    button.mark:SetShown(checked)
end

function Bingo:IsButtonChecked(button)
    return button.isChecked
end

function Bingo:UpdateWinningTiles(winningTiles)
    for index, button in pairs(self.BingoButtons) do
        if winningTiles[index] then
            button:LockHighlight()
        else
            button:UnlockHighlight()
        end
    end
end

function Bingo:CreateButton(x, y, name)
    local bingoButton = CreateBingoTile(self.BingoFrame, name)
    bingoButton:SetPoint("TOPLEFT", x, y)

    bingoButton:SetScript("OnClick", function()
        local hadBingo = Bingo.CurrentBingoCardBingo
        Bingo:SetButtonChecked(bingoButton, not bingoButton.isChecked)
        Bingo:SaveBingoCard(bingoButton.cardName, bingoButton.name, bingoButton.index)

        if Bingo:CheckForBingo() and not hadBingo then
            StaticPopup_Show("BINGO_WIN_DIALOG")
        end
    end)

    return bingoButton
end

function Bingo:CreateButtons()
    local buttonStep = BINGO_BUTTON_SIZE + BINGO_BUTTON_SPACING
    local startX = 15
    local startY = -85
    local buttonIndex = 1

    for row = 1, 5 do
        for col = 1, 5 do
            local x = startX + (col - 1) * buttonStep
            local y = startY - (row - 1) * buttonStep

            self.BingoButtons[buttonIndex] = self:CreateButton(x, y, "BingoButton" .. buttonIndex)
            self.BingoButtons[buttonIndex].index = buttonIndex
            buttonIndex = buttonIndex + 1
        end
    end

    self.CreateButton = function() end
    self.CreateButtons = function() end
end

function Bingo:FitBingoButtonText(button, text)
    local maxWidth = GetPositiveDimension(button:GetWidth(), BINGO_BUTTON_SIZE) - BINGO_BUTTON_TEXT_PADDING * 2
    local maxHeight = GetPositiveDimension(button:GetHeight(), BINGO_BUTTON_SIZE) - BINGO_BUTTON_TEXT_PADDING * 2

    UI.FitFontStringToBox(
        button.text,
        text,
        FONT_PATH,
        BINGO_TILE_FONT_FLAGS,
        maxWidth,
        maxHeight,
        BINGO_BUTTON_MIN_FONT_SIZE,
        BINGO_BUTTON_MAX_FONT_SIZE
    )
end

function Bingo:SetCardTitle(cardName)
    local card = self:GetCards()[cardName]
    self.BingoFrame.text:SetFont(FONT_PATH, card["TitleSize"] or 20, "OUTLINE")
    self.BingoFrame.text:SetText(card["Title"] or "Bingo!")
end

function Bingo:SetFreeSpace(cardName)
    local card = self:GetCards()[cardName]
    local text = card["FreeSpace"] or "Free Space"
    self:FitBingoButtonText(self.BingoButtons[13], text)
    self:SetButtonChecked(self.BingoButtons[13], true)
    self.BingoButtons[13]:Disable()
end

function Bingo:LoadButton(cardName, buttonID, cardID, enabled)
    local entry = self:GetCards()[cardName][cardID]
    local text = type(entry) == "table" and entry.value or entry or cardID

    self.BingoButtons[buttonID].cardName = cardName
    self.BingoButtons[buttonID].name = text

    self:FitBingoButtonText(self.BingoButtons[buttonID], text)
    self:SetButtonChecked(self.BingoButtons[buttonID], not enabled)
end

local function GetSortedCardEntries(cardName)
    local entries = {}
    local card = Bingo:GetCards()[cardName]

    if not card then
        return entries
    end

    for index, entry in pairs(card) do
        if type(index) == "number" then
            entries[#entries + 1] = {
                index = index,
                entry = entry,
            }
        end
    end

    table.sort(entries, function(a, b)
        return a.index < b.index
    end)

    return entries
end

function Bingo:CreateTilePreviewFrame()
    if self.TilePreviewFrame then return end

    local frame = UI.CreateBingoPanel("BingoTilePreviewFrame", UIParent, 0.95)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(10)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetToplevel(true)
    frame:SetPoint("CENTER")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame.title = UI.CreateFontString(frame, 20, "OUTLINE", { 1, 0.82, 0, 1 })
    frame.title:SetPoint("TOPLEFT", TILE_PREVIEW_PADDING, -12)
    frame.title:SetPoint("TOPRIGHT", -40, -12)
    frame.title:SetJustifyH("LEFT")

    frame.close = CreateFrame("Button", "BingoTilePreviewFrameCloseButton", frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", -6, -6)
    frame.close:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame.tiles = {}
    tinsert(UISpecialFrames, frame:GetName())

    frame:Hide()
    self.TilePreviewFrame = frame
end

function Bingo:ShowTilePreviewFrame(cardName)
    local settings = self:GetSettings()
    local cards = self:GetCards()
    cardName = cardName or self.CurrentBingoCard or settings.DefaultCard or "Default"

    if not cards[cardName] then
        print("|cffff0000Error!|cffffffff Card |cffFFFFE0'" .. tostring(cardName) .. "'|cffffffff not found.")
        return
    end

    self:CreateTilePreviewFrame()

    local frame = self.TilePreviewFrame
    local entries = GetSortedCardEntries(cardName)
    local count = #entries
    local rows = math.max(1, math.ceil(count / TILE_PREVIEW_COLUMNS))
    local width = TILE_PREVIEW_PADDING * 2
        + TILE_PREVIEW_COLUMNS * BINGO_BUTTON_SIZE
        + (TILE_PREVIEW_COLUMNS - 1) * TILE_PREVIEW_SPACING
    local height = TILE_PREVIEW_TITLE_HEIGHT
        + TILE_PREVIEW_PADDING
        + rows * BINGO_BUTTON_SIZE
        + (rows - 1) * TILE_PREVIEW_SPACING

    frame:SetSize(width, height)
    frame.title:SetText(cardName .. " Tiles (" .. count .. ")")

    for _, tile in pairs(frame.tiles) do
        tile:Hide()
    end

    for i, item in ipairs(entries) do
        local tile = frame.tiles[i]
        if not tile then
            tile = CreateBingoTile(frame)
            frame.tiles[i] = tile
        end

        local col = (i - 1) % TILE_PREVIEW_COLUMNS
        local row = math.floor((i - 1) / TILE_PREVIEW_COLUMNS)
        local entry = item.entry
        local text = type(entry) == "table" and entry.value or entry or item.index

        tile:ClearAllPoints()
        tile:SetPoint(
            "TOPLEFT",
            frame,
            "TOPLEFT",
            TILE_PREVIEW_PADDING + col * (BINGO_BUTTON_SIZE + TILE_PREVIEW_SPACING),
            -TILE_PREVIEW_TITLE_HEIGHT - row * (BINGO_BUTTON_SIZE + TILE_PREVIEW_SPACING)
        )
        tile.cardName = cardName
        tile.index = item.index
        tile.name = text

        self:FitBingoButtonText(tile, text)
        self:SetButtonChecked(tile, false)
        tile:Show()
    end

    frame:Show()
end

function Bingo:UpdateSessionPlayersDisplay()
    if not IsSessionOwner() or not self.SessionPlayersFrame then return end

    for _, fontString in pairs(self.SessionPlayerNames) do
        fontString:Hide()
        fontString:SetText("")
    end

    local sortedNames = {}
    for name, confirmed in pairs(self.SessionPlayers) do
        if confirmed then
            table.insert(sortedNames, name)
        end
    end
    table.sort(sortedNames)

    local yOffset = -30
    for i, name in ipairs(sortedNames) do
        if not self.SessionPlayerNames[i] then
            self.SessionPlayerNames[i] = UI.CreateFontString(self.SessionPlayersFrame, 12, "OUTLINE")
            self.SessionPlayerNames[i]:SetPoint("TOPLEFT", 10, yOffset)
            self.SessionPlayerNames[i]:SetPoint("TOPRIGHT", -10, yOffset)
            self.SessionPlayerNames[i]:SetJustifyH("LEFT")
        end

        local coloredName = self:GetClassColoredName(name)
        self.SessionPlayerNames[i]:SetText(coloredName)
        self.SessionPlayerNames[i]:SetPoint("TOPLEFT", 10, yOffset)
        self.SessionPlayerNames[i]:Show()

        yOffset = yOffset - 18
    end

    if self.SessionPlayersFrame.title then
        local count = #sortedNames
        self.SessionPlayersFrame.title:SetText("Session Players (" .. count .. ")")
    end
end

function Bingo:UpdateSessionRoleUI()
    local canManageSession = CanManageSession()
    local isSessionOwner = IsSessionOwner()

    if self.SessionPlayersFrame then
        if isSessionOwner and self.IsSessionLocked then
            self.SessionPlayersFrame:Show()
            self:UpdateSessionPlayersDisplay()
        else
            self.SessionPlayersFrame:Hide()
        end
    end

    if self.StartButton then
        if canManageSession and IsInGroup() and not self.IsSessionLocked then
            self.StartButton:Show()
        else
            self.StartButton:Hide()
        end
    end

    if self.EndButton then
        if isSessionOwner and self.IsSessionLocked and IsInGroup() then
            self.EndButton:Show()
        else
            self.EndButton:Hide()
        end
    end

    if self.AddPlayersButton then
        if isSessionOwner and IsInGroup() and self.IsSessionLocked then
            self.AddPlayersButton:Show()
        else
            self.AddPlayersButton:Hide()
        end
    end

    if self.LeaveSessionButton then
        if self.IsSessionLocked and (not isSessionOwner or not IsInGroup()) then
            self.LeaveSessionButton:Show()
        else
            self.LeaveSessionButton:Hide()
        end
    end

    self:UpdateShuffleButtonState()
end

function Bingo:UpdateShuffleButtonState()
    if not self.ShuffleButton then return end

    local isSessionOwner = IsSessionOwner()

    if self.IsSessionLocked then
        if isSessionOwner then
            self.ShuffleButton:Enable()
            self.ShuffleButton:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
            self.ShuffleButton.text:SetTextColor(1, 0.82, 0, 1)
            self.ShuffleButton.text:SetText("Shuffle All")
        else
            self.ShuffleButton:Disable()
            self.ShuffleButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            self.ShuffleButton.text:SetTextColor(0.5, 0.5, 0.5, 1)
        end

        if self.LockIndicator then
            if isSessionOwner then
                self.LockIndicator:Hide()
            else
                self.LockIndicator:Show()
                self.LockIndicator:SetText("In session started by " .. (self.SessionLockedBy or "leader"))
            end
        end
    else
        self.ShuffleButton.text:SetText("Shuffle")
        self.ShuffleButton:Enable()
        self.ShuffleButton:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        self.ShuffleButton.text:SetTextColor(1, 0.82, 0, 1)

        if self.LockIndicator then
            self.LockIndicator:Hide()
        end
    end
end
