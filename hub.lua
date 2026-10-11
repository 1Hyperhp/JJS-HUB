-- JJS HUB V7 | PC
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

for _, nome in ipairs({"JJSHubV1", "JJSHubV2", "JJSHubV3", "JJSHubV4", "JJSHubV5", "JJSHubV6", "JJSHubV7"}) do
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
local swapCooldown = 0.8 -- espera minima entre inicios (nao cooldown do servidor)

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
    SWAP_COOLDOWN = 0.8,
    MAX_TARGET_DISTANCE = 60
}

-- ============================================
-- INTERFACE
-- ============================================

local gui = Instance.new("ScreenGui")
gui.Name = "JJSHubV7"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(350, 350)
main.Position = UDim2.new(0.5, -175, 0.5, -175)
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
title.Text = "JJS HUB V7"
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

local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Position = UDim2.fromOffset(12, 95)
content.Size = UDim2.new(1, -24, 1, -110)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.CanvasSize = UDim2.fromOffset(0, 285)
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
local cooldownButton = makeButton("INTERVALO SWAP | 0.8 s")

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 65)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.fromRGB(195, 205, 225)
info.Font = Enum.Font.Gotham
info.TextSize = 12
info.TextWrapped = true
info.Text = "WALL: ESPACO perto da parede\nSWAP: E | F6/F7: ajustar timing\nArraste o canto inferior direito para redimensionar"
info.Parent = content

-- GUIAS: PRINCIPAL / COMBATE
local tabs = Instance.new("Frame")
tabs.Name = "Tabs"
tabs.Position = UDim2.fromOffset(12, 52)
tabs.Size = UDim2.new(1, -24, 0, 34)
tabs.BackgroundTransparency = 1
tabs.Parent = main

local function tabButton(text, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -4, 1, 0)
    b.Position = UDim2.new(x, x == 0 and 0 or 4, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(50, 75, 110)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Text = text
    b.Parent = tabs
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    return b
end

local mainTab = tabButton("PRINCIPAL", 0)
local combatTab = tabButton("COMBATE", 0.5)

local combatContent = Instance.new("ScrollingFrame")
combatContent.Name = "CombatContent"
combatContent.Position = content.Position
combatContent.Size = content.Size
combatContent.BackgroundTransparency = 1
combatContent.BorderSizePixel = 0
combatContent.ScrollBarThickness = 4
combatContent.CanvasSize = UDim2.fromOffset(0, 400)
combatContent.Visible = false
combatContent.Parent = main

local combatLayout = Instance.new("UIListLayout")
combatLayout.Padding = UDim.new(0, 8)
combatLayout.Parent = combatContent

local function combatButton(label)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -7, 0, 40)
    b.BackgroundColor3 = Color3.fromRGB(58, 65, 84)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.Text = label
    b.Parent = combatContent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    return b
end

local hitboxEnabled = false
local hitboxSize = {15, 3, 15}
local originalRoots = {}
local hitboxConnections = {}
local hitboxToggle = combatButton("HITBOX | OFF")

local function makeDimension(label, index)
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -7, 0, 38)
    line.BackgroundTransparency = 1
    line.Parent = combatContent

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.fromOffset(44, 34)
    minus.Position = UDim2.new(0, 0, 0, 0)
    minus.Text = "-"
    minus.TextSize = 20
    minus.BackgroundColor3 = Color3.fromRGB(58, 65, 84)
    minus.TextColor3 = Color3.new(1, 1, 1)
    minus.Parent = line

    local value = Instance.new("TextLabel")
    value.Size = UDim2.new(1, -100, 0, 34)
    value.Position = UDim2.fromOffset(50, 0)
    value.BackgroundTransparency = 1
    value.TextColor3 = Color3.new(1, 1, 1)
    value.Font = Enum.Font.GothamBold
    value.TextSize = 14
    value.Parent = line

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.fromOffset(44, 34)
    plus.Position = UDim2.new(1, -44, 0, 0)
    plus.Text = "+"
    plus.TextSize = 20
    plus.BackgroundColor3 = Color3.fromRGB(58, 65, 84)
    plus.TextColor3 = Color3.new(1, 1, 1)
    plus.Parent = line

    for _, b in ipairs({minus, plus}) do
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    end

    local function update()
        value.Text = label .. ": " .. tostring(hitboxSize[index])
    end
    update()
    connect(minus.MouseButton1Click, function()
        hitboxSize[index] = math.max(1, hitboxSize[index] - 1)
        update()
    end)
    connect(plus.MouseButton1Click, function()
        hitboxSize[index] = math.min(40, hitboxSize[index] + 1)
        update()
    end)
end

makeDimension("LARGURA X", 1)
makeDimension("ALTURA Y", 2)
makeDimension("PROFUNDIDADE Z", 3)

