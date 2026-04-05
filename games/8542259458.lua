if _G.SkullV4Loaded then return end
_G.SkullV4Loaded = true

local VapeLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/59Codings/VapeLib/refs/heads/main/VapeLib.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local inputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local ui = VapeLib:CreateWindow({
	Name = "Skull V4",
	Keybind = Enum.KeyCode.RightShift
})

local combat = ui:CreateCategory({Name = "Combat", Icon = "rbxassetid://14368306745"})
local utility = ui:CreateCategory({Name = "Utility", Icon = "rbxassetid://14368306745"})
local blatant = ui:CreateCategory({Name = "Blatant", Icon = "rbxassetid://14368306745"})
local movement = ui:CreateCategory({Name = "Movement", Icon = "rbxassetid://14368306745"})

local char, hum, root
local function refresh()
	char = lp.Character or lp.CharacterAdded:Wait()
	hum = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
end
refresh()
lp.CharacterAdded:Connect(refresh)

local speedState = {enabled=false,speed=23,useWS=false,heat=false,phase=1,timer=0}
local heat = {boostSpeed=40,normalSpeed=18,boostTime=0.6,normalTime=0.6}
local speedMod = movement:CreateModule({Name="Speed",Function=function(v) speedState.enabled=v speedState.phase=1 speedState.timer=0 end})
speedMod:CreateSlider({Name="Speed",Min=1,Max=100,Default=23,Function=function(v) speedState.speed=v end})
speedMod:CreateToggle({Name="WalkSpeed",Default=false,Function=function(v) speedState.useWS=v end})
speedMod:CreateToggle({Name="Heatseeker",Default=false,Function=function(v) speedState.heat=v speedState.phase=1 speedState.timer=0 end})

RunService.RenderStepped:Connect(function(dt)
	if not speedState.enabled or not char then return end
	if speedState.useWS then hum.WalkSpeed = speedState.speed return end
	local move = hum.MoveDirection
	if move.Magnitude==0 then return end
	local spd = speedState.speed
	if speedState.heat then
		speedState.timer += dt
		local duration = (speedState.phase==1 and heat.boostTime or heat.normalTime)
		if speedState.timer >= duration then speedState.timer=0 speedState.phase=(speedState.phase==1 and 2 or 1) end
		spd=(speedState.phase==1 and heat.boostSpeed or heat.normalSpeed)
	end
	root.AssemblyLinearVelocity = Vector3.new(move.X*spd,root.AssemblyLinearVelocity.Y,move.Z*spd)
end)

