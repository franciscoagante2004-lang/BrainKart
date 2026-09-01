-- HudScript (StarterGui > RaceHUDGui) - v4 LocalScript
-- HUD de corrida: posicao, voltas, velocidade, countdown, resultados

local Players = game:GetService("Players")
local RSt     = game:GetService("ReplicatedStorage")
local RS      = game:GetService("RunService")
local TS      = game:GetService("TweenService")

local player = Players.LocalPlayer
local pg     = player.PlayerGui

local RF = RSt:WaitForChild("BrainKartRemotes", 20)
if not RF then warn("[HUD] BrainKartRemotes nao encontrado!"); return end

-- ============================================================
-- CRIAR HUD (ScreenGui)
-- ============================================================
local sg = Instance.new("ScreenGui")
sg.Name            = "RaceHUD"
sg.ResetOnSpawn    = false
sg.IgnoreGuiInset  = true
sg.Enabled         = false  -- so mostra quando corrida comeca
sg.Parent          = pg

local function CR(p, r)
	Instance.new("UICorner", p).CornerRadius = UDim.new(0, r or 14)
end

local function makePanel(size, pos, alpha)
	local f = Instance.new("Frame")
	f.Size                = size
	f.Position            = pos
	f.BackgroundColor3    = Color3.fromRGB(0, 0, 0)
	f.BackgroundTransparency = alpha or 0.3
	f.BorderSizePixel     = 0
	f.Parent              = sg
	CR(f)
	return f
end

local function makeLabel(text, font, size, color, szU, posU, parent)
	local l = Instance.new("TextLabel")
	l.Text             = text
	l.Font             = font
	l.TextSize         = size
	l.TextColor3       = color
	l.Size             = szU
	l.Position         = posU
	l.BackgroundTransparency = 1
	l.TextXAlignment   = Enum.TextXAlignment.Center
	l.Parent           = parent
	return l
end

-- POSICAO (canto superior direito)
local posPanel = makePanel(UDim2.new(0, 140, 0, 80), UDim2.new(1, -155, 0, 15))
local posLabel = makeLabel("1", Enum.Font.GothamBlack, 52,
	Color3.fromRGB(255, 200, 0), UDim2.new(1, 0, 0.62, 0), UDim2.new(0, 0, 0, 2), posPanel)
makeLabel("POSICAO", Enum.Font.GothamBold, 11,
	Color3.fromRGB(170, 170, 200), UDim2.new(1, 0, 0.3, 0), UDim2.new(0, 0, 0.72, 0), posPanel)

-- VOLTA (canto superior esquerdo)
local lapPanel = makePanel(UDim2.new(0, 140, 0, 80), UDim2.new(0, 15, 0, 15))
local lapLabel = makeLabel("0/3", Enum.Font.GothamBlack, 34,
	Color3.fromRGB(255, 255, 255), UDim2.new(1, 0, 0.62, 0), UDim2.new(0, 0, 0, 2), lapPanel)
makeLabel("VOLTA", Enum.Font.GothamBold, 11,
	Color3.fromRGB(170, 170, 200), UDim2.new(1, 0, 0.3, 0), UDim2.new(0, 0, 0.72, 0), lapPanel)

-- VELOCIDADE (centro topo)
local spdPanel = makePanel(UDim2.new(0, 110, 0, 55), UDim2.new(0.5, -55, 0, 15))
local spdLabel = makeLabel("0", Enum.Font.GothamBlack, 30,
	Color3.fromRGB(100, 200, 255), UDim2.new(1, 0, 0.6, 0), UDim2.new(0, 0, 0, 2), spdPanel)
makeLabel("km/h", Enum.Font.GothamBold, 11,
	Color3.fromRGB(170, 170, 200), UDim2.new(1, 0, 0.35, 0), UDim2.new(0, 0, 0.65, 0), spdPanel)

-- COUNTDOWN (centro do ecra)
local cdLabel = Instance.new("TextLabel")
cdLabel.Text             = ""
cdLabel.Font             = Enum.Font.GothamBlack
cdLabel.TextSize         = 130
cdLabel.TextColor3       = Color3.fromRGB(255, 200, 0)
cdLabel.Size             = UDim2.new(1, 0, 0, 170)
cdLabel.Position         = UDim2.new(0, 0, 0.5, -85)
cdLabel.BackgroundTransparency = 1
cdLabel.TextXAlignment   = Enum.TextXAlignment.Center
cdLabel.TextTransparency = 1
cdLabel.ZIndex           = 15
cdLabel.Parent           = sg

