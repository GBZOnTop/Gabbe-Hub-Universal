local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera

local PainelAberto = false
local MainGui = nil
local AbaAtual = 1

local AimbotAtivo = false
local ShowFOV = false
local TamanhoFOV = 300
local PrioridadeAtual = "normal"
local ToggleKey = nil
local EsperandoTecla = false

-- Visual flags
local ESPAtivo = false
local TracerAtivo = false
local SkeletonAtivo = false
local NameESPAtivo = false
local ESPColor = Color3.fromRGB(255, 50, 50)
local TeamCheckESP = false
local TeamCheckAimbot = false
local RainbowAtivo = false
local RainbowFOVAtivo = false

-- Player flags
local SpinbotAtivo = false
local SpinbotVelocidade = 10
local WalkSpeedAtual = 16
local JumpPowerAtual = 50
local FlyAtivo = false
local JetpackAtivo = false
local FlyBodyVel = nil
local FlyBodyGyro = nil
local FlyConn = nil
local JetpackConn = nil


local TracerOrigem = "bottom"

local Estados = {
    aimbot = false,
    showfov = false,
    esp = false,
    tracer = false,
    nameesp = false,
    fly = false,
    jetpack = false,
    teamcheckesp = false,
    teamcheckaimbot = false,
    spinbot = false,
    rainbow = false,  -- adiciona essa linha
    rainbowfov = false,
}




-- ===== FOV CIRCLE =====
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "FOVGui"
FOVGui.ResetOnSpawn = false
FOVGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
FOVGui.Parent = Player:WaitForChild("PlayerGui")

local FOVCircle = Instance.new("Frame")
FOVCircle.Size = UDim2.new(0, TamanhoFOV * 2, 0, TamanhoFOV * 2)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = false
FOVCircle.Parent = FOVGui

local FOVUICorner = Instance.new("UICorner")
FOVUICorner.CornerRadius = UDim.new(1, 0)
FOVUICorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Thickness = 2
FOVStroke.Parent = FOVCircle

-- ===== ESP DRAWINGS =====
local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "ESPGui"
ESPGui.ResetOnSpawn = false
ESPGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ESPGui.Parent = Player:WaitForChild("PlayerGui")

local ESPObjects = {}

local function LimparESP(p)
    if ESPObjects[p] then
        for _, obj in pairs(ESPObjects[p]) do
            if obj and obj.Parent then obj:Destroy() end
        end
        ESPObjects[p] = nil
    end
end

local Highlights = {}


task.spawn(function()
    local hue = 0
    while true do
        if RainbowAtivo or RainbowFOVAtivo then
            hue = (hue + 0.005) % 1
            local cor = Color3.fromHSV(hue, 1, 1)

            if RainbowAtivo then
                ESPColor = cor
                for _, objs in pairs(ESPObjects) do
                    if objs.NameLabel then objs.NameLabel.TextColor3 = cor end
                    if objs.Tracer then objs.Tracer.BackgroundColor3 = cor end
                end
                for _, hl in pairs(Highlights) do
                    if hl and hl.Parent then
                        hl.FillColor = cor
                        hl.OutlineColor = cor
                    end
                end
            end

            if RainbowFOVAtivo then
                FOVStroke.Color = cor
            end
        end
        task.wait(0.03)
    end
end)



local function AplicarChams(p)
    if Highlights[p] then return end
    local char = p.Character
    if not char then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = char
    hl.FillColor = ESPColor
    hl.OutlineColor = ESPColor
    hl.FillTransparency = 0.35
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char

    Highlights[p] = hl
end

local function RemoverChams(p)
    if Highlights[p] then
        if Highlights[p].Parent then Highlights[p]:Destroy() end
        Highlights[p] = nil
    end
end

local function CriarESPParaPlayer(p)
    LimparESP(p)
    ESPObjects[p] = {}

    local NameLabel = Instance.new("TextLabel")
    NameLabel.BackgroundTransparency = 1
    NameLabel.TextColor3 = ESPColor
    NameLabel.TextSize = 14
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextStrokeTransparency = 0
    NameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    NameLabel.Visible = false
    NameLabel.Parent = ESPGui

    local Tracer = Instance.new("Frame")
    Tracer.BackgroundColor3 = ESPColor
    Tracer.BorderSizePixel = 0
    Tracer.Visible = false
    Tracer.Parent = ESPGui

    ESPObjects[p] = {
        NameLabel = NameLabel,
        Tracer = Tracer,
    }
end

local SkeletonLines = {}

local function LimparSkeleton(p)
    if SkeletonLines[p] then
        for _, line in pairs(SkeletonLines[p]) do
            if line and line.Parent then line:Destroy() end
        end
        SkeletonLines[p] = nil
    end
end

local SKELETON_CONNECTIONS = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

local function DesenharLinha(gui, x1, y1, x2, y2, cor)
    local dx = x2 - x1
    local dy = y2 - y1
    local len = math.sqrt(dx*dx + dy*dy)
    if len < 1 then return nil end
    local angle = math.atan2(dy, dx)
    local cx = (x1 + x2) / 2
    local cy = (y1 + y2) / 2

    local line = Instance.new("Frame")
    line.BackgroundColor3 = cor
    line.BorderSizePixel = 0
    line.Size = UDim2.new(0, len, 0, 2)
    line.Position = UDim2.new(0, cx - len/2, 0, cy - 1)
    line.Rotation = math.deg(angle)
    line.ZIndex = 5
    line.Parent = gui
    return line
end


