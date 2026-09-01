-- KartController (StarterPlayerScripts) - MK8 Physics v5 LocalScript
-- Controlos: W/A/S/D = conduzir | SPACE/LShift = drift+boost | E = item

local Players   = game:GetService("Players")
local UIS       = game:GetService("UserInputService")
local RS        = game:GetService("RunService")
local RSt       = game:GetService("ReplicatedStorage")
local TS        = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ============================================================
-- CONFIGURACAO MK8 DELUXE
-- ============================================================
local CFG = {
	accel       = 70,     -- aceleração rápida
	maxSpeed    = 130,    -- velocidade máxima normal (studs/s)
	brakeForce  = 0.90,   -- força de travagem
	decel       = 0.96,   -- desaceleração natural
	reverseSpd  = 30,     -- velocidade máxima em marcha atrás
	turnSpeed   = 3.5,    -- agilidade de viragem (rápida)
	
	-- Drift & Boost (Mini-Turbos)
	driftTurn   = 4.5,    -- viragem mais apertada durante o drift
	hopHeight   = 22,     -- força do salto ao iniciar o drift
	driftMin    = 0.6,    -- tempo mínimo para o nível 1 (Azul)
	driftMed    = 1.8,    -- tempo mínimo para nível 2 (Laranja)
	driftMax    = 3.5,    -- tempo mínimo para nível 3 (Rosa)
	
	boostSpds   = { 160, 190, 240 }, -- velocidades de boost (Azul, Laranja, Rosa)
	boostDurs   = { 0.8, 1.8, 3.2 }, -- durações de boost
	
	-- Suspensão (Raycast)
	rideHeight  = 3.0,    -- altura que o carro flutua sobre a pista
	downForce   = 200,    -- gravidade artificial para agarrar à pista
	
	-- Câmara
	camDist     = 22,
	camHeight   = 9,
	camSmooth   = 0.15,
}

-- ============================================================
-- ESTADO
-- ============================================================
local kart, kartRoot = nil, nil
local speed          = 0
local yVelocity      = 0
local drifting, driftDir, driftTime, driftLevel = false, 0, 0, 0
local boosting, boostEnd, currentBoostSpeed = false, 0, 0
local enabled  = false  -- so ativa apos GO!
local stunEnd  = 0
local groundNormal = Vector3.new(0, 1, 0)
local isGrounded = false

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

-- ============================================================
-- FISICAS DO KART (MK8)
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
		else topSpd = currentBoostSpeed end
	end

	-- Raycast para o chão
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {kart, player.Character}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local rOrigin = kartRoot.CFrame.Position
	local rDir = -kartRoot.CFrame.UpVector * (CFG.rideHeight + 2)
	local rResult = workspace:Raycast(rOrigin, rDir, rayParams)
	
	if rResult then
		isGrounded = true
		-- Suavizar a normal do chão para o carro não tremer muito
		groundNormal = groundNormal:Lerp(rResult.Normal, 15 * dt).Unit
	else
		isGrounded = false
		groundNormal = groundNormal:Lerp(Vector3.new(0, 1, 0), 5 * dt).Unit
	end

	-- Drift & Hop
	if isGrounded then
		if dk and not drifting and speed > 30 then
			-- Iniciar o Salto (Hop)
			yVelocity = CFG.hopHeight
			drifting = true
			driftDir = str ~= 0 and math.sign(str) or 0
			driftTime = 0
			driftLevel = 0
		elseif dk and drifting then
			-- Manter o Drift
			driftTime = driftTime + dt
			
			-- Atualizar o nível do Mini-Turbo (Sparks)
			local newLevel = 0
			if driftTime >= CFG.driftMax then newLevel = 3
			elseif driftTime >= CFG.driftMed then newLevel = 2
			elseif driftTime >= CFG.driftMin then newLevel = 1 end
			
			if newLevel ~= driftLevel then
				driftLevel = newLevel
				setSparks(driftLevel)
			end
		elseif not dk and drifting then
			-- Largar o Drift (Boost)
			drifting = false
			setSparks(0)
			
			if driftLevel > 0 then
				boosting = true
				currentBoostSpeed = CFG.boostSpds[driftLevel]
				boostEnd = tick() + CFG.boostDurs[driftLevel]
				speed = currentBoostSpeed
				
				-- Flash no HUD
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
		-- Se não está no chão, cancelar o drift
		if not dk and drifting then
			drifting = false
			setSparks(0)
		end
	end

	-- Aceleração e Velocidade
	if acc > 0 then
		speed = math.min(speed + (CFG.accel * dt), topSpd)
	elseif acc < 0 then
		speed = speed > 2 
			and speed * CFG.brakeForce 
			or math.max(speed + (acc * CFG.accel * dt * 0.5), -CFG.reverseSpd)
	else
		speed = speed * CFG.decel
		if math.abs(speed) < 1 then speed = 0 end
	end
	
	-- Viragem
	local turnAmt = 0
	if math.abs(speed) > 2 then
		if drifting and driftDir ~= 0 then
			-- Drift steering logic
			if math.sign(str) == math.sign(driftDir) then
				turnAmt = str * CFG.driftTurn
			else
				turnAmt = driftDir * (CFG.driftTurn * 0.5) + (str * 0.5)
			end
		else
			turnAmt = str * CFG.turnSpeed
		end
	end

	-- Rotação e Alinhamento com a pista
	local forward = kartRoot.CFrame.LookVector
	local right = groundNormal:Cross(forward).Unit
	local newForward = right:Cross(groundNormal).Unit
	
	-- Aplicar a viragem à nova orientação
	local turnRot = CFrame.Angles(0, -turnAmt * dt * math.sign(speed), 0)
	local targetCF = CFrame.fromMatrix(kartRoot.Position, right, groundNormal, -newForward) * turnRot
	
	kartRoot.CFrame = targetCF

	-- Física Vertical (Hop & Downforce)
	if isGrounded then
		if yVelocity <= 0 then
			-- Snap to ground
			kartRoot.CFrame = kartRoot.CFrame - Vector3.new(0, kartRoot.Position.Y - (rResult.Position.Y + CFG.rideHeight), 0)
			yVelocity = 0
		else
			-- Subindo no salto
			yVelocity = yVelocity - (CFG.downForce * dt)
		end
	else
		-- Gravidade no ar
		yVelocity = yVelocity - (CFG.downForce * dt)
	end
	
	-- Se cair do mapa
	if kartRoot.Position.Y < -50 then
		kartRoot.CFrame = CFrame.new(0, 10, 0)
		speed = 0
		yVelocity = 0
	end

	-- Aplicar força física final
	kartRoot.AssemblyLinearVelocity = (kartRoot.CFrame.LookVector * speed) + Vector3.new(0, yVelocity, 0)
end

-- ============================================================
-- CAMERA MK8
-- ============================================================
local function updateCamera()
	if not kartRoot then return end
	camera.CameraType = Enum.CameraType.Scriptable
	
	local pos = kartRoot.CFrame.Position
	-- Inclinar a câmara se estiver a fazer drift
	local driftOffset = drifting and (kartRoot.CFrame.RightVector * (driftDir * -2)) or Vector3.zero
	
	local back = kartRoot.CFrame.LookVector * -CFG.camDist
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
			setupSparks()
			print("[KC] Kart MK8 encontrado: " .. kart.Name)
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

print("[KC] KartController MK8 Deluxe carregado!")
