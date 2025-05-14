-- tppos 18, -10, -1971

if not game:IsLoaded() then game.Loaded:Wait() end

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")

-- Player and Game References
local plr = Players.LocalPlayer
local Twist = Workspace.Workplaces.Twist
local Remote = ReplicatedStorage.Remote.RestaurantJob

-- Configuration
local REJOIN_AFTER_SAME_ORDERS = 3
local REJOIN_POSITION = Vector3.new(18, -10, -1972)
local REJOIN_WAIT_TIME = 3
local JOB_NAME = "The Twist Worker"

-- Earnings Tracker
local totalEarnings = 0
local ordersCompleted = 0
local startTime = os.time()
local lastOrderFood = nil
local lastOrderDrink = nil
local sameOrderCount = 0

-- Auto-rejoin setup
local function queueRejoin()
    local scriptUrl = "https://raw.githubusercontent.com/abeljalos69/xd/refs/heads/main/lol.lua" -- Replace with your script URL
    
    -- Save current earnings to persist through rejoin
    local savedData = {
        totalEarnings = totalEarnings,
        ordersCompleted = ordersCompleted,
        startTime = startTime
    }
    
    -- Create rejoin script
    local rejoinScript = [[
        -- local savedData = ]]..game:GetService("HttpService"):JSONEncode(savedData)..[[
        
        -- Wait for game to load
        if not game:IsLoaded() then game.Loaded:Wait() end

        -- prevent reset on clicking play
        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("SpawnChar"):FireServer()
        
        -- Teleport to position
        local plr = game:GetService("Players").LocalPlayer
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.CFrame = CFrame.new(]]..REJOIN_POSITION.X..", "..REJOIN_POSITION.Y..", "..REJOIN_POSITION.Z..[[)
        end
        
        -- Wait 3 seconds
        wait(]]..REJOIN_WAIT_TIME..[[)

        -- Teleport to position
        local plr = game:GetService("Players").LocalPlayer
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.CFrame = CFrame.new(]]..REJOIN_POSITION.X..", "..REJOIN_POSITION.Y.." - 97, "..REJOIN_POSITION.Z..[[)
        end
        
        -- Change job
        local args = {"]]..JOB_NAME..[["}
        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("ChangeJob"):InvokeServer(unpack(args))
        
        -- Load main script
        loadstring(game:HttpGet("]]..scriptUrl..[["))()
    ]]
    
    -- Queue teleport with script
    queue_on_teleport(rejoinScript)
    TeleportService:Teleport(game.PlaceId, plr)
end

-- UI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TwistAutoFarmUI"
screenGui.Parent = (gethui and gethui()) or game.CoreGui

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 260)
frame.Position = UDim2.new(0.8, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Add rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

-- Add drop shadow
local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.Position = UDim2.new(0, -15, 0, -15)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://6014419937"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.Parent = frame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Text = "Twist Auto Farm"
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.RobotoMono
title.TextSize = 22
title.Parent = titleBar

-- Make UI draggable
local dragging = false
local dragStart = nil
local startPos = nil

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Content Layout
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -40, 1, -60)  -- Padding on all sides
content.Position = UDim2.new(0, 20, 0, 50)
content.BackgroundTransparency = 1
content.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.Parent = content

-- Updated Labels with new style
local function createLabel(text, textColor)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 25)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.RobotoMono
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local earningsLabel = createLabel("Earnings: $0")
earningsLabel.Parent = content

local ordersLabel = createLabel("Orders: 0")
ordersLabel.Parent = content

local rateLabel = createLabel("$/hr: $0")
rateLabel.Parent = content

local rejoinLabel = createLabel("Same orders: 0/"..REJOIN_AFTER_SAME_ORDERS, Color3.fromRGB(200, 200, 255))
rejoinLabel.Parent = content

local statusLabel = createLabel("Status: Inactive", Color3.fromRGB(255, 100, 100))
statusLabel.Parent = content

local keybindLabel = createLabel("Press [P] to toggle", Color3.fromRGB(200, 200, 255))
keybindLabel.Parent = content

