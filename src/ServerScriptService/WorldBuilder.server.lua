-- WorldBuilder.server.lua
-- Este script corre automaticamente quando o jogo comeca (Play).
-- Vai gerar a pista, decoracoes e o KartTemplate.

local SS = game:GetService("ServerStorage")

print("[WorldBuilder] A gerar o mundo...")

-- 1. LIMPAR (Apenas a pista anterior, se existir, para nao duplicar)
if workspace:FindFirstChild("Track") then workspace.Track:Destroy() end
if workspace:FindFirstChild("Barriers") then workspace.Barriers:Destroy() end
if workspace:FindFirstChild("SpawnPoints") then workspace.SpawnPoints:Destroy() end
if workspace:FindFirstChild("Checkpoints") then workspace.Checkpoints:Destroy() end
if workspace:FindFirstChild("ItemBoxes") then workspace.ItemBoxes:Destroy() end

local oldK = SS:FindFirstChild("KartTemplate")
if oldK then oldK:Destroy() end

-- 2. TERRAIN
workspace.Terrain:Clear()
workspace.Terrain:FillBlock(CFrame.new(0,-6,0), Vector3.new(1000,8,1000), Enum.Material.Grass)

-- 3. PISTA OVAL
local OX, OZ = 200, 130
local IX, IZ = 115, 65
local TY, TH, SEGS = 1, 4, 36

local trackF = Instance.new("Folder"); trackF.Name="Track"; trackF.Parent=workspace
local barrF = Instance.new("Folder"); barrF.Name="Barriers"; barrF.Parent=workspace

local function oval(t, rx, rz)
	local a = t * math.pi * 2
	return Vector3.new(math.sin(a)*rx, 0, math.cos(a)*rz)
end

for i=0, SEGS-1 do
	local t0, t1 = i/SEGS, (i+1)/SEGS
	local oP0, oP1 = oval(t0,OX,OZ), oval(t1,OX,OZ)
	local iP0, iP1 = oval(t0,IX,IZ), oval(t1,IX,IZ)
	local cO, cI = (oP0+oP1)/2, (iP0+iP1)/2
	local center = (cO+cI)/2 + Vector3.new(0,TY,0)
	local w = (cO-cI).Magnitude + 3
	local l = (oP1-oP0).Magnitude + 2
	local rD = (cO-cI).Unit; local fD = (oP1-oP0).Unit
	local seg = Instance.new("Part")
	seg.Name="TS"..i; seg.Anchored=true; seg.CanCollide=true
	seg.BrickColor=BrickColor.new("Dark grey"); seg.Material=Enum.Material.SmoothPlastic
	seg.Size=Vector3.new(w,TH,l)
	seg.CFrame=CFrame.fromMatrix(center,rD,Vector3.new(0,1,0),-fD)
	seg.Parent=trackF
	for _,rxrz in ipairs({{OX+5,OZ+5},{IX-5,IZ-5}}) do
		local rx2,rz2 = rxrz[1],rxrz[2]
		local p0,p1 = oval(t0,rx2,rz2), oval(t1,rx2,rz2)
		local bc = (p0+p1)/2 + Vector3.new(0,TY+3,0)
		local bl = (p1-p0).Magnitude + 0.5
		local br = (p0-oval(t0,0,0)).Unit
		local bf = (p1-p0).Unit
		local bar = Instance.new("Part")
		bar.Anchored=true; bar.CanCollide=true
		bar.BrickColor=i%2==0 and BrickColor.new("Bright red") or BrickColor.new("White")
		bar.Material=Enum.Material.SmoothPlastic
		bar.Size=Vector3.new(1.5,5,bl)
		bar.CFrame=CFrame.fromMatrix(bc,br,Vector3.new(0,1,0),-bf)
		bar.Parent=barrF
	end
end

-- 4. META
local finishLine = Instance.new("Part")
finishLine.Name="FinishLine"; finishLine.Anchored=true; finishLine.CanCollide=false
finishLine.Size=Vector3.new(38,0.5,3)
finishLine.CFrame=CFrame.new(0,TY+TH/2+0.3,OZ-14)
finishLine.BrickColor=BrickColor.new("White"); finishLine.Material=Enum.Material.Neon
finishLine.Parent=trackF
for r=0,1 do for c=0,8 do
	local sq = Instance.new("Part"); sq.Anchored=true; sq.CanCollide=false
	sq.Size=Vector3.new(4,0.1,3)
	sq.CFrame=CFrame.new(-16+c*4+2,TY+TH/2+0.4,OZ-14)
	sq.BrickColor=((r+c)%2==0) and BrickColor.new("Black") or BrickColor.new("White")
	sq.Material=Enum.Material.SmoothPlastic; sq.Parent=trackF
end end
local aL = Instance.new("Part"); aL.Anchored=true; aL.Size=Vector3.new(2,18,2)
aL.CFrame=CFrame.new(-19,TY+9,OZ-14); aL.BrickColor=BrickColor.new("Bright red")
aL.Material=Enum.Material.SmoothPlastic; aL.Parent=trackF
local aR = aL:Clone(); aR.CFrame=CFrame.new(19,TY+9,OZ-14); aR.Parent=trackF
local aT = Instance.new("Part"); aT.Anchored=true; aT.Size=Vector3.new(42,2,2)
aT.CFrame=CFrame.new(0,TY+18,OZ-14); aT.BrickColor=BrickColor.new("Bright red")
aT.Material=Enum.Material.SmoothPlastic; aT.Parent=trackF
local sgn = Instance.new("Part"); sgn.Anchored=true; sgn.CanCollide=false
sgn.Size=Vector3.new(28,6,1); sgn.CFrame=CFrame.new(0,TY+13,OZ-13)
sgn.BrickColor=BrickColor.new("Bright yellow"); sgn.Material=Enum.Material.SmoothPlastic; sgn.Parent=trackF
local sG = Instance.new("SurfaceGui"); sG.Face=Enum.NormalId.Back; sG.Parent=sgn
local sL = Instance.new("TextLabel"); sL.Text="BRAINKART"; sL.Font=Enum.Font.GothamBlack
sL.TextSize=55; sL.TextColor3=Color3.fromRGB(180,40,0)
sL.Size=UDim2.new(1,0,1,0); sL.BackgroundTransparency=1; sL.Parent=sG

