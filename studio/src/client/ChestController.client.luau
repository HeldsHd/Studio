--!strict
-- Apenas apresentação; propriedade e compras são validadas pelo ChestService.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local bases = workspace:WaitForChild("Bases")

type Entry = { connections: { RBXScriptConnection }, originalEnabled: boolean }
local entries: { [Instance]: Entry } = {}
local connections: { RBXScriptConnection } = {}

local function update(instance: Instance)
	if not entries[instance] then return end
	if not instance:IsA("ProximityPrompt") and not instance:IsA("BillboardGui") then return end
	local isPrompt = instance:IsA("ProximityPrompt")
	local flag = if isPrompt then "IsChestPrompt" else "IsChestLabel"
	local ownsBase = instance:GetAttribute(flag) == true
		and player:GetAttribute("BaseStatus") == "Assigned"
		and typeof(instance:GetAttribute("BaseName")) == "string"
		and player:GetAttribute("BaseName") == instance:GetAttribute("BaseName")
	local enabled = ownsBase and (not isPrompt or instance:GetAttribute("ActionAvailable") == true)
	if instance.Enabled ~= enabled then instance.Enabled = enabled end
end

local function unregister(instance: Instance)
	local entry = entries[instance]
	if not entry then return end
	entries[instance] = nil
	for _, connection in ipairs(entry.connections) do connection:Disconnect() end
	if instance:IsA("ProximityPrompt") or instance:IsA("BillboardGui") then
		instance.Enabled = entry.originalEnabled
	end
end

local function register(instance: Instance)
	if entries[instance] then return end
	if not ((instance:IsA("ProximityPrompt") and (instance.Name == "BuyChest"
		or instance.Name:match("^UpgradeChest_") ~= nil))
		or (instance:IsA("BillboardGui") and instance.Name == "ChestLabel")) then return end
	local entry: Entry = { connections = {}, originalEnabled = instance.Enabled }
	entries[instance] = entry
	local flag = if instance:IsA("ProximityPrompt") then "IsChestPrompt" else "IsChestLabel"
	for _, attribute in ipairs({ flag, "BaseName", "ActionAvailable" }) do
		table.insert(entry.connections, instance:GetAttributeChangedSignal(attribute):Connect(function()
			update(instance)
		end))
	end
	-- Também corrige uma atualização de Enabled recebida depois dos atributos.
	table.insert(entry.connections, instance:GetPropertyChangedSignal("Enabled"):Connect(function()
		update(instance)
	end))
	update(instance)
end

local function refresh()
	for instance in pairs(entries) do update(instance) end
end
table.insert(connections, bases.DescendantAdded:Connect(register))
table.insert(connections, bases.DescendantRemoving:Connect(unregister))
table.insert(connections, player:GetAttributeChangedSignal("BaseName"):Connect(refresh))
table.insert(connections, player:GetAttributeChangedSignal("BaseStatus"):Connect(refresh))
for _, instance in ipairs(bases:GetDescendants()) do register(instance) end
script.Destroying:Connect(function()
	for _, connection in ipairs(connections) do connection:Disconnect() end
	for instance in pairs(entries) do unregister(instance) end
end)
