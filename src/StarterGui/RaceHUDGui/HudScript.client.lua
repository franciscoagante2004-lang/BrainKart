-- HudScript (StarterGui > RaceHUDGui) - Premium Mario Kart 8 Deluxe Style HUD Overlay
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RF = ReplicatedStorage:WaitForChild("BrainKartRemotes", 20)
if not RF then warn("[RaceHUD] BrainKartRemotes not found!"); return end

-- Clean previous instances
local oldHUD = playerGui:FindFirstChild("RaceHUD")
if oldHUD then oldHUD:Destroy() end

-- Create Main ScreenGui
local sg = Instance.new("ScreenGui")
sg.Name = "RaceHUD"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.Enabled = true
sg.Parent = playerGui

-- ─── HELPER STYLING FUNCTIONS ───
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

local function addShadow(parent, sizeOffset, transparency)
	local shadow = Instance.new("Frame")
	shadow.Name = "DropShadow"
	shadow.Size = UDim2.new(1, sizeOffset or 6, 1, sizeOffset or 6)
	shadow.Position = UDim2.new(0, 3, 0, 4)
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = transparency or 0.65
	shadow.ZIndex = math.max(1, parent.ZIndex - 1)
	shadow.Parent = parent.Parent
	addCorner(shadow, parent:FindFirstChildOfClass("UICorner") and parent.UICorner.CornerRadius.Offset or 16)
	return shadow
end

-- ============================================================
-- 1. TOP-LEFT: ITEM SLOTS (ABILIDADES - MK8 PREMIUM GLASS)
-- ============================================================
local itemContainer = Instance.new("Frame")
itemContainer.Name = "ItemContainer"
itemContainer.Size = UDim2.new(0, 160, 0, 160)
itemContainer.Position = UDim2.new(0, 25, 0, 25)
itemContainer.BackgroundTransparency = 1
itemContainer.Parent = sg

-- Primary Main Item Slot (Held)
local mainSlot = Instance.new("Frame")
mainSlot.Name = "MainItemSlot"
mainSlot.Size = UDim2.new(0, 96, 0, 96)
mainSlot.Position = UDim2.new(0, 35, 0, 35)
mainSlot.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
mainSlot.BackgroundTransparency = 0.25
mainSlot.ZIndex = 3
mainSlot.Parent = itemContainer
addCorner(mainSlot, 48)
addShadow(mainSlot, 10, 0.6)

-- Main Slot Metallic Chrome Ring
local mainStroke = addStroke(mainSlot, Color3.fromRGB(255, 255, 255), 5)
addGradient(mainStroke, ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(180, 190, 210)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(90, 100, 120)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(200, 210, 230)),
}), -45)

-- Main Slot Inner Glass Sheen & Dark Radial Center
local mainInner = Instance.new("Frame")
mainInner.Size = UDim2.new(1, -6, 1, -6)
mainInner.Position = UDim2.new(0, 3, 0, 3)
mainInner.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
mainInner.BackgroundTransparency = 0.1
mainInner.ZIndex = 4
mainInner.Parent = mainSlot
addCorner(mainInner, 45)
addGradient(mainInner, ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(45, 55, 80)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 18, 28)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(5, 7, 12)),
}), 60)

-- Curved Glass Highlight (Reflection Arc)
local glassArc = Instance.new("Frame")
glassArc.Name = "GlassReflection"
glassArc.Size = UDim2.new(0.85, 0, 0.4, 0)
glassArc.Position = UDim2.new(0.075, 0, 0.05, 0)
glassArc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
glassArc.BackgroundTransparency = 0.82
glassArc.ZIndex = 5
glassArc.Parent = mainInner
addCorner(glassArc, 20)
addGradient(glassArc, ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
}), 90)

-- Secondary Stored Item Slot (Top-Left Overlap)
local subSlot = Instance.new("Frame")
subSlot.Name = "SubItemSlot"
subSlot.Size = UDim2.new(0, 60, 0, 60)
subSlot.Position = UDim2.new(0, 8, 0, 8)
subSlot.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
subSlot.BackgroundTransparency = 0.25
subSlot.ZIndex = 6
subSlot.Parent = itemContainer
addCorner(subSlot, 30)
addShadow(subSlot, 8, 0.65)

local subStroke = addStroke(subSlot, Color3.fromRGB(255, 255, 255), 4)
addGradient(subStroke, ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(240, 245, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 150, 170)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(80, 90, 110)),
}), -45)

