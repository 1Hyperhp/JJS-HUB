
-- JJS HUB V1
-- WALL CLIMB V3 + TODO PERFECT SWAP V11
-- PC

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remover versoes anteriores do HUB
if _G.JJSHubCleanup then
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

local antigo = playerGui:FindFirstChild("JJSHubV1")
if antigo then
    antigo:Destroy()
end

local connections = {}
local ativo = true

local wallEnabled = false
local swapEnabled = false

local segurandoSpace = false
local ultimoImpulso = 0
local ocupado = false
local ajuste = 0

local CONFIG = {
    DISTANCIA_PAREDE = 3.5,
    IMPULSO_VERTICAL = 30,
    IMPULSO_LATERAL = 10,
    INTERVALO_IMPULSO = 0.38,

    R_HOLD = 0.10,
    M1_HOLD = 0.035,
    COOLDOWN = 2.5,
    MAX_DIST = 60
}

local function conectar(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(connections, conn)
    return conn
end

-- ==================================
-- TODO PERFECT SWAP V11
-- ==================================

local function calcularTiming(dist)
    if not dist then
        return 300
    elseif dist <= 10 then
        return 300
    elseif dist <= 25 then
        return 320
    elseif dist <= 35 then
        return 370
    else
        return 450
    end
end

local function obterAlvo()
    local camera = workspace.CurrentCamera
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not camera or not root then
        return nil
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}

    local resultado = workspace:Raycast(
        camera.CFrame.Position,
        camera.CFrame.LookVector * 100,
        params
    )

    if not resultado then
        return nil
    end

    local model = resultado.Instance:FindFirstAncestorOfClass("Model")
    if not model then
        return nil
    end

    local hum = model:FindFirstChildOfClass("Humanoid")
    local alvoRoot = model:FindFirstChild("HumanoidRootPart")

    if not hum or hum.Health <= 0 or not alvoRoot then
        return nil
    end

    local delta = alvoRoot.Position - root.Position
    local dist = Vector3.new(delta.X, 0, delta.Z).Magnitude

    if dist > CONFIG.MAX_DIST then
        return nil
    end

    return model, dist
end

local function enviarR()
    VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game)
    task.wait(CONFIG.R_HOLD)
    VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game)
end

local function enviarM1()
    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(CONFIG.M1_HOLD)
    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function executarSwap()
    if not ativo or not swapEnabled or ocupado then
        return
    end

    ocupado = true

    local ok, erro = pcall(function()
        local alvo, dist = obterAlvo()

        local timing = math.clamp(
            calcularTiming(dist) + ajuste,
            180,
            650
        )

        local inicio = os.clock()

        enviarR()

        local restante = timing / 1000 - (os.clock() - inicio)

        if restante > 0 then
            task.wait(restante)
        end

        if not ativo or not swapEnabled then
            return
        end

        enviarM1()

        print(string.format(
            "[TODO V11] Alvo: %s | Timing: %dms",
            alvo and alvo.Name or "Nao identificado",
            timing
        ))
    end)

    if not ok then
        warn("[TODO V11]", erro)
    end

    task.wait(CONFIG.COOLDOWN)
    ocupado = false
end

-- ==================================
-- WALL CLIMB V3
-- ==================================

local function atualizarWallClimb()
    if not ativo or not wallEnabled or not segurandoSpace then
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
        root.CFrame.LookVector * CONFIG.DISTANCIA_PAREDE,
        params
    )

    if not hit or math.abs(hit.Normal.Y) > 0.3 then
        return
    end

    local agora = os.clock()

    if agora - ultimoImpulso < CONFIG.INTERVALO_IMPULSO then
        return
    end

    ultimoImpulso = agora

    local lateral = 0

    if UIS:IsKeyDown(Enum.KeyCode.A) then
        lateral = -1
    elseif UIS:IsKeyDown(Enum.KeyCode.D) then
        lateral = 1
    end

    local velocidade = root.AssemblyLinearVelocity
    local direita = root.CFrame.RightVector

    root.AssemblyLinearVelocity =
        Vector3.new(
            velocidade.X,
            CONFIG.IMPULSO_VERTICAL,
            velocidade.Z
        ) + direita * lateral * CONFIG.IMPULSO_LATERAL
end

-- ==================================
-- INTERFACE DO HUB
-- ==================================

local gui = Instance.new("ScreenGui")
gui.Name = "JJSHubV1"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(340, 355)
frame.Position = UDim2.new(0.5, -170, 0.5, -177)
frame.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 90, 120)
stroke.Thickness = 1
stroke.Parent = frame

