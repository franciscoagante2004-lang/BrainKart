-- KartController (StarterPlayerScripts) - MK8 Arcade Physics (Senior Gameplay Programmer Edition)
-- Implementação: Kinematic Body Hovercraft, State Machine, Steering Lerp, Drift Slip-Angle, Mini-Turbo

local Players   = game:GetService("Players")
local UIS       = game:GetService("UserInputService")
local RS        = game:GetService("RunService")
local RSt       = game:GetService("ReplicatedStorage")
local TS        = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ============================================================
-- TUNING PARAMETERS (MK8 Arcade Physics)
-- ============================================================
local CFG = {
	-- Aceleração e Velocidade
	accel       = 80,
	maxSpeed    = 135,
	brakeForce  = 0.90,
	decel       = 0.97,
	offroadDecel= 0.85,
	reverseSpd  = 30,
	
	-- 1. Sensibilidade e Suavização de Input
	steerLerpSpeed = 4.5, -- ~0.22s para ir de 0 a 1, dá peso à direção
	baseTurnRate   = math.rad(95), -- Graus/s em condução normal
	
	-- 2, 3 & 4. Drift & Slip Angle
	hopForce       = 32,
	baseDriftTurn  = math.rad(45), -- Velocidade angular constante passiva do drift
	minDriftTurn   = math.rad(15), -- Quando contra-breca
	maxDriftTurn   = math.rad(85), -- Quando vira tudo para dentro
	driftTraction  = 2.8, -- Deslizamento: Velocidade com que o vetor de movimento persegue o modelo 3D
	
	-- 5. Mini-Turbo System
	mtChargeRate = 1.0,
	mtSoftDrift  = 0.7, -- Threshold do input bruto para carregar mais rápido
	mtTier1 = 0.6,    -- Azul
	mtTier2 = 1.8,    -- Laranja
	mtTier3 = 3.5,    -- Rosa (Ultra)
	
	boostSpds   = { 170, 205, 255 },
	boostDurs   = { 0.8, 1.8, 3.2 },
	
	-- Kinematic Hovercraft (Suspensão)
	rideHeight  = 3.0,
	downForce   = 220,
	
	-- Visuais
	maxTilt     = math.rad(15),
	tiltSpeed   = 6,
	camDist     = 22,
	camHeight   = 9,
	camSmooth   = 0.15,
	baseFOV     = 70,
	boostFOV    = 90,
}

-- ============================================================
-- STATE MACHINE
-- ============================================================
local STATE_DRIVING  = 1
local STATE_AIRBORNE = 2
local STATE_DRIFTING = 3

local currentState = STATE_DRIVING

local kart, kartRoot = nil, nil
local speed          = 0
local yVelocity      = 0
local enabled        = false

-- Input e Vetores
local currentSteer   = 0 -- Input suavizado (Lerp)
local rawSteer       = 0
local driftKeyHeld   = false

local visualForward  = Vector3.new(0, 0, -1)
local movementVector = Vector3.new(0, 0, -1)
local groundNormal   = Vector3.new(0, 1, 0)
local isGrounded     = false
local isOnOffroad    = false
local currentTilt    = 0
local lastBump       = 0

-- Drift State Variables
local driftDir       = 0
local mtCharge       = 0
local driftLevel     = 0

-- Boost State
local boosting, boostEnd, currentBoostSpeed = false, 0, 0
local sparkEmitters = {}

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
-- EFEITOS VISUAIS
-- ============================================================
local function setupSparks()
	if not kart or #sparkEmitters > 0 then return end
	local root = kart:FindFirstChild("KartRoot")
	if not root then return end
	
	for _, offset in ipairs({Vector3.new(-3, -1, 3.5), Vector3.new(3, -1, 3.5)}) do
		local a = Instance.new("Attachment")
		a.Position = offset
		a.Parent = root
		
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxassetid://1347000185"
		e.Rate = 0
		e.Speed = NumberRange.new(5, 10)
		e.Lifetime = NumberRange.new(0.2, 0.4)
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
		e.EmissionDirection = Enum.NormalId.Back
		e.SpreadAngle = Vector2.new(30, 30)
		e.Parent = a
		table.insert(sparkEmitters, e)
	end
end