-- ============================================================
-- EVENTOS
-- ============================================================
local totalLaps = 3

RF:WaitForChild("StartRace", 10).OnClientEvent:Connect(function(laps)
	totalLaps     = laps or 3
	lapLabel.Text = "0/" .. totalLaps
	sg.Enabled    = true
end)

RF:WaitForChild("Countdown", 10).OnClientEvent:Connect(function(count)
	cdLabel.Text       = count == 0 and "GO!" or tostring(count)
	cdLabel.TextColor3 = count == 0
		and Color3.fromRGB(0, 255, 120)
		or  Color3.fromRGB(255, 200, 0)
	cdLabel.TextTransparency = 0
	TS:Create(cdLabel, TweenInfo.new(0.9), { TextTransparency = 1 }):Play()
end)

RF:WaitForChild("EndRace", 10).OnClientEvent:Connect(function(results)
	-- Criar ecra de resultados
	local rg = Instance.new("ScreenGui")
	rg.Name         = "Results"
	rg.ResetOnSpawn = false
	rg.Parent       = pg

	local rb = Instance.new("Frame")
	rb.Size                = UDim2.new(1, 0, 1, 0)
	rb.BackgroundColor3    = Color3.fromRGB(0, 0, 0)
	rb.BackgroundTransparency = 0.4
	rb.Parent              = rg

	local rp = Instance.new("Frame")
	rp.Size             = UDim2.new(0, 460, 0, 400)
	rp.Position         = UDim2.new(0.5, -230, 0.5, -200)
	rp.BackgroundColor3 = Color3.fromRGB(8, 12, 45)
	rp.BorderSizePixel  = 0
	rp.Parent           = rg
	Instance.new("UICorner", rp).CornerRadius = UDim.new(0, 22)

	local rt = Instance.new("TextLabel")
	rt.Text              = "RESULTADOS"
	rt.Font              = Enum.Font.GothamBlack
	rt.TextSize          = 34
	rt.TextColor3        = Color3.fromRGB(255, 200, 0)
	rt.Size              = UDim2.new(1, 0, 0, 66)
	rt.BackgroundTransparency = 1
	rt.TextXAlignment    = Enum.TextXAlignment.Center
	rt.Parent            = rp

	local medals = { "1 ", "2 ", "3 " }
	for i, r in ipairs(results) do
		local row = Instance.new("TextLabel")
		local ts  = r.time > 0 and string.format("%.1fs", r.time) or "DNF"
		row.Text  = (medals[i] or (i .. "o ")) .. r.name .. "   " .. ts
		row.Font  = Enum.Font.GothamBold
		row.TextSize  = 20
		row.TextColor3 = Color3.fromRGB(255, 255, 255)
		row.Size       = UDim2.new(0.9, 0, 0, 42)
		row.Position   = UDim2.new(0.05, 0, 0, 66 + i * 44)
		row.BackgroundTransparency = 1
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Parent         = rp
	end

	sg.Enabled = false
end)

RF:WaitForChild("UpdatePositions", 10).OnClientEvent:Connect(function(data, pData)
	for _, e in ipairs(data) do
		if e.name == player.Name then
			posLabel.Text = tostring(e.pos)
		end
	end
	if pData then
		for p, d in pairs(pData) do
			if typeof(p) == "Instance" and p.Name == player.Name then
				lapLabel.Text = d.lap .. "/" .. totalLaps
				break
			end
		end
	end
end)

-- ============================================================
-- VELOCIDADE EM TEMPO REAL
-- ============================================================
RS.Heartbeat:Connect(function()
	local k = workspace:FindFirstChild(player.Name .. "Kart")
	if k then
		local kr = k:FindFirstChild("KartRoot")
		if kr then
			local v   = kr.AssemblyLinearVelocity
			local spd = math.floor(Vector3.new(v.X, 0, v.Z).Magnitude * 3.6)
			spdLabel.Text = tostring(spd)
		end
	end
end)

print("[HUD] RaceHUD v4 carregado!")