-- ===== FLY FUNCTIONS =====
local function IniciarFly()
    local char = Player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    hum.PlatformStand = true

    FlyBodyVel = Instance.new("BodyVelocity")
    FlyBodyVel.Velocity = Vector3.zero
    FlyBodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    FlyBodyVel.Parent = root

    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    FlyBodyGyro.D = 50
    FlyBodyGyro.Parent = root

    local speed = 60

    FlyConn = RunService.RenderStepped:Connect(function()
        if not FlyAtivo or not root or not root.Parent then return end

        local dir = Vector3.zero
        local camCF = Camera.CFrame

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

        if dir.Magnitude > 0 then
            FlyBodyVel.Velocity = dir.Unit * speed
        else
            FlyBodyVel.Velocity = Vector3.zero
        end

        FlyBodyGyro.CFrame = camCF
    end)
end

local function PararFly()
    if FlyConn then FlyConn:Disconnect() FlyConn = nil end
    if FlyBodyVel then FlyBodyVel:Destroy() FlyBodyVel = nil end
    if FlyBodyGyro then FlyBodyGyro:Destroy() FlyBodyGyro = nil end
    local char = Player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end


-- ===== JETPACK FUNCTIONS =====
local function IniciarJetpack()
    JetpackConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.Space and JetpackAtivo then
            local char = Player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local boost = Instance.new("BodyVelocity")
            boost.Velocity = Vector3.new(root.Velocity.X, 80, root.Velocity.Z)
            boost.MaxForce = Vector3.new(0, 1e5, 0)
            boost.Parent = root
            game:GetService("Debris"):AddItem(boost, 0.25)
        end
    end)
end

local function PararJetpack()
    if JetpackConn then JetpackConn:Disconnect() JetpackConn = nil end
end

-- Reaplicar stats no respawn
Player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").WalkSpeed = WalkSpeedAtual
    char:WaitForChild("Humanoid").JumpPower = JumpPowerAtual
    Highlights[Player] = nil
    if FlyAtivo then
        task.wait(0.1)
        IniciarFly()
    end
end)

-- ===== MAIN LOOP =====

local function MesmoTime(p)
    return p.Team ~= nil and Player.Team ~= nil and p.Team == Player.Team
end

RunService.RenderStepped:Connect(function()
    FOVCircle.Size = UDim2.new(0, TamanhoFOV * 2, 0, TamanhoFOV * 2)
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = UDim2.new(0, mousePos.X - TamanhoFOV, 0, mousePos.Y - TamanhoFOV)
    FOVCircle.Visible = ShowFOV

    local ViewportSize = Camera.ViewportSize

    for _, OtherPlayer in ipairs(Players:GetPlayers()) do
        if OtherPlayer == Player then continue end
        if TeamCheckESP and MesmoTime(OtherPlayer) then continue end


        local char = OtherPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not (char and hum and hrp and head) then
            if ESPObjects[OtherPlayer] then
                for _, obj in pairs(ESPObjects[OtherPlayer]) do
                    if obj and obj.Parent then obj.Visible = false end
                end
            end
            LimparSkeleton(OtherPlayer)
            continue
        end

        if not ESPObjects[OtherPlayer] then
            CriarESPParaPlayer(OtherPlayer)
        end

        local objs = ESPObjects[OtherPlayer]
        local screenHRP, visHRP = Camera:WorldToViewportPoint(hrp.Position)
        local onScreen = visHRP

        local headTop = head.Position + Vector3.new(0, head.Size.Y / 2, 0)
        local footPart = char:FindFirstChild("LeftFoot")
                      or char:FindFirstChild("RightFoot")
                      or char:FindFirstChild("Left Leg")
                      or char:FindFirstChild("Right Leg")
                      or hrp

        local footBase = footPart.Position - Vector3.new(0, footPart.Size.Y / 2, 0)
        local screenTop, visTop = Camera:WorldToViewportPoint(headTop)
        local screenBot, visBot = Camera:WorldToViewportPoint(footBase)
        local anyVisible = visTop or visBot

        if ESPAtivo then
            if not Highlights[OtherPlayer] then AplicarChams(OtherPlayer) end
        else
            if Highlights[OtherPlayer] then RemoverChams(OtherPlayer) end
        end

        local uiVisible = onScreen and anyVisible and (NameESPAtivo or TracerAtivo)

        if uiVisible then
            local height = math.abs(screenBot.Y - screenTop.Y)
            local width  = height * 0.55
            local cx     = screenHRP.X
            local ty     = math.min(screenTop.Y, screenBot.Y)

            if NameESPAtivo then
                objs.NameLabel.Visible = true
                objs.NameLabel.Text = OtherPlayer.DisplayName
                objs.NameLabel.TextColor3 = ESPColor
                objs.NameLabel.Size = UDim2.new(0, width + 20, 0, 18)
                objs.NameLabel.Position = UDim2.new(0, cx - (width+20)/2, 0, ty - 20)
            else
                objs.NameLabel.Visible = false
            end

            if TracerAtivo then
                local fx = ViewportSize.X / 2
                local fy
                if TracerOrigem == "top" then
                    fy = 0
                elseif TracerOrigem == "middle" then
                    fy = ViewportSize.Y / 2
                else
                    fy = ViewportSize.Y
                end

                local tx = screenHRP.X
                local ty2 = screenHRP.Y
                local dx = tx - fx
                local dy = ty2 - fy
                local len = math.sqrt(dx*dx + dy*dy)
                if len > 1 then
                    local angle = math.atan2(dy, dx)
                    objs.Tracer.Visible = true
                    objs.Tracer.BackgroundColor3 = ESPColor
                    objs.Tracer.Size = UDim2.new(0, len, 0, 2)
                    objs.Tracer.Position = UDim2.new(0, (fx + tx)/2 - len/2, 0, (fy + ty2)/2 - 1)
                    objs.Tracer.Rotation = math.deg(angle)
                end
            else
                objs.Tracer.Visible = false
            end
        else
            for _, obj in pairs(objs) do
                if obj and typeof(obj) == "Instance" and obj:IsA("GuiObject") then
                    obj.Visible = false
                end
            end
        end

        LimparSkeleton(OtherPlayer)
        if SkeletonAtivo and onScreen then
            SkeletonLines[OtherPlayer] = {}
            for _, conn in ipairs(SKELETON_CONNECTIONS) do
                local p1 = char:FindFirstChild(conn[1])
                local p2 = char:FindFirstChild(conn[2])
                if p1 and p2 then
                    local s1, v1 = Camera:WorldToViewportPoint(p1.Position)
                    local s2, v2 = Camera:WorldToViewportPoint(p2.Position)
                    if v1 and v2 then
                        local line = DesenharLinha(ESPGui, s1.X, s1.Y, s2.X, s2.Y, ESPColor)
                        if line then
                            table.insert(SkeletonLines[OtherPlayer], line)
                        end
                    end
                end
            end
        end
    end

    -- Aimbot
   -- Aimbot
    if AimbotAtivo then
        local ClosestPlayer = nil
        local ClosestDistance = math.huge
        local ClosestWorldDistance = math.huge

        for _, OtherPlayer in ipairs(Players:GetPlayers()) do
            if OtherPlayer ~= Player and OtherPlayer.Character then
            if TeamCheckAimbot and MesmoTime(OtherPlayer) then continue end
                local Character = OtherPlayer.Character
                local Head = Character:FindFirstChild("Head")
                local Humanoid = Character:FindFirstChild("Humanoid")
                if Head and Humanoid and Humanoid.Health > 0 then
                    local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
                    if OnScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local DistFromMouse = (Vector2.new(ScreenPos.X, ScreenPos.Y) - mousePos).Magnitude
                        if DistFromMouse <= TamanhoFOV then
                            if PrioridadeAtual == "normal" then
                                if DistFromMouse < ClosestDistance then
                                    ClosestDistance = DistFromMouse
                                    ClosestPlayer = OtherPlayer
                                end
                            elseif PrioridadeAtual == "distance" then
                                local MyChar = Player.Character
                                local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
                                if MyRoot then
                                    local WorldDist = (Head.Position - MyRoot.Position).Magnitude
                                    if WorldDist < ClosestWorldDistance then
                                        ClosestWorldDistance = WorldDist
                                        ClosestPlayer = OtherPlayer
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if ClosestPlayer and ClosestPlayer.Character then
            local Head = ClosestPlayer.Character:FindFirstChild("Head")
            local Humanoid = ClosestPlayer.Character:FindFirstChild("Humanoid")
            if Head and Humanoid and Humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(Head.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local deltaX = screenPos.X - mousePos.X
                    local deltaY = screenPos.Y - mousePos.Y
                    if math.abs(deltaX) < TamanhoFOV and math.abs(deltaY) < TamanhoFOV then
                        mousemoverel(deltaX / 2, deltaY / 2)
                    end
                end
            end
        end
    end
    
     -- SPINBOT (aqui, fora do aimbot mas dentro do RenderStepped)
    if SpinbotAtivo then
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SpinbotVelocidade), 0)
        end
    end  -- fecha o if AimbotAtivo