local function setSparks(level)
	for _, e in ipairs(sparkEmitters) do
		if level == 0 then e.Rate = 0
		else
			e.Rate = 60
			if level == 1 then e.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255))
			elseif level == 2 then e.Color = ColorSequence.new(Color3.fromRGB(255, 120, 0))
			elseif level == 3 then e.Color = ColorSequence.new(Color3.fromRGB(255, 50, 200)) end
		end
	end
end

local function cancelDrift()
	if currentState == STATE_DRIFTING then
		currentState = STATE_DRIVING
	end
	mtCharge = 0
	driftLevel = 0
	setSparks(0)
end

-- ============================================================
-- MATH HELPERS
-- ============================================================
local function lerp(a, b, t) return a + (b - a) * t end

local function applyBoost(tier)
	boosting = true
	currentBoostSpeed = CFG.boostSpds[tier]
	boostEnd = tick() + CFG.boostDurs[tier]
	speed = currentBoostSpeed
	
	task.spawn(function()
		local gui = player.PlayerGui:FindFirstChild("RaceHUD")
		if not gui then return end
		local flash = Instance.new("Frame")
		flash.Size = UDim2.new(1, 0, 1, 0)
		flash.BackgroundColor3 = (tier == 1 and Color3.fromRGB(0,200,255)) or (tier == 2 and Color3.fromRGB(255,120,0)) or Color3.fromRGB(255,50,200)
		flash.BackgroundTransparency = 0.6
		flash.ZIndex = 50
		flash.Parent = gui
		TS:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		task.delay(0.5, function() if flash then flash:Destroy() end end)
	end)
end

