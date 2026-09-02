-- HudScript (StarterGui > RaceHUDGui) - MK8 Authentic Overlay
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RF = ReplicatedStorage:WaitForChild("BrainKartRemotes", 20)
if not RF then warn("[RaceHUD] BrainKartRemotes not found!"); return end

-- Clean previous HUD instances
local oldHUD = playerGui:FindFirstChild("RaceHUD")
if oldHUD then oldHUD:Destroy() end

-- Create Main ScreenGui
local sg = Instance.new("ScreenGui")
sg.Name = "RaceHUD"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.Enabled = true
sg.Parent = playerGui

-- Helpers
local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function addGradient(parent, colorSequence, rotation)
	local g = Instance.new("UIGradient")
	g.Color = colorSequence
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

local function addStroke(parent, color, thickness, mode)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(255, 255, 255)
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

-- ============================================================
-- 1. TOP-LEFT: ITEM SLOTS (ABILIDADES - SEM FUNDO ESCURO)
-- ============================================================
local itemContainer = Instance.new("Frame")
itemContainer.Name = "ItemContainer"
itemContainer.Size = UDim2.new(0, 160, 0, 160)
itemContainer.Position = UDim2.new(0, 30, 0, 50) -- Ligeiramente abaixo do menu do Roblox
itemContainer.BackgroundTransparency = 1 -- 100% invisível (sem fundo quadrado)
itemContainer.Parent = sg

-- Primary Main Item Slot (Held)
local mainSlot = Instance.new("Frame")
mainSlot.Name = "MainItemSlot"
mainSlot.Size = UDim2.new(0, 85, 0, 85)
mainSlot.Position = UDim2.new(0, 30, 0, 30)
mainSlot.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
mainSlot.BackgroundTransparency = 0.35
mainSlot.ZIndex = 3
mainSlot.Parent = itemContainer
addCorner(mainSlot, 43)

-- Chrome Outer Ring
local mainStroke = addStroke(mainSlot, Color3.fromRGB(255, 255, 255), 4.5)
addGradient(mainStroke, ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(240, 245, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(130, 140, 160)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(60, 70, 90)),
}), -45)

-- Glass Reflection Arc
local glassArc = Instance.new("Frame")
glassArc.Name = "GlassReflection"
glassArc.Size = UDim2.new(0.85, 0, 0.38, 0)
glassArc.Position = UDim2.new(0.075, 0, 0.06, 0)
glassArc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
glassArc.BackgroundTransparency = 0.82
glassArc.ZIndex = 5
glassArc.Parent = mainSlot
addCorner(glassArc, 20)

-- Secondary Stored Item Slot (Top-Left Overlap)
local subSlot = Instance.new("Frame")
subSlot.Name = "SubItemSlot"
subSlot.Size = UDim2.new(0, 52, 0, 52)
subSlot.Position = UDim2.new(0, 5, 0, 5)
subSlot.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
subSlot.BackgroundTransparency = 0.35
subSlot.ZIndex = 6
subSlot.Parent = itemContainer
addCorner(subSlot, 26)

local subStroke = addStroke(subSlot, Color3.fromRGB(255, 255, 255), 3.5)
addGradient(subStroke, ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(230, 235, 250)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(80, 90, 110)),
}), -45)

-- Item Icon Holders
local mainIcon = Instance.new("ImageLabel")
mainIcon.Name = "ItemIcon"
mainIcon.Size = UDim2.new(0.75, 0, 0.75, 0)
mainIcon.Position = UDim2.new(0.125, 0, 0.125, 0)
mainIcon.BackgroundTransparency = 1
mainIcon.ZIndex = 6
mainIcon.Parent = mainSlot

local subIcon = Instance.new("ImageLabel")
subIcon.Name = "ItemIcon"
subIcon.Size = UDim2.new(0.75, 0, 0.75, 0)
subIcon.Position = UDim2.new(0.125, 0, 0.125, 0)
subIcon.BackgroundTransparency = 1
subIcon.ZIndex = 8
subIcon.Parent = subSlot


-- ============================================================
-- 2. BOTTOM-LEFT: COINS & LAPS PANEL (PILULA TRANSLUCIDA MK8)
-- ============================================================
local infoPanel = Instance.new("Frame")
infoPanel.Name = "CoinsAndLapPanel"
infoPanel.Size = UDim2.new(0, 230, 0, 52)
infoPanel.Position = UDim2.new(0, 35, 1, -85)
infoPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
infoPanel.BackgroundTransparency = 0.45 -- Translúcido limpo exatamente como MK8
infoPanel.BorderSizePixel = 0
infoPanel.ZIndex = 3
infoPanel.Parent = sg
addCorner(infoPanel, 16)