local versionLabel = createLabel("v2.5 | Same-Order Rejoin | @focat", Color3.fromRGB(150, 150, 150))
versionLabel.TextSize = 14
versionLabel.Parent = content

-- Update UI function
local function updateUI()
    earningsLabel.Text = string.format("Earnings: $%d", totalEarnings)
    ordersLabel.Text = string.format("Orders: %d", ordersCompleted)
    rejoinLabel.Text = string.format("Same orders: %d/%d", sameOrderCount, REJOIN_AFTER_SAME_ORDERS)
    
    local hours = math.max(1, (os.time() - startTime)) / 3600
    local hourlyRate = math.floor(totalEarnings / hours)
    rateLabel.Text = string.format("$/hr: $%d", hourlyRate)
    
    if getgenv().AutoFarm then
        statusLabel.Text = "Status: Active"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        statusLabel.Text = "Status: Inactive"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

-- CashChangeDisp Monitor
local cashChangeMonitor = nil
local function monitorCashChanges()
    local moneyGui = plr.PlayerGui:WaitForChild("UI"):WaitForChild("Uni"):WaitForChild("Hud"):WaitForChild("Money")
    
    local function handleCashChange(cashLabel)
        local text = cashLabel.Text
        if string.sub(text, 1, 2) == "+$" then
            local amount = tonumber(string.match(text, "%d+")) or 0
            if amount > 0 then
                totalEarnings = totalEarnings + amount
                ordersCompleted = ordersCompleted + 1
                updateUI()
            end
        end
    end
    
    for _, child in next, moneyGui:GetChildren() do
        if child.Name == "CashChangeDisp" then
            handleCashChange(child)
        end
    end
    
    moneyGui.ChildAdded:Connect(function(child)
        if child.Name == "CashChangeDisp" then
            handleCashChange(child)
        end
    end)
end

-- Core Functions
local function safeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        warn("Error: " .. tostring(err))
        return false
    end
    return true
end

local function GetRegister()
    local startTime = os.clock()
    while os.clock() - startTime < 10 do
        for _, ShoppingStation in pairs(Twist:GetChildren()) do
            if ShoppingStation.Name == "_ShoppingStation" and ShoppingStation:FindFirstChild("NPC") then
                local register = ShoppingStation:FindFirstChild("CashRegister")
                if register then
                    return register
                end
            end
        end
        task.wait(0.5)
    end
    return nil
end

local function GetChildrenOfClass(parent, ClassName)
    local childrenOfClass = {}
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA(ClassName) then
            table.insert(childrenOfClass, child)
        end
    end
    return childrenOfClass
end

local function GetOrderButtons(NPC)
    local Order = NPC.Head.ImageBubble.Frame
    local FoodList, DrinkList = Lists.FoodList, Lists.DrinkList
    local Food, Drink = Order.Food, Order.Drink
    
    local F, D
    for _, f in pairs(GetChildrenOfClass(FoodList, "ImageButton")) do
        if f.Image == Food.Image then
            F = f
            break
        end
    end
    for _, d in pairs(GetChildrenOfClass(DrinkList, "ImageButton")) do
        if d.Image == Drink.Image then
            D = d
            break
        end
    end
    return F, D
end

local function calculateChange(input)
    local amount = tonumber(string.match(input, "%d+%.?%d*")) or 0
    local billDenominations = {20, 5, 1}
    local coinDenominations = {0.25, 0.05, 0.01}
    
    local bills = {
        [20] = 0,
        [5] = 0,
        [1] = 0
    }

    local coins = {
        [0.25] = 0,
        [0.05] = 0,
        [0.01] = 0
    }

    for _, bill in ipairs(billDenominations) do
        bills[bill] = math.floor(amount / bill)
        amount = amount % bill
    end

    amount = math.floor(amount * 100 + 0.5) / 100
   
    for _, coin in ipairs(coinDenominations) do
        coins[coin] = math.floor(amount / coin)
        amount = amount % coin
    end

    return bills, coins
end

