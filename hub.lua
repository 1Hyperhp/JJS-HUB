
-- JJS HUB V3 | PC
-- WALL CLIMB V3 + TODO PERFECT SWAP V11
-- Janela arrastavel, redimensionavel e minimizavel

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- LIMPEZA DE VERSOES ANTERIORES

if type(_G.JJSHubCleanup) == "function" then
    pcall(_G.JJSHubCleanup)
end

for _, nome in ipairs({
    "TodoV6Connection",
    "TodoV7Connection",
    "TodoV8Connection",
    "TodoV9Connection",
    "TodoV10Connection",
    "TodoV11Connection"
}) do
    if _G[nome] then
        pcall(function()
            _G[nome]:Disconnect()
        end)
        _G[nome] = nil
    end
end

for _, nome in ipairs({"JJSHubV1", "JJSHubV2", "JJSHubV3"}) do
    local antigo = playerGui:FindFirstChild(nome)
    if antigo then antigo:Destroy() end
end

local alive = true
local connections = {}
local wallON = false
local swapON = false
local spaceHeld = false
local lastImpulse = 0
local swapBusy = false
local timingOffset = 0

local function connect(signal, fn)
    local connection = signal:Connect(fn)
    table.insert(connections, connection)
    return connection
end

-- CONFIGURACOES

local CONFIG = {
    WALL_DISTANCE = 3.5,
    WALL_UP = 30,
    WALL_SIDE = 10,
    WALL_INTERVAL = 0.38,
    R_HOLD = 0.10,
    M1_HOLD = 0.035,
    SWAP_COOLDOWN = 2.5,
    MAX_TARGET_DISTANCE = 60
}

-- ============================================
-- INTERFACE
-- ============================================

local gui = Instance.new("ScreenGui")
gui.Name = "JJSHubV3"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(350, 315)
main.Position = UDim2.new(0.5, -175, 0.5, -157)
main.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 11)
mainCorner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(90, 105, 140)
stroke.Thickness = 1
stroke.Parent = main

-- CABECALHO

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
header.BorderSizePixel = 0
header.Active = true
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "JJS HUB V3"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(34, 29)
minimize.Position = UDim2.new(1, -78, 0, 8)
minimize.BackgroundColor3 = Color3.fromRGB(65, 75, 100)
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.Text = "_"
minimize.TextSize = 19
minimize.Font = Enum.Font.GothamBold
minimize.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(34, 29)
close.Position = UDim2.new(1, -40, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(145, 55, 65)
close.TextColor3 = Color3.new(1, 1, 1)
close.Text = "X"
close.TextSize = 15
close.Font = Enum.Font.GothamBold
close.Parent = header

for _, button in ipairs({minimize, close}) do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = button
end

-- AREA DOS BOTOES

local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.fromOffset(12, 57)
content.Size = UDim2.new(1, -24, 1, -72)
content.BackgroundTransparency = 1
content.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 9)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = content

local function makeButton(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 45)
    b.BackgroundColor3 = Color3.fromRGB(58, 65, 84)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Text = text
    b.Parent = content

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = b

    return b
end

local wallButton = makeButton("WALL CLIMB V3 | OFF")
local swapButton = makeButton("PERFECT SWAP V11 | OFF")
local timingButton = makeButton("TIMING | 0 ms")

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 65)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.fromRGB(195, 205, 225)
info.Font = Enum.Font.Gotham
info.TextSize = 12
info.TextWrapped = true
info.Text = "WALL: ESPACO perto da parede\nSWAP: E | F6/F7: ajustar timing\nArraste o canto inferior direito para redimensionar"
info.Parent = content

-- ALCA PARA REDIMENSIONAR

local resizeHandle = Instance.new("TextButton")
resizeHandle.Name = "ResizeHandle"
resizeHandle.Size = UDim2.fromOffset(28, 28)
resizeHandle.Position = UDim2.new(1, -28, 1, -28)
resizeHandle.BackgroundTransparency = 1
resizeHandle.Text = "◢"
resizeHandle.TextColor3 = Color3.fromRGB(170, 190, 230)
resizeHandle.TextSize = 23
resizeHandle.Font = Enum.Font.GothamBold
resizeHandle.ZIndex = 5
resizeHandle.Parent = main