local panelStroke = addStroke(infoPanel, Color3.fromRGB(70, 75, 85), 1.5)

-- ─── COIN SECTION ───
local coinSection = Instance.new("Frame")
coinSection.Name = "CoinSection"
coinSection.Size = UDim2.new(0.48, 0, 1, 0)
coinSection.Position = UDim2.new(0, 0, 0, 0)
coinSection.BackgroundTransparency = 1
coinSection.ZIndex = 4
coinSection.Parent = infoPanel

-- Solid Yellow Coin Icon
local coinBadge = Instance.new("Frame")
coinBadge.Size = UDim2.new(0, 28, 0, 28)
coinBadge.Position = UDim2.new(0, 14, 0.5, -14)
coinBadge.BackgroundColor3 = Color3.fromRGB(255, 205, 0)
coinBadge.ZIndex = 5
coinBadge.Parent = coinSection
addCorner(coinBadge, 14)

local coinStroke = addStroke(coinBadge, Color3.fromRGB(180, 130, 0), 2)

local coinDetail = Instance.new("TextLabel")
coinDetail.Size = UDim2.new(1, 0, 1, 0)
coinDetail.BackgroundTransparency = 1
coinDetail.Text = "$"
coinDetail.Font = Enum.Font.FredokaOne
coinDetail.TextSize = 18
coinDetail.TextColor3 = Color3.fromRGB(160, 95, 0)
coinDetail.ZIndex = 6
coinDetail.Parent = coinBadge

