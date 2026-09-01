-- KartController (StarterPlayerScripts) - v4 LocalScript
-- Controlos: W/A/S/D = conduzir | SPACE/LShift = drift+boost | E = item

local Players   = game:GetService("Players")
local UIS       = game:GetService("UserInputService")
local RS        = game:GetService("RunService")
local RSt       = game:GetService("ReplicatedStorage")
local TS        = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ============================================================
-- CONFIGURACAO
-- ============================================================
local CFG = {
	accel       = 10,    -- forca de aceleracao
	maxSpeed    = 90,    -- velocidade maxima normal (studs/s)
	brakeForce  = 0.78,  -- desaceleracao ao travar
	decel       = 0.91,  -- desaceleracao natural
	reverseSpd  = 18,    -- velocidade maxima em re
	turnSpeed   = 2.5,   -- velocidade de viragem
	driftTurn   = 3.8,   -- viragem durante drift
	driftMin    = 0.5,   -- tempo minimo drift para boost
	boostSpeed  = 135,   -- velocidade com mini-turbo
	boostDur    = 1.0,   -- duracao do boost (segundos)
	camDist     = 26,    -- distancia da camera
	camHeight   = 11,    -- altura da camera
	camSmooth   = 0.10,  -- suavidade da camera
	gravityExtra = 95,   -- gravidade extra para manter kart na pista
}

-- ============================================================
-- ESTADO
-- ============================================================
local kart, kartRoot = nil, nil
local speed          = 0
local drifting, driftDir, driftTime = false, 0, 0
local boosting, boostEnd = false, 0
local enabled  = false  -- so ativa apos GO!
local stunEnd  = 0

-- ============================================================
-- HELPERS
-- ============================================================
local function findKart()
	local k = workspace:FindFirstChild(player.Name .. "Kart")
	if k then return k, k:FindFirstChild("KartRoot") end
	return nil, nil
end

local function keyDown(...)
	for _, k in ipairs({...}) do
		if UIS:IsKeyDown(k) then return true end
	end
	return false
end

-- ============================================================
-- FISICAS DO KART
-- ============================================================
local function updateKart(dt)
	if not kartRoot then return end
	if tick() < stunEnd then speed = speed * 0.88; return end

	local acc, str = 0, 0
	if keyDown(Enum.KeyCode.W, Enum.KeyCode.Up)    then acc =  1    end
	if keyDown(Enum.KeyCode.S, Enum.KeyCode.Down)   then acc = -0.5  end
	if keyDown(Enum.KeyCode.A, Enum.KeyCode.Left)   then str = -1    end
	if keyDown(Enum.KeyCode.D, Enum.KeyCode.Right)  then str =  1    end
	local dk = keyDown(Enum.KeyCode.Space, Enum.KeyCode.LeftShift)

	local topSpd = CFG.maxSpeed
	if boosting then
		if tick() > boostEnd then boosting = false
		else topSpd = CFG.boostSpeed end
	end

	-- Drift
	if dk and math.abs(str) > 0.1 and acc > 0 then
		if not drifting then drifting = true; driftDir = str; driftTime = 0 end
		driftTime = driftTime + dt
	else
		if drifting and driftTime >= CFG.driftMin then
			boosting = true
			boostEnd = tick() + CFG.boostDur
			task.spawn(function()
				local gui = player.PlayerGui:FindFirstChild("RaceHUD")
				if not gui then return end
				local flash = Instance.new("Frame")
				flash.Size                = UDim2.new(1, 0, 1, 0)
				flash.BackgroundColor3    = Color3.fromRGB(255, 220, 0)
				flash.BackgroundTransparency = 0.75
				flash.ZIndex              = 50
				flash.Parent              = gui
				TS:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
				task.delay(0.4, function() if flash then flash:Destroy() end end)
			end)
		end
		drifting = false; driftDir = 0; driftTime = 0
	end

	-- Aceleracao / travagem
	if acc > 0 then
		speed = math.min(speed + acc * CFG.accel, topSpd)
	elseif acc < 0 then
		speed = speed > 2
			and speed * CFG.brakeForce
			or math.max(speed + acc * (CFG.accel * 0.5), -CFG.reverseSpd)
	else
		speed = speed * CFG.decel
		if math.abs(speed) < 0.3 then speed = 0 end
	end

	-- Viragem
	if math.abs(speed) > 0.5 and math.abs(str) > 0 then
		local turnAmt = str * (drifting and CFG.driftTurn or CFG.turnSpeed)
		kartRoot.CFrame = kartRoot.CFrame * CFrame.Angles(0, -turnAmt * dt * math.sign(speed), 0)
	end

	-- Aplicar velocidade
	local fwd    = kartRoot.CFrame.LookVector
	local curVel = kartRoot.AssemblyLinearVelocity
	local tVel   = fwd * speed
	kartRoot.AssemblyLinearVelocity = Vector3.new(tVel.X, curVel.Y, tVel.Z)

	-- Gravidade extra para manter kart na pista
	if curVel.Y > -2 and curVel.Y < 2 then
		kartRoot.AssemblyLinearVelocity = Vector3.new(
			kartRoot.AssemblyLinearVelocity.X,
			-CFG.gravityExtra * dt,
			kartRoot.AssemblyLinearVelocity.Z
		)
	end
