-- KartController (StarterPlayerScripts) - Advanced MK8 Physics LocalScript
-- Controlos: W/A/S/D = conduzir | SPACE/LShift = drift+boost | E = item

local Players   = game:GetService("Players")
local UIS       = game:GetService("UserInputService")
local RS        = game:GetService("RunService")
local RSt       = game:GetService("ReplicatedStorage")
local TS        = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ============================================================
-- CONFIGURACAO HYPER KARTS / MK8 ADVANCED
-- ============================================================
local CFG = {
	accel       = 80,     -- aceleração rápida
	maxSpeed    = 135,    -- velocidade máxima normal (studs/s)
	brakeForce  = 0.90,   -- força de travagem normal
	decel       = 0.97,   -- desaceleração natural
	offroadDecel= 0.85,   -- desaceleração extra quando na relva/terra
	reverseSpd  = 30,     -- velocidade máxima em marcha atrás
	turnSpeed   = 1.5,    -- agilidade de viragem (muito suave)
	
	-- Tilt Visual (Inclinação)
	maxTilt     = math.rad(15), 
	tiltSpeed   = 6,      
	
	-- Drift, Momentum & MT (Mini-Turbo)
	driftTurn   = 3.6,    -- viragem mais apertada durante o drift
	hopHeight   = 22,     -- força do salto ao iniciar o drift
	
	-- Mini-Turbo Charge
	baseChargeRate = 1.0,
	mtThreshold1 = 0.6,    -- Limiar Azul
	mtThreshold2 = 1.8,    -- Limiar Laranja
	mtThreshold3 = 3.5,    -- Limiar Rosa (Ultra)
	
	boostSpds   = { 170, 205, 255 }, -- velocidades de boost (Azul, Laranja, Rosa)
	boostDurs   = { 0.8, 1.8, 3.2 }, -- durações de boost
	
	-- Suspensão (Raycast)
	rideHeight  = 3.0,    -- altura que o carro flutua sobre a pista
	downForce   = 200,    -- gravidade artificial para agarrar à pista
	
	-- Câmara
	camDist     = 22,
	camHeight   = 9,
	camSmooth   = 0.15,
	baseFOV     = 70,
	boostFOV    = 90,
}

-- ============================================================
-- ESTADO
-- ============================================================
local kart, kartRoot = nil, nil
local speed          = 0
local yVelocity      = 0
local drifting, driftDir = false, 0
local mtCharge, driftLevel = 0, 0
local boosting, boostEnd, currentBoostSpeed = false, 0, 0
local enabled  = false  -- so ativa apos GO!
local stunEnd  = 0
local groundNormal = Vector3.new(0, 1, 0)
local isGrounded = false
local currentTilt = 0
local isOnOffroad = false
local lastBump = 0 -- Cooldown de colisão com parede
local currentTurnAmt = 0 -- Suavizador de curva

-- Momentum Desacoplado
local movementVector = Vector3.new(0, 0, -1)

-- Referências para as faíscas
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

-- Configura as partículas de Drift
local function setupSparks()
	if not kart or #sparkEmitters > 0 then return end
	local root = kart:FindFirstChild("KartRoot")
	if not root then return end
	
	for _, offset in ipairs({Vector3.new(-3, -1, 3.5), Vector3.new(3, -1, 3.5)}) do
		local a = Instance.new("Attachment")
		a.Position = offset
		a.Parent = root
		
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxassetid://1347000185" -- Estrela simples ou flash
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
		if level == 0 then
			e.Rate = 0
		else
			e.Rate = 60
			if level == 1 then
				e.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255)) -- Azul
			elseif level == 2 then
				e.Color = ColorSequence.new(Color3.fromRGB(255, 120, 0)) -- Laranja
			elseif level == 3 then
				e.Color = ColorSequence.new(Color3.fromRGB(255, 50, 200)) -- Rosa
			end
		end
	end
end

local function cancelDrift()
	drifting = false
	mtCharge = 0
	driftLevel = 0
	setSparks(0)