-- ============================================================
-- MAIN PHYSICS LOOP
-- ============================================================
local function updateKart(dt)
	if not kartRoot then return end

	-- ─── LER INPUT ───
	local acc = 0
	rawSteer = 0
	local braking = false
	
	if keyDown(Enum.KeyCode.W, Enum.KeyCode.Up)    then acc = 1    end
	if keyDown(Enum.KeyCode.S, Enum.KeyCode.Down)  then acc = -0.5; braking = true end
	if keyDown(Enum.KeyCode.A, Enum.KeyCode.Left)  then rawSteer = -1 end
	if keyDown(Enum.KeyCode.D, Enum.KeyCode.Right) then rawSteer = 1  end
	
	local driftKeyJustPressed = false
	if keyDown(Enum.KeyCode.Space, Enum.KeyCode.LeftShift) then
		if not driftKeyHeld then driftKeyJustPressed = true end
		driftKeyHeld = true
	else
		driftKeyHeld = false
	end

	-- 1. SENSITIVIDADE E SUAVIZAÇÃO DE INPUT (Steering Lerp)
	currentSteer = lerp(currentSteer, rawSteer, CFG.steerLerpSpeed * dt)

	-- ─── RAYCAST (Hovercraft / Chão) ───
	local rOrigin = kartRoot.CFrame.Position
	local rDir = -kartRoot.CFrame.UpVector * (CFG.rideHeight + 2)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {kart, player.Character}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local rResult = workspace:Raycast(rOrigin, rDir, rayParams)
	isOnOffroad = false
	
	if rResult and rResult.Normal.Y > 0.4 then
		isGrounded = true
		groundNormal = groundNormal:Lerp(rResult.Normal, 15 * dt).Unit
		if rResult.Material == Enum.Material.Grass or rResult.Material == Enum.Material.Sand then
			isOnOffroad = true
		end
	else
		isGrounded = false
		groundNormal = groundNormal:Lerp(Vector3.new(0, 1, 0), 5 * dt).Unit
	end
	
	-- Colisões rígidas (Paredes)
	if speed > 20 and tick() > lastBump then
		local wallRay = workspace:Raycast(rOrigin, movementVector * 6, rayParams)
		if wallRay then
			local dot = -movementVector:Dot(wallRay.Normal)
			if dot > 0.65 then
				cancelDrift()
				speed = 0
				lastBump = tick() + 0.8
			elseif dot > 0.1 then
				speed = speed * 0.8
				movementVector = (movementVector + wallRay.Normal * 0.5).Unit
				lastBump = tick() + 0.3
			end
		end
	end

	-- Efeito Offroad
	local effectiveDecel = CFG.decel
	local topSpd = CFG.maxSpeed
	
	if boosting then
		if tick() > boostEnd then boosting = false
		else topSpd = currentBoostSpeed end
	end
	
	if isOnOffroad and not boosting then
		effectiveDecel = CFG.offroadDecel
		topSpd = topSpd * 0.3
		if currentState == STATE_DRIFTING then cancelDrift() end
	end

	-- ─── STATE MACHINE (Jump & Drift Initiation) ───
	if isGrounded then
		if currentState == STATE_AIRBORNE then
			-- Aterrar
			if driftKeyHeld and math.abs(rawSteer) > 0.1 and speed > 30 and not isOnOffroad then
				currentState = STATE_DRIFTING
				driftDir = math.sign(rawSteer)
				mtCharge = 0
				driftLevel = 0
			else
				currentState = STATE_DRIVING
			end
		end
		
		if currentState == STATE_DRIVING and driftKeyJustPressed and speed > 30 and not isOnOffroad then
			yVelocity = CFG.hopForce
			currentState = STATE_AIRBORNE
		end
	else
		currentState = STATE_AIRBORNE
	end

	-- ─── ACELERAÇÃO PDRÃO ───
	if not (currentState == STATE_DRIFTING and braking) then
		if acc > 0 then
			speed = math.min(speed + (CFG.accel * dt), topSpd)
		elseif acc < 0 then
			speed = speed > 2 and speed * CFG.brakeForce or math.max(speed + (acc * CFG.accel * dt * 0.5), -CFG.reverseSpd)
		else
			speed = speed * effectiveDecel
			if math.abs(speed) < 1 then speed = 0 end
		end
	end
	if isOnOffroad and not boosting and speed > topSpd then
		speed = speed * effectiveDecel
	end

	-- ─── 3 & 4. MATEMÁTICA DA DERRAPAGEM E DESLIZAMENTO ───
	local turnRate = 0
	local targetTilt = 0
	
	if currentState == STATE_DRIFTING then
		if not driftKeyHeld then
			-- Largar o drift = Boost se carregado
			currentState = STATE_DRIVING
			setSparks(0)
			if driftLevel > 0 then applyBoost(driftLevel) end
			driftLevel = 0
		else
			if braking then speed = speed * 0.95 end
			
			-- 5. Mini-Turbo System
			local chargeMult = 0.2
			if math.sign(rawSteer) == driftDir and math.abs(rawSteer) >= CFG.mtSoftDrift then
				chargeMult = 1.0 -- Soft drifting (input forte para dentro)
			end
			mtCharge = mtCharge + (CFG.mtChargeRate * chargeMult * dt)
			
			local newLevel = 0
			if mtCharge >= CFG.mtTier3 then newLevel = 3
			elseif mtCharge >= CFG.mtTier2 then newLevel = 2
			elseif mtCharge >= CFG.mtTier1 then newLevel = 1 end
			
			if newLevel ~= driftLevel then
				driftLevel = newLevel
				setSparks(driftLevel)
			end
			
			-- 3. Turn Rate (Velocidade Angular Clamped)
			local steerInDir = currentSteer * driftDir
			if steerInDir > 0 then
				-- Virar para dentro da curva (Max)
				turnRate = driftDir * lerp(CFG.baseDriftTurn, CFG.maxDriftTurn, steerInDir)
			else
				-- Contra-brecar (Min)
				turnRate = driftDir * lerp(CFG.baseDriftTurn, CFG.minDriftTurn, -steerInDir)
			end
			
			targetTilt = -driftDir * CFG.maxTilt * 1.5
		end
	elseif currentState == STATE_DRIVING then
		turnRate = currentSteer * CFG.baseTurnRate
		targetTilt = -currentSteer * CFG.maxTilt
	end
	
	if speed < 5 then turnRate = 0 end

	-- Roda o vetor visual (para onde o modelo aponta) em torno da normal do chão
	local turnRot = CFrame.fromAxisAngle(groundNormal, -turnRate * math.sign(speed) * dt)
	visualForward = (turnRot * visualForward).Unit
	
	-- Garante ortogonalidade
	local right = visualForward:Cross(groundNormal).Unit
	visualForward = groundNormal:Cross(right).Unit
	
	-- 4. O DESLIZAMENTO (Slip Angle)
	if currentState == STATE_DRIFTING then
		-- O vetor de movimento (tração) persegue lentamente a frente do kart (cria o drift outward)
		movementVector = movementVector:Lerp(visualForward, CFG.driftTraction * dt).Unit
	else
		-- Na condução normal, o kart move-se exatamente para onde aponta
		movementVector = visualForward
	end

	-- Tilt Visual
	currentTilt = lerp(currentTilt, targetTilt, CFG.tiltSpeed * dt)
	local visualOffsetYaw = (currentState == STATE_DRIFTING) and (-driftDir * math.rad(30)) or 0
	
	local modelRot = CFrame.fromMatrix(kartRoot.Position, right, groundNormal, -visualForward)
	kartRoot.CFrame = modelRot * CFrame.Angles(0, visualOffsetYaw, currentTilt)

	-- Física Vertical
	if isGrounded then
		if yVelocity <= 0 then
			kartRoot.CFrame = kartRoot.CFrame - Vector3.new(0, kartRoot.Position.Y - (rResult.Position.Y + CFG.rideHeight), 0)
			yVelocity = 0
		else
			yVelocity = yVelocity - (CFG.downForce * dt)
		end
	else
		yVelocity = yVelocity - (CFG.downForce * dt)
	end
	
	if kartRoot.Position.Y < -300 then
		kartRoot.CFrame = CFrame.new(0, 10, 0)
		visualForward = Vector3.new(0, 0, -1)
		movementVector = visualForward
		speed = 0; yVelocity = 0
	end

	-- APLICAR FORÇA (Hovercraft)
	kartRoot.AssemblyLinearVelocity = (movementVector * speed) + Vector3.new(0, yVelocity, 0)
	
	-- FOV Camera
	local targetFOV = boosting and CFG.boostFOV or CFG.baseFOV
	camera.FieldOfView = lerp(camera.FieldOfView, targetFOV, 10 * dt)
