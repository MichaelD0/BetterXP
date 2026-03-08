-- Saved position & lock state
BetterXPDB = BetterXPDB or {}

local frame = CreateFrame("Frame", "BetterXPFrame", UIParent)
frame:SetSize(800, 30)
frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 2)
frame:SetFrameStrata("HIGH")
frame:SetClampedToScreen(true)

-- Dragging support
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
    if not BetterXPDB.locked then
        self:StartMoving()
    end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save position
    local point, _, relPoint, x, y = self:GetPoint()
    BetterXPDB.point = point
    BetterXPDB.relPoint = relPoint
    BetterXPDB.x = x
    BetterXPDB.y = y
end)

-- Background
local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.7)

-- XP bar fill
local bar = frame:CreateTexture(nil, "ARTWORK")
bar:SetPoint("TOPLEFT")
bar:SetPoint("BOTTOMLEFT")
bar:SetColorTexture(0.6, 0.2, 0.8, 0.9)

-- Rested XP bar fill (shown behind main bar)
local restedBar = frame:CreateTexture(nil, "BORDER")
restedBar:SetPoint("TOPLEFT", bar, "TOPRIGHT")
restedBar:SetPoint("BOTTOMLEFT", bar, "BOTTOMRIGHT")
restedBar:SetColorTexture(0.2, 0.4, 0.8, 0.5)

-- Text overlay
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER")
text:SetTextColor(1, 1, 1, 1)

-- Time tracking
local sessionStartTime = GetTime()
local sessionStartXP = 0

local function FormatTime(seconds)
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds / 60), seconds % 60)
    else
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

local function FormatNumber(n)
    if n >= 1e6 then
        return string.format("%.1fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.1fK", n / 1e3)
    end
    return tostring(n)
end

local function UpdateBar()
    if UnitLevel("player") == GetMaxLevelForPlayerExpansion() then
        frame:Hide()
        return
    end
    frame:Show()

    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local restedXP = GetXPExhaustion() or 0
    local remainingXP = maxXP - currentXP
    local pct = (currentXP / maxXP) * 100

    -- Main bar
    local barWidth = math.max(1, (currentXP / maxXP) * frame:GetWidth())
    bar:SetWidth(barWidth)

    -- Rested bar
    if restedXP > 0 then
        local restedWidth = math.min(restedXP, remainingXP) / maxXP * frame:GetWidth()
        restedBar:SetWidth(math.max(1, restedWidth))
        restedBar:Show()
    else
        restedBar:Hide()
    end

    -- Time tracking
    local elapsed = GetTime() - sessionStartTime
    local levelTime = (BetterXPDB.levelTime or 0) + elapsed
    local xpGained = currentXP - sessionStartXP + (BetterXPDB.levelXPGained or 0)
    local totalElapsed = (BetterXPDB.levelTimeOffset or 0) + elapsed

    local ttlText = ""
    if xpGained > 0 and totalElapsed > 0 then
        local xpPerSec = xpGained / totalElapsed
        local ttlSeconds = remainingXP / xpPerSec
        ttlText = string.format("  |cFFFFD200TTL: %s|r", FormatTime(math.floor(ttlSeconds)))
    end

    -- Text: percentage + remaining + time on level + TTL
    local restedText = ""
    if restedXP > 0 then
        restedText = string.format("  |cFF4488FF(+%s rested)|r", FormatNumber(restedXP))
    end

    text:SetText(string.format(
        "%.1f%%  —  %s / %s  (%s remaining)%s%s  |cFFAAAAAAT: %s|r",
        pct, FormatNumber(currentXP), FormatNumber(maxXP), FormatNumber(remainingXP), restedText, ttlText, FormatTime(math.floor(levelTime))
    ))
end

frame:RegisterEvent("PLAYER_XP_UPDATE")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("UPDATE_EXHAUSTION")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "BetterXP" then
        BetterXPDB = BetterXPDB or {}
        -- Restore saved position
        if BetterXPDB.point then
            self:ClearAllPoints()
            self:SetPoint(BetterXPDB.point, UIParent, BetterXPDB.relPoint, BetterXPDB.x, BetterXPDB.y)
        end
        -- Default to unlocked
        if BetterXPDB.locked == nil then
            BetterXPDB.locked = false
        end
        -- Initialize time tracking for this level
        local currentLevel = UnitLevel("player")
        if BetterXPDB.trackedLevel ~= currentLevel then
            -- New level or first time: reset tracking
            BetterXPDB.trackedLevel = currentLevel
            BetterXPDB.levelTime = 0
            BetterXPDB.levelTimeOffset = 0
            BetterXPDB.levelXPGained = 0
        end
        sessionStartTime = GetTime()
        sessionStartXP = UnitXP("player")
    elseif event == "PLAYER_LEVEL_UP" then
        -- Reset time tracking for the new level
        BetterXPDB.trackedLevel = arg1
        BetterXPDB.levelTime = 0
        BetterXPDB.levelTimeOffset = 0
        BetterXPDB.levelXPGained = 0
        sessionStartTime = GetTime()
        sessionStartXP = 0
    end
    UpdateBar()