-- BOTAO FLUTUANTE PARA REABRIR

local openButton = Instance.new("TextButton")
openButton.Name = "OpenHub"
openButton.Size = UDim2.fromOffset(116, 38)
openButton.Position = UDim2.new(0, 20, 0.5, -19)
openButton.BackgroundColor3 = Color3.fromRGB(40, 115, 90)
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 13
openButton.Text = "ABRIR HUB"
openButton.Visible = false
openButton.Active = true
openButton.Parent = gui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 8)
openCorner.Parent = openButton

-- ============================================
-- ARRASTAR JANELA E REDIMENSIONAR
-- ============================================

local dragging = false
local resizing = false

local dragStart
local originalPosition
local resizeStart
local originalSize

local MIN_WIDTH = 230
local MIN_HEIGHT = 245
local MAX_WIDTH = 850
local MAX_HEIGHT = 650

connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Nao iniciar arrasto ao clicar nos controles
        local x = input.Position.X
        local right = header.AbsolutePosition.X + header.AbsoluteSize.X

        if x >= right - 90 then return end

        dragging = true
        dragStart = input.Position
        originalPosition = main.Position
    end
end)

connect(resizeHandle.MouseButton1Down, function()
    resizing = true
    resizeStart = UIS:GetMouseLocation()
    originalSize = main.AbsoluteSize
end)

connect(UIS.InputChanged, function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end

    local mouse = UIS:GetMouseLocation()

    if dragging and dragStart and originalPosition then
        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            originalPosition.X.Scale,
            originalPosition.X.Offset + delta.X,
            originalPosition.Y.Scale,
            originalPosition.Y.Offset + delta.Y
        )
    end

    if resizing and resizeStart and originalSize then
        local delta = mouse - resizeStart

        local newWidth = math.clamp(
            originalSize.X + delta.X,
            MIN_WIDTH,
            MAX_WIDTH
        )

        local newHeight = math.clamp(
            originalSize.Y + delta.Y,
            MIN_HEIGHT,
            MAX_HEIGHT
        )

        main.Size = UDim2.fromOffset(newWidth, newHeight)
    end
end)

connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        resizing = false
    end
end)

-- ============================================
-- MINIMIZAR, REABRIR E FECHAR
-- ============================================

connect(minimize.MouseButton1Click, function()
    main.Visible = false
    openButton.Visible = true
end)

connect(openButton.MouseButton1Click, function()
    main.Visible = true
    openButton.Visible = false
end)

-- ============================================
-- ATUALIZACAO DOS BOTOES
-- ============================================

local function refresh()
    wallButton.Text =
        "WALL CLIMB V3 | " .. (wallON and "ON" or "OFF")

    swapButton.Text =
        "PERFECT SWAP V11 | " .. (swapON and "ON" or "OFF")

    timingButton.Text =
        "TIMING | " .. timingOffset .. " ms"

    wallButton.BackgroundColor3 = wallON
        and Color3.fromRGB(40, 130, 90)
        or Color3.fromRGB(58, 65, 84)

    swapButton.BackgroundColor3 = swapON
        and Color3.fromRGB(40, 130, 90)
        or Color3.fromRGB(58, 65, 84)
end

connect(wallButton.MouseButton1Click, function()
    wallON = not wallON
    if not wallON then spaceHeld = false end
    refresh()
end)

connect(swapButton.MouseButton1Click, function()
    swapON = not swapON
    refresh()
end)

connect(timingButton.MouseButton1Click, function()
    timingOffset = timingOffset + 10
    if timingOffset > 120 then
        timingOffset = -120
    end
    refresh()
end)

-- ============================================
-- TODO PERFECT SWAP V11
-- ============================================

local function calculateTiming(distance)
    if not distance then return 300 end
    if distance <= 10 then return 300 end
    if distance <= 25 then return 320 end
    if distance <= 35 then return 370 end
    return 450
end

