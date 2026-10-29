--!strict
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "EconomyHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local panel = Instance.new("Frame")
panel.Name = "Balance"
panel.Position = UDim2.fromOffset(12, 12)
panel.Size = UDim2.new(1, -24, 0, 112)
panel.BackgroundColor3 = Color3.fromRGB(22, 26, 35)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = gui

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(224, 112)
sizeLimit.Parent = panel

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 91, 109)
stroke.Transparency = 0.45
stroke.Thickness = 1
stroke.Parent = panel

local function makeLabel(
	name: string,
	y: number,
	height: number,
	textSize: number,
	color: Color3,
	font: Enum.Font
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = UDim2.fromOffset(12, y)
	label.Size = UDim2.new(1, -24, 0, height)
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = ""
	label.Parent = panel
	return label
end

local title = makeLabel(
	"Title", 9, 14, 11,
	Color3.fromRGB(181, 191, 208), Enum.Font.GothamMedium
)
title.Text = "DINHEIRO"

local moneyLabel = makeLabel(
	"Money", 26, 26, 22,
	Color3.fromRGB(248, 250, 255), Enum.Font.GothamBold
)

local incomeLabel = makeLabel(
	"Income", 58, 18, 13,
	Color3.fromRGB(138, 230, 170), Enum.Font.GothamMedium
)

local pendingLabel = makeLabel(
	"Pending", 82, 18, 13,
	Color3.fromRGB(255, 216, 128), Enum.Font.GothamMedium
)

local function readNumber(attribute: string): number
	local value = player:GetAttribute(attribute)
	if typeof(value) ~= "number"
		or value ~= value
		or value == math.huge
		or value == -math.huge
	then
		return 0
	end
	return math.max(0, value)
end

local function formatAmount(value: number): string
	local divisor = 1
	local suffix = ""
	if value >= 1e12 then
		divisor, suffix = 1e12, " tri"
	elseif value >= 1e9 then
		divisor, suffix = 1e9, " bi"
	elseif value >= 1e6 then
		divisor, suffix = 1e6, " mi"
	elseif value >= 1e3 then
		divisor, suffix = 1e3, " mil"
	end

	local text = string.format("%.2f", value / divisor)
	text = text:gsub("0+$", ""):gsub("%.$", ""):gsub("%.", ",")
	return text .. suffix
end

local function refresh()
	moneyLabel.Text = "$ " .. formatAmount(readNumber("Money"))
	incomeLabel.Text = "Produção: $ " .. formatAmount(readNumber("IncomePerSecond")) .. "/s"
	pendingLabel.Text = "A coletar: $ " .. formatAmount(readNumber("PendingMoney"))
end

local moneyConnection = player:GetAttributeChangedSignal("Money"):Connect(refresh)
local incomeConnection = player:GetAttributeChangedSignal("IncomePerSecond"):Connect(refresh)

local pendingConnection = player:GetAttributeChangedSignal("PendingMoney"):Connect(refresh)

gui.Destroying:Connect(function()
	moneyConnection:Disconnect()
	incomeConnection:Disconnect()
	pendingConnection:Disconnect()
end)

refresh()
gui.Parent = playerGui
