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
	-- Esperar pelo KartTemplate em ServerStorage
	local template = SS:WaitForChild("KartTemplate", 30)
	if not template then
		warn("[KS] KartTemplate nao encontrado em ServerStorage!")
		warn("[KS] Executa FullRebuildBrainKart.lua no Studio para criar a pista e o kart!")
		return
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
	if kr then kr.Color = col end
	if kb then kb.Color = col end

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