local function getTarget()
    local camera = workspace.CurrentCamera
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not camera or not root then return nil end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}

    local hit = workspace:Raycast(
        camera.CFrame.Position,
        camera.CFrame.LookVector * 100,
        params
    )

    if not hit then return nil end

    local model = hit.Instance:FindFirstAncestorOfClass("Model")
    if not model then return nil end

    local hum = model:FindFirstChildOfClass("Humanoid")
    local targetRoot = model:FindFirstChild("HumanoidRootPart")

    if not hum or hum.Health <= 0 or not targetRoot then
        return nil
    end

    local delta = targetRoot.Position - root.Position
    local distance = Vector3.new(delta.X, 0, delta.Z).Magnitude

    if distance > CONFIG.MAX_TARGET_DISTANCE then
        return nil
    end

    return model, distance
end

local function sendR()
    VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game)
    task.wait(CONFIG.R_HOLD)
    VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game)
end

local function sendM1()
    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(CONFIG.M1_HOLD)
    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function doSwap()
    if not alive or not swapON or swapBusy then return end

    swapBusy = true

    local ok, err = pcall(function()
        local target, distance = getTarget()

        local ms = math.clamp(
            calculateTiming(distance) + timingOffset,
            180,
            650
        )

        local start = os.clock()
        sendR()

        local remaining = ms / 1000 - (os.clock() - start)

        if remaining > 0 then
            task.wait(remaining)
        end

        if alive and swapON then
            sendM1()
        end

        print(
            "[PERFECT SWAP V11]",
            target and target.Name or "Sem alvo",
            ms .. "ms"
        )
    end)

    if not ok then
        warn("[PERFECT SWAP V11]", err)
    end

    task.wait(CONFIG.SWAP_COOLDOWN)
    swapBusy = false
end

-- ============================================
-- WALL CLIMB V3
-- ============================================

local function wallStep()
    if not alive or not wallON or not spaceHeld then
        return
    end

    local char = player.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    if not hum or not root or hum.Health <= 0 then
        return
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}

    local hit = workspace:Raycast(
        root.Position,
        root.CFrame.LookVector * CONFIG.WALL_DISTANCE,
        params
    )

    if not hit or math.abs(hit.Normal.Y) > 0.3 then
        return
    end

    if os.clock() - lastImpulse < CONFIG.WALL_INTERVAL then
        return
    end

    lastImpulse = os.clock()

    local lateral = 0

    if UIS:IsKeyDown(Enum.KeyCode.A) then
        lateral = -1
    elseif UIS:IsKeyDown(Enum.KeyCode.D) then
        lateral = 1
    end

    local velocity = root.AssemblyLinearVelocity

    root.AssemblyLinearVelocity =
        Vector3.new(
            velocity.X,
            CONFIG.WALL_UP,
            velocity.Z
        ) + root.CFrame.RightVector
            * lateral
            * CONFIG.WALL_SIDE
end

-- ============================================
-- CONTROLES DO TECLADO
-- ============================================

connect(UIS.InputBegan, function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.Space then
        spaceHeld = true

    elseif input.KeyCode == Enum.KeyCode.E then
        if swapON then
            task.spawn(doSwap)
        end

    elseif input.KeyCode == Enum.KeyCode.F6 then
        timingOffset = math.max(timingOffset - 10, -120)
        refresh()

    elseif input.KeyCode == Enum.KeyCode.F7 then
        timingOffset = math.min(timingOffset + 10, 120)
        refresh()
    end
end)

connect(UIS.InputEnded, function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        spaceHeld = false
    end
end)

connect(player.CharacterAdded, function()
    spaceHeld = false
    lastImpulse = 0
end)

connect(RunService.Heartbeat, wallStep)

-- ============================================
-- LIMPEZA DO HUB
-- ============================================

local function cleanup()
    if not alive then return end

    alive = false
    wallON = false
    swapON = false

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(connections)
    gui:Destroy()
end

_G.JJSHubCleanup = cleanup

connect(close.MouseButton1Click, cleanup)

refresh()

print("[JJS HUB V3] CARREGADO")
print("Janela redimensionavel e minimizavel")