end

-- ============================================================
-- CAMERA
-- ============================================================
local function updateCamera()
	if not kartRoot then return end
	camera.CameraType = Enum.CameraType.Scriptable
	local pos     = kartRoot.CFrame.Position
	local back    = kartRoot.CFrame.LookVector * -CFG.camDist
	local desired = pos + back + Vector3.new(0, CFG.camHeight, 0)
	camera.CFrame = camera.CFrame:Lerp(
		CFrame.new(desired, pos + Vector3.new(0, 2, 0)),
		CFG.camSmooth
	)
end

-- ============================================================
-- PROCURAR KART (loop de espera)
-- ============================================================
local function waitForKart()
	local attempts = 0
	while not kartRoot and attempts < 120 do
		kart, kartRoot = findKart()
		if kartRoot then
			speed = 0
			print("[KC] Kart encontrado: " .. kart.Name)
		else
			attempts = attempts + 1
			task.wait(0.5)
		end
	end
	if not kartRoot then warn("[KC] Kart nao encontrado apos 60s!") end
end

-- ============================================================
-- REMOTE EVENTS
-- ============================================================
task.spawn(function()
	local RF = RSt:WaitForChild("BrainKartRemotes", 20)
	if not RF then warn("[KC] BrainKartRemotes nao encontrado!"); return end

	RF:WaitForChild("Countdown", 10).OnClientEvent:Connect(function(count)
		if count == 0 then
			enabled = true
			speed   = 0
			print("[KC] GO! Kart ativado.")
		else
			enabled = false
		end
	end)

	RF:WaitForChild("EndRace", 10).OnClientEvent:Connect(function()
		enabled = false
		speed   = 0
		if kartRoot then kartRoot.AssemblyLinearVelocity = Vector3.zero end
	end)

	RF:WaitForChild("HitEffect", 10).OnClientEvent:Connect(function()
		stunEnd = tick() + 1.2
		speed   = speed * 0.3
	end)
end)

-- ============================================================
-- RESPAWN
-- ============================================================
player.CharacterAdded:Connect(function()
	kart, kartRoot = nil, nil
	speed   = 0
	enabled = false
	task.spawn(waitForKart)
end)
if player.Character then task.spawn(waitForKart) end

-- ============================================================
-- LOOP PRINCIPAL
-- ============================================================
RS.Heartbeat:Connect(function(dt)
	if not kartRoot or not kartRoot.Parent then
		kart, kartRoot = findKart()
	end
	if not kartRoot or not enabled then return end
	updateKart(dt)
end)

RS.RenderStepped:Connect(function()
	if kartRoot and kartRoot.Parent then
		updateCamera()
	end
end)

print("[KC] KartController v4 carregado!")