local subInner = Instance.new("Frame")
subInner.Size = UDim2.new(1, -4, 1, -4)
subInner.Position = UDim2.new(0, 2, 0, 2)
subInner.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
subInner.BackgroundTransparency = 0.1
subInner.ZIndex = 7
subInner.Parent = subSlot
addCorner(subInner, 28)
addGradient(subInner, ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(40, 50, 75)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(8, 10, 16)),
}), 60)

-- Item Icons (Placeholders)
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
-- 2. BOTTOM-LEFT: COINS & LAPS PANEL (GLOSSY MK8 METALLIC)
-- ============================================================
local infoPanel = Instance.new("Frame")
infoPanel.Name = "CoinsAndLapPanel"
infoPanel.Size = UDim2.new(0, 260, 0, 62)
infoPanel.Position = UDim2.new(0, 35, 1, -95)
infoPanel.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
infoPanel.BackgroundTransparency = 0.25
infoPanel.BorderSizePixel = 0
infoPanel.ZIndex = 3
infoPanel.Parent = sg
addCorner(infoPanel, 18)
addShadow(infoPanel, 12, 0.55)

-- Panel Bevel Border
local panelStroke = addStroke(infoPanel, Color3.fromRGB(255, 255, 255), 2.5)
addGradient(panelStroke, ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(220, 230, 250)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 110, 130)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(40, 45, 60)),
}), 90)

-- Panel Background Gradient
addGradient(infoPanel, ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(28, 34, 52)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(14, 17, 26)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(8, 10, 16)),
}), 90)

-- Glossy Top Shine Bar
local panelTopShine = Instance.new("Frame")
panelTopShine.Size = UDim2.new(1, -20, 0, 2)
panelTopShine.Position = UDim2.new(0, 10, 0, 3)
panelTopShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
panelTopShine.BackgroundTransparency = 0.6
panelTopShine.BorderSizePixel = 0
panelTopShine.ZIndex = 4
panelTopShine.Parent = infoPanel
addCorner(panelTopShine, 1)

-- ─── COIN SECTION ───
local coinSection = Instance.new("Frame")
coinSection.Name = "CoinSection"
coinSection.Size = UDim2.new(0.48, 0, 1, 0)
coinSection.Position = UDim2.new(0, 0, 0, 0)
coinSection.BackgroundTransparency = 1
coinSection.ZIndex = 4
coinSection.Parent = infoPanel

-- Glowing Yellow Backing Halo for Coin
local coinHalo = Instance.new("Frame")
coinHalo.Size = UDim2.new(0, 42, 0, 42)
coinHalo.Position = UDim2.new(0, 11, 0.5, -21)
coinHalo.BackgroundColor3 = Color3.fromRGB(255, 210, 0)
coinHalo.BackgroundTransparency = 0.75
coinHalo.ZIndex = 4
coinHalo.Parent = coinSection
addCorner(coinHalo, 21)

-- 3D Gold Coin Badge
local coinBadge = Instance.new("Frame")
coinBadge.Size = UDim2.new(0, 34, 0, 34)
coinBadge.Position = UDim2.new(0, 15, 0.5, -17)
coinBadge.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
coinBadge.ZIndex = 5
coinBadge.Parent = coinSection
addCorner(coinBadge, 17)
addGradient(coinBadge, ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 245, 140)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 195, 0)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(200, 130, 0)),
}), -45)

local coinStroke = addStroke(coinBadge, Color3.fromRGB(160, 95, 0), 2.5)

-- Inner Star / Dollar Detail on Coin
local coinDetail = Instance.new("TextLabel")
coinDetail.Size = UDim2.new(1, 0, 1, 0)
coinDetail.BackgroundTransparency = 1
coinDetail.Text = "★"
coinDetail.Font = Enum.Font.FredokaOne
coinDetail.TextSize = 20
coinDetail.TextColor3 = Color3.fromRGB(150, 85, 0)
coinDetail.ZIndex = 6
coinDetail.Parent = coinBadge

-- Coin Count Text (With Gradient & Stroke)
local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinCount"
coinLabel.Size = UDim2.new(0, 65, 1, 0)
coinLabel.Position = UDim2.new(0, 56, 0, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "00"
coinLabel.Font = Enum.Font.FredokaOne
coinLabel.TextSize = 32
coinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.ZIndex = 5
coinLabel.Parent = coinSection

local coinTextStroke = addStroke(coinLabel, Color3.fromRGB(10, 12, 20), 3.5, Enum.ApplyStrokeMode.Contextual)
addGradient(coinLabel, ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(230, 235, 245)),
}), 90)