end

-- ============================================================
-- FISICAS DO KART (ADVANCED MK8)
-- ============================================================
local function updateKart(dt)
	if not kartRoot then return end
	
	-- HITSTUN: Se bater de frente numa parede, perde controlo
	if tick() < stunEnd then 
		speed = speed * 0.88 
		-- Aplicar gravidade passiva
		yVelocity = yVelocity - (CFG.downForce * dt)
		kartRoot.AssemblyLinearVelocity = (movementVector * speed) + Vector3.new(0, yVelocity, 0)
		return 
	end

	local acc, str = 0, 0
	local dk = false -- drift key
	local braking = false

	-- Leitura do teclado
	if keyDown(Enum.KeyCode.W, Enum.KeyCode.Up)    then acc =  1    end
	if keyDown(Enum.KeyCode.S, Enum.KeyCode.Down)   then 
		acc = -0.5
		braking = true 
	end
	if keyDown(Enum.KeyCode.A, Enum.KeyCode.Left)   then str = -1    end
	if keyDown(Enum.KeyCode.D, Enum.KeyCode.Right)  then str =  1    end
	if keyDown(Enum.KeyCode.Space, Enum.KeyCode.LeftShift) then dk = true end

	-- Leitura do Comando (Xbox/PS)
	local gamepads = UIS:GetConnectedGamepads()
	if #gamepads > 0 then
		local gp = gamepads[1]
		local state = UIS:GetGamepadState(gp)
		for _, input in ipairs(state) do
			if input.KeyCode == Enum.KeyCode.ButtonB and input.UserInputState == Enum.UserInputState.Begin then
				acc = 1
			elseif input.KeyCode == Enum.KeyCode.ButtonA and input.UserInputState == Enum.UserInputState.Begin then
				acc = -0.5
				braking = true
			elseif (input.KeyCode == Enum.KeyCode.ButtonR1 or input.KeyCode == Enum.KeyCode.ButtonR2) and input.UserInputState == Enum.UserInputState.Begin then
				dk = true
			elseif input.KeyCode == Enum.KeyCode.Thumbstick1 then
				if math.abs(input.Position.X) > 0.15 then
					str = input.Position.X
				end
			end
		end
	end

	local topSpd = CFG.maxSpeed
	
	-- BOOST OVERRIDE
	local targetFOV = CFG.baseFOV
	if boosting then
		if tick() > boostEnd then 
			boosting = false
		else 
			topSpd = currentBoostSpeed
			targetFOV = CFG.boostFOV 
		end
	end
	camera.FieldOfView = camera.FieldOfView + (targetFOV - camera.FieldOfView) * 10 * dt

	-- Raycasts
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {kart, player.Character}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	-- RAYCAST 1: CHÃO (Offroad & Orientação)
	local rOrigin = kartRoot.CFrame.Position
	local rDir = -kartRoot.CFrame.UpVector * (CFG.rideHeight + 2)
	local rResult = workspace:Raycast(rOrigin, rDir, rayParams)
	
	isOnOffroad = false
	if rResult then
		isGrounded = true
		groundNormal = groundNormal:Lerp(rResult.Normal, 15 * dt).Unit
		
		-- Detetar Off-road
		if rResult.Material == Enum.Material.Grass or rResult.Material == Enum.Material.Sand or rResult.Material == Enum.Material.LeafyGrass then
			isOnOffroad = true
		end
	else
		isGrounded = false
		groundNormal = groundNormal:Lerp(Vector3.new(0, 1, 0), 5 * dt).Unit
	end
	
	-- RAYCAST 2: COLISÕES RÍGIDAS (Paredes)
	if speed > 20 and tick() > lastBump then
		-- Verifica à frente
		local wallRay = workspace:Raycast(rOrigin, movementVector * 6, rayParams)
		if wallRay then
			local dot = -movementVector:Dot(wallRay.Normal)
			if dot > 0.65 then
				-- ÂNGULO OBTUSO (Frontal): Hitstun, cancela tudo, speed 0
				cancelDrift()
				speed = 0
				stunEnd = tick() + 0.6
				lastBump = tick() + 0.8
			elseif dot > 0.1 then
				-- ÂNGULO AGUDO (Roçar de raspão): Perde 20% da velocidade, repele
				speed = speed * 0.8
				movementVector = (movementVector + wallRay.Normal * 0.5).Unit
				lastBump = tick() + 0.3
			end
		end
	end

	-- EFEITO OFF-ROAD
	local effectiveDecel = CFG.decel
	if isOnOffroad and not boosting then
		effectiveDecel = CFG.offroadDecel
		topSpd = topSpd * 0.3 -- Velocidade máxima cai drasticamente para 30%
		
		-- OFFROAD CANCELA DRIFT IMEDIATAMENTE
		if drifting then
			cancelDrift()
		end
	end

	-- Drift & Hop State Machine
	if isGrounded then
		if dk and not drifting and speed > 30 and not isOnOffroad then
			yVelocity = CFG.hopHeight
			if math.abs(str) > 0.1 then
				drifting = true
				driftDir = math.sign(str)
				mtCharge = 0
				driftLevel = 0
			end
		elseif dk and drifting then
			if braking then
				speed = speed * 0.95
			end
			
			local chargeMult = 0
			if math.sign(str) == math.sign(driftDir) then
				if math.abs(str) >= 0.707 then
					chargeMult = 1.0 
				else
					chargeMult = math.abs(str) / 0.707
				end
			else
				chargeMult = 0.2 
			end
			
			mtCharge = mtCharge + (CFG.baseChargeRate * chargeMult * dt)
			
			local newLevel = 0
			if mtCharge >= CFG.mtThreshold3 then newLevel = 3
			elseif mtCharge >= CFG.mtThreshold2 then newLevel = 2
			elseif mtCharge >= CFG.mtThreshold1 then newLevel = 1 end
			
			if newLevel ~= driftLevel then
				driftLevel = newLevel
				setSparks(driftLevel)
			end
		elseif not dk and drifting then
			drifting = false
			setSparks(0)
			if driftLevel > 0 then
				boosting = true
				currentBoostSpeed = CFG.boostSpds[driftLevel]
				boostEnd = tick() + CFG.boostDurs[driftLevel]
				speed = currentBoostSpeed
				
				task.spawn(function()
					local gui = player.PlayerGui:FindFirstChild("RaceHUD")
					if not gui then return end
					local flash = Instance.new("Frame")
					flash.Size = UDim2.new(1, 0, 1, 0)
					flash.BackgroundColor3 = (driftLevel == 1 and Color3.fromRGB(0,200,255)) or (driftLevel == 2 and Color3.fromRGB(255,120,0)) or Color3.fromRGB(255,50,200)
					flash.BackgroundTransparency = 0.6
					flash.ZIndex = 50
					flash.Parent = gui
					TS:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
					task.delay(0.5, function() if flash then flash:Destroy() end end)
				end)
			end
			driftLevel = 0
		end
	else
		if not dk and drifting then
			cancelDrift()
		end
	end

	-- Aceleração Padrão
	if not (drifting and braking) then
		if acc > 0 then
			speed = math.min(speed + (CFG.accel * dt), topSpd)
		elseif acc < 0 then
			speed = speed > 2 
				and speed * CFG.brakeForce 
				or math.max(speed + (acc * CFG.accel * dt * 0.5), -CFG.reverseSpd)
		else
			speed = speed * effectiveDecel
			if math.abs(speed) < 1 then speed = 0 end
		end
	end
	
	if isOnOffroad and not boosting and speed > topSpd then
		speed = speed * effectiveDecel
	end
	
	-- Viragem
	local targetTurnAmt = 0
	local targetTilt = 0
	local visualOffsetYaw = 0 
	
	if math.abs(speed) > 2 then
		if drifting and driftDir ~= 0 then
			-- 1. O VIÉS BASE (A Âncora)
			local baseTurn = driftDir * (CFG.turnSpeed * 0.6)
			
			-- O analógico só soma/subtrai a este viés
			local steerAdjust = str * (CFG.driftTurn * 0.7)
			targetTurnAmt = baseTurn + steerAdjust
			
			-- 2. CLAMPING ESTRITO
			local minTurn = CFG.turnSpeed * 0.25 
			local maxTurn = CFG.driftTurn * 1.15 
			
			if driftDir > 0 then
				targetTurnAmt = math.clamp(targetTurnAmt, minTurn, maxTurn)
			else
				targetTurnAmt = math.clamp(targetTurnAmt, -maxTurn, -minTurn)
			end
			
			targetTilt = -driftDir * CFG.maxTilt * 1.5 
			visualOffsetYaw = -driftDir * math.rad(35) 
		else
			targetTurnAmt = str * CFG.turnSpeed
			targetTilt = -str * CFG.maxTilt 
		end
	end
	
	-- SUAVIZAÇÃO DA CURVA (Interpolamos a força da viragem para não ser instantânea)
	-- Quanto mais baixo o número multiplicador (ex: 4), mais demora a apertar a curva
	currentTurnAmt = currentTurnAmt + (targetTurnAmt - currentTurnAmt) * 4 * dt
	
	currentTilt = currentTilt + (targetTilt - currentTilt) * CFG.tiltSpeed * dt

	local right = movementVector:Cross(groundNormal).Unit
	local newForward = groundNormal:Cross(right).Unit
	
	local movementTurnRot = CFrame.Angles(0, -currentTurnAmt * dt * math.sign(speed), 0)
	local movementCF = CFrame.fromMatrix(kartRoot.Position, right, groundNormal, -newForward) * movementTurnRot
	movementVector = movementCF.LookVector
	
	local visualRot = movementCF * CFrame.Angles(0, visualOffsetYaw, currentTilt)
	kartRoot.CFrame = visualRot

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
	
	if kartRoot.Position.Y < -50 then
		kartRoot.CFrame = CFrame.new(0, 10, 0)
		movementVector = Vector3.new(0, 0, -1)
		speed = 0
		yVelocity = 0
	end

	kartRoot.AssemblyLinearVelocity = (movementVector * speed) + Vector3.new(0, yVelocity, 0)