-- LOCK ON (Q) - tecla E reservada para Perfect Swap
local lockButton = combatButton("LOCK ON | OFF (Q)")
local lockEnabled = false
local lockTarget = nil
local lockHighlight = nil
local savedAutoRotate = nil
local LOCK_DISTANCE = 80
local LOCK_ROTATION_SPEED = 14

local function clearLockMarker()
    if lockHighlight then
        lockHighlight:Destroy()
        lockHighlight = nil
    end
end

local function markLockTarget(character)
    clearLockMarker()
    if not character then return end
    local marker = Instance.new("Highlight")
    marker.Name = "JJSLockMarker"
    marker.Adornee = character
    marker.FillColor = Color3.fromRGB(255, 60, 60)
    marker.OutlineColor = Color3.fromRGB(255, 255, 255)
    marker.FillTransparency = 0.75
    marker.OutlineTransparency = 0
    marker.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    marker.Parent = gui
    lockHighlight = marker
end

local function closestLockTarget()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local best, bestDistance = nil, LOCK_DISTANCE
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and other.Character then
            local model = other.Character
            local enemyRoot = model:FindFirstChild("HumanoidRootPart")
            local enemyHum = model:FindFirstChildOfClass("Humanoid")
            if enemyRoot and enemyHum and enemyHum.Health > 0 then
                local distance = (enemyRoot.Position - root.Position).Magnitude
                if distance < bestDistance then
                    best, bestDistance = model, distance
                end
            end
        end
    end
    return best
end

local function updateLockButton()
    lockButton.Text = "LOCK ON | " .. (lockEnabled and "ON" or "OFF") .. " (Q)"
    lockButton.BackgroundColor3 = lockEnabled
        and Color3.fromRGB(40, 130, 90)
        or Color3.fromRGB(58, 65, 84)
end

local function disableLock()
    lockEnabled = false
    lockTarget = nil
    clearLockMarker()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.AutoRotate = savedAutoRotate == nil and true or savedAutoRotate
    end
    savedAutoRotate = nil
    updateLockButton()
end

local function enableLock()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local chosen = closestLockTarget()
    if not chosen then
        print("[LOCK ON] Nenhum alvo dentro de 80 studs")
        return
    end
    savedAutoRotate = hum.AutoRotate
    lockTarget = chosen
    lockEnabled = true
    hum.AutoRotate = false
    markLockTarget(chosen)
    updateLockButton()
end

local function toggleLock()
    if lockEnabled then disableLock() else enableLock() end
end

connect(lockButton.MouseButton1Click, toggleLock)
connect(UIS.InputBegan, function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Q then
        toggleLock()
    end
end)

connect(RunService.RenderStepped, function(dt)
    if not alive or not lockEnabled then return end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then
        disableLock()
        return
    end
    hum.AutoRotate = false
    local targetRoot = lockTarget and lockTarget:FindFirstChild("HumanoidRootPart")
    local targetHum = lockTarget and lockTarget:FindFirstChildOfClass("Humanoid")
    if not lockTarget or not lockTarget.Parent or not targetRoot
        or not targetHum or targetHum.Health <= 0
        or (targetRoot.Position - root.Position).Magnitude > LOCK_DISTANCE then
        lockTarget = closestLockTarget()
        if not lockTarget then
            disableLock()
            return
        end
        markLockTarget(lockTarget)
        targetRoot = lockTarget:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end
    end
    local delta = targetRoot.Position - root.Position
    local flat = Vector3.new(delta.X, 0, delta.Z)
    if flat.Magnitude > 0.01 then
        local desired = CFrame.lookAt(root.Position, root.Position + flat.Unit)
        root.CFrame = root.CFrame:Lerp(desired, math.clamp(LOCK_ROTATION_SPEED * dt, 0, 1))
    end
end)

connect(player.CharacterAdded, function()
    if lockEnabled then
        -- Aguardar o novo personagem antes de selecionar um alvo novamente
        lockEnabled = false
        lockTarget = nil
        savedAutoRotate = nil
        clearLockMarker()
        updateLockButton()
    end
end)

local combatInfo = Instance.new("TextLabel")
combatInfo.Size = UDim2.new(1, -7, 0, 78)
combatInfo.BackgroundTransparency = 1
combatInfo.TextColor3 = Color3.fromRGB(190, 200, 220)
combatInfo.TextSize = 12
combatInfo.TextWrapped = true
combatInfo.Text = "Alteracao local de HumanoidRootPart em outros personagens e dummies. Nao garante acerto registrado pelo servidor."
combatInfo.Parent = combatContent

local function refreshTabs(combat)
    content.Visible = not combat
    combatContent.Visible = combat
    mainTab.BackgroundColor3 = combat and Color3.fromRGB(58,65,84) or Color3.fromRGB(40,110,145)
    combatTab.BackgroundColor3 = combat and Color3.fromRGB(40,110,145) or Color3.fromRGB(58,65,84)
end
connect(mainTab.MouseButton1Click, function() refreshTabs(false) end)
connect(combatTab.MouseButton1Click, function() refreshTabs(true) end)
refreshTabs(false)

