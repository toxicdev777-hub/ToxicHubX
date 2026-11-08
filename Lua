-- toxic hub | pvp + farm + dungeon | weapons separated
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local character, humanoid, humanoidRootPart

local function refreshChar(c)
	character = c or Player.Character
	if not character then return end
	humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	humanoidRootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
end
refreshChar(Player.Character)
Player.CharacterAdded:Connect(function(c)
	task.wait(0.45)
	refreshChar(c)
	task.wait(0.2)
	if getgenv().ToxicHub then
		local T = getgenv().ToxicHub
		if T.AutoDungeon then
			-- re-equip dungeon weapon only
		elseif T.StartFarm then
			-- re-equip farm weapon only
		end
	end
end)

local Net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local function CommF(...)
	local r = Remotes and Remotes:FindFirstChild("CommF_")
	if not r then return end
	local a = {...}
	local ok, res = pcall(function() return r:InvokeServer(unpack(a)) end)
	return ok and res or nil
end

local function findTool(pred)
	if character then
		for _, t in ipairs(character:GetChildren()) do
			if t:IsA("Tool") and pred(t) then return t end
		end
	end
	for _, t in ipairs(Player.Backpack:GetChildren()) do
		if t:IsA("Tool") and pred(t) then return t end
	end
end

getgenv().ToxicHub = getgenv().ToxicHub or {}
local T = getgenv().ToxicHub

T.SelectPlayer = T.SelectPlayer or ""
T.TPTween = T.TPTween or false
T.TPBypass = T.TPBypass or false
T.TPNearest = T.TPNearest or false
T.ViewScreen = T.ViewScreen or false
T.TweenSpeed = T.TweenSpeed or 250
T.OffsetY = T.OffsetY or 3

T.Aura = T.Aura or false
T.AuraRange = T.AuraRange or 30
T.AuraPlayers = T.AuraPlayers ~= false
T.AuraMobs = T.AuraMobs or false
T.FA = T.FA ~= false
T.Fruit = T.Fruit or false
T.Gun = T.Gun or false
T.Bring = T.Bring or false
T.BringRange = T.BringRange or 400

T.ESP = T.ESP or false
T.ESPName = T.ESPName ~= false
T.ESPHP = T.ESPHP ~= false
T.ESPBox = T.ESPBox ~= false
T.ESPDist = T.ESPDist ~= false

T.FarmMode = T.FarmMode or "Tyrant"
T.StartFarm = T.StartFarm or false
T.AutoQuest = T.AutoQuest or false
T.DestroyVases = T.DestroyVases or false
T.Weapon = T.Weapon or "Melee"              -- FARM ONLY
T.DungeonWeapon = T.DungeonWeapon or "Melee" -- DUNGEON ONLY
T.FarmDist = T.FarmDist or 20
T.FarmTween = T.FarmTween or 250
T.V3 = T.V3 or false
T.V4 = T.V4 or false
T._QuestBusy = false

T.AutoDungeon = T.AutoDungeon or false
T.DestroyEvents = T.DestroyEvents or false
T.AutoCards = T.AutoCards or false

T.NoFog = T.NoFog or false
T.FPSBoost = T.FPSBoost or false
T.WalkSpeed = T.WalkSpeed or false
T.WalkSpeedVal = T.WalkSpeedVal or 20
T.JumpPower = T.JumpPower or false
T.JumpPowerVal = T.JumpPowerVal or 50
T.NoClip = T.NoClip or false
T.AntiAFK = T.AntiAFK ~= false

local BonesList = {["Reborn Skeleton"]=true,["Living Zombie"]=true,["Demonic Soul"]=true,["Posessed Mummy"]=true}
local CakesList = {["Head Baker"]=true,["Baking Staff"]=true,["Cake Guard"]=true,["Cookie Crafter"]=true}
local TyrantList = {["Isle Champion"]=true,["Serpent Hunter"]=true,["Skull Slayer"]=true,["Sun-kissed Warrior"]=true}
local CF = {
	Bone = CFrame.new(-9506, 172, 6057),
	Cake = CFrame.new(-2304, 228, -12240),
	CakePortal = CFrame.new(-2168, 84, -12397),
	Tyrant = CFrame.new(-16257, 22, 1062),
	BoneQuest = CFrame.new(-9515, 172, 6078),
	CakeQuest = CFrame.new(-2021, 38, -12029),
	TyrantQuest = CFrame.new(-16257, 22, 1062),
}
local CardPriority = { "Melee Damage", "Sword Damage", "Life Steal", "Lifesteal", "Melee", "Sword", "Life" }

local function playerNames()
	local t = {}
	for _, p in ipairs(Players:GetPlayers()) do if p ~= Player then table.insert(t, p.Name) end end
	table.sort(t)
	return t
end

-- TWEEN
local tweenToken, tweening, bodyVelocity = 0, false, nil
local function ensureBV()
	if not humanoidRootPart then return end
	if bodyVelocity and bodyVelocity.Parent then return end
	local old = humanoidRootPart:FindFirstChild("PartVelocuty")
	if old then old:Destroy() end
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "PartVelocuty"
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.P = 1000
	bodyVelocity.Parent = humanoidRootPart
end
local function stopTween()
	tweenToken += 1
	tweening = false
	if bodyVelocity then pcall(function() if bodyVelocity.Parent then bodyVelocity:Destroy() end end) bodyVelocity = nil end
	if humanoidRootPart then
		local pv = humanoidRootPart:FindFirstChild("PartVelocuty")
		if pv then pv:Destroy() end
	end