end

-- ============================================================
-- CAMERA MK8
-- ============================================================
local function updateCamera()
	if not kartRoot then return end
	camera.CameraType = Enum.CameraType.Scriptable
	
	local pos = kartRoot.CFrame.Position
	local driftOffset = drifting and (kartRoot.CFrame.RightVector * (driftDir * -2)) or Vector3.zero
	local back = movementVector * -CFG.camDist
	local desired = pos + back + Vector3.new(0, CFG.camHeight, 0) + driftOffset
	
	camera.CFrame = camera.CFrame:Lerp(
		CFrame.new(desired, pos + Vector3.new(0, 3, 0) + driftOffset),
		CFG.camSmooth
	)
end

-- ============================================================
-- PROCURAR KART
-- ============================================================
local function waitForKart()
	local attempts = 0
	while not kartRoot and attempts < 120 do
		kart, kartRoot = findKart()
		if kartRoot then
			speed = 0
			movementVector = kartRoot.CFrame.LookVector
			setupSparks()
			print("[KC] Kart Advanced MK8 encontrado: " .. kart.Name)
		else
			attempts = attempts + 1
			task.wait(0.5)
		end
	end
end

-- ============================================================
-- REMOTE EVENTS
-- ============================================================
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

-- ============================================================
-- RESPAWN & LOOPS
-- ============================================================
player.CharacterAdded:Connect(function()
	kart, kartRoot = nil, nil
	speed, yVelocity = 0, 0
	enabled, drifting = false, false
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

print("[KC] KartController Colisoes & Offroad carregado!")