end

-- ============================================================
-- CAMERA MK8
-- ============================================================
local function updateCamera()
	if not kartRoot then return end
	camera.CameraType = Enum.CameraType.Scriptable
	
	local pos = kartRoot.CFrame.Position
	local driftOffset = (currentState == STATE_DRIFTING) and (kartRoot.CFrame.RightVector * (driftDir * -2)) or Vector3.zero
	local back = movementVector * -CFG.camDist
	local desired = pos + back + Vector3.new(0, CFG.camHeight, 0) + driftOffset
	
	camera.CFrame = camera.CFrame:Lerp(
		CFrame.new(desired, pos + Vector3.new(0, 3, 0) + driftOffset),
		CFG.camSmooth
	)
end

-- ============================================================
-- INIT & LOOPS
-- ============================================================
local function waitForKart()
	local attempts = 0
	while not kartRoot and attempts < 120 do
		kart, kartRoot = findKart()
		if kartRoot then
			speed = 0
			visualForward = kartRoot.CFrame.LookVector
			movementVector = visualForward
			setupSparks()
			print("[KC] MK8 Arcade Physics Initialized")
		else
			attempts = attempts + 1
			task.wait(0.5)
		end
	end
end

task.spawn(function()
	local RF = RSt:WaitForChild("BrainKartRemotes", 20)
	if not RF then return end
	RF:WaitForChild("Countdown", 10).OnClientEvent:Connect(function(count)
		if count == 0 then enabled = true; speed = 0 end
	end)
	RF:WaitForChild("EndRace", 10).OnClientEvent:Connect(function()
		enabled = false; speed = 0
		if kartRoot then kartRoot.AssemblyLinearVelocity = Vector3.zero end
	end)
end)

player.CharacterAdded:Connect(function()
	kart, kartRoot = nil, nil
	speed, yVelocity = 0, 0
	enabled, currentState = false, STATE_DRIVING
	sparkEmitters = {}
	camera.FieldOfView = CFG.baseFOV
	task.spawn(waitForKart)
end)
if player.Character then task.spawn(waitForKart) end

RS.Heartbeat:Connect(function(dt)
	if not kartRoot or not kartRoot.Parent then kart, kartRoot = findKart() end
	if not kartRoot or not enabled then return end
	updateKart(dt)
end)

RS.RenderStepped:Connect(function()
	if kartRoot and kartRoot.Parent then updateCamera() end
end)
