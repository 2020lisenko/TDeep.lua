local Player = {}
Player.__index = Player

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

function Player:Initialize(Tab)
    local self = setmetatable({}, Player)

    self.LocalPlayer = Players.LocalPlayer
    self.Connections = {}
    self.noclipEnabled = false
    self.InfiniteJumpEnabled = false
    self.flySpeed = 50

    -- сохраняем текущие значения слайдеров для восстановления при респавне
    self.currentWalkSpeed = 16
    self.currentJumpHeight = 7.2

    -- таблица для сохранения оригинальных CanCollide каждой части при ноклипе
    self.originalCanCollide = {}

    -- Loop-фичи
    self.loopWalkEnabled = false
    self.loopJumpEnabled = false
    self.loopWalkConnection = nil
    self.loopJumpConnection = nil

    local Movement = Tab:AddLeftGroupbox("Movement")

    Movement:AddSlider("WalkSpeed", {
        Text = "Walk Speed",
        Default = 16,
        Min = 1,
        Max = 200,
        Rounding = 0,
        Callback = function(v)
            self.currentWalkSpeed = v
            local char = self.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = v
            end
        end
    })

    -- Loop WalkSpeed: переприменяет скорость каждый кадр,
    -- чтобы игра не могла сбросить её обратно
    local LoopWalkToggle = Movement:AddToggle("LoopWalkSpeed", {
        Text = "Loop Walk Speed",
        Default = false,
        Callback = function(v)
            self.loopWalkEnabled = v
            if v then
                self:StartLoopWalk()
            else
                self:StopLoopWalk()
            end
        end
    })

    LoopWalkToggle:AddKeyPicker("LoopWalkKeybind", {
        Text = "Loop Walk Keybind",
        Default = "None",
        Mode = "Toggle",
        SyncToggleState = true,
        Callback = function(v)
            self.loopWalkEnabled = v
            if v then
                self:StartLoopWalk()
            else
                self:StopLoopWalk()
            end
        end
    })

    Movement:AddSlider("JumpHeight", {
        Text = "Jump Height",
        Default = 7.2,
        Min = 1,
        Max = 50,
        Rounding = 1,
        Callback = function(v)
            self.currentJumpHeight = v
            local char = self.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.JumpHeight = v
            end
        end
    })

    -- Loop Jump: автоматически прыгает каждый раз как только персонаж приземляется
    local LoopJumpToggle = Movement:AddToggle("LoopJump", {
        Text = "Loop Jump",
        Default = false,
        Callback = function(v)
            self.loopJumpEnabled = v
            if v then
                self:StartLoopJump()
            else
                self:StopLoopJump()
            end
        end
    })

    LoopJumpToggle:AddKeyPicker("LoopJumpKeybind", {
        Text = "Loop Jump Keybind",
        Default = "None",
        Mode = "Toggle",
        SyncToggleState = true,
        Callback = function(v)
            self.loopJumpEnabled = v
            if v then
                self:StartLoopJump()
            else
                self:StopLoopJump()
            end
        end
    })

    local Character = Tab:AddLeftGroupbox("Character")

    local FlyToggle = Character:AddToggle("Fly", {
        Text = "Fly",
        Default = false,
        Callback = function(v)
            if v then
                self:StartFly()
            else
                self:StopFly()
            end
        end
    })

    FlyToggle:AddKeyPicker("FlyKeybind", {
        Text = "Fly Keybind",
        Default = "F",
        Mode = "Toggle",
        SyncToggleState = true,
        Callback = function(v)
            if v then
                self:StartFly()
            else
                self:StopFly()
            end
        end
    })

    Character:AddSlider("FlySpeed", {
        Text = "Fly Speed",
        Default = 50,
        Min = 10,
        Max = 200,
        Rounding = 0,
        Callback = function(v)
            self.flySpeed = v
        end
    })

    local NoclipToggle = Character:AddToggle("Noclip", {
        Text = "Noclip",
        Default = false,
        Callback = function(v)
            self.noclipEnabled = v
            if v then
                self:StartNoclip()
            else
                self:StopNoclip()
            end
        end
    })

    NoclipToggle:AddKeyPicker("NoclipKeybind", {
        Text = "Noclip Keybind",
        Default = "G",
        Mode = "Toggle",
        SyncToggleState = true,
        Callback = function(v)
            self.noclipEnabled = v
            if v then
                self:StartNoclip()
            else
                self:StopNoclip()
            end
        end
    })

    Character:AddToggle("InfiniteJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(v)
            self.InfiniteJumpEnabled = v
        end
    })

    self:SetupInfiniteJump()

    -- при респавне восстанавливаем скорость и выключаем фичи безопасно
    local respawnConn = self.LocalPlayer.CharacterAdded:Connect(function(newChar)
        newChar:WaitForChild("Humanoid", 5)

        self:StopFly()
        self.originalCanCollide = {}

        local hum = newChar:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = self.currentWalkSpeed
            hum.JumpHeight = self.currentJumpHeight
        end

        -- Перезапускаем loop-фичи на новом персонаже
        if self.loopWalkEnabled then self:StartLoopWalk() end
        if self.loopJumpEnabled then self:StartLoopJump() end
    end)
    table.insert(self.Connections, respawnConn)

    return self
