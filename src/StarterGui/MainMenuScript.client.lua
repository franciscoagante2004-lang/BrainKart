-- MainMenuScript (StarterGui) - v4 LocalScript
-- Menu principal com selecao de modo e numero de voltas

local Players = game:GetService("Players")
local RSt     = game:GetService("ReplicatedStorage")
local TS      = game:GetService("TweenService")

local player = Players.LocalPlayer
local pg     = player.PlayerGui

-- ============================================================
-- HELPERS DE UI
-- ============================================================
local function E(cls, props, parent)
	local e = Instance.new(cls)
	for k, v in pairs(props or {}) do pcall(function() e[k] = v end) end
	if parent then e.Parent = parent end
	return e
end

local function CR(p, r)
	Instance.new("UICorner", p).CornerRadius = UDim.new(0, r or 14)
end

local function GR(p, cols, rot)
	local kps = {}
	for i, c in ipairs(cols) do
		table.insert(kps, ColorSequenceKeypoint.new((i-1)/(#cols-1), c))
	end
	E("UIGradient", { Color = ColorSequence.new(kps), Rotation = rot or 0 }, p)
end

local function hoverFx(btn, normal, hovered)
	btn.MouseEnter:Connect(function()
		TS:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = hovered }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TS:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = normal }):Play()
	end)
end

-- ============================================================
-- PALETA DE CORES
-- ============================================================
local C = {
	bg    = Color3.fromRGB(5,  10, 30),
	bg2   = Color3.fromRGB(15, 5,  45),
	acc   = Color3.fromRGB(255, 200, 0),
	acc2  = Color3.fromRGB(255, 130, 0),
	blue  = Color3.fromRGB(60,  130, 255),
	green = Color3.fromRGB(50,  200, 80),
	white = Color3.fromRGB(255, 255, 255),
	dark  = Color3.fromRGB(22,  22,  50),
}

-- ============================================================
-- SCREEN GUI + FUNDO
-- ============================================================
local sg = E("ScreenGui", {
	Name = "MenuGui", ResetOnSpawn = false, IgnoreGuiInset = true
}, pg)

local bg = E("Frame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = C.bg,
	BorderSizePixel  = 0,
}, sg)
GR(bg, { C.bg, C.bg2 }, 135)

-- Estrelas de fundo
for i = 1, 80 do
	local s = E("Frame", {
		Size       = UDim2.new(0, math.random(1, 3), 0, math.random(1, 3)),
		Position   = UDim2.new(math.random(), 0, math.random(), 0),
		BackgroundColor3 = C.white,
		BackgroundTransparency = math.random() * 0.7 + 0.1,
		BorderSizePixel = 0,
	}, bg)
	CR(s, 50)
end

-- ============================================================
-- PAINEL CENTRAL
-- ============================================================
local panel = E("Frame", {
	Name = "Panel",
	Size = UDim2.new(0, 500, 0, 490),
	Position = UDim2.new(0.5, -250, -0.7, 0), -- começa fora do ecra
	BackgroundColor3 = Color3.fromRGB(8, 12, 45),
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
}, sg)
CR(panel, 26)

-- Linha decorativa no topo
local topLine = E("Frame", {
	Size = UDim2.new(1, 0, 0, 5),
	BackgroundColor3 = C.acc,
	BorderSizePixel  = 0,
}, panel)
CR(topLine, 5)
GR(topLine, { C.acc, C.acc2, C.acc }, 90)

-- Titulo
E("TextLabel", {
	Text = "BRAINKART",
	Font = Enum.Font.GothamBlack,
	TextSize = 60,
	TextColor3 = C.acc,
	Size = UDim2.new(1, 0, 0, 80),
	Position = UDim2.new(0, 0, 0, 18),
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Center,
}, panel)

E("TextLabel", {
	Text = "Escolhe o modo e arranca!",
	Font = Enum.Font.Gotham,
	TextSize = 15,
	TextColor3 = Color3.fromRGB(170, 170, 210),
	Size = UDim2.new(1, -40, 0, 24),
	Position = UDim2.new(0, 20, 0, 96),
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Center,
}, panel)

-- Separador
local sep = E("Frame", {
	Size = UDim2.new(0.75, 0, 0, 2),
	Position = UDim2.new(0.125, 0, 0, 128),
	BackgroundColor3 = Color3.fromRGB(50, 50, 90),
	BorderSizePixel = 0,
}, panel)
CR(sep, 2)