end)        -- fecha o RenderStepped


Players.PlayerRemoving:Connect(function(p)
    RemoverChams(p)
    LimparESP(p)
    LimparSkeleton(p)
end)

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        Highlights[p] = nil
        if ESPAtivo and not (TeamCheckESP and MesmoTime(p)) then
            task.wait(0.1)
            AplicarChams(p)
        end
    end)
end)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= Player then
        p.CharacterAdded:Connect(function()
            Highlights[p] = nil
            if ESPAtivo and not (TeamCheckESP and MesmoTime(p)) then
                task.wait(0.1)
                AplicarChams(p)
            end
        end)
    end
end
-- ===== TOGGLE KEY LISTENER =====
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Insert then
        if not PainelAberto then
            CriarPainel()
            PainelAberto = true
        else
            if MainGui then MainGui:Destroy() end
            MainGui = nil
            PainelAberto = false
        end
        return
    end

    if EsperandoTecla then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            ToggleKey = input.KeyCode
            EsperandoTecla = false
        end
        return
    end

if ToggleKey and input.KeyCode == ToggleKey then
    Estados["aimbot"] = not Estados["aimbot"]
    AimbotAtivo = Estados["aimbot"]
end
end)  -- fecha o InputBegan

-- ===== PAINEL =====
function CriarPainel()
    if MainGui then MainGui:Destroy() end

    MainGui = Instance.new("ScreenGui")
    MainGui.Name = "PainelGabbe"
    MainGui.ResetOnSpawn = false
    MainGui.Parent = Player:WaitForChild("PlayerGui")

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 600, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.ZIndex = 100
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = MainGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 15)
    Corner.Parent = MainFrame

    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 60)
    Header.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    Header.BorderSizePixel = 0
    Header.ZIndex = 101
    Header.Parent = MainFrame

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 15)
    HeaderCorner.Parent = Header

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "PAINEL UNIVERSAL GABBE"
    Title.TextColor3 = Color3.fromRGB(0, 200, 255)
    Title.TextSize = 20
    Title.Font = Enum.Font.GothamBold
    Title.ZIndex = 102
    Title.Parent = Header

local BtnMinimizar = Instance.new("TextButton")
BtnMinimizar.Size = UDim2.new(0, 35, 0, 35)
BtnMinimizar.Position = UDim2.new(1, -85, 0.5, -17)
BtnMinimizar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
BtnMinimizar.TextColor3 = Color3.fromRGB(0, 200, 255)
BtnMinimizar.Text = "—"
BtnMinimizar.TextSize = 16
BtnMinimizar.Font = Enum.Font.GothamBold
BtnMinimizar.BorderSizePixel = 0
BtnMinimizar.ZIndex = 103
BtnMinimizar.Parent = Header