end

function Player:StartLoopWalk()
    self:StopLoopWalk()
    self.loopWalkConnection = RunService.Stepped:Connect(function()
        if not self.loopWalkEnabled then return end
        local char = self.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = self.currentWalkSpeed
            end
        end
    end)
end

function Player:StopLoopWalk()
    if self.loopWalkConnection then
        self.loopWalkConnection:Disconnect()
        self.loopWalkConnection = nil
    end
end

-- Loop Jump: ждёт пока персонаж на земле и сразу прыгает снова
function Player:StartLoopJump()
    self:StopLoopJump()
    self.loopJumpConnection = RunService.Stepped:Connect(function()
        if not self.loopJumpEnabled then return end
        local char = self.LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        -- Прыгаем только если стоим на земле (не в воздухе)
        if hum:GetState() == Enum.HumanoidStateType.Running
            or hum:GetState() == Enum.HumanoidStateType.RunningNoPhysics then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

function Player:StopLoopJump()
    if self.loopJumpConnection then
        self.loopJumpConnection:Disconnect()
        self.loopJumpConnection = nil
    end
end

function Player:SetupInfiniteJump()
    local conn = UserInputService.JumpRequest:Connect(function()
        if self.InfiniteJumpEnabled then
            local char = self.LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end)
    table.insert(self.Connections, conn)
end

function Player:StartFly()
    self:StopFly()

    local char = self.LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    hum.PlatformStand = true

    self.flyBV = Instance.new("BodyVelocity")
    self.flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    self.flyBV.Velocity = Vector3.zero
    self.flyBV.Parent = root

    self.flyBG = Instance.new("BodyGyro")
    self.flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    self.flyBG.D = 500
    self.flyBG.P = 3000
    self.flyBG.CFrame = workspace.CurrentCamera.CFrame
    self.flyBG.Parent = root

    self.flyConnection = RunService.RenderStepped:Connect(function()
        if not char or not char.Parent or hum.Health <= 0 then
            self:StopFly()
            return
        end

        local cam = workspace.CurrentCamera
        if not cam or not self.flyBV or not self.flyBG then return end

        self.flyBG.CFrame = cam.CFrame

        local currentFlySpeed = self.flySpeed or 50
        local moveVel = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVel = moveVel + cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVel = moveVel - cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVel = moveVel + cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVel = moveVel - cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVel = moveVel + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveVel = moveVel - Vector3.new(0, 1, 0)
        end

        if moveVel.Magnitude > 0 then
            moveVel = moveVel.Unit * currentFlySpeed
        end

        self.flyBV.Velocity = moveVel
    end)
end

function Player:StopFly()
    if self.flyConnection then
        self.flyConnection:Disconnect()
        self.flyConnection = nil
    end

    if self.flyBV then
        self.flyBV:Destroy()
        self.flyBV = nil
    end

    if self.flyBG then
        self.flyBG:Destroy()
        self.flyBG = nil
    end

    local char = self.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum.PlatformStand = false
        end
    end
end

function Player:StartNoclip()
    self:StopNoclip()

    -- FIX: сохраняем оригинальные значения CanCollide перед отключением
    local char = self.LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                self.originalCanCollide[part] = part.CanCollide
            end
        end
    end

    self.noclipConnection = RunService.Stepped:Connect(function()
        if not self.noclipEnabled then return end

        local character = self.LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

function Player:StopNoclip()
    if self.noclipConnection then
        self.noclipConnection:Disconnect()
        self.noclipConnection = nil
    end

    local char = self.LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                -- FIX: восстанавливаем оригинальное значение CanCollide, а не просто true
                local original = self.originalCanCollide[part]
                part.CanCollide = (original ~= nil) and original or true
            end
        end
    end

    self.originalCanCollide = {}
end

function Player:Cleanup()
    self:StopFly()
    self:StopNoclip()
    self:StopLoopWalk()
    self:StopLoopJump()
    self.noclipEnabled = false
    self.InfiniteJumpEnabled = false
    self.loopWalkEnabled = false
    self.loopJumpEnabled = false

    for _, conn in pairs(self.Connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    self.Connections = {}
end

return Player