local fastFlySettings = {Distance=50,Speed=200,StopOnWall=false,Noclip=true,FlyUpDown=false,AutoToggleOff=true}
local fastFlyConn
local fastFly = movement:CreateModule({
	Name="FastFly",
	Function=function(toggle, api)
		if toggle then
			if not root or not hum then return end
			local origin = root.Position
			local dir = root.CFrame.LookVector * fastFlySettings.Distance
			local params = RaycastParams.new()
			params.FilterDescendantsInstances = {lp.Character}
			params.FilterType = Enum.RaycastFilterType.Blacklist
			local result = not fastFlySettings.Noclip and Workspace:Raycast(origin,dir,params) or nil
			local targetPos = result and (result.Position + Vector3.new(0,3,0)) or (origin + dir)
			if result and fastFlySettings.StopOnWall then api:Toggle(false) return end
			local currentTime, duration = 0, (targetPos - origin).Magnitude / fastFlySettings.Speed
			local yOffset = 0
			fastFlyConn = RunService.RenderStepped:Connect(function(dt)
				if currentTime >= duration then
					root.CFrame = CFrame.new(targetPos + Vector3.new(0, yOffset, 0), targetPos + root.CFrame.LookVector)
					if flyPos then flyPos = root.Position end
					if fastFlyConn then fastFlyConn:Disconnect() fastFlyConn = nil end
					if fastFlySettings.AutoToggleOff then
						task.spawn(function()
							while hum and hum.Parent and hum.FloorMaterial == Enum.Material.Air do task.wait() end
							api:Toggle(false)
						end)
					end
					return
				end
				if fastFlySettings.FlyUpDown then
					if inputService:IsKeyDown(Enum.KeyCode.Space) then yOffset += 50 * dt end
					if inputService:IsKeyDown(Enum.KeyCode.LeftShift) then yOffset -= 50 * dt end
				end
				currentTime += dt
				local newPos = origin:Lerp(targetPos, math.clamp(currentTime/duration,0,1)) + Vector3.new(0, yOffset, 0)
				root.CFrame = CFrame.new(newPos, newPos + root.CFrame.LookVector)
				if flyPos then flyPos = root.Position end
			end)
		else
			if fastFlyConn then fastFlyConn:Disconnect() fastFlyConn = nil end
			if root then root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
		end
	end
})
fastFly:CreateSlider({Name="Fly Distance",Min=10,Max=300,Default=50,Function=function(v) fastFlySettings.Distance=v end})
fastFly:CreateSlider({Name="Fly Speed",Min=50,Max=500,Default=200,Function=function(v) fastFlySettings.Speed=v end})
fastFly:CreateToggle({Name="Noclip",Default=true,Function=function(v) fastFlySettings.Noclip=v end})

local flySettings = {HSpeed=50,VSpeed=50,Method="CFrame",Up=Enum.KeyCode.Z,Down=Enum.KeyCode.X}
local normalFlyConn, flyPos
local flyMod = movement:CreateModule({
	Name = "Fly",
	Function = function(toggle)
		if toggle then
			if not root then return end
			flyPos = root.Position
			normalFlyConn = RunService.RenderStepped:Connect(function(dt)
				if not root or not hum then return end
				if fastFlyConn or (auraEnabled and auraSettings.Strafe and hum.MoveDirection.Magnitude == 0) then return end
				local moveDir = hum.MoveDirection
				local vel = Vector3.new(0, 0, 0)
				if inputService:IsKeyDown(flySettings.Up) then vel = vel + Vector3.new(0, 1, 0) end
				if inputService:IsKeyDown(flySettings.Down) then vel = vel - Vector3.new(0, 1, 0) end
				
				if flySettings.Method == "CFrame" then
					root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					local hVel = moveDir * flySettings.HSpeed * dt
					local vVel = vel * flySettings.VSpeed * dt
					flyPos = flyPos + hVel + vVel
					root.CFrame = CFrame.new(flyPos, flyPos + Workspace.CurrentCamera.CFrame.LookVector)
				elseif flySettings.Method == "Velocity" then
					local hVel = moveDir * flySettings.HSpeed
					local vVel = vel * flySettings.VSpeed
					root.AssemblyLinearVelocity = hVel + vVel + Vector3.new(0, (vel.Y == 0 and 0.5 or 0), 0)
				end
			end)
		else
			if normalFlyConn then normalFlyConn:Disconnect() normalFlyConn = nil end
			if root then root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
		end
	end
})
flyMod:CreateSlider({Name="Horizontal Speed",Min=1,Max=100,Default=50,Function=function(v) flySettings.HSpeed=v end})
flyMod:CreateSlider({Name="Vertical Speed",Min=1,Max=100,Default=50,Function=function(v) flySettings.VSpeed=v end})
flyMod:CreateDropdown({Name="Method",List={"CFrame","Velocity"},Default="CFrame",Function=function(v) flySettings.Method=v end})

