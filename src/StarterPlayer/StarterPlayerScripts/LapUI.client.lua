-- LapUI.client.lua
-- Mostra a volta atual, total de voltas e notificação ao cruzar a meta

local Players    = game:GetService("Players")
local RSt        = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar pelos RemoteEvents
local RF       = RSt:WaitForChild("BrainKartRemotes", 15)
if not RF then warn("[LapUI] BrainKartRemotes não encontrado"); return end

local LapEv    = RF:WaitForChild("LapUpdate", 15)
local StartEv  = RF:WaitForChild("StartRace", 15)
local FinEv    = RF:WaitForChild("PlayerFinished", 15)
local CountEv  = RF:WaitForChild("Countdown", 15)

-- ─── Criar UI ─────────────────────────────────────────────────────────────────

local screen = Instance.new("ScreenGui")
screen.Name = "LapUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.Parent = playerGui

-- Contador de voltas (canto superior direito)
local lapFrame = Instance.new("Frame")
lapFrame.Name = "LapFrame"
lapFrame.Size = UDim2.new(0, 220, 0, 70)
lapFrame.Position = UDim2.new(1, -230, 0, 20)
lapFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
lapFrame.BackgroundTransparency = 0.4
lapFrame.BorderSizePixel = 0
lapFrame.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = lapFrame

local lapLabel = Instance.new("TextLabel")
lapLabel.Size = UDim2.new(1, 0, 1, 0)
lapLabel.BackgroundTransparency = 1
lapLabel.Text = "VOLTA  -/-"
lapLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
lapLabel.Font = Enum.Font.GothamBold
lapLabel.TextScaled = true
lapLabel.Parent = lapFrame

-- Notificação de volta (centro do ecrã)
local notifFrame = Instance.new("Frame")
notifFrame.Name = "LapNotif"
notifFrame.Size = UDim2.new(0, 400, 0, 90)
notifFrame.Position = UDim2.new(0.5, -200, 0.3, 0)
notifFrame.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
notifFrame.BackgroundTransparency = 1
notifFrame.BorderSizePixel = 0
notifFrame.Visible = false
notifFrame.Parent = screen

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 16)
notifCorner.Parent = notifFrame

local notifLabel = Instance.new("TextLabel")
notifLabel.Size = UDim2.new(1, 0, 1, 0)
notifLabel.BackgroundTransparency = 1
notifLabel.Text = ""
notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifLabel.Font = Enum.Font.GothamBold
notifLabel.TextScaled = true
notifLabel.Parent = notifFrame

-- Countdown no centro
local countFrame = Instance.new("Frame")
countFrame.Size = UDim2.new(0, 200, 0, 200)
countFrame.Position = UDim2.new(0.5, -100, 0.5, -100)
countFrame.BackgroundTransparency = 1
countFrame.Visible = false
countFrame.Parent = screen

local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, 0, 1, 0)
countLabel.BackgroundTransparency = 1
countLabel.TextColor3 = Color3.fromRGB(255, 220, 0)
countLabel.Font = Enum.Font.GothamBold
countLabel.TextScaled = true
countLabel.Parent = countFrame

-- ─── Animação de notificação ──────────────────────────────────────────────────

local function showNotif(text, color)
	notifLabel.Text = text
	notifFrame.BackgroundColor3 = color or Color3.fromRGB(255, 200, 0)
	notifFrame.BackgroundTransparency = 0.15
	notifFrame.Visible = true
	notifFrame.Size = UDim2.new(0, 300, 0, 70)
	notifFrame.Position = UDim2.new(0.5, -150, 0.3, 0)

	-- Animação de entrada
	local tween = game:GetService("TweenService"):Create(notifFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 400, 0, 90), Position = UDim2.new(0.5, -200, 0.3, 0)}
	)
	tween:Play()

	task.delay(2.5, function()
		local fadeOut = game:GetService("TweenService"):Create(notifFrame,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{BackgroundTransparency = 1}
		)
		local fadeText = game:GetService("TweenService"):Create(notifLabel,
			TweenInfo.new(0.5), {TextTransparency = 1}
		)
		fadeOut:Play(); fadeText:Play()
		task.delay(0.6, function()
			notifFrame.Visible = false
			notifLabel.TextTransparency = 0
		end)
	end)
end

-- ─── Eventos ──────────────────────────────────────────────────────────────────

local totalLaps = 3

StartEv.OnClientEvent:Connect(function(laps)
	totalLaps = laps
	lapLabel.Text = "VOLTA  1/" .. laps
end)

CountEv.OnClientEvent:Connect(function(n)
	countFrame.Visible = true
	if n == 0 then
		countLabel.Text = "GO!"
		countLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
		task.delay(1.2, function() countFrame.Visible = false end)
	else
		countLabel.Text = tostring(n)
		countLabel.TextColor3 = Color3.fromRGB(255, 220, 0)
	end

	-- Animação de escala
	countFrame.Size = UDim2.new(0, 100, 0, 100)
	countFrame.Position = UDim2.new(0.5, -50, 0.5, -50)
	local pop = game:GetService("TweenService"):Create(countFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 200, 0, 200), Position = UDim2.new(0.5, -100, 0.5, -100)}
	)
	pop:Play()
end)

LapEv.OnClientEvent:Connect(function(currentLap, maxLaps)
	totalLaps = maxLaps
	lapLabel.Text = "VOLTA  " .. currentLap .. "/" .. maxLaps

	if currentLap < maxLaps then
		showNotif("🏁  Volta " .. currentLap .. " de " .. maxLaps, Color3.fromRGB(30, 120, 255))
	else
		showNotif("🏆  ÚLTIMA VOLTA!", Color3.fromRGB(255, 60, 60))
		lapLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	end
end)

FinEv.OnClientEvent:Connect(function(pos)
	local msgs = {"🥇 1.º Lugar!", "🥈 2.º Lugar!", "🥉 3.º Lugar!"}
	local msg = msgs[pos] or (pos .. ".º Lugar!")
	showNotif("🏁  CHEGASTE!  " .. msg, Color3.fromRGB(255, 160, 0))
end)

print("[LapUI] Interface de voltas carregada!")
