--!strict
-- Notificações compartilhadas pelas compras de chaves e baús.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")


local gui = Instance.new("ScreenGui")
gui.Name = "PurchaseNotifications"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local panel = Instance.new("Frame")
panel.Name = "Toast"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 140)
panel.Size = UDim2.new(1, -24, 0, 64)
panel.BorderSizePixel = 0
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.Parent = gui

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(340, 64)
sizeLimit.Parent = panel
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Transparency = 0.3
stroke.Parent = panel

local label = Instance.new("TextLabel")
label.Name = "Message"
label.Position = UDim2.fromOffset(12, 8)
label.Size = UDim2.new(1, -24, 1, -16)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamMedium
label.TextSize = 16
label.TextColor3 = Color3.fromRGB(250, 250, 255)
label.TextWrapped = true
label.RichText = false
label.Text = ""
label.Parent = panel

local messageVersion = 0
local function showResult(success: boolean, message: string)
	if typeof(success) ~= "boolean" or typeof(message) ~= "string" then return end
	messageVersion += 1
	local version = messageVersion
	panel.BackgroundColor3 = if success then Color3.fromRGB(25, 68, 49) else Color3.fromRGB(87, 32, 39)
	stroke.Color = if success then Color3.fromRGB(90, 214, 147) else Color3.fromRGB(245, 111, 123)
	label.Text = message
	panel.Visible = true
	task.delay(3, function()
		if messageVersion == version and gui.Parent then panel.Visible = false end
	end)
end

local connections: { RBXScriptConnection } = {}
local destroyed = false
gui.Destroying:Connect(function()
	destroyed = true
	messageVersion += 1
	for _, connection in ipairs(connections) do connection:Disconnect() end
end)
gui.Parent = playerGui
for _, name in ipairs({ "ConveyorPurchaseResult", "ChestPurchaseResult" }) do
	task.spawn(function()
		local event = remotes:WaitForChild(name)
		if destroyed then return end
		assert(event:IsA("RemoteEvent"), name .. " deve ser RemoteEvent")
		table.insert(connections, event.OnClientEvent:Connect(showResult))
	end)
end