local BtnFechar = Instance.new("TextButton")
BtnFechar.Size = UDim2.new(0, 35, 0, 35)
BtnFechar.Position = UDim2.new(1, -45, 0.5, -17)
BtnFechar.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
BtnFechar.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnFechar.Text = "X"
BtnFechar.TextSize = 16
BtnFechar.Font = Enum.Font.GothamBold
BtnFechar.BorderSizePixel = 0
BtnFechar.ZIndex = 103
BtnFechar.Parent = Header

local BtnFecharCorner = Instance.new("UICorner")
BtnFecharCorner.CornerRadius = UDim.new(0, 6)
BtnFecharCorner.Parent = BtnFechar

BtnFechar.MouseButton1Click:Connect(function()
    -- Desliga tudo
    AimbotAtivo = false
    ShowFOV = false
    ESPAtivo = false
    TracerAtivo = false
    NameESPAtivo = false
    SpinbotAtivo = false
    RainbowAtivo = false
    RainbowFOVAtivo = false
    TeamCheckESP = false
    TeamCheckAimbot = false
    FOVCircle.Visible = false
    FOVStroke.Color = Color3.fromRGB(255, 255, 255)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            RemoverChams(p)
            LimparESP(p)
        end
    end
    if FlyAtivo then PararFly() end
    if JetpackAtivo then PararJetpack() end
    FlyAtivo = false
    JetpackAtivo = false
    for k in pairs(Estados) do Estados[k] = false end

    MainGui:Destroy()
    MainGui = nil
    PainelAberto = false
end)

local BtnMinCorner = Instance.new("UICorner")
BtnMinCorner.CornerRadius = UDim.new(0, 6)
BtnMinCorner.Parent = BtnMinimizar

local minimizado = false

