-- HudScript (StarterGui > RaceHUDGui) - Mario Kart 8 Deluxe Style Overlay
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RF = ReplicatedStorage:WaitForChild("BrainKartRemotes", 20)
if not RF then warn("[RaceHUD] BrainKartRemotes not found!"); return end

-- Create ScreenGui
local sg = Instance.new("ScreenGui")
sg.Name = "RaceHUD"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.Enabled = true
sg.Parent = playerGui

-- Helpers for styling
local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

-- ============================================================
-- 1. TOP-LEFT: ITEM SLOTS (ABILIDADES - MK8 STYLE)
-- ============================================================
local itemContainer = Instance.new("Frame")
itemContainer.Name = "ItemContainer"
itemContainer.Size = UDim2.new(0, 140, 0, 140)
itemContainer.Position = UDim2.new(0, 25, 0, 25)
itemContainer.BackgroundTransparency = 1
itemContainer.Parent = sg

-- Primary Item Circle (Held Item)
local mainItemCircle = Instance.new("Frame")
mainItemCircle.Name = "MainItemSlot"
mainItemCircle.Size = UDim2.new(0, 85, 0, 85)
mainItemCircle.Position = UDim2.new(0, 30, 0, 30)
mainItemCircle.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
mainItemCircle.BackgroundTransparency = 0.35
mainItemCircle.Parent = itemContainer
addCorner(mainItemCircle, 45)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(200, 205, 215)
mainStroke.Thickness = 4.5
mainStroke.Parent = mainItemCircle

-- Inner Ring Glow
local mainInnerGlow = Instance.new("Frame")
mainInnerGlow.Size = UDim2.new(1, -8, 1, -8)
mainInnerGlow.Position = UDim2.new(0, 4, 0, 4)
mainInnerGlow.BackgroundTransparency = 1
mainInnerGlow.Parent = mainItemCircle
addCorner(mainInnerGlow, 40)
local innerStroke = Instance.new("UIStroke")
innerStroke.Color = Color3.fromRGB(60, 65, 80)
innerStroke.Thickness = 2
innerStroke.Parent = mainInnerGlow

-- Secondary Item Circle (Stored / Backup Item)
local subItemCircle = Instance.new("Frame")
subItemCircle.Name = "SubItemSlot"
subItemCircle.Size = UDim2.new(0, 52, 0, 52)
subItemCircle.Position = UDim2.new(0, 5, 0, 5)
subItemCircle.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
subItemCircle.BackgroundTransparency = 0.35
subItemCircle.ZIndex = 2
subItemCircle.Parent = itemContainer
addCorner(subItemCircle, 26)

local subStroke = Instance.new("UIStroke")
subStroke.Color = Color3.fromRGB(160, 165, 175)
subStroke.Thickness = 3.5
subStroke.Parent = subItemCircle

-- Placeholder Icons for Items
local mainItemIcon = Instance.new("ImageLabel")
mainItemIcon.Name = "ItemIcon"
mainItemIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
mainItemIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
mainItemIcon.BackgroundTransparency = 1
mainItemIcon.Image = ""
mainItemIcon.Parent = mainItemCircle

local subItemIcon = Instance.new("ImageLabel")
subItemIcon.Name = "ItemIcon"
subItemIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
subItemIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
subItemIcon.BackgroundTransparency = 1
subItemIcon.Image = ""
subItemIcon.Parent = subItemCircle


-- ============================================================
-- 2. BOTTOM-LEFT: COINS & LAPS PANEL (MK8 STYLE)
-- ============================================================
local infoPanel = Instance.new("Frame")
infoPanel.Name = "CoinsAndLapPanel"
infoPanel.Size = UDim2.new(0, 240, 0, 56)
infoPanel.Position = UDim2.new(0, 30, 1, -85)
infoPanel.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
infoPanel.BackgroundTransparency = 0.35
infoPanel.BorderSizePixel = 0
infoPanel.Parent = sg
addCorner(infoPanel, 16)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(90, 95, 110)
panelStroke.Thickness = 2
panelStroke.Parent = infoPanel

-- Coin Section (Left Half)
local coinFrame = Instance.new("Frame")
coinFrame.Name = "CoinSection"
coinFrame.Size = UDim2.new(0.48, 0, 1, 0)
coinFrame.Position = UDim2.new(0, 0, 0, 0)
coinFrame.BackgroundTransparency = 1
coinFrame.Parent = infoPanel

-- Gold Coin Icon
local coinBg = Instance.new("Frame")
coinBg.Size = UDim2.new(0, 32, 0, 32)
coinBg.Position = UDim2.new(0, 14, 0.5, -16)
coinBg.BackgroundColor3 = Color3.fromRGB(255, 205, 0)
coinBg.Parent = coinFrame
addCorner(coinBg, 16)
local coinOuterStroke = Instance.new("UIStroke")
coinOuterStroke.Color = Color3.fromRGB(200, 140, 0)
coinOuterStroke.Thickness = 3
coinOuterStroke.Parent = coinBg