-- 5. SPAWN POINTS
local spawnF = Instance.new("Folder"); spawnF.Name="SpawnPoints"; spawnF.Parent=workspace
local spawnPos = {{-5,OZ-28}, {5,OZ-28}, {-5,OZ-40}, {5,OZ-40}, {-5,OZ-52}, {5,OZ-52}, {-5,OZ-64}, {5,OZ-64}}
for i,pos in ipairs(spawnPos) do
	local sp = Instance.new("Part"); sp.Name="Spawn"..i; sp.Anchored=true; sp.CanCollide=false
	sp.Size=Vector3.new(8,0.5,8)
	sp.CFrame=CFrame.new(pos[1],TY+TH/2+0.3,pos[2])*CFrame.Angles(0,math.pi,0)
	sp.Transparency=0.7; sp.BrickColor=BrickColor.new("Bright yellow"); sp.Material=Enum.Material.Neon; sp.Parent=spawnF
end

-- 6. CHECKPOINTS
local cpF = Instance.new("Folder"); cpF.Name="Checkpoints"; cpF.Parent=workspace
local cpDefs = {{0,-OZ+10,0}, {-OX+10,0,math.pi/2}, {OX-10,0,math.pi/2}}
for i,cd in ipairs(cpDefs) do
	local cp = Instance.new("Part"); cp.Name="Checkpoint"..i; cp.Anchored=true; cp.CanCollide=false
	cp.Size=Vector3.new(38,14,4); cp.CFrame=CFrame.new(cd[1],TY+7,cd[2])*CFrame.Angles(0,cd[3],0)
	cp.Transparency=0.85; cp.BrickColor=BrickColor.new("Bright blue"); cp.Material=Enum.Material.Neon; cp.Parent=cpF
	
	-- Script do checkpoint
	local cs = Instance.new("Script"); cs.Name="CPScript"
	cs.Source = [[
		local idx = ]]..i..[[ 
		local Players = game:GetService("Players")
		script.Parent.Touched:Connect(function(hit)
			local p = Players:GetPlayerFromCharacter(hit.Parent)
			if not p then local n = hit.Parent.Name:match("(.+)Kart"); if n then p = Players:FindFirstChild(n) end end
			if p and _G.BrainKartCP then _G.BrainKartCP(p,idx) end
		end)
	]]
	cs.Parent = cp
end

-- 7. KART TEMPLATE
local function makeKart()
	local m = Instance.new("Model"); m.Name="KartTemplate"
	local root = Instance.new("Part")
	root.Name="KartRoot"; root.Size=Vector3.new(5,2,8)
	root.BrickColor=BrickColor.new("Bright red"); root.Material=Enum.Material.SmoothPlastic
	root.CanCollide=true; root.Anchored=false; root.Parent=m; m.PrimaryPart=root
	local function addPart(name, size, bc, cc, cf)
		local p = Instance.new("Part"); p.Name=name; p.Size=size
		p.BrickColor=bc; p.Material=Enum.Material.SmoothPlastic
		p.CanCollide=false; p.Parent=m
		local w = Instance.new("WeldConstraint"); w.Part0=root; w.Part1=p; w.Parent=root
		p.CFrame=root.CFrame*cf
		return p
	end
	addPart("Body", Vector3.new(4.5,1.5,5), BrickColor.new("Bright red"), false, CFrame.new(0,1.2,-0.5))
	local ws = addPart("Windshield", Vector3.new(3,1,1.5), BrickColor.new("Cyan"), false, CFrame.new(0,1.8,-1.2))
	ws.Material=Enum.Material.Glass; ws.Transparency=0.4
	addPart("Spoiler", Vector3.new(4,0.3,1.5), BrickColor.new("Dark grey"), false, CFrame.new(0,1.5,3.2))
	for _,wo in ipairs({{-2.7,-1,2.5}, {2.7,-1,2.5}, {-2.7,-1,-2.5}, {2.7,-1,-2.5}}) do
		local wh = Instance.new("Part"); wh.Shape=Enum.PartType.Cylinder
		wh.Size=Vector3.new(1.5,1.8,1.8); wh.BrickColor=BrickColor.new("Really black")
		wh.Material=Enum.Material.SmoothPlastic; wh.CanCollide=false; wh.Parent=m
		local wc = Instance.new("WeldConstraint"); wc.Part0=root; wc.Part1=wh; wc.Parent=root
		wh.CFrame=root.CFrame*CFrame.new(wo[1],wo[2],wo[3])*CFrame.Angles(0,0,math.pi/2)
	end
	return m
end

local kt = makeKart()
kt.Parent = SS

-- 8. LUZES
local L = game:GetService("Lighting")
L.Brightness=2; L.ClockTime=14
pcall(function() L.Atmosphere.Density=0.2 end)

print("[WorldBuilder] Mundo e Kart criados com sucesso!")