BtnMinimizar.MouseButton1Click:Connect(function()
    minimizado = not minimizado
    if minimizado then
        MainFrame.Size = UDim2.new(0, 600, 0, 60)
        BtnMinimizar.Text = "▼"
        TabsFrame.Visible = false
        ContentFrame.Visible = false
    else
        MainFrame.Size = UDim2.new(0, 600, 0, 500)
        BtnMinimizar.Text = "—"
        TabsFrame.Visible = true
        ContentFrame.Visible = true
    end
end)


    local TabsFrame = Instance.new("Frame")
    TabsFrame.Size = UDim2.new(1, 0, 0, 50)
    TabsFrame.Position = UDim2.new(0, 0, 0, 60)
    TabsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    TabsFrame.BorderSizePixel = 0
    TabsFrame.ZIndex = 101
    TabsFrame.Parent = MainFrame

    local TabsGrid = Instance.new("UIGridLayout")
    TabsGrid.CellSize = UDim2.new(1/3, -5, 1, -5)
    TabsGrid.CellPadding = UDim2.new(0, 5, 0, 5)
    TabsGrid.Parent = TabsFrame

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, 0, 1, -110)
    ContentFrame.Position = UDim2.new(0, 0, 0, 110)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ZIndex = 100
    ContentFrame.Parent = MainFrame

    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingLeft = UDim.new(0, 15)
    ContentPadding.PaddingRight = UDim.new(0, 15)
    ContentPadding.PaddingTop = UDim.new(0, 15)
    ContentPadding.PaddingBottom = UDim.new(0, 15)
    ContentPadding.Parent = ContentFrame

    local TabNames = {"AIMBOT🎯", "VISUAL👁", "PLAYER🥶"}
    local TabButtons = {}
    local TabContents = {}

    for i, TabName in ipairs(TabNames) do
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = TabName
        TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        TabBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
        TabBtn.Text = TabName
        TabBtn.TextSize = 14
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.BorderSizePixel = 0
        TabBtn.ZIndex = 102
        TabBtn.Parent = TabsFrame

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 8)
        BtnCorner.Parent = TabBtn

        if i == AbaAtual then
            TabBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
            TabBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
        end

        local Content = Instance.new("Frame")
        Content.Name = "Content_" .. TabName
        Content.Size = UDim2.new(1, 0, 1, 0)
        Content.BackgroundTransparency = 1
        Content.ZIndex = 100
        Content.Visible = (i == AbaAtual)
        Content.Parent = ContentFrame

        local ScrollList = Instance.new("ScrollingFrame")
        ScrollList.Size = UDim2.new(1, 0, 1, 0)
        ScrollList.BackgroundTransparency = 1
        ScrollList.BorderSizePixel = 0
        ScrollList.ZIndex = 100
        ScrollList.ScrollBarThickness = 8
        ScrollList.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 200)
        ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
        ScrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y
        ScrollList.Parent = Content

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 12)
        ListLayout.Parent = ScrollList

        table.insert(TabButtons, TabBtn)
        table.insert(TabContents, {Frame = Content, List = ScrollList})

        TabBtn.MouseButton1Click:Connect(function()
            AbaAtual = i
            for j, btn in ipairs(TabButtons) do
                if j == i then
                    btn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
                    btn.TextColor3 = Color3.fromRGB(0, 200, 255)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                    btn.TextColor3 = Color3.fromRGB(100, 100, 100)
                end
            end
            for j, tab in ipairs(TabContents) do
                tab.Frame.Visible = (j == i)
            end
        end)
    end

    local AimbotList = TabContents[1].List
    local VisualList = TabContents[2].List
    local PlayerList = TabContents[3].List

    -- ===== FUNÇÃO TOGGLE GENÉRICA =====
    local function CriarToggle(lista, nome, variavel, callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 45)
        Container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Container.BorderSizePixel = 0
        Container.ZIndex = 101
        Container.Parent = lista

        local ContainerCorner = Instance.new("UICorner")
        ContainerCorner.CornerRadius = UDim.new(0, 8)
        ContainerCorner.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.6, -10, 1, 0)
        Label.Position = UDim2.new(0, 10, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = nome
        Label.TextColor3 = Color3.fromRGB(200, 200, 200)
        Label.TextSize = 14
        Label.Font = Enum.Font.GothamBold
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 102
        Label.Parent = Container

        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0, 80, 0, 30)
        Button.Position = UDim2.new(1, -90, 0.5, -15)
        Button.BorderSizePixel = 0
        Button.TextSize = 13
        Button.Font = Enum.Font.GothamBold
        Button.ZIndex = 103
        Button.Parent = Container

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 6)
        BtnCorner.Parent = Button

        local function AtualizarVisual(estado)
            if estado then
                Button.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                Button.Text = "ON"
            else
                Button.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                Button.Text = "OFF"
            end
        end

        AtualizarVisual(Estados[variavel])

        Button.MouseButton1Click:Connect(function()
            Estados[variavel] = not Estados[variavel]
            AtualizarVisual(Estados[variavel])
            if callback then callback(Estados[variavel]) end
        end)

        return Container
    end

    -- ===== SLIDER GENÉRICO =====
    local function CriarSlider(lista, nome, minVal, maxVal, valorAtual, onChange)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 70)
        Container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Container.BorderSizePixel = 0
        Container.ZIndex = 101
        Container.Parent = lista

        local ContainerCorner = Instance.new("UICorner")
        ContainerCorner.CornerRadius = UDim.new(0, 8)
        ContainerCorner.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -10, 0, 25)
        Label.Position = UDim2.new(0, 10, 0, 5)
        Label.BackgroundTransparency = 1
        Label.Text = nome .. ": " .. valorAtual
        Label.TextColor3 = Color3.fromRGB(200, 200, 200)
        Label.TextSize = 14
        Label.Font = Enum.Font.GothamBold
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 102
        Label.Parent = Container

        local SliderBG = Instance.new("Frame")
        SliderBG.Size = UDim2.new(1, -20, 0, 12)
        SliderBG.Position = UDim2.new(0, 10, 0, 38)
        SliderBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        SliderBG.BorderSizePixel = 0
        SliderBG.ZIndex = 102
        SliderBG.Parent = Container

        local SliderCorner = Instance.new("UICorner")
        SliderCorner.CornerRadius = UDim.new(0, 6)
        SliderCorner.Parent = SliderBG

        local SliderFill = Instance.new("Frame")
        SliderFill.Size = UDim2.new((valorAtual - minVal) / (maxVal - minVal), 0, 1, 0)
        SliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        SliderFill.BorderSizePixel = 0
        SliderFill.ZIndex = 103
        SliderFill.Parent = SliderBG

        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(0, 6)
        FillCorner.Parent = SliderFill

        local isDragging = false

        SliderBG.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = true
                local relX = math.clamp(Mouse.X - SliderBG.AbsolutePosition.X, 0, SliderBG.AbsoluteSize.X)
                local pct = relX / SliderBG.AbsoluteSize.X
                local val = math.floor(minVal + (pct * (maxVal - minVal)))
                SliderFill.Size = UDim2.new(pct, 0, 1, 0)
                Label.Text = nome .. ": " .. val
                if onChange then onChange(val) end
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local relX = math.clamp(Mouse.X - SliderBG.AbsolutePosition.X, 0, SliderBG.AbsoluteSize.X)
                local pct = relX / SliderBG.AbsoluteSize.X
                local val = math.floor(minVal + (pct * (maxVal - minVal)))
                SliderFill.Size = UDim2.new(pct, 0, 1, 0)
                Label.Text = nome .. ": " .. val
                if onChange then onChange(val) end
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = false
            end
        end)

        return Container
    end

    -- ===== TRACER SPAWN =====
    local function CriarTracerSpawn(lista)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 45)
        Container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Container.BorderSizePixel = 0
        Container.ZIndex = 101
        Container.ClipsDescendants = true
        Container.Parent = lista

        local ContainerCorner = Instance.new("UICorner")
        ContainerCorner.CornerRadius = UDim.new(0, 8)
        ContainerCorner.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.6, -10, 0, 45)
        Label.Position = UDim2.new(0, 10, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = "Tracer Spawn"
        Label.TextColor3 = Color3.fromRGB(200, 200, 200)
        Label.TextSize = 14
        Label.Font = Enum.Font.GothamBold
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 102
        Label.Parent = Container

        local DropBtn = Instance.new("TextButton")
        DropBtn.Size = UDim2.new(0, 110, 0, 30)
        DropBtn.Position = UDim2.new(1, -120, 0, 7)
        DropBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
        DropBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
        DropBtn.TextSize = 13
        DropBtn.Font = Enum.Font.GothamBold
        DropBtn.BorderSizePixel = 0
        DropBtn.ZIndex = 103
        DropBtn.Parent = Container

        local DropBtnCorner = Instance.new("UICorner")
        DropBtnCorner.CornerRadius = UDim.new(0, 6)
        DropBtnCorner.Parent = DropBtn

        local opcoes = {
            {label = "Cima",  valor = "top"},
            {label = "Meio",  valor = "middle"},
            {label = "Baixo", valor = "bottom"},
        }

        local SubBtns = {}
        for idx, op in ipairs(opcoes) do
            local SubBtn = Instance.new("TextButton")
            SubBtn.Size = UDim2.new(1, -20, 0, 34)
            SubBtn.Position = UDim2.new(0, 10, 0, 45 + (idx - 1) * 38)
            SubBtn.BorderSizePixel = 0
            SubBtn.TextSize = 13
            SubBtn.Font = Enum.Font.GothamBold
            SubBtn.Text = op.label
            SubBtn.ZIndex = 103
            SubBtn.Parent = Container

            local SubCorner = Instance.new("UICorner")
            SubCorner.CornerRadius = UDim.new(0, 6)
            SubCorner.Parent = SubBtn

            SubBtns[idx] = SubBtn
        end

        local expanded = false

        local function AtualizarSubBtns()
            for idx, op in ipairs(opcoes) do
                if op.valor == TracerOrigem then
                    SubBtns[idx].BackgroundColor3 = Color3.fromRGB(0, 120, 200)
                    SubBtns[idx].TextColor3 = Color3.fromRGB(0, 200, 255)
                else
                    SubBtns[idx].BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    SubBtns[idx].TextColor3 = Color3.fromRGB(160, 160, 160)
                end
            end
        end

        local function AtualizarDropLabel()
            local nomes = {top = "Cima", middle = "Meio", bottom = "Baixo"}
            DropBtn.Text = (expanded and "▲ " or "▼ ") .. (nomes[TracerOrigem] or "Baixo")
        end

        AtualizarSubBtns()
        AtualizarDropLabel()

        local alturaExpandida = 45 + #opcoes * 38 + 8
        local alturaColapsada = 45

        DropBtn.MouseButton1Click:Connect(function()
            expanded = not expanded
            Container.Size = UDim2.new(1, 0, 0, expanded and alturaExpandida or alturaColapsada)
            AtualizarDropLabel()
        end)

        for idx, op in ipairs(opcoes) do
            SubBtns[idx].MouseButton1Click:Connect(function()
                TracerOrigem = op.valor
                expanded = false
                Container.Size = UDim2.new(1, 0, 0, alturaColapsada)
                AtualizarSubBtns()
                AtualizarDropLabel()
            end)
        end

        return Container
    end

    -- ===== ESP COLOR PICKER =====
    local function CriarESPColors(lista)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 120)
        Container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Container.BorderSizePixel = 0
        Container.ZIndex = 101
        Container.Parent = lista

        local ContainerCorner = Instance.new("UICorner")
        ContainerCorner.CornerRadius = UDim.new(0, 8)
        ContainerCorner.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -10, 0, 25)
        Label.Position = UDim2.new(0, 10, 0, 5)
        Label.BackgroundTransparency = 1
        Label.Text = "ESP Colors"
        Label.TextColor3 = Color3.fromRGB(200, 200, 200)
        Label.TextSize = 14
        Label.Font = Enum.Font.GothamBold
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 102
        Label.Parent = Container

        local Preview = Instance.new("Frame")
        Preview.Size = UDim2.new(0, 40, 0, 25)
        Preview.Position = UDim2.new(1, -50, 0, 5)
        Preview.BackgroundColor3 = ESPColor
        Preview.BorderSizePixel = 0
        Preview.ZIndex = 103
        Preview.Parent = Container

        local PreviewCorner = Instance.new("UICorner")
        PreviewCorner.CornerRadius = UDim.new(0, 6)
        PreviewCorner.Parent = Preview

        local cores = {"R", "G", "B"}
        local valores = {ESPColor.R * 255, ESPColor.G * 255, ESPColor.B * 255}

        local function AtualizarCor()
            ESPColor = Color3.fromRGB(math.floor(valores[1]), math.floor(valores[2]), math.floor(valores[3]))
            Preview.BackgroundColor3 = ESPColor
            for _, objs in pairs(ESPObjects) do
                if objs.NameLabel then objs.NameLabel.TextColor3 = ESPColor end
                if objs.Tracer then objs.Tracer.BackgroundColor3 = ESPColor end
            end
            for _, hl in pairs(Highlights) do
                if hl and hl.Parent then
                    hl.FillColor = ESPColor
                    hl.OutlineColor = ESPColor
                end
            end
        end

        for idx, cor in ipairs(cores) do
            local SliderRow = Instance.new("Frame")
            SliderRow.Size = UDim2.new(1, -20, 0, 20)
            SliderRow.Position = UDim2.new(0, 10, 0, 30 + (idx - 1) * 28)
            SliderRow.BackgroundTransparency = 1
            SliderRow.ZIndex = 102
            SliderRow.Parent = Container

            local CorLabel = Instance.new("TextLabel")
            CorLabel.Size = UDim2.new(0, 15, 1, 0)
            CorLabel.BackgroundTransparency = 1
            CorLabel.Text = cor
            CorLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            CorLabel.TextSize = 13
            CorLabel.Font = Enum.Font.GothamBold
            CorLabel.ZIndex = 103
            CorLabel.Parent = SliderRow

            local SliderBG = Instance.new("Frame")
            SliderBG.Size = UDim2.new(1, -50, 1, 0)
            SliderBG.Position = UDim2.new(0, 20, 0, 0)
            SliderBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            SliderBG.BorderSizePixel = 0
            SliderBG.ZIndex = 103
            SliderBG.Parent = SliderRow

            local SliderCorner = Instance.new("UICorner")
            SliderCorner.CornerRadius = UDim.new(0, 4)
            SliderCorner.Parent = SliderBG

            local SliderFill = Instance.new("Frame")
            SliderFill.Size = UDim2.new(valores[idx] / 255, 0, 1, 0)
            SliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
            SliderFill.BorderSizePixel = 0
            SliderFill.ZIndex = 104
            SliderFill.Parent = SliderBG

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(0, 4)
            FillCorner.Parent = SliderFill

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Size = UDim2.new(0, 28, 1, 0)
            ValLabel.Position = UDim2.new(1, -28, 0, 0)
            ValLabel.BackgroundTransparency = 1
            ValLabel.Text = tostring(math.floor(valores[idx]))
            ValLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            ValLabel.TextSize = 11
            ValLabel.Font = Enum.Font.Gotham
            ValLabel.ZIndex = 103
            ValLabel.Parent = SliderRow

            local isDragging = false
            local capturedIdx = idx

            SliderBG.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    isDragging = true
                    local relX = math.clamp(Mouse.X - SliderBG.AbsolutePosition.X, 0, SliderBG.AbsoluteSize.X)
                    local pct = relX / SliderBG.AbsoluteSize.X
                    valores[capturedIdx] = pct * 255
                    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
                    ValLabel.Text = tostring(math.floor(valores[capturedIdx]))
                    AtualizarCor()
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local relX = math.clamp(Mouse.X - SliderBG.AbsolutePosition.X, 0, SliderBG.AbsoluteSize.X)
                    local pct = relX / SliderBG.AbsoluteSize.X
                    valores[capturedIdx] = pct * 255
                    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
                    ValLabel.Text = tostring(math.floor(valores[capturedIdx]))
                    AtualizarCor()
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    isDragging = false
                end
            end)
        end

        return Container
    end

    -- ===== PRIORITY =====
    local function CriarPriority()
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 75)
        Container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Container.BorderSizePixel = 0
        Container.ZIndex = 101
        Container.Parent = AimbotList

        local ContainerCorner = Instance.new("UICorner")
        ContainerCorner.CornerRadius = UDim.new(0, 8)
        ContainerCorner.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -10, 0, 25)
        Label.Position = UDim2.new(0, 10, 0, 5)
        Label.BackgroundTransparency = 1
        Label.Text = "Priority"
        Label.TextColor3 = Color3.fromRGB(200, 200, 200)
        Label.TextSize = 14
        Label.Font = Enum.Font.GothamBold
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 102
        Label.Parent = Container

        local BtnNormal = Instance.new("TextButton")
        BtnNormal.Size = UDim2.new(0.45, 0, 0, 30)
        BtnNormal.Position = UDim2.new(0, 10, 0, 35)
        BtnNormal.Text = "Normal"
        BtnNormal.TextSize = 13
        BtnNormal.Font = Enum.Font.GothamBold
        BtnNormal.BorderSizePixel = 0
        BtnNormal.ZIndex = 103
        BtnNormal.Parent = Container

        local NormalCorner = Instance.new("UICorner")
        NormalCorner.CornerRadius = UDim.new(0, 6)
        NormalCorner.Parent = BtnNormal

        local BtnDistance = Instance.new("TextButton")
        BtnDistance.Size = UDim2.new(0.45, 0, 0, 30)
        BtnDistance.Position = UDim2.new(0.52, 0, 0, 35)
        BtnDistance.Text = "Distance"
        BtnDistance.TextSize = 13
        BtnDistance.Font = Enum.Font.GothamBold
        BtnDistance.BorderSizePixel = 0
        BtnDistance.ZIndex = 103
        BtnDistance.Parent = Container

        local DistanceCorner = Instance.new("UICorner")
        DistanceCorner.CornerRadius = UDim.new(0, 6)
        DistanceCorner.Parent = BtnDistance

        local function AtualizarPriority()
            if PrioridadeAtual == "normal" then
                BtnNormal.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
                BtnNormal.TextColor3 = Color3.fromRGB(0, 200, 255)
                BtnDistance.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                BtnDistance.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                BtnDistance.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
                BtnDistance.TextColor3 = Color3.fromRGB(0, 200, 255)
                BtnNormal.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                BtnNormal.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end

        AtualizarPriority()
        BtnNormal.MouseButton1Click:Connect(function() PrioridadeAtual = "normal" AtualizarPriority() end)
        BtnDistance.MouseButton1Click:Connect(function() PrioridadeAtual = "distance" AtualizarPriority() end)

        return Container
    end

    -- ===== TOGGLE KEY =====
    local function CriarToggleKey()
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, 0, 0, 75)
        Container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Container.BorderSizePixel = 0
        Container.ZIndex = 101
        Container.Parent = AimbotList

        local ContainerCorner = Instance.new("UICorner")
        ContainerCorner.CornerRadius = UDim.new(0, 8)
        ContainerCorner.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -10, 0, 25)
        Label.Position = UDim2.new(0, 10, 0, 5)
        Label.BackgroundTransparency = 1
        Label.Text = "Toggle Key"
        Label.TextColor3 = Color3.fromRGB(200, 200, 200)
        Label.TextSize = 14
        Label.Font = Enum.Font.GothamBold
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 102
        Label.Parent = Container

        local KeyDisplay = Instance.new("TextButton")
        KeyDisplay.Size = UDim2.new(0.55, 0, 0, 30)
        KeyDisplay.Position = UDim2.new(0, 10, 0, 38)
        KeyDisplay.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        KeyDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
        KeyDisplay.Text = ToggleKey and tostring(ToggleKey):gsub("Enum.KeyCode.", "") or "Nenhuma"
        KeyDisplay.TextSize = 13
        KeyDisplay.Font = Enum.Font.GothamBold
        KeyDisplay.BorderSizePixel = 0
        KeyDisplay.ZIndex = 103
        KeyDisplay.Parent = Container

        local KeyDisplayCorner = Instance.new("UICorner")
        KeyDisplayCorner.CornerRadius = UDim.new(0, 6)
        KeyDisplayCorner.Parent = KeyDisplay

        local BtnCapturar = Instance.new("TextButton")
        BtnCapturar.Size = UDim2.new(0.35, 0, 0, 30)
        BtnCapturar.Position = UDim2.new(0.62, 0, 0, 38)
        BtnCapturar.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
        BtnCapturar.TextColor3 = Color3.fromRGB(255, 255, 255)
        BtnCapturar.Text = "Definir"
        BtnCapturar.TextSize = 13
        BtnCapturar.Font = Enum.Font.GothamBold
        BtnCapturar.BorderSizePixel = 0
        BtnCapturar.ZIndex = 103
        BtnCapturar.Parent = Container

        local BtnCapturarCorner = Instance.new("UICorner")
        BtnCapturarCorner.CornerRadius = UDim.new(0, 6)
        BtnCapturarCorner.Parent = BtnCapturar

        BtnCapturar.MouseButton1Click:Connect(function()
            EsperandoTecla = true
            BtnCapturar.Text = "..."
            BtnCapturar.BackgroundColor3 = Color3.fromRGB(180, 120, 0)
            KeyDisplay.Text = "Pressione"

            local conn
            conn = RunService.Heartbeat:Connect(function()
                if not EsperandoTecla then
                    conn:Disconnect()
                    BtnCapturar.Text = "Definir"
                    BtnCapturar.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
                    KeyDisplay.Text = ToggleKey and tostring(ToggleKey):gsub("Enum.KeyCode.", "") or "Nenhuma"
                end
            end)
        end)

        return Container
    end

    -- ===== MONTAR ABAS =====

    -- AIMBOT
    CriarToggle(AimbotList, "Aimbot", "aimbot", function(v) AimbotAtivo = v end)
    CriarToggle(AimbotList, "Team Check", "teamcheckaimbot", function(v) TeamCheckAimbot = v end)
    CriarToggle(AimbotList, "Show FOV Aimbot", "showfov", function(v) ShowFOV = v end)
    CriarPriority()
    CriarToggleKey()
    CriarSlider(AimbotList, "Tamanho FOV", 50, 550, TamanhoFOV, function(v) TamanhoFOV = v end)
    CriarToggle(AimbotList, "Rainbow FOV", "rainbowfov", function(v)
    RainbowFOVAtivo = v
    if not v then
        FOVStroke.Color = Color3.fromRGB(255, 255, 255)
    end
end)

    -- VISUAL
    CriarToggle(VisualList, "ESP", "esp", function(v)
        ESPAtivo = v
        if not v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player then RemoverChams(p) end
            end
        end
    end)
   CriarToggle(VisualList, "Team Check", "teamcheckesp", function(v)
    TeamCheckESP = v
    if v then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and MesmoTime(p) then
                RemoverChams(p)
                LimparESP(p)
            end
        end
    end
end)
    CriarToggle(VisualList, "Tracer", "tracer", function(v) TracerAtivo = v end)
    CriarTracerSpawn(VisualList)
    CriarToggle(VisualList, "Name ESP", "nameesp", function(v) NameESPAtivo = v end)
    CriarESPColors(VisualList)
   CriarToggle(VisualList, "Rainbow ESP", "rainbow", function(v)
    RainbowAtivo = v
end)



    -- PLAYER