local auraSettings = {Range=30,SwingRange=30,TeamCheck=true,HitTime=0.25,Combos=true,SyncHitTime=true,AirHitChance=0.4,SwingAnimation=true,MouseDown=false,FaceTarget=false,TargetPriority="Distance",Strafe=false,StrafeSpeed=10,StrafeDistance=5}
local auraRemote = game:GetService("ReplicatedStorage"):WaitForChild("Kw8"):WaitForChild("93b2718b-2b2a-4859-b36e-fd4614c7f0c9")
local auraAnims = {"rbxassetid://8542350607","rbxassetid://8542350607","rbxassetid://8542350607"}
local auraCombo, auraLastSwing, strafeAngle, auraEnabled = 1, 0, 0, false
local lastSafePos = Vector3.new(0, 0, 0)

RunService.Heartbeat:Connect(function()
	if root and hum and hum.FloorMaterial ~= Enum.Material.Air then
		lastSafePos = root.Position
	end
end)

local function getTarget()
	local myRoot = root
	if not myRoot then return nil end
	local target, bestVal = nil, (auraSettings.TargetPriority == "Distance" and auraSettings.Range or 999999)
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= lp then
			local char = plr.Character
			local pRoot = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if pRoot and hum and hum.Health > 0 then
				local dist = (myRoot.Position - pRoot.Position).Magnitude
				if dist < auraSettings.Range then
					if auraSettings.TeamCheck and plr:GetAttribute("TeamId") == lp:GetAttribute("TeamId") then continue end
					if hum.FloorMaterial == Enum.Material.Air and math.random() > auraSettings.AirHitChance then continue end
					
					if auraSettings.TargetPriority == "Distance" then
						if dist < bestVal then bestVal, target = dist, plr end
					elseif auraSettings.TargetPriority == "Health" then
						if hum.Health < bestVal then bestVal, target = hum.Health, plr end
					end
				end
			end
		end
	end
	return target
end

