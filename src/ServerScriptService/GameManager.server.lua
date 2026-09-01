-- GameManager (ServerScriptService) - v5
-- Sistema de voltas baseado na linha de meta (FinishLine) no Workspace
-- Sem checkpoints - conta uma volta cada vez que o kart atravessa a meta

local Players = game:GetService("Players")
local RSt     = game:GetService("ReplicatedStorage")
local RunS    = game:GetService("RunService")

-- RemoteEvents
local RF = RSt:FindFirstChild("BrainKartRemotes")
if not RF then
	RF = Instance.new("Folder"); RF.Name = "BrainKartRemotes"; RF.Parent = RSt
end

local function getOrCreate(name)
	local r = RF:FindFirstChild(name)
	if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = RF end
	return r
end

local StartEv  = getOrCreate("StartRace")
local EndEv    = getOrCreate("EndRace")
local CountEv  = getOrCreate("Countdown")
local UpdEv    = getOrCreate("UpdatePositions")
local FinEv    = getOrCreate("PlayerFinished")
local ReqEv    = getOrCreate("RequestStart")
local UseEv    = getOrCreate("UseItem")
local HitEv    = getOrCreate("ItemHit")
local LapEv    = getOrCreate("LapUpdate")   -- novo: notifica o cliente da volta atual
getOrCreate("CollectItem"); getOrCreate("HitEffect")

local TOTAL_LAPS = 3
local ACTIVE     = false
local pData      = {}  -- [player] = { lap, done, ft, st, lastCrossed }
local finishOrder = {}

-- ─── Finish Line ─────────────────────────────────────────────────────────────

local function getFinishLine()
	return workspace:FindFirstChild("FinishLine")
end

-- Verifica se um kart cruzou a linha de meta
-- Usa distância ao plano da FinishLine (eixo Z da part)
local COOLDOWN = 3  -- segundos mínimos entre duas contagens (evita dupla contagem)

local function checkFinishLineCrossing(player, kartRoot, finishPart)
	local d = pData[player]
	if not d or d.done then return end

	-- Posição do kart relativa à meta (no espaço local da meta)
	local relPos = finishPart.CFrame:PointToObjectSpace(kartRoot.Position)

	-- relPos.Z < 0 = atrás da meta, relPos.Z > 0 = à frente
	-- Só conta se o kart está perto da meta (X e Y dentro dos limites) e passou pelo plano
	local halfX = finishPart.Size.X / 2
	local halfY = finishPart.Size.Y / 2

	local inBounds = math.abs(relPos.X) < halfX and math.abs(relPos.Y) < halfY

	if not inBounds then return end

	local prevZ = d.prevZ or relPos.Z
	d.prevZ = relPos.Z

	-- Cruzamento: de positivo para negativo (vai para a frente passando pela meta)
	if prevZ > 0.5 and relPos.Z < -0.5 then
		local now = tick()
		if (now - (d.lastCrossed or 0)) < COOLDOWN then return end
		d.lastCrossed = now

		d.lap = d.lap + 1
		print(string.format("[GM] %s - Volta %d/%d", player.Name, d.lap, TOTAL_LAPS))

		-- Notifica o cliente
		LapEv:FireClient(player, d.lap, TOTAL_LAPS)

		if d.lap >= TOTAL_LAPS then
			d.done = true
			d.ft = tick()
			table.insert(finishOrder, player)
			FinEv:FireClient(player, #finishOrder)
			print(string.format("[GM] %s TERMINOU em %d.º lugar!", player.Name, #finishOrder))

			-- Verifica se todos terminaram
			local allDone = true
			for _, dd in pairs(pData) do
				if not dd.done then allDone = false; break end
			end
			if allDone then task.delay(3, endRace) end
		end
	end
end

-- ─── Race Flow ────────────────────────────────────────────────────────────────

local function setup(p)
	pData[p] = { lap = 0, done = false, ft = 0, st = 0, lastCrossed = 0, prevZ = nil }
end

local function endRace()
	ACTIVE = false
	local res = {}
	for i, p in ipairs(finishOrder) do
		local d = pData[p]
		if d then table.insert(res, { name = p.Name, pos = i, time = d.ft - d.st }) end
	end
	for p, d in pairs(pData) do
		if not d.done then table.insert(res, { name = p.Name, pos = #res + 1, time = -1 }) end
	end
	EndEv:FireAllClients(res)
	print("[GM] Corrida terminada!")
end

local function startRace()
	if ACTIVE then return end
	ACTIVE = true
	finishOrder = {}
	for _, p in ipairs(Players:GetPlayers()) do setup(p) end

	StartEv:FireAllClients(TOTAL_LAPS)
	for i = 3, 1, -1 do CountEv:FireAllClients(i); task.wait(1) end
	CountEv:FireAllClients(0) -- GO!

	local st = tick()
	for _, d in pairs(pData) do d.st = st end

	-- Loop principal: deteta cruzamentos da meta e atualiza posições
	local finishPart = getFinishLine()

	while ACTIVE do
		task.wait(0.05)  -- 20hz

		if finishPart then
			for _, player in ipairs(Players:GetPlayers()) do
				local kart = workspace:FindFirstChild(player.Name .. "Kart")
				local kr = kart and kart:FindFirstChild("KartRoot")
				if kr then
					checkFinishLineCrossing(player, kr, finishPart)
				end
			end
		end

		-- Atualizar posições (a cada 0.5s apenas)
		local out, sorted = {}, {}
		for p, d in pairs(pData) do
			if not d.done then table.insert(sorted, { p = p, s = d.lap }) end
		end
		table.sort(sorted, function(a, b) return a.s > b.s end)
		local posT = {}
		for i, p in ipairs(finishOrder) do posT[p] = i end
		local off = #finishOrder
		for i, e in ipairs(sorted) do posT[e.p] = off + i end
		for p, pos in pairs(posT) do table.insert(out, { name = p.Name, pos = pos, lap = pData[p].lap }) end
		UpdEv:FireAllClients(out)
	end
end

-- ─── Eventos ──────────────────────────────────────────────────────────────────

ReqEv.OnServerEvent:Connect(function(p)
	print("[GM] " .. p.Name .. " iniciou corrida")
	if not ACTIVE then task.spawn(startRace) end
end)

UseEv.OnServerEvent:Connect(function(p, item)
	if not ACTIVE then return end
	local d = pData[p]
	if not d then return end
	d.item = nil
	HitEv:FireAllClients(p.Name, item)
end)

Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(p) pData[p] = nil end)
for _, p in ipairs(Players:GetPlayers()) do setup(p) end

-- Corrida começa automaticamente com 1 jogador (para teste)
task.delay(2, function()
	if not ACTIVE and #Players:GetPlayers() > 0 then
		task.spawn(startRace)
	end
end)

print("[GM] GameManager v5 carregado! Sistema de voltas por linha de meta ativo.")