-- ─── SLANTED SEPARATOR BAR ───
local sepBar = Instance.new("Frame")
sepBar.Size = UDim2.new(0, 3, 0.65, 0)
sepBar.Position = UDim2.new(0.485, 0, 0.175, 0)
sepBar.BackgroundColor3 = Color3.fromRGB(180, 195, 225)
sepBar.BackgroundTransparency = 0.4
sepBar.Rotation = 12
sepBar.BorderSizePixel = 0
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
flagIcon.Size = UDim2.new(0, 34, 0, 34)
flagIcon.Position = UDim2.new(0, 12, 0.5, -17)
flagIcon.BackgroundTransparency = 1
flagIcon.Text = "🏁"
flagIcon.TextSize = 26
flagIcon.ZIndex = 5
flagIcon.Parent = lapSection

local lapLabel = Instance.new("TextLabel")
lapLabel.Name = "LapCount"
lapLabel.Size = UDim2.new(0, 75, 1, 0)
lapLabel.Position = UDim2.new(0, 48, 0, 0)
lapLabel.BackgroundTransparency = 1
lapLabel.Text = "1/3"
lapLabel.Font = Enum.Font.FredokaOne
lapLabel.TextSize = 30
lapLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
lapLabel.TextXAlignment = Enum.TextXAlignment.Left
lapLabel.ZIndex = 5
lapLabel.Parent = lapSection

local lapTextStroke = addStroke(lapLabel, Color3.fromRGB(10, 12, 20), 3.5, Enum.ApplyStrokeMode.Contextual)
addGradient(lapLabel, ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(220, 230, 245)),
}), 90)


-- ============================================================
-- 3. BOTTOM-RIGHT: POSITION RANK (3D VIBRANT MK8 STYLE)
-- ============================================================
local rankContainer = Instance.new("Frame")
rankContainer.Name = "RankContainer"
rankContainer.Size = UDim2.new(0, 220, 0, 130)
rankContainer.Position = UDim2.new(1, -240, 1, -145)
rankContainer.BackgroundTransparency = 1
rankContainer.ZIndex = 4
rankContainer.Parent = sg

-- Soft Backing Radial Glow so position number pops against any terrain
local rankGlow = Instance.new("Frame")
rankGlow.Name = "RankGlow"
rankGlow.Size = UDim2.new(0, 160, 0, 110)
rankGlow.Position = UDim2.new(0, 20, 0, 10)
rankGlow.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
rankGlow.BackgroundTransparency = 0.85
rankGlow.ZIndex = 3
rankGlow.Parent = rankContainer
addCorner(rankGlow, 55)

-- Big Skewed Position Number
local rankNumLabel = Instance.new("TextLabel")
rankNumLabel.Name = "RankNum"
rankNumLabel.Size = UDim2.new(0, 130, 1, 0)
rankNumLabel.Position = UDim2.new(0, 0, 0, 0)
rankNumLabel.BackgroundTransparency = 1
rankNumLabel.Text = "1"
rankNumLabel.Font = Enum.Font.LuckiestGuy
rankNumLabel.TextSize = 115
rankNumLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
rankNumLabel.TextXAlignment = Enum.TextXAlignment.Right
rankNumLabel.ZIndex = 5
rankNumLabel.Parent = rankContainer

local rankNumStroke = addStroke(rankNumLabel, Color3.fromRGB(12, 14, 24), 7, Enum.ApplyStrokeMode.Contextual)

-- Position Suffix ("st", "nd", "rd", "th")
local rankSuffixLabel = Instance.new("TextLabel")
rankSuffixLabel.Name = "RankSuffix"
rankSuffixLabel.Size = UDim2.new(0, 75, 0.5, 0)
rankSuffixLabel.Position = UDim2.new(0, 134, 0, 52)
rankSuffixLabel.BackgroundTransparency = 1
rankSuffixLabel.Text = "st"
rankSuffixLabel.Font = Enum.Font.LuckiestGuy
rankSuffixLabel.TextSize = 48
rankSuffixLabel.TextColor3 = Color3.fromRGB(255, 210, 50)
rankSuffixLabel.TextXAlignment = Enum.TextXAlignment.Left
rankSuffixLabel.ZIndex = 5
rankSuffixLabel.Parent = rankContainer

local rankSuffixStroke = addStroke(rankSuffixLabel, Color3.fromRGB(12, 14, 24), 5, Enum.ApplyStrokeMode.Contextual)