local function playSwing()
	if not hum or not auraSettings.SwingAnimation then return end
	local anim = Instance.new("Animation")
	anim.AnimationId = auraAnims[auraCombo]
	local track = hum:LoadAnimation(anim)
	track:Play()
	if auraSettings.Combos then auraCombo = (auraCombo % #auraAnims) + 1 end
	return track
end

local auraMod = blatant:CreateModule({
	Name = "KillAura",
	Function = function(toggle)
		auraEnabled = toggle
		if toggle then
			task.spawn(function()
				while auraEnabled do
					local dt = task.wait()
					if auraSettings.MouseDown and not inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then continue end
					local target = getTarget()
					if not target or not root then continue end
					local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
					if not tRoot or (root.Position - tRoot.Position).Magnitude > auraSettings.SwingRange then continue end
					
					if auraSettings.FaceTarget then
						root.CFrame = CFrame.new(root.Position, Vector3.new(tRoot.Position.X, root.Position.Y, tRoot.Position.Z))
					end
					
					if auraSettings.Strafe and hum.MoveDirection.Magnitude == 0 then
						if (lastSafePos.Y - tRoot.Position.Y) > 16 then
							root.CFrame = CFrame.new(lastSafePos + Vector3.new(0, 3, 0))
						else
							strafeAngle = (strafeAngle + (dt * auraSettings.StrafeSpeed)) % (math.pi * 2)
							local offset = Vector3.new(math.cos(strafeAngle) * auraSettings.StrafeDistance, 0, math.sin(strafeAngle) * auraSettings.StrafeDistance)
							root.CFrame = CFrame.new(tRoot.Position + offset, Vector3.new(tRoot.Position.X, root.Position.Y, tRoot.Position.Z))
						end
						if flyPos then flyPos = root.Position end
					end

					if tick() - auraLastSwing >= auraSettings.HitTime then
						auraLastSwing = tick()
						local track = playSwing()
						if auraSettings.SyncHitTime and track then
							task.delay(track.Length * 0.5, function() auraRemote:FireServer(target) end)
						else
							auraRemote:FireServer(target)
						end
					end
				end
			end)
		else
			if root then root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
		end
	end
})

auraMod:CreateSlider({Name="Range",Min=1,Max=50,Default=30,Function=function(v) auraSettings.Range=v end})
auraMod:CreateSlider({Name="Swing Range",Min=1,Max=50,Default=30,Function=function(v) auraSettings.SwingRange=v end})
auraMod:CreateSlider({Name="Hit Time",Min=1,Max=250,Default=25,Function=function(v) auraSettings.HitTime=v/100 end})
auraMod:CreateSlider({Name="Air Hit Chance",Min=0,Max=10,Default=4,Function=function(v) auraSettings.AirHitChance=v/10 end})
auraMod:CreateDropdown({Name="Target Mode",List={"Distance","Health"},Default="Distance",Function=function(v) auraSettings.TargetPriority=v end})
auraMod:CreateToggle({Name="Strafe",Default=false,Function=function(v) auraSettings.Strafe=v end})
auraMod:CreateSlider({Name="Strafe Distance",Min=1,Max=15,Default=5,Function=function(v) auraSettings.StrafeDistance=v end})
auraMod:CreateSlider({Name="Strafe Speed",Min=1,Max=20,Default=10,Function=function(v) auraSettings.StrafeSpeed=v end})
auraMod:CreateToggle({Name="Require Mouse Down",Default=false,Function=function(v) auraSettings.MouseDown=v end})
auraMod:CreateToggle({Name="Face Target",Default=false,Function=function(v) auraSettings.FaceTarget=v end})
auraMod:CreateToggle({Name="Team Check",Default=true,Function=function(v) auraSettings.TeamCheck=v end})
auraMod:CreateToggle({Name="Combos",Default=true,Function=function(v) auraSettings.Combos=v end})
auraMod:CreateToggle({Name="Sync Hit Time",Default=true,Function=function(v) auraSettings.SyncHitTime=v end})
auraMod:CreateToggle({Name="Swing Animation",Default=true,Function=function(v) auraSettings.SwingAnimation=v end})

local nukeSettings = {Range=30,Delay=0.1}
local entityRemote = game:GetService("ReplicatedStorage"):WaitForChild("Kw8"):WaitForChild("f32c9bc1-cb4b-4616-96ac-bddaefd35e92")
local nukeMod = blatant:CreateModule({
	Name = "Nuker",
	Function = function(toggle)
		if toggle then
			task.spawn(function()
				while toggle and task.wait(nukeSettings.Delay) do
					local eggs = Workspace:FindFirstChild("Eggs")
					if not eggs or not root then continue end
					for _, egg in pairs(eggs:GetChildren()) do
						if egg.Name == "Egg" and egg:IsA("Model") and egg.PrimaryPart then
							local dist = (root.Position - egg.PrimaryPart.Position).Magnitude
							if dist < nukeSettings.Range then
								local eTeam = egg:GetAttribute("TeamId")
								local eHealth = egg:GetAttribute("Health") or 100
								if eTeam ~= lp:GetAttribute("TeamId") and eHealth > 0 then
									entityRemote:FireServer(egg)
								end
							end
						end
					end
				end
			end)
		end
	end
})
nukeMod:CreateSlider({Name="Range",Min=1,Max=50,Default=30,Function=function(v) nukeSettings.Range=v end})
nukeMod:CreateSlider({Name="Nuke Speed",Min=1,Max=100,Default=10,Function=function(v) nukeSettings.Delay=v/100 end})

local antiVoidEnabled = false
local antiVoidMod = utility:CreateModule({
	Name = "AntiVoid",
	Function = function(toggle)
		antiVoidEnabled = toggle
		if toggle then
			task.spawn(function()
				local params = RaycastParams.new()
				params.FilterDescendantsInstances = {lp.Character}
				params.FilterType = Enum.RaycastFilterType.Blacklist
				while antiVoidEnabled and task.wait() do
					if root then
						local ray = Workspace:Raycast(root.Position, Vector3.new(0, -50, 0), params)
						if not ray and (lastSafePos.Y - root.Position.Y) > 16 then
							root.CFrame = CFrame.new(lastSafePos + Vector3.new(0, 3, 0))
							if flyPos then flyPos = root.Position end
							root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						end
					end
				end
			end)
		end
	end
})

local autoWinEnabled, autoWinSettings = false, {Speed=10,Distance=5,Height=3}
local autoWinMod = utility:CreateModule({
	Name = "AutoWin",
	Function = function(toggle)
		autoWinEnabled = toggle
		if toggle then
			task.spawn(function()
				local lastHealth, lastChange, lastEggSeen = 0, tick(), tick()
				while autoWinEnabled and task.wait() do
					local eggs = Workspace:FindFirstChild("Eggs")
					local targetEgg = nil
					if eggs then
						local available = {}
						for _, egg in pairs(eggs:GetChildren()) do
							if egg.Name == "Egg" and egg:IsA("Model") and egg.PrimaryPart then
								local eTeam = egg:GetAttribute("TeamId")
								local eHealth = egg:GetAttribute("Health") or 100
								if eTeam ~= lp:GetAttribute("TeamId") and eHealth > 0 then
									table.insert(available, egg)
								end
							end
						end
						if #available > 0 then
							targetEgg = available[1]
							lastEggSeen = tick()
							local curHealth = targetEgg:GetAttribute("Health") or 100
							if curHealth ~= lastHealth then
								lastHealth, lastChange = curHealth, tick()
							end
							if tick() - lastChange > 5 then
								table.remove(available, 1)
								targetEgg = available[1] or targetEgg
								lastChange = tick()
							end
						end
					end

					if targetEgg then
						root.CFrame = CFrame.new(targetEgg.PrimaryPart.Position - Vector3.new(0, 5, 0))
						if flyPos then flyPos = root.Position end
						entityRemote:FireServer(targetEgg)
					elseif tick() - lastEggSeen > 5 then
						local target = nil
						for _, plr in pairs(Players:GetPlayers()) do
							if plr ~= lp and plr.Character and plr:GetAttribute("TeamId") ~= lp:GetAttribute("TeamId") then
								local hum = plr.Character:FindFirstChildOfClass("Humanoid")
								if hum and hum.Health > 0 then
									local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
									if tRoot then
										if (lastSafePos.Y - tRoot.Position.Y) < 16 then
											target = plr break
										end
									end
								end
							end
						end
						if target and root then
							local tChar = target.Character
							local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
							local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
							if tRoot and tHum and tHum.Health > 0 then
								root.CFrame = CFrame.new(tRoot.Position + Vector3.new(math.cos(tick()*autoWinSettings.Speed)*autoWinSettings.Distance, autoWinSettings.Height, math.sin(tick()*autoWinSettings.Speed)*autoWinSettings.Distance), tRoot.Position)
								if flyPos then flyPos = root.Position end
								auraRemote:FireServer(target)
							end
						end
					end
				end
			end)
		end
	end
})
autoWinMod:CreateSlider({Name="AutoWin Speed",Min=1,Max=20,Default=10,Function=function(v) autoWinSettings.Speed=v end})
autoWinMod:CreateSlider({Name="AutoWin Distance",Min=1,Max=15,Default=5,Function=function(v) autoWinSettings.Distance=v end})
autoWinMod:CreateSlider({Name="AutoWin Height",Min=1,Max=10,Default=3,Function=function(v) autoWinSettings.Height=v end})

local qot = (queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport))
local teleportCheck = false
lp.OnTeleport:Connect(function(State)
	if not teleportCheck and qot then
		teleportCheck = true
		qot('loadstring(game:HttpGet("https://raw.githubusercontent.com/59Codings/SkullV4/main/games/8542259458.lua"))()')
	end
end)

ui:Notify({Title="Script Loaded",Description="Press Right Shift to toggle UI",Duration=5})