local function TakeOrder()
    local FoodButton, DrinkButton = GetOrderButtons(Customer)
    
    -- Check if this is the same order as last time
    if FoodButton.Name == lastOrderFood and DrinkButton.Name == lastOrderDrink then
        sameOrderCount = sameOrderCount + 1
    else
        sameOrderCount = 1
        lastOrderFood = FoodButton.Name
        lastOrderDrink = DrinkButton.Name
    end
    
    -- Check if we need to rejoin
    if sameOrderCount >= REJOIN_AFTER_SAME_ORDERS then
        queueRejoin()
        return false
    end
    
    Remote:InvokeServer("food", Register.Parent, FoodButton.Name)
    Remote:InvokeServer("drink", Register.Parent, DrinkButton.Name)
    return true
end

local function GiveChange()
    local ChangeAmount = Lists.Frame.Received.Text
    local bills, coins = calculateChange(ChangeAmount)
    
    for denomination, amount in pairs(bills) do 
        if amount > 0 then 
            for i = 1, amount do
                Remote:InvokeServer("change", Register.Parent, denomination)
                task.wait(0.05)
            end
        end
    end
   
    for denomination, amount in pairs(coins) do
        for i = 1, amount do
            Remote:InvokeServer("change", Register.Parent, denomination)
            task.wait(0.05)
        end
    end
end

local function fcd(cd)
    fireclickdetector(cd)
    task.wait(0.1)
end

local function PrepareOrder()
    local Tray = Twist.Tray.ClickDetector
    local PlaceTray = Twist.PlaceTray.ClickDetector
    local FoodModels = Twist.Food
    local DrinkModels = Twist.Drinks
    
    local FoodName, DrinkName = GetOrderButtons(Customer)
    FoodName = FoodName.Name
    DrinkName = DrinkName.Name
    
    fcd(Tray)
    fcd(FoodModels[FoodName].ClickDetector)
    fcd(DrinkModels[DrinkName].ClickDetector)
    fcd(PlaceTray)
end

local function Cycle()
    local maxAttempts = 2  -- Allow 2 attempts per NPC
    local attempts = 0
    
    while attempts < maxAttempts do
        if not safeCall(TakeOrder) then break end
        if not safeCall(GiveChange) then break end
        
        local changeStart = os.clock()
        while Register.Parent:FindFirstChild("NPC") and os.clock() - changeStart < 5 do
            safeCall(function()
                Remote:InvokeServer("change", Register.Parent, 0.01)
            end)
            task.wait(0.1)
        end
        
        if not safeCall(PrepareOrder) then break end
        attempts = attempts + 1
        task.wait(0.5)
    end
end

local function Init()
    while getgenv().AutoFarm do
        local success, register = pcall(GetRegister)
        if not success or not register then
            task.wait(1)
            continue
        end
        
        Register = register
        Lists = Register.Pad.Display.Register
        Customer = Register.Parent:FindFirstChild("NPC")
        
        if Customer then
            local bubble = Customer:FindFirstChild("Head") and Customer.Head:FindFirstChild("ImageBubble")
            if bubble then
                local startTime = os.clock()
                while os.clock() - startTime < 5 and not bubble.Enabled do
                    task.wait(0.1)
                end
                
                if bubble.Enabled then
                    safeCall(Cycle)
                end
            end
        end
        task.wait(0.5)
    end
end

-- Toggle Function
local function toggleAutoFarm()
    getgenv().AutoFarm = not getgenv().AutoFarm
    if getgenv().AutoFarm then
        startTime = os.time() -- Reset timer when starting
        -- Start monitoring cash changes if not already running
        if not cashChangeMonitor then
            cashChangeMonitor = coroutine.create(monitorCashChanges)
            coroutine.resume(cashChangeMonitor)
        end
        coroutine.wrap(function()
            while getgenv().AutoFarm do
                safeCall(Init)
                task.wait(1)
            end
        end)()
    end
    updateUI()
end

-- Keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or input.KeyCode ~= Enum.KeyCode.P then return end
    toggleAutoFarm()
end)

-- Initial State
if not getgenv().AutoFarm then getgenv().AutoFarm = false end
updateUI()

-- Start monitoring cash changes
coroutine.wrap(monitorCashChanges)()