local coinInner = Instance.new("TextLabel")
coinInner.Size = UDim2.new(1, 0, 1, 0)
coinInner.BackgroundTransparency = 1
coinInner.Text = "$"
coinInner.Font = Enum.Font.FredokaOne
coinInner.TextSize = 20
coinInner.TextColor3 = Color3.fromRGB(160, 100, 0)
coinInner.Parent = coinBg

local coinCountLabel = Instance.new("TextLabel")
coinCountLabel.Name = "CoinCount"
coinCountLabel.Size = UDim2.new(0, 55, 1, 0)
coinCountLabel.Position = UDim2.new(0, 52, 0, 0)
coinCountLabel.BackgroundTransparency = 1
coinCountLabel.Text = "00"
coinCountLabel.Font = Enum.Font.FredokaOne
coinCountLabel.TextSize = 28
coinCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
coinCountLabel.TextXAlignment = Enum.TextXAlignment.Left
coinCountLabel.Parent = coinFrame

-- Vertical Separator
local sep = Instance.new("Frame")
sep.Size = UDim2.new(0, 2, 0.6, 0)
sep.Position = UDim2.new(0.48, 0, 0.2, 0)
sep.BackgroundColor3 = Color3.fromRGB(150, 155, 170)
sep.BackgroundTransparency = 0.5
sep.BorderSizePixel = 0
sep.Parent = infoPanel

-- Lap Section (Right Half)
local lapFrame = Instance.new("Frame")
lapFrame.Name = "LapSection"
lapFrame.Size = UDim2.new(0.5, 0, 1, 0)
lapFrame.Position = UDim2.new(0.5, 0, 0, 0)
lapFrame.BackgroundTransparency = 1
lapFrame.Parent = infoPanel

-- Checkered Flag Graphic / Icon
local flagIcon = Instance.new("TextLabel")
flagIcon.Size = UDim2.new(0, 32, 0, 32)
flagIcon.Position = UDim2.new(0, 10, 0.5, -16)
flagIcon.BackgroundTransparency = 1
flagIcon.Text = "🏁"
flagIcon.TextSize = 24
flagIcon.Parent = lapFrame

local lapCountLabel = Instance.new("TextLabel")
lapCountLabel.Name = "LapCount"
lapCountLabel.Size = UDim2.new(0, 70, 1, 0)
lapCountLabel.Position = UDim2.new(0, 44, 0, 0)
lapCountLabel.BackgroundTransparency = 1
lapCountLabel.Text = "1/3"
lapCountLabel.Font = Enum.Font.FredokaOne
lapCountLabel.TextSize = 26
lapCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
lapCountLabel.TextXAlignment = Enum.TextXAlignment.Left
lapCountLabel.Parent = lapFrame


-- ============================================================
-- 3. BOTTOM-RIGHT: POSITION RANK (LUGAR - MK8 STYLE)
-- ============================================================
local rankContainer = Instance.new("Frame")
rankContainer.Name = "RankContainer"
rankContainer.Size = UDim2.new(0, 180, 0, 110)
rankContainer.Position = UDim2.new(1, -200, 1, -130)
rankContainer.BackgroundTransparency = 1
rankContainer.Parent = sg

-- Big Position Number
local rankNumLabel = Instance.new("TextLabel")
rankNumLabel.Name = "RankNum"
rankNumLabel.Size = UDim2.new(0, 110, 1, 0)
rankNumLabel.Position = UDim2.new(0, 0, 0, 0)
rankNumLabel.BackgroundTransparency = 1
rankNumLabel.Text = "1"
rankNumLabel.Font = Enum.Font.FredokaOne
rankNumLabel.TextSize = 100
rankNumLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
rankNumLabel.TextXAlignment = Enum.TextXAlignment.Right
rankNumLabel.Parent = rankContainer

local rankNumStroke = Instance.new("UIStroke")
rankNumStroke.Color = Color3.fromRGB(20, 20, 30)
rankNumStroke.Thickness = 6
rankNumStroke.Parent = rankNumLabel

-- Position Suffix ("st", "nd", "rd", "th")
local rankSuffixLabel = Instance.new("TextLabel")
rankSuffixLabel.Name = "RankSuffix"
rankSuffixLabel.Size = UDim2.new(0, 60, 0.5, 0)
rankSuffixLabel.Position = UDim2.new(0, 114, 0, 48)
rankSuffixLabel.BackgroundTransparency = 1
rankSuffixLabel.Text = "st"
rankSuffixLabel.Font = Enum.Font.FredokaOne
rankSuffixLabel.TextSize = 42
rankSuffixLabel.TextColor3 = Color3.fromRGB(255, 190, 40)
rankSuffixLabel.TextXAlignment = Enum.TextXAlignment.Left
rankSuffixLabel.Parent = rankContainer

local rankSuffixStroke = Instance.new("UIStroke")
rankSuffixStroke.Color = Color3.fromRGB(20, 20, 30)
rankSuffixStroke.Thickness = 4.5
rankSuffixStroke.Parent = rankSuffixLabel