local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, -55, 0, 48)
titulo.Position = UDim2.fromOffset(15, 0)
titulo.BackgroundTransparency = 1
titulo.Text = "JJS HUB | V1"
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.TextSize = 21
titulo.Font = Enum.Font.GothamBold
titulo.TextXAlignment = Enum.TextXAlignment.Left
titulo.Parent = frame

local minimizar = Instance.new("TextButton")
minimizar.Size = UDim2.fromOffset(35, 32)
minimizar.Position = UDim2.new(1, -44, 0, 8)
minimizar.Text = "-"
minimizar.TextSize = 24
minimizar.Font = Enum.Font.GothamBold
minimizar.TextColor3 = Color3.new(1, 1, 1)
minimizar.BackgroundColor3 = Color3.fromRGB(55, 60, 75)
minimizar.Parent = frame

local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 7)
miniCorner.Parent = minimizar

local conteudo = Instance.new("Frame")
conteudo.Size = UDim2.new(1, -24, 1, -60)
conteudo.Position = UDim2.fromOffset(12, 54)
conteudo.BackgroundTransparency = 1
conteudo.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = conteudo

local function criarBotao(nome)
    local botao = Instance.new("TextButton")
    botao.Size = UDim2.new(1, 0, 0, 49)
    botao.BackgroundColor3 = Color3.fromRGB(55, 60, 76)
    botao.TextColor3 = Color3.fromRGB(255, 255, 255)
    botao.TextSize = 15
    botao.Font = Enum.Font.GothamBold
    botao.Text = nome
    botao.Parent = conteudo

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = botao

    return botao
end

local wallButton = criarBotao("WALL CLIMB V3 | OFF")
local swapButton = criarBotao("PERFECT SWAP V11 | OFF")
local timingButton = criarBotao("AJUSTE TIMING | 0ms")

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 72)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.fromRGB(185, 190, 205)
info.TextSize = 13
info.Font = Enum.Font.Gotham
info.TextWrapped = true
info.Text = "WALL: segure ESPACO perto da parede\nSWAP: aperte E\nF6 = -10ms | F7 = +10ms"
info.Parent = conteudo

local function atualizarBotoes()
    wallButton.Text = "WALL CLIMB V3 | " .. (wallEnabled and "ON" or "OFF")
    swapButton.Text = "PERFECT SWAP V11 | " .. (swapEnabled and "ON" or "OFF")
    timingButton.Text = "AJUSTE TIMING | " .. ajuste .. "ms"

    wallButton.BackgroundColor3 = wallEnabled
        and Color3.fromRGB(40, 125, 85)
        or Color3.fromRGB(55, 60, 76)

    swapButton.BackgroundColor3 = swapEnabled
        and Color3.fromRGB(40, 125, 85)
        or Color3.fromRGB(55, 60, 76)
end

conectar(wallButton.MouseButton1Click, function()
    wallEnabled = not wallEnabled
    atualizarBotoes()
end)

conectar(swapButton.MouseButton1Click, function()
    swapEnabled = not swapEnabled
    atualizarBotoes()
end)

conectar(timingButton.MouseButton1Click, function()
    ajuste = ajuste + 10

    if ajuste > 120 then
        ajuste = -120
    end

    atualizarBotoes()
end)

local minimizado = false

conectar(minimizar.MouseButton1Click, function()
    minimizado = not minimizado
    conteudo.Visible = not minimizado

    frame.Size = minimizado
        and UDim2.fromOffset(340, 48)
        or UDim2.fromOffset(340, 355)

    minimizar.Text = minimizado and "+" or "-"
end)

-- ==================================
-- CONTROLES DO TECLADO
-- ==================================

conectar(UIS.InputBegan, function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.Space then
        segurandoSpace = true

    elseif input.KeyCode == Enum.KeyCode.E then
        if swapEnabled then
            task.spawn(executarSwap)
        end

    elseif input.KeyCode == Enum.KeyCode.F6 then
        ajuste = math.max(ajuste - 10, -120)
        atualizarBotoes()

    elseif input.KeyCode == Enum.KeyCode.F7 then
        ajuste = math.min(ajuste + 10, 120)
        atualizarBotoes()
    end
end)

conectar(UIS.InputEnded, function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        segurandoSpace = false
    end
end)

conectar(player.CharacterAdded, function()
    segurandoSpace = false
    ultimoImpulso = 0
end)

conectar(RunService.Heartbeat, atualizarWallClimb)

-- ==================================
-- LIMPEZA
-- ==================================

_G.JJSHubCleanup = function()
    ativo = false
    wallEnabled = false
    swapEnabled = false

    for _, conn in ipairs(connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end

    table.clear(connections)

    if gui then
        gui:Destroy()
    end
end

atualizarBotoes()

print("[JJS HUB V1] CARREGADO")
print("Wall Climb V3 + Todo Perfect Swap V11")
