
-- TODO PERFECT SWAP V11
-- E = R + M1
-- F6 = M1 10ms mais cedo
-- F7 = M1 10ms mais tarde
-- Sem interface e sem varredura constante
-- Usa VirtualInputManager

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- CONFIGURACOES
local R_HOLD = 0.10
local M1_HOLD = 0.035
local COOLDOWN = 2.5
local MAX_DIST = 60

local AJUSTE = 0
local ocupado = false

-- Desligar versoes anteriores
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

-- Timing inicial conservador
-- Valores experimentais, nao garantidos
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

    local root = char and
        char:FindFirstChild("HumanoidRootPart")

    if not camera or not root then
        return nil
    end

    local origem = camera.CFrame.Position
    local direcao = camera.CFrame.LookVector * 100

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}

    local resultado = workspace:Raycast(
        origem, direcao, params
    )

    if not resultado then
        return nil
    end

    local parte = resultado.Instance
    local model = parte:FindFirstAncestorOfClass("Model")

    if not model then
        return nil
    end

    local hum = model:FindFirstChildOfClass("Humanoid")
    local alvoRoot = model:FindFirstChild(
        "HumanoidRootPart"
    )

    if not hum or hum.Health <= 0 or not alvoRoot then
        return nil
    end

    local delta = alvoRoot.Position - root.Position

    local distancia = Vector3.new(
        delta.X, 0, delta.Z
    ).Magnitude

    if distancia > MAX_DIST then
        return nil
    end

    return model, distancia
end

local function enviarR()
    VIM:SendKeyEvent(
        true, Enum.KeyCode.R, false, game
    )

    task.wait(R_HOLD)

    VIM:SendKeyEvent(
        false, Enum.KeyCode.R, false, game
    )
end

local function enviarM1()
    VIM:SendMouseButtonEvent(
        0, 0, 0, true, game, 0
    )

    task.wait(M1_HOLD)

    VIM:SendMouseButtonEvent(
        0, 0, 0, false, game, 0
    )
end

local function executar()
    if ocupado then return end
    ocupado = true

    local ok, erro = pcall(function()
        local alvo, dist = obterAlvo()

        local timing = calcularTiming(dist)
        timing = math.clamp(
            timing + AJUSTE, 180, 650
        )

        -- Comeca a contagem do R
        local inicio = os.clock()

        enviarR()

        -- Aguarda ate o instante calculado
        local restante =
            timing / 1000 - (os.clock() - inicio)

        if restante > 0 then
            task.wait(restante)
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

    task.wait(COOLDOWN)
    ocupado = false
end

_G.TodoV11Connection =
    UIS.InputBegan:Connect(function(input, processed)
        if processed then return end

        if input.KeyCode == Enum.KeyCode.E then
            task.spawn(executar)

        elseif input.KeyCode == Enum.KeyCode.F6 then
            AJUSTE = math.max(AJUSTE - 10, -120)
            print("[TODO] Ajuste:", AJUSTE, "ms")

        elseif input.KeyCode == Enum.KeyCode.F7 then
            AJUSTE = math.min(AJUSTE + 10, 120)
            print("[TODO] Ajuste:", AJUSTE, "ms")
        end
    end)

print("[TODO V11] ATIVADO")
print("E = Swap | F6/F7 = Ajustar timing")

-- WALL CLIMB V3
-- W + ESPACO = escalar
-- A / D = deslocamento lateral
-- Soltar ESPACO = parar
-- LocalScript em StarterPlayerScripts

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local CONFIG = {
    DISTANCIA_PAREDE = 3.5,
    IMPULSO_VERTICAL = 30,
    IMPULSO_LATERAL = 10,
    INTERVALO_IMPULSO = 0.38,

    -- Coloque aqui o ID da animacao original
    -- quando conseguirmos identifica-la
    ANIMACAO_ID = ""
}

local segurando = false
local ultimoImpulso = 0
local track = nil

local function pararAnimacao()
    if track and track.IsPlaying then
        track:Stop(0.12)
    end
end

local function prepararAnimacao(humanoid)
    if CONFIG.ANIMACAO_ID == "" then
        return nil
    end

    if track then
        return track
    end

    local animator =
        humanoid:FindFirstChildOfClass("Animator")

    if not animator then return nil end

    local anim = Instance.new("Animation")
    anim.AnimationId =
        "rbxassetid://" .. CONFIG.ANIMACAO_ID

    track = animator:LoadAnimation(anim)
    track.Looped = true
    track.Priority = Enum.AnimationPriority.Action

    return track
end

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.Space then
        segurando = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        segurando = false
        pararAnimacao()
    end
end)

player.CharacterAdded:Connect(function()
    segurando = false
    ultimoImpulso = 0
    track = nil
end)

RunService.Heartbeat:Connect(function()
    local char = player.Character
    if not char then return end

    local hum =
        char:FindFirstChildOfClass("Humanoid")

    local root =
        char:FindFirstChild("HumanoidRootPart")

    if not hum or not root or hum.Health <= 0 then
        pararAnimacao()
        return
    end

    if not segurando then
        pararAnimacao()
        return
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}

    local hit = workspace:Raycast(
        root.Position,
        root.CFrame.LookVector
            * CONFIG.DISTANCIA_PAREDE,
        params
    )

    if not hit or math.abs(hit.Normal.Y) > 0.3 then
        pararAnimacao()
        return
    end

    local agora = os.clock()

    if agora - ultimoImpulso
        >= CONFIG.INTERVALO_IMPULSO then

        ultimoImpulso = agora

        local lateral = 0

        if UIS:IsKeyDown(Enum.KeyCode.A) then
            lateral = -1
        elseif UIS:IsKeyDown(Enum.KeyCode.D) then
            lateral = 1
        end

        local velocidade =
            root.AssemblyLinearVelocity

        local direita =
            root.CFrame.RightVector

        root.AssemblyLinearVelocity =
            Vector3.new(
                velocidade.X,
                CONFIG.IMPULSO_VERTICAL,
                velocidade.Z
            ) + direita
                * lateral
                * CONFIG.IMPULSO_LATERAL

        local animacao = prepararAnimacao(hum)

        if animacao and not animacao.IsPlaying then
            animacao:Play(0.08)
        end
    end
end)

print("[WALL CLIMB V3] ATIVADO")
