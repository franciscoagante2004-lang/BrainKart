-- KartSpawner (ServerScriptService) - v4
-- Cria e liga um kart a cada jogador quando entra no jogo

local Players = game:GetService("Players")
local SS      = game:GetService("ServerStorage")
local RSt     = game:GetService("ReplicatedStorage")

-- Criar RemoteEvents se ainda nao existirem
local RF = RSt:FindFirstChild("BrainKartRemotes")
if not RF then
	RF = Instance.new("Folder")
	RF.Name = "BrainKartRemotes"
	RF.Parent = RSt
end

local function getOrCreate(name)
	local r = RF:FindFirstChild(name)
	if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = RF end
	return r
end

getOrCreate("StartRace"); getOrCreate("EndRace"); getOrCreate("Countdown")
getOrCreate("UpdatePositions"); getOrCreate("PlayerFinished"); getOrCreate("HitEffect")
getOrCreate("UseItem"); getOrCreate("ItemHit"); getOrCreate("RequestStart"); getOrCreate("CollectItem")

print("[KS] RemoteEvents criados/verificados.")

local COLORS = {
	Color3.fromRGB(220, 50,  50),
	Color3.fromRGB(50,  100, 255),
	Color3.fromRGB(50,  200, 50),
	Color3.fromRGB(255, 150, 0),
	Color3.fromRGB(200, 50,  200),
	Color3.fromRGB(50,  220, 200),
	Color3.fromRGB(255, 255, 50),
	Color3.fromRGB(255, 100, 150),
}

local function getPlayerIdx(player)
	local ps = Players:GetPlayers()
	for i, p in ipairs(ps) do
		if p == player then return i end
	end
	return 1
end

local function doSpawnKart(player, char)
	-- Esperar pelo KartTemplate em ServerStorage, ou criar um de reserva
	local template = SS:FindFirstChild("KartTemplate")
	if not template then
		warn("[KS] KartTemplate nao encontrado! A gerar modelo de reserva...")
		template = Instance.new("Model")
		template.Name = "KartTemplate"
		
		local root = Instance.new("Part")
		root.Name = "KartRoot"; root.Size = Vector3.new(5, 2, 8)
		root.BrickColor = BrickColor.new("Bright red")
		root.Material = Enum.Material.SmoothPlastic
		root.CanCollide = true; root.Anchored = false
		root.Parent = template; template.PrimaryPart = root
		
		local function addPart(name, size, bc, cf)
			local p = Instance.new("Part"); p.Name = name; p.Size = size
			p.BrickColor = bc; p.Material = Enum.Material.SmoothPlastic
			p.CanCollide = false; p.Parent = template
			local w = Instance.new("WeldConstraint")
			w.Part0 = root; w.Part1 = p; w.Parent = root
			p.CFrame = root.CFrame * cf
			return p
		end
		
		addPart("Body", Vector3.new(4.5, 1.5, 5), BrickColor.new("Bright red"), CFrame.new(0, 1.2, -0.5))
		local ws = addPart("Windshield", Vector3.new(3, 1, 1.5), BrickColor.new("Cyan"), CFrame.new(0, 1.8, -1.2))
		ws.Material = Enum.Material.Glass; ws.Transparency = 0.4
		addPart("Spoiler", Vector3.new(4, 0.3, 1.5), BrickColor.new("Dark grey"), CFrame.new(0, 1.5, 3.2))
		
		for _, wo in ipairs({{-2.7, -1, 2.5}, {2.7, -1, 2.5}, {-2.7, -1, -2.5}, {2.7, -1, -2.5}}) do
			local wh = Instance.new("Part"); wh.Shape = Enum.PartType.Cylinder
			wh.Size = Vector3.new(1.5, 1.8, 1.8); wh.BrickColor = BrickColor.new("Really black")
			wh.Material = Enum.Material.SmoothPlastic; wh.CanCollide = false; wh.Parent = template
			local wc = Instance.new("WeldConstraint")
			wc.Part0 = root; wc.Part1 = wh; wc.Parent = root
			wh.CFrame = root.CFrame * CFrame.new(wo[1], wo[2], wo[3]) * CFrame.Angles(0, 0, math.pi/2)
		end
		
		template.Parent = SS
	end

	-- Remover kart antigo
	local old = workspace:FindFirstChild(player.Name .. "Kart")
	if old then old:Destroy() end

	-- Clonar e colorir
	local kc  = template:Clone()
	local idx = getPlayerIdx(player)
	local col = COLORS[(idx - 1) % #COLORS + 1]

	local kr = kc:FindFirstChild("KartRoot")
	local kb = kc:FindFirstChild("Body")
	if kr and kr:IsA("BasePart") then kr.Color = col end
	if kb and kb:IsA("BasePart") then kb.Color = col end

	-- Posicionar no spawn point
	local sf   = workspace:FindFirstChild("SpawnPoints")
	local sp   = sf and sf:FindFirstChild("Spawn" .. idx)
	local spCF = sp and sp.CFrame or CFrame.new(0, 8, 100)

	kc.Name = player.Name .. "Kart"
	kc:SetPrimaryPartCFrame(spCF + Vector3.new(0, 3, 0))
	kc.Parent = workspace

	-- Aguardar personagem estar completamente carregado
	task.wait(0.8)

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	kr = kc:FindFirstChild("KartRoot")

	if not hrp or not hum or not kr then
		warn("[KS] Partes em falta! HRP=" .. tostring(hrp~=nil) .. " H=" .. tostring(hum~=nil) .. " KR=" .. tostring(kr~=nil))
		return
	end

	-- Desativar movimento proprio do personagem
	hum.WalkSpeed    = 0
	hum.JumpPower    = 0
	hum.JumpHeight   = 0
	hum.AutoRotate   = false
	hum.PlatformStand = true

	-- Posicionar HRP dentro do kart e soldar
	hrp.Anchored    = false
	hrp.CanCollide  = false
	hrp.CFrame      = kr.CFrame * CFrame.new(0, 2, 0)

	local wc   = Instance.new("WeldConstraint")
	wc.Part0   = kr
	wc.Part1   = hrp
	wc.Parent  = kr

	-- Tornar personagem invisivel (so o kart e visivel)
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 1
			part.CanCollide   = false
		elseif part:IsA("Decal") then
			pcall(function() part.Transparency = 1 end)
		end
	end

	print("[KS] Kart criado para " .. player.Name .. " (slot " .. idx .. ")")
end

local function setupPlayer(player)
	player.CharacterAdded:Connect(function(char)
		print("[KS] CharacterAdded: " .. player.Name)
		task.wait(1.5) -- esperar character carregar
		doSpawnKart(player, char)
	end)
end

-- Setup jogadores existentes
for _, p in ipairs(Players:GetPlayers()) do
	setupPlayer(p)
	p:LoadCharacter()
end
Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(p)
	local k = workspace:FindFirstChild(p.Name .. "Kart")
	if k then k:Destroy() end
end)

print("[KS] KartSpawner v4 carregado!")