-- ============================================================
-- SELECAO DE MODO
-- ============================================================
E("TextLabel", {
	Text = "MODO DE JOGO",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = Color3.fromRGB(140, 140, 190),
	Size = UDim2.new(1, -40, 0, 20),
	Position = UDim2.new(0, 20, 0, 142),
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local modes = {
	{ label = "SOLO",   color = C.blue,  mode = "solo" },
	{ label = "AMIGOS", color = C.green, mode = "friends" },
}
local selectedMode = "solo"
local modeButtons  = {}

for i, md in ipairs(modes) do
	local btn = E("TextButton", {
		Text    = md.label,
		Font    = Enum.Font.GothamBlack,
		TextSize = 20,
		TextColor3 = C.white,
		Size = UDim2.new(0.45, 0, 0, 62),
		Position = UDim2.new((i == 1) and 0.02 or 0.53, 0, 0, 166),
		BackgroundColor3 = (i == 1) and md.color or C.dark,
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, panel)
	CR(btn, 14)
	table.insert(modeButtons, { btn = btn, color = md.color, mode = md.mode })

	btn.MouseButton1Click:Connect(function()
		selectedMode = md.mode
		for _, mb in ipairs(modeButtons) do
			TS:Create(mb.btn, TweenInfo.new(0.15), {
				BackgroundColor3 = mb.mode == selectedMode and mb.color or C.dark
			}):Play()
		end
	end)
	hoverFx(btn,
		(i == 1) and md.color or C.dark,
		Color3.fromRGB(40, 40, 70)
	)
end

-- ============================================================
-- SELECAO DE VOLTAS
-- ============================================================
E("TextLabel", {
	Text = "NUMERO DE VOLTAS",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = Color3.fromRGB(140, 140, 190),
	Size = UDim2.new(1, -40, 0, 20),
	Position = UDim2.new(0, 20, 0, 250),
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local lapOptions  = { "1", "3", "5" }
local selectedLaps = "3"
local lapButtons  = {}

for i, lv in ipairs(lapOptions) do
	local btn = E("TextButton", {
		Text     = lv .. (lv == "1" and " Volta" or " Voltas"),
		Font     = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = C.white,
		Size = UDim2.new(0.28, 0, 0, 42),
		Position = UDim2.new(0.02 + (i - 1) * 0.33, 0, 0, 274),
		BackgroundColor3 = lv == "3" and C.acc or C.dark,
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, panel)
	CR(btn, 12)
	table.insert(lapButtons, { btn = btn, laps = lv })

	btn.MouseButton1Click:Connect(function()
		selectedLaps = lv
		for _, lb in ipairs(lapButtons) do
			TS:Create(lb.btn, TweenInfo.new(0.15), {
				BackgroundColor3 = lb.laps == selectedLaps and C.acc or C.dark
			}):Play()
		end
	end)
end

-- ============================================================
-- BOTAO JOGAR
-- ============================================================
local playBtn = E("TextButton", {
	Text     = "  JOGAR",
	Font     = Enum.Font.GothamBlack,
	TextSize = 24,
	TextColor3 = Color3.fromRGB(0, 0, 0),
	Size = UDim2.new(0.86, 0, 0, 65),
	Position = UDim2.new(0.07, 0, 0, 360),
	BackgroundColor3 = C.acc,
	BorderSizePixel  = 0,
	AutoButtonColor  = false,
}, panel)
CR(playBtn, 18)
GR(playBtn, { C.acc, C.acc2 }, 90)
hoverFx(playBtn, C.acc, Color3.fromRGB(255, 235, 60))

playBtn.MouseButton1Click:Connect(function()
	-- Enviar pedido de inicio ao servidor
	local RF = RSt:FindFirstChild("BrainKartRemotes")
	if RF then
		local req = RF:FindFirstChild("RequestStart")
		if req then
			req:FireServer()
			print("[Menu] Corrida iniciada!")
		end
	end

	-- Animacao de saida
	TS:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -250, 1.6, 0),
	}):Play()
	TS:Create(bg, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
	task.delay(0.7, function()
		if sg and sg.Parent then sg:Destroy() end
	end)
end)

-- Animacao de entrada
TS:Create(panel, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Position = UDim2.new(0.5, -250, 0.5, -245),
}):Play()

print("[Menu] MainMenuScript v4 carregado!")