-- Coin Count Text
local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinCount"
coinLabel.Size = UDim2.new(0, 55, 1, 0)
coinLabel.Position = UDim2.new(0, 48, 0, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "00"
coinLabel.Font = Enum.Font.FredokaOne
coinLabel.TextSize = 26
coinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.ZIndex = 5
coinLabel.Parent = coinSection

local coinTextStroke = addStroke(coinLabel, Color3.fromRGB(0, 0, 0), 3, Enum.ApplyStrokeMode.Contextual)

-- ─── SLANTED DIVIDER ───
local sepBar = Instance.new("TextLabel")
sepBar.Size = UDim2.new(0, 15, 1, 0)
sepBar.Position = UDim2.new(0.46, 0, 0, 0)
sepBar.BackgroundTransparency = 1
sepBar.Text = "/"
sepBar.Font = Enum.Font.FredokaOne
sepBar.TextSize = 22
sepBar.TextColor3 = Color3.fromRGB(180, 185, 200)
sepBar.ZIndex = 5
sepBar.Parent = infoPanel

-- ─── LAP SECTION ───
local lapSection = Instance.new("Frame")
lapSection.Name = "LapSection"
lapSection.Size = UDim2.new(0.5, 0, 1, 0)
lapSection.Position = UDim2.new(0.5, 0, 0, 0)
lapSection.BackgroundTransparency = 1
lapSection.ZIndex = 4
lapSection.Parent = infoPanel

-- Checkered Flag Graphic
local flagIcon = Instance.new("TextLabel")
flagIcon.Size = UDim2.new(0, 28, 0, 28)
flagIcon.Position = UDim2.new(0, 10, 0.5, -14)
flagIcon.BackgroundTransparency = 1
flagIcon.Text = "🏁"
flagIcon.TextSize = 22
flagIcon.ZIndex = 5
flagIcon.Parent = lapSection

local lapLabel = Instance.new("TextLabel")
lapLabel.Name = "LapCount"
lapLabel.Size = UDim2.new(0, 65, 1, 0)
lapLabel.Position = UDim2.new(0, 42, 0, 0)
lapLabel.BackgroundTransparency = 1
lapLabel.Text = "1/3"
lapLabel.Font = Enum.Font.FredokaOne
lapLabel.TextSize = 26
lapLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
lapLabel.TextXAlignment = Enum.TextXAlignment.Left
lapLabel.ZIndex = 5
lapLabel.Parent = lapSection

local lapTextStroke = addStroke(lapLabel, Color3.fromRGB(0, 0, 0), 3, Enum.ApplyStrokeMode.Contextual)


-- ============================================================
-- 3. BOTTOM-RIGHT: POSITION RANK (3D FLOATING OVER TRACK - NO BG)
-- ============================================================
local rankContainer = Instance.new("Frame")
rankContainer.Name = "RankContainer"
rankContainer.Size = UDim2.new(0, 180, 0, 120)
rankContainer.Position = UDim2.new(1, -200, 1, -130)
rankContainer.BackgroundTransparency = 1
rankContainer.ZIndex = 4
rankContainer.Parent = sg

-- Big Skewed Position Number (Flutuante sem círculo de fundo)
local rankNumLabel = Instance.new("TextLabel")
rankNumLabel.Name = "RankNum"
rankNumLabel.Size = UDim2.new(0, 110, 1, 0)
rankNumLabel.Position = UDim2.new(0, 0, 0, 0)
rankNumLabel.BackgroundTransparency = 1
rankNumLabel.Text = "1"
rankNumLabel.Font = Enum.Font.LuckiestGuy
rankNumLabel.TextSize = 105
rankNumLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
rankNumLabel.TextXAlignment = Enum.TextXAlignment.Right
rankNumLabel.ZIndex = 5
rankNumLabel.Parent = rankContainer

local rankNumStroke = addStroke(rankNumLabel, Color3.fromRGB(10, 10, 15), 6.5, Enum.ApplyStrokeMode.Contextual)

-- Position Suffix ("st", "nd", "rd", "th")
local rankSuffixLabel = Instance.new("TextLabel")
rankSuffixLabel.Name = "RankSuffix"
rankSuffixLabel.Size = UDim2.new(0, 65, 0.5, 0)
rankSuffixLabel.Position = UDim2.new(0, 114, 0, 48)
rankSuffixLabel.BackgroundTransparency = 1
rankSuffixLabel.Text = "st"
rankSuffixLabel.Font = Enum.Font.LuckiestGuy
rankSuffixLabel.TextSize = 44
rankSuffixLabel.TextColor3 = Color3.fromRGB(255, 195, 40)
rankSuffixLabel.TextXAlignment = Enum.TextXAlignment.Left
rankSuffixLabel.ZIndex = 5
rankSuffixLabel.Parent = rankContainer

local rankSuffixStroke = addStroke(rankSuffixLabel, Color3.fromRGB(10, 10, 15), 4.5, Enum.ApplyStrokeMode.Contextual)

-- Dynamic Color Gradients according to Rank
local function updateRankDisplay(rankNumber)
	local suffixes = { [1] = "st", [2] = "nd", [3] = "rd" }
	local suffix = suffixes[rankNumber] or "th"
	rankNumLabel.Text = tostring(rankNumber)
	rankSuffixLabel.Text = suffix

	local oldG1 = rankNumLabel:FindFirstChildOfClass("UIGradient")
	if oldG1 then oldG1:Destroy() end
	local oldG2 = rankSuffixLabel:FindFirstChildOfClass("UIGradient")
	if oldG2 then oldG2:Destroy() end

	local seq
	if rankNumber == 1 then
		seq = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 245, 120)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 180, 0)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(220, 100, 0)),
		})
	elseif rankNumber == 2 then
		seq = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190, 205, 225)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(120, 135, 160)),
		})
	elseif rankNumber == 3 then
		seq = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 200, 130)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 130, 50)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(160, 60, 20)),
		})
	else
		seq = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 195, 50)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 135, 0)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(190, 65, 0)),
		})
	end

	addGradient(rankNumLabel, seq, 85)
	addGradient(rankSuffixLabel, seq, 85)
end
updateRankDisplay(1)


-- ============================================================
-- 4. CENTER: COUNTDOWN & LAP NOTIFICATIONS
-- ============================================================
local cdLabel = Instance.new("TextLabel")
cdLabel.Name = "CountdownLabel"
cdLabel.Text = ""
cdLabel.Font = Enum.Font.LuckiestGuy
cdLabel.TextSize = 140
cdLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
cdLabel.Size = UDim2.new(1, 0, 0, 180)
cdLabel.Position = UDim2.new(0, 0, 0.5, -90)
cdLabel.BackgroundTransparency = 1
cdLabel.TextXAlignment = Enum.TextXAlignment.Center
cdLabel.TextTransparency = 1
cdLabel.ZIndex = 20
cdLabel.Parent = sg

local cdStroke = addStroke(cdLabel, Color3.fromRGB(10, 12, 22), 7, Enum.ApplyStrokeMode.Contextual)
addGradient(cdLabel, ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 160)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 160, 0)),
}), 90)

-- Lap Banner Notification Frame
local bannerFrame = Instance.new("Frame")
bannerFrame.Name = "LapBanner"
bannerFrame.Size = UDim2.new(0, 440, 0, 84)
bannerFrame.Position = UDim2.new(0.5, -220, 0.28, 0)
bannerFrame.BackgroundColor3 = Color3.fromRGB(14, 18, 30)
bannerFrame.BackgroundTransparency = 1
bannerFrame.BorderSizePixel = 0
bannerFrame.ZIndex = 15
bannerFrame.Parent = sg
addCorner(bannerFrame, 22)