-- Guardar propriedades para restaurar ao desligar
local function restoreHitboxes()
    for root, original in pairs(originalRoots) do
        if root and root.Parent then
            pcall(function()
                root.Size = original.Size
                root.Transparency = original.Transparency
                root.Material = original.Material
                root.CanCollide = original.CanCollide
                root.CanTouch = original.CanTouch
                root.CanQuery = original.CanQuery
                root.Massless = original.Massless
            end)
        end
        originalRoots[root] = nil
    end
end

local function applyHitbox(model)
    if not hitboxEnabled or not model or model == player.Character then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then return end
    if not originalRoots[root] then
        originalRoots[root] = {
            Size = root.Size, Transparency = root.Transparency,
            Material = root.Material, CanCollide = root.CanCollide,
            CanTouch = root.CanTouch, CanQuery = root.CanQuery,
            Massless = root.Massless
        }
    end
    root.Size = Vector3.new(hitboxSize[1], hitboxSize[2], hitboxSize[3])
    root.CanCollide = false
    root.CanTouch = true
    root.CanQuery = true
    root.Massless = true
    root.Transparency = 1
end

local function refreshHitboxes()
    if not hitboxEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then applyHitbox(p.Character) end
    end
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("Model") and object:FindFirstChildOfClass("Humanoid") then
            applyHitbox(object)
        end
    end
end

connect(hitboxToggle.MouseButton1Click, function()
    hitboxEnabled = not hitboxEnabled
    hitboxToggle.Text = "HITBOX | " .. (hitboxEnabled and "ON" or "OFF")
    hitboxToggle.BackgroundColor3 = hitboxEnabled and Color3.fromRGB(40,130,90) or Color3.fromRGB(58,65,84)
    if hitboxEnabled then refreshHitboxes() else restoreHitboxes() end
end)

-- Reaplicar para novos personagens e para valores ajustados
local hitboxElapsed = 0
connect(RunService.Heartbeat, function(dt)
    if not hitboxEnabled then return end
    hitboxElapsed = hitboxElapsed + dt
    if hitboxElapsed >= 1 then
        hitboxElapsed = 0
        refreshHitboxes()
    end
end)

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
local MIN_HEIGHT = 280
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

-- BOTAO VERDE ARRASTAVEL + CTRL DIREITO PARA OCULTAR
local buttonHidden = false
local movingOpen = false
local openWasDragged = false
local openStartMouse = nil
local openStartPosition = nil

connect(openButton.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        movingOpen = true
        openWasDragged = false
        openStartMouse = input.Position
        openStartPosition = openButton.Position
    end
end)

connect(UIS.InputChanged, function(input)
    if not movingOpen or not openStartMouse or not openStartPosition then
        return
    end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end

    local delta = input.Position - openStartMouse
    if delta.Magnitude >= 6 then
        openWasDragged = true
    end
    if not openWasDragged then return end

    local screen = workspace.CurrentCamera.ViewportSize
    local width = openButton.AbsoluteSize.X
    local height = openButton.AbsoluteSize.Y
    local targetX = openStartPosition.X.Offset + delta.X
    local targetY = openStartPosition.Y.Offset + delta.Y
    -- O botao inicia com Y.Scale=0.5, por isso convertemos para pixels
    targetX = openStartPosition.X.Scale * screen.X + targetX
    targetY = openStartPosition.Y.Scale * screen.Y + targetY
    openButton.Position = UDim2.fromOffset(
        math.clamp(targetX, 0, math.max(0, screen.X - width)),
        math.clamp(targetY, 0, math.max(0, screen.Y - height))
    )
end)

connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        movingOpen = false
    end
end)

connect(minimize.MouseButton1Click, function()
    main.Visible = false
    openButton.Visible = not buttonHidden
end)

connect(openButton.MouseButton1Click, function()
    if openWasDragged then
        openWasDragged = false
        return
    end
    main.Visible = true
    openButton.Visible = false
end)

connect(UIS.InputBegan, function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        buttonHidden = not buttonHidden
        openButton.Visible = not buttonHidden and not main.Visible
        print("[JJS HUB] Botao flutuante:", buttonHidden and "OCULTO" or "VISIVEL")
    end
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
    cooldownButton.Text = string.format("INTERVALO SWAP | %.1f s", swapCooldown)

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

connect(cooldownButton.MouseButton1Click, function()
    swapCooldown = swapCooldown + 0.2
    if swapCooldown > 2.01 then swapCooldown = 0.4 end
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
    local attemptStart = os.clock()

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

    local waitLeft = swapCooldown - (os.clock() - attemptStart)
    if waitLeft > 0 then task.wait(waitLeft) end
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
    hitboxEnabled = false
    disableLock()
    restoreHitboxes()

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

print("[JJS HUB V7] CARREGADO")
print("Janela redimensionavel e minimizavel")