CriarToggle(PlayerList, "Spinbot", "spinbot", function(v) SpinbotAtivo = v end)
CriarSlider(PlayerList, "Velocidade Spin", 1, 50, SpinbotVelocidade, function(v) SpinbotVelocidade = v end)

    CriarSlider(PlayerList, "WalkSpeed", 16, 500, WalkSpeedAtual, function(v)
        WalkSpeedAtual = v
        local char = Player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = v
        end
    end)
    CriarSlider(PlayerList, "JumpPower", 50, 500, JumpPowerAtual, function(v)
        JumpPowerAtual = v
        local char = Player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = v
        end
    end)
    CriarToggle(PlayerList, "Fly  (W/A/S/D + Espaço)", "fly", function(v)
        FlyAtivo = v
        if v then IniciarFly() else PararFly() end
    end)
    CriarToggle(PlayerList, "Jetpack  (Espaço = boost)", "jetpack", function(v)
        JetpackAtivo = v
        if v then IniciarJetpack() else PararJetpack() end
    end)

    

    -- ===== DRAG =====
    local dragging = false
    local dragStart = nil
    local startPos = nil

  Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = Vector2.new(Mouse.X, Mouse.Y)
        startPos = MainFrame.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = Vector2.new(Mouse.X, Mouse.Y) - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    Mouse.Move:Connect(function()
        if dragging and dragStart then
            local delta = Mouse.Position - dragStart
            MainFrame.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
        end
    end)