local bannerStroke = addStroke(bannerFrame, Color3.fromRGB(255, 200, 0), 3)
bannerStroke.Transparency = 1

local bannerLabel = Instance.new("TextLabel")
bannerLabel.Size = UDim2.new(1, 0, 1, 0)
bannerLabel.BackgroundTransparency = 1
bannerLabel.Text = ""
bannerLabel.Font = Enum.Font.LuckiestGuy
bannerLabel.TextSize = 36
bannerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bannerLabel.ZIndex = 16
bannerLabel.Parent = bannerFrame

local bannerTextStroke = addStroke(bannerLabel, Color3.fromRGB(10, 12, 20), 4.5, Enum.ApplyStrokeMode.Contextual)
bannerTextStroke.Transparency = 1

local function showBanner(text, strokeColor)
	bannerLabel.Text = text
	bannerStroke.Color = strokeColor or Color3.fromRGB(255, 200, 0)
	
	bannerFrame.BackgroundTransparency = 0.15
	bannerStroke.Transparency = 0
	bannerTextStroke.Transparency = 0
	bannerLabel.TextTransparency = 0
	
	bannerFrame.Size = UDim2.new(0, 320, 0, 60)
	bannerFrame.Position = UDim2.new(0.5, -160, 0.28, 0)
	
	local popIn = TweenService:Create(bannerFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 440, 0, 84), Position = UDim2.new(0.5, -220, 0.28, 0) }
	)
	popIn:Play()
	
	task.delay(2.2, function()
		local fadeOut = TweenService:Create(bannerFrame, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
		local fadeStroke = TweenService:Create(bannerStroke, TweenInfo.new(0.5), { Transparency = 1 })
		local fadeText = TweenService:Create(bannerLabel, TweenInfo.new(0.5), { TextTransparency = 1 })
		local fadeTextStroke = TweenService:Create(bannerTextStroke, TweenInfo.new(0.5), { Transparency = 1 })
		
		fadeOut:Play(); fadeStroke:Play(); fadeText:Play(); fadeTextStroke:Play()
	end)
end


-- ============================================================
-- 5. EVENT LISTENERS
-- ============================================================
local totalLaps = 3

RF:WaitForChild("StartRace", 10).OnClientEvent:Connect(function(laps)
	totalLaps = laps or 3
	lapLabel.Text = "1/" .. totalLaps
	sg.Enabled = true
end)

RF:WaitForChild("Countdown", 10).OnClientEvent:Connect(function(count)
	cdLabel.Text = count == 0 and "GO!" or tostring(count)
	cdLabel.TextColor3 = count == 0 and Color3.fromRGB(40, 255, 120) or Color3.fromRGB(255, 215, 0)
	cdLabel.TextTransparency = 0
	cdStroke.Transparency = 0
	
	cdLabel.Size = UDim2.new(0, 110, 0, 110)
	cdLabel.Position = UDim2.new(0.5, -55, 0.5, -55)
	
	local pop = TweenService:Create(cdLabel,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(1, 0, 0, 180), Position = UDim2.new(0, 0, 0.5, -90) }
	)
	pop:Play()
	
	TweenService:Create(cdLabel, TweenInfo.new(0.9), { TextTransparency = 1 }):Play()
	TweenService:Create(cdStroke, TweenInfo.new(0.9), { Transparency = 1 }):Play()
end)

RF:WaitForChild("LapUpdate", 10).OnClientEvent:Connect(function(currentLap, maxLaps)
	totalLaps = maxLaps
	lapLabel.Text = currentLap .. "/" .. maxLaps
	
	if currentLap < maxLaps then
		showBanner("🏁  VOLTA " .. currentLap .. " DE " .. maxLaps, Color3.fromRGB(0, 160, 255))
	else
		showBanner("⚡  ÚLTIMA VOLTA!", Color3.fromRGB(255, 50, 50))
		lapLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	end
end)

RF:WaitForChild("UpdatePositions", 10).OnClientEvent:Connect(function(data)
	for _, e in ipairs(data) do
		if e.name == player.Name then
			updateRankDisplay(e.pos)
			if e.lap then
				lapLabel.Text = math.max(1, e.lap) .. "/" .. totalLaps
			end
		end
	end
end)

RF:WaitForChild("PlayerFinished", 10).OnClientEvent:Connect(function(pos)
	updateRankDisplay(pos)
	showBanner("🏆  FINISH! " .. pos .. "º LUGAR", Color3.fromRGB(255, 180, 0))
end)

print("[RaceHUD] Authentic MK8 Overlay UI Loaded!")
