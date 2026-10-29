--!strict
-- Oculta interações de bases alheias. A autorização real continua no servidor.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local bases = workspace:WaitForChild("Bases")
local prompts: { [ProximityPrompt]: boolean } = {}

local function update(prompt: ProximityPrompt)
	prompt.Enabled = player:GetAttribute("BaseStatus") == "Assigned"
		and player:GetAttribute("BaseName") == prompt:GetAttribute("BaseName")
end

local function register(instance: Instance)
	if instance:IsA("ProximityPrompt") and instance:GetAttribute("IsSlotPrompt") then
		prompts[instance] = true
		update(instance)
	end
end

bases.DescendantAdded:Connect(register)
bases.DescendantRemoving:Connect(function(instance)
	if instance:IsA("ProximityPrompt") then prompts[instance] = nil end
end)
for _, instance in ipairs(bases:GetDescendants()) do register(instance) end
local function refresh()
	for prompt in pairs(prompts) do update(prompt) end
end
player:GetAttributeChangedSignal("BaseName"):Connect(refresh)
player:GetAttributeChangedSignal("BaseStatus"):Connect(refresh)