-- Dynamic Color Gradients according to Rank
local function updateRankDisplay(rankNumber)
	local suffixes = { [1] = "st", [2] = "nd", [3] = "rd" }
	local suffix = suffixes[rankNumber] or "th"
	rankNumLabel.Text = tostring(rankNumber)
	rankSuffixLabel.Text = suffix

	-- Remove old gradients if any
	local oldG1 = rankNumLabel:FindFirstChildOfClass("UIGradient")
	if oldG1 then oldG1:Destroy() end
	local oldG2 = rankSuffixLabel:FindFirstChildOfClass("UIGradient")
	if oldG2 then oldG2:Destroy() end

	local seq, glowColor
	if rankNumber == 1 then
		seq = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 245, 120)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 185, 0)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(230, 110, 0)),
		})
		glowColor = Color3.fromRGB(255, 180, 0)
	elseif rankNumber == 2 then
		seq = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 215, 235)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(120, 140, 170)),
		})
		glowColor = Color3.fromRGB(180, 200, 230)
	elseif rankNumber == 3 then
		seq = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 210, 140)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(230, 140, 60)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(170, 70, 20)),
		})
		glowColor = Color3.fromRGB(230, 130, 40)
	else
		seq = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 200, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 0)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(200, 70, 0)),
		})
		glowColor = Color3.fromRGB(255, 130, 0)
	end

	addGradient(rankNumLabel, seq, 85)
	addGradient(rankSuffixLabel, seq, 85)
	rankGlow.BackgroundColor3 = glowColor
end
updateRankDisplay(1)


-- ============================================================
-- 4. CENTER: COUNTDOWN & LAP NOTIFICATIONS
-- ============================================================
local cdLabel = Instance.new("TextLabel")
cdLabel.Name = "CountdownLabel"
cdLabel.Text = ""
cdLabel.Font = Enum.Font.LuckiestGuy
cdLabel.TextSize = 150
cdLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
cdLabel.Size = UDim2.new(1, 0, 0, 200)
cdLabel.Position = UDim2.new(0, 0, 0.5, -100)
cdLabel.BackgroundTransparency = 1
cdLabel.TextXAlignment = Enum.TextXAlignment.Center
cdLabel.TextTransparency = 1
cdLabel.ZIndex = 20
cdLabel.Parent = sg

local cdStroke = addStroke(cdLabel, Color3.fromRGB(10, 12, 22), 8, Enum.ApplyStrokeMode.Contextual)
addGradient(cdLabel, ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 160)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 160, 0)),
}), 90)

-- Lap Banner Notification Frame
local bannerFrame = Instance.new("Frame")
bannerFrame.Name = "LapBanner"
bannerFrame.Size = UDim2.new(0, 460, 0, 88)
bannerFrame.Position = UDim2.new(0.5, -230, 0.28, 0)
bannerFrame.BackgroundColor3 = Color3.fromRGB(14, 18, 30)
bannerFrame.BackgroundTransparency = 1
bannerFrame.BorderSizePixel = 0
bannerFrame.ZIndex = 15
bannerFrame.Parent = sg
addCorner(bannerFrame, 22)
addShadow(bannerFrame, 12, 0.6)

local bannerStroke = addStroke(bannerFrame, Color3.fromRGB(255, 200, 0), 3.5)
bannerStroke.Transparency = 1

local bannerLabel = Instance.new("TextLabel")
bannerLabel.Size = UDim2.new(1, 0, 1, 0)
bannerLabel.BackgroundTransparency = 1
bannerLabel.Text = ""
bannerLabel.Font = Enum.Font.LuckiestGuy
bannerLabel.TextSize = 38
bannerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bannerLabel.ZIndex = 16
bannerLabel.Parent = bannerFrame

local bannerTextStroke = addStroke(bannerLabel, Color3.fromRGB(10, 12, 20), 5, Enum.ApplyStrokeMode.Contextual)
bannerTextStroke.Transparency = 1

local function showBanner(text, strokeColor)
	bannerLabel.Text = text
	bannerStroke.Color = strokeColor or Color3.fromRGB(255, 200, 0)
	
	bannerFrame.BackgroundTransparency = 0.15
	bannerStroke.Transparency = 0
	bannerTextStroke.Transparency = 0
	bannerLabel.TextTransparency = 0
	
	bannerFrame.Size = UDim2.new(0, 340, 0, 64)
	bannerFrame.Position = UDim2.new(0.5, -170, 0.28, 0)
	
	local popIn = TweenService:Create(bannerFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 460, 0, 88), Position = UDim2.new(0.5, -230, 0.28, 0) }
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
		{ Size = UDim2.new(1, 0, 0, 200), Position = UDim2.new(0, 0, 0.5, -100) }
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

print("[RaceHUD] Ultra Premium MK8 Overlay UI Loaded!")