local function updateRankDisplay(rankNumber)
	local suffixes = { [1] = "st", [2] = "nd", [3] = "rd" }
	local suffix = suffixes[rankNumber] or "th"
	rankNumLabel.Text = tostring(rankNumber)
	rankSuffixLabel.Text = suffix

	if rankNumber == 1 then
		rankNumLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
		rankSuffixLabel.TextColor3 = Color3.fromRGB(255, 210, 50)
	elseif rankNumber == 2 then
		rankNumLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
		rankSuffixLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
	elseif rankNumber == 3 then
		rankNumLabel.TextColor3 = Color3.fromRGB(220, 130, 50)
		rankSuffixLabel.TextColor3 = Color3.fromRGB(240, 160, 80)
	else
		rankNumLabel.TextColor3 = Color3.fromRGB(255, 140, 20)
		rankSuffixLabel.TextColor3 = Color3.fromRGB(255, 170, 40)
	end
end
updateRankDisplay(1)


-- ============================================================
-- 4. CENTER: COUNTDOWN & LAP NOTIFICATIONS
-- ============================================================
local cdLabel = Instance.new("TextLabel")
cdLabel.Name = "CountdownLabel"
cdLabel.Text = ""
cdLabel.Font = Enum.Font.FredokaOne
cdLabel.TextSize = 140
cdLabel.TextColor3 = Color3.fromRGB(255, 205, 0)
cdLabel.Size = UDim2.new(1, 0, 0, 180)
cdLabel.Position = UDim2.new(0, 0, 0.5, -90)
cdLabel.BackgroundTransparency = 1
cdLabel.TextXAlignment = Enum.TextXAlignment.Center
cdLabel.TextTransparency = 1
cdLabel.ZIndex = 20
cdLabel.Parent = sg

local cdStroke = Instance.new("UIStroke")
cdStroke.Color = Color3.fromRGB(20, 20, 30)
cdStroke.Thickness = 7
cdStroke.Parent = cdLabel

-- Lap Banner Notification
local bannerFrame = Instance.new("Frame")
bannerFrame.Name = "LapBanner"
bannerFrame.Size = UDim2.new(0, 440, 0, 84)
bannerFrame.Position = UDim2.new(0.5, -220, 0.28, 0)
bannerFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
bannerFrame.BackgroundTransparency = 1
bannerFrame.BorderSizePixel = 0
bannerFrame.ZIndex = 15
bannerFrame.Parent = sg
addCorner(bannerFrame, 20)

local bannerStroke = Instance.new("UIStroke")
bannerStroke.Color = Color3.fromRGB(255, 200, 0)
bannerStroke.Thickness = 3
bannerStroke.Transparency = 1
bannerStroke.Parent = bannerFrame

local bannerLabel = Instance.new("TextLabel")
bannerLabel.Size = UDim2.new(1, 0, 1, 0)
bannerLabel.BackgroundTransparency = 1
bannerLabel.Text = ""
bannerLabel.Font = Enum.Font.FredokaOne
bannerLabel.TextSize = 36
bannerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bannerLabel.ZIndex = 16
bannerLabel.Parent = bannerFrame

local bannerTextStroke = Instance.new("UIStroke")
bannerTextStroke.Color = Color3.fromRGB(10, 10, 20)
bannerTextStroke.Thickness = 4
bannerTextStroke.Transparency = 1
bannerTextStroke.Parent = bannerLabel

local function showBanner(text, strokeColor)
	bannerLabel.Text = text
	bannerStroke.Color = strokeColor or Color3.fromRGB(255, 200, 0)
	
	bannerFrame.BackgroundTransparency = 0.2
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
	lapCountLabel.Text = "1/" .. totalLaps
	sg.Enabled = true
end)

RF:WaitForChild("Countdown", 10).OnClientEvent:Connect(function(count)
	cdLabel.Text = count == 0 and "GO!" or tostring(count)
	cdLabel.TextColor3 = count == 0 and Color3.fromRGB(40, 255, 120) or Color3.fromRGB(255, 205, 0)
	cdLabel.TextTransparency = 0
	cdStroke.Transparency = 0
	
	cdLabel.Size = UDim2.new(0, 100, 0, 100)
	cdLabel.Position = UDim2.new(0.5, -50, 0.5, -50)
	
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
	lapCountLabel.Text = currentLap .. "/" .. maxLaps
	
	if currentLap < maxLaps then
		showBanner("🏁  VOLTA " .. currentLap .. " DE " .. maxLaps, Color3.fromRGB(0, 160, 255))
	else
		showBanner("⚡  ÚLTIMA VOLTA!", Color3.fromRGB(255, 50, 50))
		lapCountLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	end
end)

RF:WaitForChild("UpdatePositions", 10).OnClientEvent:Connect(function(data)
	for _, e in ipairs(data) do
		if e.name == player.Name then
			updateRankDisplay(e.pos)
			if e.lap then
				lapCountLabel.Text = math.max(1, e.lap) .. "/" .. totalLaps
			end
		end
	end
end)

RF:WaitForChild("PlayerFinished", 10).OnClientEvent:Connect(function(pos)
	updateRankDisplay(pos)
	showBanner("🏆  FINISH! " .. pos .. "º LUGAR", Color3.fromRGB(255, 180, 0))
end)

print("[RaceHUD] MK8 Overlay UI v1 Loaded!")