end


print("✅ Painel GABBE carregado!")

task.spawn(function()
    local TweenService = game:GetService("TweenService")

    local IntroGui = Instance.new("ScreenGui")
    IntroGui.Name = "IntroGabbe"
    IntroGui.ResetOnSpawn = false
    IntroGui.Parent = Player:WaitForChild("PlayerGui")

    local IntroLabel = Instance.new("TextLabel")
    IntroLabel.Size = UDim2.new(1, 0, 0, 60)
    IntroLabel.Position = UDim2.new(0, 0, 0.5, -30)
    IntroLabel.BackgroundTransparency = 1
    IntroLabel.Text = "PAINEL UNIVERSAL GABBE"
    IntroLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    IntroLabel.TextSize = 24
    IntroLabel.Font = Enum.Font.GothamBold
    IntroLabel.TextTransparency = 1
    IntroLabel.Parent = IntroGui

    -- Fade in do título
    TweenService:Create(IntroLabel, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()
    task.wait(1.2)

    -- Abre o painel
    CriarPainel()
    PainelAberto = true

    local MainFrame = MainGui:FindFirstChild("MainFrame")
    if MainFrame then
        -- Começa acima do centro e invisível
        MainFrame.Position = UDim2.new(0.5, -300, 0.5, -220)

        -- Slide down + fade in
        TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -300, 0.5, -250),
        }):Play()
    end

    -- Fade out do título
    task.wait(0.3)
    TweenService:Create(IntroLabel, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    task.wait(0.4)
    IntroGui:Destroy()
end)