end)

-- Save accumulated time when logging out
local logoutFrame = CreateFrame("Frame")
logoutFrame:RegisterEvent("PLAYER_LOGOUT")
logoutFrame:SetScript("OnEvent", function()
    local elapsed = GetTime() - sessionStartTime
    BetterXPDB.levelTime = (BetterXPDB.levelTime or 0) + elapsed
    BetterXPDB.levelTimeOffset = (BetterXPDB.levelTimeOffset or 0) + elapsed
    BetterXPDB.levelXPGained = (BetterXPDB.levelXPGained or 0) + (UnitXP("player") - sessionStartXP)
end)

-- Update timer to keep time display current
local ticker = C_Timer.NewTicker(1, function()
    if frame:IsShown() then
        UpdateBar()
    end
end)

-- Slash command: /bxp lock
SLASH_BETTERXP1 = "/bxp"
SlashCmdList["BETTERXP"] = function(msg)
    msg = strtrim(msg):lower()
    if msg == "lock" then
        BetterXPDB.locked = true
        print("|cFF9933FFBetterXP:|r Bar |cFFFF0000locked|r.")
    elseif msg == "unlock" then
        BetterXPDB.locked = false
        print("|cFF9933FFBetterXP:|r Bar |cFF00FF00unlocked|r. Drag to move.")
    elseif msg == "reset" then
        BetterXPDB.locked = false
        BetterXPDB.point = nil
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 2)
        print("|cFF9933FFBetterXP:|r Position reset.")
    else
        print("|cFF9933FFBetterXP commands:|r")
        print("  /bxp lock   - Lock the bar in place")
        print("  /bxp unlock - Unlock the bar to drag it")
        print("  /bxp reset  - Reset position to default")
    end
end

-- Tooltip on hover
frame:EnableMouse(true)
frame:SetScript("OnEnter", function(self)
    if UnitLevel("player") == GetMaxLevelForPlayerExpansion() then return end

    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local remainingXP = maxXP - currentXP
    local restedXP = GetXPExhaustion() or 0
    local pct = (currentXP / maxXP) * 100

    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("BetterXP", 0.6, 0.2, 0.8)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("Current XP:", string.format("%s / %s", currentXP, maxXP), 1,1,1, 1,0.82,0)
    GameTooltip:AddDoubleLine("Remaining:", string.format("%s (%.1f%%)", remainingXP, 100 - pct), 1,1,1, 1,0.82,0)
    if restedXP > 0 then
        GameTooltip:AddDoubleLine("Rested XP:", tostring(restedXP), 1,1,1, 0.2,0.4,1)
    end
    GameTooltip:AddDoubleLine("Level:", tostring(UnitLevel("player")), 1,1,1, 1,0.82,0)
    local elapsed = GetTime() - sessionStartTime
    local levelTime = (BetterXPDB.levelTime or 0) + elapsed
    local xpGained = currentXP - sessionStartXP + (BetterXPDB.levelXPGained or 0)
    local totalElapsed = (BetterXPDB.levelTimeOffset or 0) + elapsed
    GameTooltip:AddDoubleLine("Time on level:", FormatTime(math.floor(levelTime)), 1,1,1, 0.6,0.8,1)
    if xpGained > 0 and totalElapsed > 0 then
        local xpPerSec = xpGained / totalElapsed
        local xpPerHour = xpPerSec * 3600
        local ttlSeconds = remainingXP / xpPerSec
        GameTooltip:AddDoubleLine("XP/hour:", FormatNumber(math.floor(xpPerHour)), 1,1,1, 0.6,0.8,1)
        GameTooltip:AddDoubleLine("Time to level:", FormatTime(math.floor(ttlSeconds)), 1,1,1, 1,0.82,0)
    end
    GameTooltip:Show()
end)
frame:SetScript("OnLeave", GameTooltip_Hide)
