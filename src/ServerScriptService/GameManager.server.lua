-- GameManager (ServerScriptService) - v4
-- Gere o estado da corrida: countdown, voltas, posicoes, fim de jogo
-- Iniciado pelo menu via RemoteEvent "RequestStart"

local Players = game:GetService("Players")
local RSt = game:GetService("ReplicatedStorage")

local RF = RSt:WaitForChild("BrainKartRemotes", 15)
if not RF then warn("[GM] BrainKartRemotes nao encontrado!"); return end

local StartEv   = RF:WaitForChild("StartRace")
local EndEv     = RF:WaitForChild("EndRace")
local CountEv   = RF:WaitForChild("Countdown")
local UpdEv     = RF:WaitForChild("UpdatePositions")
local FinEv     = RF:WaitForChild("PlayerFinished")
local ReqEv     = RF:WaitForChild("RequestStart")
local UseEv     = RF:WaitForChild("UseItem")
local HitEv     = RF:WaitForChild("ItemHit")

local LAPS   = 3
local CPS    = 3
local ACTIVE = false
local pData  = {}
local finishOrder = {}

local function setup(p)
	pData[p] = { lap=0, cp=0, done=false, ft=0, st=0 }
end

local function endRace()
	ACTIVE = false
	local res = {}
	for i, p in ipairs(finishOrder) do
		local d = pData[p]
		if d then table.insert(res, { name=p.Name, pos=i, time=d.ft-d.st }) end
	end
	for p, d in pairs(pData) do
		if not d.done then table.insert(res, { name=p.Name, pos=#res+1, time=-1 }) end
	end
	EndEv:FireAllClients(res)
	print("[GM] Corrida terminada!")
end

local function startRace()
	if ACTIVE then return end
	ACTIVE = true
	finishOrder = {}
	for _, p in ipairs(Players:GetPlayers()) do setup(p) end

	StartEv:FireAllClients(LAPS)
	for i = 3, 1, -1 do CountEv:FireAllClients(i); task.wait(1) end
	CountEv:FireAllClients(0) -- GO!

	local st = tick()
	for _, d in pairs(pData) do d.st = st end

	while ACTIVE do
		local out, sorted = {}, {}
		for p, d in pairs(pData) do
			if not d.done then table.insert(sorted, { p=p, s=d.lap*1000+d.cp }) end
		end
		table.sort(sorted, function(a, b) return a.s > b.s end)
		local posT = {}
		for i, p in ipairs(finishOrder) do posT[p] = i end
		local off = #finishOrder
		for i, e in ipairs(sorted) do posT[e.p] = off+i end
		for p, pos in pairs(posT) do table.insert(out, { name=p.Name, pos=pos }) end
		UpdEv:FireAllClients(out, pData)
		task.wait(0.5)
	end
end

-- Checkpoint handler (chamado pelos scripts de checkpoint no workspace)
_G.BrainKartCP = function(player, idx)
	if not ACTIVE then return end
	local d = pData[player]
	if not d or d.done then return end
	local exp = (d.cp % CPS) + 1
	if idx == exp then
		d.cp = d.cp + 1
		if idx == CPS then
			d.lap = d.lap + 1
			d.cp = 0
			print("[GM] " .. player.Name .. " volta " .. d.lap .. "/" .. LAPS)
			if d.lap >= LAPS then
				d.done = true
				d.ft = tick()
				table.insert(finishOrder, player)
				FinEv:FireClient(player, #finishOrder)
				local all = true
				for _, dd in pairs(pData) do if not dd.done then all = false; break end end
				if all then task.delay(3, endRace) end
			end
		end
	end
end

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

print("[GM] GameManager v4 carregado! Aguarda RequestStart...")