end
local function topos(goalCF, keepBV, speed)
	if tweening or not humanoidRootPart or not humanoid or humanoid.Health <= 0 then return end
	local goal = typeof(goalCF) == "CFrame" and goalCF or CFrame.new(goalCF)
	if goal.Y < -50 then goal = CFrame.new(goal.X, 20, goal.Z) end
	local start, magnitude = humanoidRootPart.CFrame, (goal.Position - humanoidRootPart.Position).Magnitude
	if magnitude <= 6 then
		humanoidRootPart.CFrame = goal
		if keepBV then ensureBV() end
		return
	end
	tweenToken += 1
	local my = tweenToken
	tweening = true
	ensureBV()
	if character then
		for _, p in pairs(character:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end
	task.spawn(function()
		local now, traveled = tick(), 0
		local spd = math.max(speed or T.TweenSpeed or 250, 0.1)
		while my == tweenToken and humanoid and humanoid.Health > 0 and humanoidRootPart do
			local now2 = tick()
			traveled += spd * (now2 - now)
			local a = math.clamp(traveled / magnitude, 0, 1)
			local cf = start:Lerp(goal, a)
			if cf.Y < -20 then cf = CFrame.new(cf.X, 20, cf.Z) end
			humanoidRootPart.CFrame = cf
			if bodyVelocity and bodyVelocity.Parent then bodyVelocity.Velocity = Vector3.zero end
			if a >= 1 or (goal.Position - humanoidRootPart.Position).Magnitude <= 10 then
				humanoidRootPart.CFrame = goal
				break
			end
			task.wait()
			now = now2
		end
		tweening = false
		if keepBV then ensureBV() else
			if bodyVelocity then pcall(function() bodyVelocity:Destroy() end) bodyVelocity = nil end
		end
	end)
end
local function tpBypass(cf)
	if humanoidRootPart then
		humanoidRootPart.CFrame = typeof(cf) == "CFrame" and cf or CFrame.new(cf)
		ensureBV()
	end
end

-- ========== WEAPONS (Melee / Sword / Fruit / Gun) ==========
local function matchWeapon(tool, kind)
	local tip = tostring(tool.ToolTip or "")
	if kind == "Gun" then
		return tip == "Gun" or tool.Name == "Dragonstorm" or tool.Name == "Skull Guitar"
	elseif kind == "Fruit" then
		return tip == "Blox Fruit"
	elseif kind == "Sword" then
		return tip == "Sword"
	else
		return tip == "Melee" or tip == "Combat"
	end
end

local function equipByKind(kind)
	if not character or not humanoid then return nil end
	kind = kind or "Melee"
	for _, t in ipairs(character:GetChildren()) do
		if t:IsA("Tool") and matchWeapon(t, kind) then return t end
	end
	for _, t in ipairs(Player.Backpack:GetChildren()) do
		if t:IsA("Tool") and matchWeapon(t, kind) then
			pcall(function() humanoid:EquipTool(t) end)
			task.wait(0.07)
			return character:FindFirstChild(t.Name) or t
		end
	end
	return nil
end

local function fruitAttack()
	local tool = equipByKind("Fruit")
	if not tool then return end
	if tool.Parent == Player.Backpack and humanoid then
		pcall(function() humanoid:EquipTool(tool) end)
		task.wait(0.05)
		tool = character and character:FindFirstChild(tool.Name) or tool
	end
	local remote = tool:FindFirstChild("LeftClickRemote")
	if remote then
		pcall(function() remote:FireServer(Vector3.new(0, -1, 0), 1, true) end)
		pcall(function() remote:FireServer(Vector3.new(0, -1, 0), 1) end)
		pcall(function() remote:FireServer(Vector3.new(0.01, -1, 0.01), true) end)
		pcall(function() remote:FireServer(Vector3.new(0, -1, 0)) end)
	end
	pcall(function() tool:Activate() end)
end

local function gunAttack(targetPos)
	local tool = equipByKind("Gun")
	if not tool or not humanoidRootPart then return end
	if tool.Parent == Player.Backpack and humanoid then
		pcall(function() humanoid:EquipTool(tool) end)
		task.wait(0.05)
		tool = character and character:FindFirstChild(tool.Name) or tool
	end
	local pos = targetPos or (humanoidRootPart.Position + humanoidRootPart.CFrame.LookVector * 80)
	pcall(function()
		tool:SetAttribute("IsReloading_Client", false)
		tool:SetAttribute("LocalShotsLeft", 999)
	end)
	if tool:FindFirstChild("RemoteEvent") then
		pcall(function() tool.RemoteEvent:FireServer("TAP", pos) end)
		pcall(function() tool.RemoteEvent:FireServer(pos) end)
	end
	if Net then
		local S = Net:FindFirstChild("RE/ShootGunEvent")
		if S then
			pcall(function() S:FireServer(pos, { humanoidRootPart }) end)
			pcall(function() S:FireServer(pos, {}) end)
		end
	end
	pcall(function() tool:Activate() end)
end

local function meleeSwordAttack(kind, targetRoot)
	local tool = equipByKind(kind)
	if not tool then return end
	if targetRoot then
		local mp = tool:FindFirstChild("MousePos")
		if mp and mp:IsA("Vector3Value") then mp.Value = targetRoot.Position end
	end
	pcall(function() tool:Activate() end)
end

local function autoHaki()
	pcall(function()
		if not character then return end
		if not character:HasTag("Buso") then CommF("BuyHaki", "Buso") end
		if character:HasTag("Buso") and not character:FindFirstChild("HasBuso") then CommF("Buso") end
	end)
end

local function registerHit(targetModel, targetRoot)
	if not (T.FA and Net and targetModel and targetRoot) then return end
	local RA = Net:FindFirstChild("RE/RegisterAttack")
	local RH = Net:FindFirstChild("RE/RegisterHit")
	if RA and RH then
		pcall(function()
			RA:FireServer(0)
			RH:FireServer(targetModel:FindFirstChild("Head") or targetRoot, {{ targetModel, targetRoot }})
		end)
	end
end

local function attackWithKind(kind, targetModel, targetRoot)
	autoHaki()
	if kind == "Fruit" then
		fruitAttack()
	elseif kind == "Gun" then
		gunAttack(targetRoot and targetRoot.Position)
	elseif kind == "Sword" then
		meleeSwordAttack("Sword", targetRoot)
	else
		meleeSwordAttack("Melee", targetRoot)
	end
	registerHit(targetModel, targetRoot)
end

local function farmWeaponKind()
	return T.Weapon or "Melee"
end
local function dungeonWeaponKind()
	return T.DungeonWeapon or "Melee"
end

-- AURA
local function auraStep()
	if not T.Aura or not humanoidRootPart then return end
	autoHaki()
	local range = T.AuraRange or 30
	if T.AuraPlayers then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == Player then continue end
			local ch = plr.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health > 0 and root and (root.Position - humanoidRootPart.Position).Magnitude <= range then
				if T.Fruit then fruitAttack() end
				if T.Gun then gunAttack(root.Position) end
				local tool = character and character:FindFirstChildOfClass("Tool")
				if tool then
					local mp = tool:FindFirstChild("MousePos")
					if mp and mp:IsA("Vector3Value") then mp.Value = root.Position end
					pcall(function() tool:Activate() end)
				end
				registerHit(ch, root)
			end
		end
	end
	if T.AuraMobs then
		local en = Workspace:FindFirstChild("Enemies")
		if en then
			for _, e in ipairs(en:GetChildren()) do
				local hum = e:FindFirstChildOfClass("Humanoid")
				local root = e:FindFirstChild("HumanoidRootPart")
				if hum and hum.Health > 0 and root and (root.Position - humanoidRootPart.Position).Magnitude <= range then
					if T.Fruit then fruitAttack() end
					if T.Gun then gunAttack(root.Position) end
					registerHit(e, root)
				end
			end
		end
	end
end

-- BRING
local BRING_TAG = "ToxicBring"
local bringCache, lastBring = {}, 0
local function getNearestMob()
	local en = Workspace:FindFirstChild("Enemies")
	if not en or not humanoidRootPart then return nil end
	local best, bd = nil, math.huge
	for _, e in ipairs(en:GetChildren()) do
		if string.find(string.lower(e.Name), "shadow") then continue end
		local h, r = e:FindFirstChildOfClass("Humanoid"), e:FindFirstChild("HumanoidRootPart")
		if h and h.Health > 0 and r and r.Position.Y > -50 then
			local d = (r.Position - humanoidRootPart.Position).Magnitude
			if d < bd then bd, best = d, e end
		end
	end
	return best
end
local function bringStep(target)
	if not T.Bring or not humanoidRootPart then return end
	target = target or getNearestMob()
	if not target then return end
	local tRoot = target:FindFirstChild("HumanoidRootPart")
	if not tRoot or tick() - lastBring < 0.2 then return end
	lastBring = tick()
	bringCache[target.Name] = tRoot.CFrame
	local radius = T.BringRange or 400
	pcall(function() sethiddenproperty(Player, "SimulationRadius", math.clamp(radius + 50, 100, 500)) end)
	local en, n = Workspace:FindFirstChild("Enemies"), 0
	if not en then return end
	for _, e in ipairs(en:GetChildren()) do
		if e ~= target and e.Name == target.Name and not CollectionService:HasTag(e, BRING_TAG) then
			local r, h = e:FindFirstChild("HumanoidRootPart"), e:FindFirstChildOfClass("Humanoid")
			if r and h and h.Health > 0 and (r.Position - tRoot.Position).Magnitude <= radius then
				CollectionService:AddTag(e, BRING_TAG)
				n += 1
				if n >= 5 then break end
			end
		end
	end
end
CollectionService:GetInstanceAddedSignal(BRING_TAG):Connect(function(mob)
	task.spawn(function()
		local r, h = mob:FindFirstChild("HumanoidRootPart"), mob:FindFirstChildOfClass("Humanoid")
		if not r or not h then return end
		local bp = r:FindFirstChild("BringBodyPos") or Instance.new("BodyPosition")
		bp.Name, bp.MaxForce, bp.P, bp.D = "BringBodyPos", Vector3.new(1e6, 1e6, 1e6), 8000, 600
		bp.Parent = r
		local expire = tick() + 25
		while T.Bring and mob.Parent and h.Health > 0 and tick() < expire do
			local cache = bringCache[mob.Name]
			if cache then
				for _, p in ipairs(mob:GetChildren()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
				r.AssemblyLinearVelocity = Vector3.zero
				bp.Position = cache.Position
			end
			task.wait(0.04)
		end
		pcall(function()
			if bp then bp:Destroy() end
			CollectionService:RemoveTag(mob, BRING_TAG)
		end)
	end)
end)

-- ESP
local ESPFolder
local function clearESP()
	if ESPFolder then ESPFolder:Destroy() ESPFolder = nil end
end
local function updateESP()
	if not T.ESP then clearESP() return end
	if not ESPFolder then
		ESPFolder = Instance.new("Folder")
		ESPFolder.Name = "ToxicESP"
		ESPFolder.Parent = CoreGui
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p == Player then continue end
		local ch = p.Character
		local root = ch and ch:FindFirstChild("HumanoidRootPart")
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		local head = ch and ch:FindFirstChild("Head")
		if not root or not hum or hum.Health <= 0 then
			local old = ESPFolder:FindFirstChild(p.Name)
			if old then old:Destroy() end
			continue
		end
		local holder = ESPFolder:FindFirstChild(p.Name)
		if not holder then
			holder = Instance.new("Folder")
			holder.Name = p.Name
			holder.Parent = ESPFolder
			local bill = Instance.new("BillboardGui")
			bill.Name = "Bill"
			bill.Size = UDim2.new(0, 160, 0, 50)
			bill.AlwaysOnTop = true
			bill.StudsOffset = Vector3.new(0, 3.4, 0)
			bill.Parent = holder
			local nameL = Instance.new("TextLabel")
			nameL.Name = "Name"
			nameL.BackgroundTransparency = 1
			nameL.Size = UDim2.new(1, 0, 0.4, 0)
			nameL.Font = Enum.Font.GothamBold
			nameL.TextSize = 13
			nameL.TextColor3 = Color3.fromRGB(255, 80, 90)
			nameL.TextStrokeTransparency = 0.4
			nameL.Parent = bill
			local hpL = Instance.new("TextLabel")
			hpL.Name = "HP"
			hpL.BackgroundTransparency = 1
			hpL.Position = UDim2.new(0, 0, 0.35, 0)
			hpL.Size = UDim2.new(1, 0, 0.3, 0)
			hpL.Font = Enum.Font.Gotham
			hpL.TextSize = 12
			hpL.TextStrokeTransparency = 0.4
			hpL.Parent = bill
			local distL = Instance.new("TextLabel")
			distL.Name = "Dist"
			distL.BackgroundTransparency = 1
			distL.Position = UDim2.new(0, 0, 0.65, 0)
			distL.Size = UDim2.new(1, 0, 0.3, 0)
			distL.Font = Enum.Font.Gotham
			distL.TextSize = 11
			distL.TextColor3 = Color3.fromRGB(200, 200, 210)
			distL.TextStrokeTransparency = 0.4
			distL.Parent = bill
			local hl = Instance.new("Highlight")
			hl.Name = "HL"
			hl.FillTransparency = 0.75
			hl.OutlineColor = Color3.fromRGB(255, 60, 70)
			hl.FillColor = Color3.fromRGB(255, 60, 70)
			hl.Parent = holder
		end
		local bill = holder:FindFirstChild("Bill")
		if bill then bill.Adornee = head or root end
		local hl = holder:FindFirstChild("HL")
		if hl then hl.Adornee = ch hl.Enabled = T.ESPBox end
		local nameL = bill and bill:FindFirstChild("Name")
		local hpL = bill and bill:FindFirstChild("HP")
		local distL = bill and bill:FindFirstChild("Dist")
		if nameL then nameL.Visible = T.ESPName nameL.Text = p.DisplayName or p.Name end
		if hpL and T.ESPHP then
			local pct = math.floor((hum.Health / math.max(hum.MaxHealth, 1)) * 100)
			hpL.Text = pct .. "%"
			hpL.TextColor3 = pct > 60 and Color3.fromRGB(80, 255, 80) or pct > 30 and Color3.fromRGB(255, 200, 40) or Color3.fromRGB(255, 50, 50)
		elseif hpL then hpL.Text = "" end
		if distL and T.ESPDist and humanoidRootPart then
			distL.Text = math.floor((root.Position - humanoidRootPart.Position).Magnitude) .. "m"
		elseif distL then distL.Text = "" end
	end
end

-- FARM
local function getEnemy(mapOrName)
	local en = Workspace:FindFirstChild("Enemies")
	if not en or not humanoidRootPart then return nil end
	local best, bd = nil, math.huge
	for _, e in ipairs(en:GetChildren()) do
		if string.find(string.lower(e.Name), "shadow") then continue end
		local h, r = e:FindFirstChildOfClass("Humanoid"), e:FindFirstChild("HumanoidRootPart")
		if h and h.Health > 0 and r and r.Position.Y > -50 then
			local ok = type(mapOrName) == "string" and e.Name == mapOrName or type(mapOrName) == "table" and mapOrName[e.Name]
			if ok then
				local d = (r.Position - humanoidRootPart.Position).Magnitude
				if d < bd then bd, best = d, e end
			end
		end
	end
	return best
end

local function doFarmAttack(mob)
	if not mob then return end
	local root = mob:FindFirstChild("HumanoidRootPart")
	local hum = mob:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end
	local kind = farmWeaponKind()
	equipByKind(kind)
	local y = math.clamp(T.FarmDist or 20, 5, 30)
	local farmCF = CFrame.new(root.Position + Vector3.new(0, y, 0.5))
	if humanoidRootPart and (humanoidRootPart.Position - farmCF.Position).Magnitude > 8 then
		topos(farmCF, true, T.FarmTween)
	elseif humanoidRootPart then
		ensureBV()
		humanoidRootPart.CFrame = farmCF
	end
	attackWithKind(kind, mob, root)
	bringStep(mob)
end

local function hasQuest()
	local q = Player.PlayerGui:FindFirstChild("Main") and Player.PlayerGui.Main:FindFirstChild("Quest")
	return q and q.Visible
end
local function runQuestOnce()
	if not T.AutoQuest or T.FarmMode == "Level" then return false end
	if hasQuest() then T._QuestBusy = false return false end
	if T._QuestBusy then return true end
	T._QuestBusy = true
	task.spawn(function()
		local targetCF, args
		if T.FarmMode == "Bone" then
			targetCF, args = CF.BoneQuest, { "StartQuest", "HauntedQuest2", 1 }
		elseif T.FarmMode == "Katakuri" then
			targetCF, args = CF.CakeQuest, { "StartQuest", "CakeQuest2", 1 }
		else
			targetCF, args = CF.TyrantQuest, { "StartQuest", "TikiQuest2", 1 }
		end
		local tries = 0
		while T.AutoQuest and T.StartFarm and humanoidRootPart and tries < 40 do
			if (humanoidRootPart.Position - targetCF.Position).Magnitude <= 12 then break end
			topos(targetCF, false, T.FarmTween)
			task.wait(0.35)
			tries += 1
		end
		task.wait(0.25)
		pcall(function() CommF(unpack(args)) end)
		task.wait(0.5)
		T._QuestBusy = false
	end)
	return true
end

local lastVase = 0
local function DetectTree()
	local tiki = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("TikiOutpost")
	local arena = tiki and tiki:FindFirstChild("IslandModel") and tiki.IslandModel:FindFirstChild("EagleBossArena", true)
	if not arena or not humanoidRootPart then return nil end
	local nearest, nd = nil, 200
	for _, j in ipairs(arena:GetChildren()) do
		if j.Name == "Tree" and not j:GetAttribute("AlreadyDestroyedClient") then
			local p = j:GetPivot().Position
			local d = (p - humanoidRootPart.Position).Magnitude
			if d < nd then nd, nearest = d, j end
		end
	end
	return nearest
end
local function eyesOpen()
	local V = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("TikiOutpost")
		and Workspace.Map.TikiOutpost:FindFirstChild("IslandModel", true)
	if not V then return false end
	local a, b, c, d = V:FindFirstChild("Eye1", true), V:FindFirstChild("Eye2", true), V:FindFirstChild("Eye3", true), V:FindFirstChild("Eye4", true)
	return a and b and c and d and a.Transparency == 0 and b.Transparency == 0 and c.Transparency == 0 and d.Transparency == 0
end
local function vaseClick(tree)
	if tick() - lastVase < 0.6 then return end
	lastVase = tick()
	local tool = findTool(function(t) return t.Name == "Skull Guitar" end)
	if not tool then
		CommF("LoadItem", "Skull Guitar")
		task.wait(0.35)
		tool = findTool(function(t) return t.Name == "Skull Guitar" end)
	end
	if tool and humanoid and tool.Parent == Player.Backpack then
		pcall(function() humanoid:EquipTool(tool) end)
		task.wait(0.12)
	end
	tool = character and character:FindFirstChildOfClass("Tool")
	if tool then pcall(function() tool:Activate() end) end
	local size = Camera.ViewportSize
	pcall(function()
		VIM:SendTouchEvent(88, 0, size.X / 2, size.Y / 2)
		task.wait(0.02)
		VIM:SendTouchEvent(88, 2, size.X / 2, size.Y / 2)
	end)
	if tool and tool:FindFirstChild("RemoteEvent") and tree then
		pcall(function() tool.RemoteEvent:FireServer("TAP", tree:GetPivot().Position) end)
	end
end

local function farmStep()
	if not humanoidRootPart or T._QuestBusy then return end
	if T.AutoQuest and not hasQuest() then
		if runQuestOnce() then return end
	end
	if T.FarmMode == "Bone" then
		local m = getEnemy(BonesList)
		if m then doFarmAttack(m) else topos(CF.Bone, false, T.FarmTween) end
	elseif T.FarmMode == "Katakuri" then
		local prince = getEnemy("Cake Prince")
		if prince then
			if Player:GetAttribute("CurrentLocation") ~= "Dimensional Shift" then
				topos(CF.CakePortal, false, T.FarmTween)
				return
			end
			doFarmAttack(prince)
			return
		end
		local m = getEnemy(CakesList)
		if m then doFarmAttack(m) else topos(CF.Cake, false, T.FarmTween) end
	elseif T.FarmMode == "Level" then
		local m = getNearestMob()
		if m then doFarmAttack(m) end
	else
		local boss = getEnemy("Tyrant of the Skies")
		if boss then doFarmAttack(boss) return end
		if T.DestroyVases and eyesOpen() then
			local tree = DetectTree()
			if tree then
				local pivot = tree:GetPivot()
				if (humanoidRootPart.Position - pivot.Position).Magnitude > 14 then
					topos(pivot * CFrame.new(0, 3, 0), true, T.FarmTween)
				else
					ensureBV()
					humanoidRootPart.CFrame = pivot * CFrame.new(0, 3, 0)
					vaseClick(tree)
				end
				return
			end
		end
		local m = getEnemy(TyrantList)
		if m then doFarmAttack(m) else topos(CF.Tyrant, false, T.FarmTween) end
	end
end

-- DUNGEON
local function getDungeon()
	return (Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Dungeon")) or Workspace:FindFirstChild("Dungeon")
end
local function getDungeonRoom()
	local dungeon = getDungeon()
	if not dungeon or not humanoidRootPart then return nil, dungeon end
	local best, bestD = nil, math.huge
	for i = 1, 120 do
		local room = dungeon:FindFirstChild(tostring(i))
		if room then
			local ok, piv = pcall(function() return room:GetPivot().Position end)
			if ok and piv then
				local d = (Vector3.new(humanoidRootPart.Position.X, 0, humanoidRootPart.Position.Z) - Vector3.new(piv.X, 0, piv.Z)).Magnitude
				local ext = room:GetExtentsSize()
				if d < math.max(ext.X, ext.Z) / 2 + 350 and d < bestD then
					bestD, best = d, room
				end
			end
		end
	end
	return best, dungeon
end
local function getDungeonMobs(room)
	local en = Workspace:FindFirstChild("Enemies")
	if not en or not humanoidRootPart then return {} end
	local list, center, radius = {}, humanoidRootPart.Position, 450
	if room then
		local ok, piv = pcall(function() return room:GetPivot().Position end)
		if ok and piv then center = piv end
		local ext = room:GetExtentsSize()
		radius = math.max(ext.X, ext.Z) / 2 + 350
	end
	for _, e in ipairs(en:GetChildren()) do
		if string.find(string.lower(e.Name), "shadow") then continue end
		local h, r = e:FindFirstChildOfClass("Humanoid"), e:FindFirstChild("HumanoidRootPart")
		if h and h.Health > 0 and r and r.Position.Y > -50 then
			local d = (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude
			if d < radius then table.insert(list, e) end
		end
	end
	return list
end
local function DetectPropEvent()
	local dungeon = getDungeon()
	if not dungeon or not humanoidRootPart then return nil end
	local best, bd = nil, 500
	for _, inst in ipairs(dungeon:GetDescendants()) do
		local n = string.lower(inst.Name)
		if n:find("prophitbox") or n:find("hitboxplaceholder") or n:find("shrine") or n:find("vent") or n:find("totem") or n:find("crystal") then
			local part = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart", true)
			if part and part.Transparency < 1 then
				local d = (part.Position - humanoidRootPart.Position).Magnitude
				if d < bd then bd, best = d, part end
			end
		end
	end
	return best
end
local function useExitPortal(room)
	if room and room:FindFirstChild("ExitTeleporter") and room.ExitTeleporter:FindFirstChild("Root") then
		local root = room.ExitTeleporter.Root
		tpBypass(root.CFrame * CFrame.new(0, 3, 0))
		task.wait(0.2)
		if humanoidRootPart then
			pcall(function()
				firetouchinterest(humanoidRootPart, root, 0)
				task.wait(0.08)
				firetouchinterest(humanoidRootPart, root, 1)
			end)
		end
		return true
	end
	return false
end
local function stripFont(s)
	return tostring(s or ""):gsub("<[^>]+>", "")
end
local function AutoPickDungeonCard()
	local bestBtn, bestRank, allBtns = nil, math.huge, {}
	for _, Y in ipairs(Player.PlayerGui:GetChildren()) do
		local H = Y:FindFirstChild("DisplayName", true)
		local C = Y:FindFirstChild("BuffDescription", true)
		local J = Y:FindFirstChildWhichIsA("TextButton", true)
		if H and C and J and H:IsA("TextLabel") then
			local name = stripFont(H.Text)
			table.insert(allBtns, J)
			for i, pref in ipairs(CardPriority) do
				if name:lower():find(pref:lower(), 1, true) and i < bestRank then
					bestRank, bestBtn = i, J
				end
			end
		end
	end
	local btn = bestBtn or (#allBtns > 0 and allBtns[math.random(1, #allBtns)])
	if not btn then return end
	pcall(function()
		for _, c in pairs(getconnections(btn.Activated)) do
			if c.Function then c.Function() end
		end
	end)
	pcall(function()
		for _, c in pairs(getconnections(btn.MouseButton1Click)) do
			if c.Function then c.Function() end
		end
	end)
end
local function teleportDungeon()
	pcall(function()
		if Net and Net:FindFirstChild("RF/DungeonNPCNetworkFunction") then
			Net["RF/DungeonNPCNetworkFunction"]:InvokeServer("TeleportToDungeonHub", false)
		end
	end)
end

local function doDungeonAttack(mob)
	if not mob then return end
	local root = mob:FindFirstChild("HumanoidRootPart")
	local hum = mob:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end
	local kind = dungeonWeaponKind()
	equipByKind(kind)
	tpBypass(CFrame.new(root.Position + Vector3.new(0, 20, 0.5)))
	attackWithKind(kind, mob, root)
end

local function dungeonStep()
	if not humanoidRootPart then return end
	local room, dungeon = getDungeonRoom()
	if not dungeon then return end -- only farm inside, no auto enter

	if T.AutoCards then pcall(AutoPickDungeonCard) end

	if T.DestroyEvents then
		local prop = DetectPropEvent()
		if prop then
			tpBypass(prop.CFrame * CFrame.new(0, 5, 0))
			local kind = dungeonWeaponKind()
			equipByKind(kind)
			if kind == "Gun" then
				gunAttack(prop.Position)
			elseif kind == "Fruit" then
				fruitAttack()
			elseif kind == "Sword" then
				meleeSwordAttack("Sword", prop)
			else
				meleeSwordAttack("Melee", prop)
			end
			return
		end
	end

	local mobs = getDungeonMobs(room)
	if #mobs > 0 then
		local best, bd = mobs[1], math.huge
		for _, m in ipairs(mobs) do
			local r = m:FindFirstChild("HumanoidRootPart")
			if r then
				local d = (r.Position - humanoidRootPart.Position).Magnitude
				if d < bd then bd, best = d, m end
			end
		end
		doDungeonAttack(best)
		return
	end
	useExitPortal(room)
end

local function removeGhostShip()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		local n = string.lower(obj.Name)
		if n:find("ghost") and n:find("ship") then pcall(function() obj:Destroy() end) end
	end
end
local function removeLava()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		local n = string.lower(obj.Name)
		if n:find("lava") or n:find("magmalava") then
			if obj:IsA("BasePart") then
				pcall(function() obj.CanTouch = false obj.Transparency = 1 end)
			else
				pcall(function() obj:Destroy() end)
			end
		end
	end
end

local function applyNoFog()
	Lighting.FogEnd = 100000
	Lighting.FogStart = 100000
	for _, v in ipairs(Lighting:GetChildren()) do
		if v:IsA("Atmosphere") then pcall(function() v.Density = 0 end) end
	end
end
local function applyFPSBoost()
	pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 9e9
	for _, R in pairs(Workspace:GetDescendants()) do
		if R:IsA("ParticleEmitter") or R:IsA("Trail") then pcall(function() R.Enabled = false end) end
	end
end

-- LOOPS
task.spawn(function()
	while true do
		if T.StartFarm and not T.AutoDungeon then
			pcall(farmStep)
			task.wait(0.05)
		elseif T.AutoDungeon then
			pcall(dungeonStep)
			task.wait(0.05)
		else
			if not T.TPTween and not T.TPBypass and not T.TPNearest then stopTween() end
			task.wait(0.15)
		end
	end
end)

task.spawn(function()
	while true do
		local p = Players:FindFirstChild(T.SelectPlayer)
		local r = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if r then
			local cf = r.CFrame * CFrame.new(0, T.OffsetY or 3, 0)
			if T.TPTween then
				topos(cf, true, T.TweenSpeed)
			elseif T.TPBypass then
				tpBypass(cf)
			end
		end
		if T.TPNearest and humanoidRootPart then
			local best, bd = nil, math.huge
			for _, pl in ipairs(Players:GetPlayers()) do
				if pl ~= Player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
					local rr = pl.Character.HumanoidRootPart
					local d = (rr.Position - humanoidRootPart.Position).Magnitude
					if d < bd then bd, best = d, rr end
				end
			end
			if best then topos(best.CFrame * CFrame.new(0, T.OffsetY or 3, 0), true, T.TweenSpeed) end
		end
		task.wait(0.08)
	end
end)

task.spawn(function()
	while true do
		if T.Aura then pcall(auraStep) end
		task.wait(0.05)
	end
end)
task.spawn(function()
	while true do
		if T.Bring and not T.StartFarm then pcall(bringStep) end
		task.wait(0.2)
	end
end)
task.spawn(function()
	while true do
		pcall(updateESP)
		task.wait(0.25)
	end
end)
task.spawn(function()
	while true do
		if T.AutoCards and T.AutoDungeon then pcall(AutoPickDungeonCard) end
		task.wait(0.15)
	end
end)
task.spawn(function()
	while true do
		task.wait(0.4)
		if T.V3 then
			pcall(function()
				if Remotes and Remotes:FindFirstChild("CommE") then
					Remotes.CommE:FireServer("ActivateAbility")
				end
			end)
		end
		if T.V4 then
			pcall(function()
				if character and character:FindFirstChild("RaceEnergy") and character:FindFirstChild("RaceTransformed") then
					if character.RaceEnergy.Value >= 1 and not character.RaceTransformed.Value then
						local aw = Player.Backpack:FindFirstChild("Awakening")
						if aw and aw:FindFirstChild("RemoteFunction") then
							aw.RemoteFunction:InvokeServer({ true })
						end
					end
				end
			end)
		end
		if T.NoFog then applyNoFog() end
		if T.WalkSpeed and humanoid then humanoid.WalkSpeed = T.WalkSpeedVal end
		if T.JumpPower and humanoid then humanoid.JumpPower = T.JumpPowerVal end
		if T.NoClip and character then
			for _, p in ipairs(character:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end
		-- keep correct weapon equipped for active mode
		if T.AutoDungeon then
			equipByKind(dungeonWeaponKind())
		elseif T.StartFarm then
			equipByKind(farmWeaponKind())
		end
	end
end)

local viewConn
local function setView(on)
	T.ViewScreen = on
	if viewConn then viewConn:Disconnect() viewConn = nil end
	if not on then
		if Camera and humanoid then Camera.CameraSubject = humanoid end
		return
	end
	viewConn = RunService.RenderStepped:Connect(function()
		local p = Players:FindFirstChild(T.SelectPlayer)
		local hum = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hum and Camera then Camera.CameraSubject = hum end
	end)
end

Player.Idled:Connect(function()
	if T.AntiAFK then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end)

-- UI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({
	Title = "Toxic Hub",
	Icon = "swords",
	Author = "PVP",
	Folder = "ToxicHubPVP",
	Size = UDim2.fromOffset(520, 400),
	Transparent = true,
	Theme = "Dark",
	SideBarWidth = 130,
})

local TabTP = Window:Tab({ Title = "TP", Icon = "map" })
local TabMain = Window:Tab({ Title = "Main", Icon = "swords" })
local TabESP = Window:Tab({ Title = "ESP", Icon = "eye" })
local TabFarm = Window:Tab({ Title = "Farm", Icon = "target" })
local TabDungeon = Window:Tab({ Title = "Dungeon", Icon = "castle" })
local TabMisc = Window:Tab({ Title = "Misc", Icon = "settings" })

TabTP:Dropdown({ Title = "Players", Values = playerNames(), Value = playerNames()[1] or "", Callback = function(v) T.SelectPlayer = v end })
TabTP:Toggle({ Title = "TP Tween", Value = T.TPTween, Callback = function(v) T.TPTween = v if v then T.TPBypass = false end end })
TabTP:Toggle({ Title = "TP Bypass", Value = T.TPBypass, Callback = function(v) T.TPBypass = v if v then T.TPTween = false end end })
TabTP:Toggle({ Title = "TP Nearest", Value = T.TPNearest, Callback = function(v) T.TPNearest = v end })
TabTP:Toggle({ Title = "View Screen", Value = T.ViewScreen, Callback = function(v) setView(v) end })
TabTP:Button({ Title = "Remove Ghost Ship", Callback = function() removeGhostShip() WindUI:Notify({ Title = "Toxic Hub", Content = "Ghost Ship removed", Duration = 2 }) end })
TabTP:Button({ Title = "Remove Lava", Callback = function() removeLava() WindUI:Notify({ Title = "Toxic Hub", Content = "Lava removed", Duration = 2 }) end })

TabMain:Toggle({ Title = "Aura", Value = T.Aura, Callback = function(v) T.Aura = v end })
TabMain:Slider({ Title = "Aura Range", Value = { Min = 5, Max = 80, Default = T.AuraRange }, Callback = function(v) T.AuraRange = v end })
TabMain:Toggle({ Title = "Aura Players", Value = T.AuraPlayers, Callback = function(v) T.AuraPlayers = v end })
TabMain:Toggle({ Title = "Aura Mobs", Value = T.AuraMobs, Callback = function(v) T.AuraMobs = v end })
TabMain:Toggle({ Title = "Fast Attack", Value = T.FA, Callback = function(v) T.FA = v end })
TabMain:Toggle({ Title = "Fruit", Value = T.Fruit, Callback = function(v) T.Fruit = v end })
TabMain:Toggle({ Title = "Gun", Value = T.Gun, Callback = function(v) T.Gun = v end })
TabMain:Toggle({ Title = "Bring Mob", Value = T.Bring, Callback = function(v) T.Bring = v end })
TabMain:Slider({ Title = "Bring Range", Value = { Min = 50, Max = 400, Default = T.BringRange }, Callback = function(v) T.BringRange = v end })

TabESP:Toggle({ Title = "ESP", Value = T.ESP, Callback = function(v) T.ESP = v if not v then clearESP() end end })
TabESP:Toggle({ Title = "ESP Name", Value = T.ESPName, Callback = function(v) T.ESPName = v end })
TabESP:Toggle({ Title = "ESP HP", Value = T.ESPHP, Callback = function(v) T.ESPHP = v end })
TabESP:Toggle({ Title = "ESP Box", Value = T.ESPBox, Callback = function(v) T.ESPBox = v end })
TabESP:Toggle({ Title = "ESP Distance", Value = T.ESPDist, Callback = function(v) T.ESPDist = v end })

-- FARM weapon (independent)
TabFarm:Dropdown({
	Title = "Farm",
	Values = { "Tyrant", "Bone", "Katakuri", "Level" },
	Value = T.FarmMode,
	Callback = function(v) T.FarmMode = v T._QuestBusy = false end,
})
TabFarm:Toggle({
	Title = "Start Farm",
	Value = T.StartFarm,
	Callback = function(v)
		T.StartFarm = v
		if v then
			T.AutoDungeon = false
			equipByKind(farmWeaponKind())
		else
			stopTween()
		end
	end,
})
TabFarm:Toggle({ Title = "Auto Quest", Value = T.AutoQuest, Callback = function(v) T.AutoQuest = v end })
TabFarm:Toggle({ Title = "Auto Destroy Vases", Value = T.DestroyVases, Callback = function(v) T.DestroyVases = v end })
TabFarm:Dropdown({
	Title = "Weapon",
	Values = { "Melee", "Sword", "Fruit", "Gun" },
	Value = T.Weapon,
	Callback = function(v)
		T.Weapon = v
		if T.StartFarm and not T.AutoDungeon then equipByKind(v) end
	end,
})
TabFarm:Slider({ Title = "Farm Distance", Value = { Min = 5, Max = 30, Default = T.FarmDist }, Callback = function(v) T.FarmDist = v end })
TabFarm:Slider({ Title = "Tween Speed", Value = { Min = 50, Max = 300, Default = T.FarmTween }, Callback = function(v) T.FarmTween = v end })
TabFarm:Toggle({ Title = "Auto V3", Value = T.V3, Callback = function(v) T.V3 = v end })
TabFarm:Toggle({ Title = "Auto V4", Value = T.V4, Callback = function(v) T.V4 = v end })

-- DUNGEON weapon (independent)
TabDungeon:Dropdown({
	Title = "Weapon",
	Values = { "Melee", "Sword", "Fruit", "Gun" },
	Value = T.DungeonWeapon,
	Callback = function(v)
		T.DungeonWeapon = v
		if T.AutoDungeon then equipByKind(v) end
	end,
})
TabDungeon:Toggle({
	Title = "Auto Dungeon",
	Value = T.AutoDungeon,
	Callback = function(v)
		T.AutoDungeon = v
		if v then
			T.StartFarm = false
			stopTween()
			equipByKind(dungeonWeaponKind())
		end
	end,
})
TabDungeon:Toggle({ Title = "Auto Destroy Events", Value = T.DestroyEvents, Callback = function(v) T.DestroyEvents = v end })
TabDungeon:Toggle({ Title = "Auto Cards", Value = T.AutoCards, Callback = function(v) T.AutoCards = v end })
TabDungeon:Button({
	Title = "Teleport Dungeon",
	Callback = function()
		teleportDungeon()
		WindUI:Notify({ Title = "Toxic Hub", Content = "Teleport Dungeon", Duration = 2 })
	end,
})

TabMisc:Toggle({ Title = "No Fog", Value = T.NoFog, Callback = function(v) T.NoFog = v if v then applyNoFog() end end })
TabMisc:Toggle({ Title = "FPS Boost", Value = T.FPSBoost, Callback = function(v) T.FPSBoost = v if v then applyFPSBoost() end end })
TabMisc:Toggle({ Title = "Walk Speed", Value = T.WalkSpeed, Callback = function(v) T.WalkSpeed = v end })
TabMisc:Slider({ Title = "Walk Speed Value", Value = { Min = 16, Max = 200, Default = T.WalkSpeedVal }, Callback = function(v) T.WalkSpeedVal = v end })
TabMisc:Toggle({ Title = "Jump Power", Value = T.JumpPower, Callback = function(v) T.JumpPower = v end })
TabMisc:Slider({ Title = "Jump Power Value", Value = { Min = 50, Max = 200, Default = T.JumpPowerVal }, Callback = function(v) T.JumpPowerVal = v end })
TabMisc:Toggle({ Title = "No Clip", Value = T.NoClip, Callback = function(v) T.NoClip = v end })
TabMisc:Toggle({ Title = "Anti AFK", Value = T.AntiAFK, Callback = function(v) T.AntiAFK = v end })

WindUI:Notify({ Title = "Toxic Hub", Content = "Loaded — Farm/Dungeon weapons separated", Duration = 3 })
print("[Toxic Hub] Farm Weapon =", T.Weapon, "| Dungeon Weapon =", T.DungeonWeapon)
