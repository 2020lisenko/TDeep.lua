local Aimbot = {}
Aimbot.__index = Aimbot

function Aimbot:Initialize(Tab)
    local self = setmetatable({}, Aimbot)

    if not getgenv().Deep then
        getgenv().Deep = {
            Settings = {},
            FOVSettings = {},
            Functions = {}
        }
    end

    self.Env = getgenv().Deep
    self.Connections = {}
    self.Running = false
    self.Typing = false
    self.Locked = nil
    self.Animation = nil

    self.Services = {
        RunService = game:GetService("RunService"),
        UserInputService = game:GetService("UserInputService"),
        TweenService = game:GetService("TweenService"),
        Players = game:GetService("Players"),
        Camera = workspace.CurrentCamera,
        LocalPlayer = game:GetService("Players").LocalPlayer
    }

    self:LoadDefaultSettings()
    self:CreateUI(Tab)
    self.FOVCircle = Drawing.new("Circle")
    self:SetupConnections()

    return self
end

function Aimbot:LoadDefaultSettings()
    self.Env.Settings = {
        Enabled = false,
        TeamCheck = false,
        AliveCheck = true,
        WallCheck = false,
        Sensitivity = 0,
        TriggerKey = "MouseButton2",
        Toggle = false,
        LockPart = "Head",
        MaxDistance = 2000
    }

    self.Env.FOVSettings = {
        Enabled = false,
        Visible = true,
        Amount = 90,
        Color = Color3.fromRGB(255, 255, 255),
        LockedColor = Color3.fromRGB(255, 70, 70),
        Transparency = 0.5,
        Sides = 60,
        Thickness = 1,
        Filled = false
    }
end

function Aimbot:CancelLock()
    self.Locked = nil
    if self.Animation then
        self.Animation:Cancel()
        self.Animation = nil
    end
    if self.FOVCircle then
        self.FOVCircle.Color = self.Env.FOVSettings.Color
    end
end

function Aimbot:GetClosestPlayer()
    local settings = self.Env.Settings
    local fovSettings = self.Env.FOVSettings

    -- Радиус поиска: FOV в пикселях (если включён) или весь экран (MaxDistance)
    local searchRadius = fovSettings.Enabled and fovSettings.Amount or settings.MaxDistance

    -- FIX: разделяем логику «найти ближайшего» и «проверить текущую цель»
    if self.Locked then
        -- Проверяем, что текущая цель ещё в зоне и жива
        local char = self.Locked.Character
        if char and char:FindFirstChild(settings.LockPart) then
            if settings.AliveCheck then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then
                    self:CancelLock()
                    return
                end
            end

            local vector, onScreen = self.Services.Camera:WorldToViewportPoint(char[settings.LockPart].Position)
            if not onScreen then
                self:CancelLock()
                return
            end

            local mousePos = self.Services.UserInputService:GetMouseLocation()
            local distance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(vector.X, vector.Y)).Magnitude
            if distance > searchRadius then
                self:CancelLock()
            end
        else
            self:CancelLock()
        end
        return
    end

    -- Ищем ближайшего игрока к прицелу
    local closestDist = searchRadius
    local closestPlayer = nil

    for _, player in ipairs(self.Services.Players:GetPlayers()) do
        if player == self.Services.LocalPlayer then continue end

        local character = player.Character
        if not character then continue end
        if not character:FindFirstChild(settings.LockPart) then continue end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then continue end
        if settings.AliveCheck and humanoid.Health <= 0 then continue end
        if settings.TeamCheck and player.Team == self.Services.LocalPlayer.Team then continue end

        if settings.WallCheck then
            local parts = self.Services.Camera:GetPartsObscuringTarget(
                {character[settings.LockPart].Position},
                character:GetDescendants()
            )
            if #parts > 0 then continue end
        end

        local vector, onScreen = self.Services.Camera:WorldToViewportPoint(character[settings.LockPart].Position)
        if not onScreen then continue end

        local mousePos = self.Services.UserInputService:GetMouseLocation()
        local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(vector.X, vector.Y)).Magnitude

        if dist < closestDist then
            closestDist = dist
            closestPlayer = player
        end
    end

    self.Locked = closestPlayer
end

function Aimbot:UpdateAimbot()
    if not self.Running or not self.Env.Settings.Enabled then return end

    self:GetClosestPlayer()

    if self.Locked and self.Locked.Character then
        local targetPart = self.Locked.Character:FindFirstChild(self.Env.Settings.LockPart)
        if not targetPart then return end

        if self.Env.Settings.Sensitivity > 0 then
            -- FIX: отменяем предыдущий tween перед созданием нового, чтобы не конфликтовали
            if self.Animation then
                self.Animation:Cancel()
            end
            self.Animation = self.Services.TweenService:Create(
                self.Services.Camera,
                TweenInfo.new(self.Env.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                {CFrame = CFrame.new(self.Services.Camera.CFrame.Position, targetPart.Position)}
            )
            self.Animation:Play()
        else
            self.Services.Camera.CFrame = CFrame.new(
                self.Services.Camera.CFrame.Position,
                targetPart.Position
            )
        end

        if self.FOVCircle then
            self.FOVCircle.Color = self.Env.FOVSettings.LockedColor
        end
    end
end

function Aimbot:UpdateFOV()
    if not self.FOVCircle then return end

    if self.Env.FOVSettings.Enabled and self.Env.Settings.Enabled then
        self.FOVCircle.Radius = self.Env.FOVSettings.Amount
        self.FOVCircle.Thickness = self.Env.FOVSettings.Thickness
        self.FOVCircle.Filled = self.Env.FOVSettings.Filled
        self.FOVCircle.NumSides = self.Env.FOVSettings.Sides
        -- FIX: цвет FOV не перезаписываем если залочен (LockedColor выставляется в UpdateAimbot)
        if not self.Locked then
            self.FOVCircle.Color = self.Env.FOVSettings.Color
        end
        self.FOVCircle.Transparency = self.Env.FOVSettings.Transparency
        self.FOVCircle.Visible = self.Env.FOVSettings.Visible

        local mousePos = self.Services.UserInputService:GetMouseLocation()
        self.FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
    else
        self.FOVCircle.Visible = false
    end
end

function Aimbot:SetupConnections()
    self:DisconnectAll()

    self.Connections.TypingStarted = self.Services.UserInputService.TextBoxFocused:Connect(function()
        self.Typing = true
    end)

    self.Connections.TypingEnded = self.Services.UserInputService.TextBoxFocusReleased:Connect(function()
        self.Typing = false
    end)

    self.Connections.RenderStepped = self.Services.RunService.RenderStepped:Connect(function()
        self:UpdateFOV()
        self:UpdateAimbot()
    end)

    self.Connections.InputBegan = self.Services.UserInputService.InputBegan:Connect(function(input)
        if self.Typing then return end

        local triggered = false
        pcall(function()
            triggered = input.KeyCode == Enum.KeyCode[self.Env.Settings.TriggerKey]
        end)
        if not triggered then
            pcall(function()
                triggered = input.UserInputType == Enum.UserInputType[self.Env.Settings.TriggerKey]
            end)
        end

        if triggered then
            if self.Env.Settings.Toggle then
                self.Running = not self.Running
                if not self.Running then self:CancelLock() end
            else
                self.Running = true
            end
        end
    end)

    self.Connections.InputEnded = self.Services.UserInputService.InputEnded:Connect(function(input)
        if self.Typing or self.Env.Settings.Toggle then return end

        local triggered = false
        pcall(function()
            triggered = input.KeyCode == Enum.KeyCode[self.Env.Settings.TriggerKey]
        end)
        if not triggered then
            pcall(function()
                triggered = input.UserInputType == Enum.UserInputType[self.Env.Settings.TriggerKey]
            end)
        end

        if triggered then
            self.Running = false
            self:CancelLock()
        end
    end)
end

function Aimbot:DisconnectAll()
    for _, connection in pairs(self.Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    self.Connections = {}
end

function Aimbot:CreateUI(Tab)
    local Main = Tab:AddLeftGroupbox("Aimbot")
    local Right = Tab:AddRightGroupbox("FOV & Sensitivity")

    Main:AddToggle("DeepAimbotEnabled", {
        Text = "Enabled",
        Default = false,
        Callback = function(v) self.Env.Settings.Enabled = v end
    })

    Main:AddDropdown("LockPart", {
        Values = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"},
        Default = "Head",
        Text = "Lock Part",
        Callback = function(v) self.Env.Settings.LockPart = v end
    })

    Main:AddDropdown("TriggerKey", {
        Values = {"MouseButton1", "MouseButton2", "E", "Q", "F", "T", "Shift", "Control"},
        Default = "MouseButton2",
        Text = "Trigger Key",
        Callback = function(v) self.Env.Settings.TriggerKey = v end
    })

    Main:AddToggle("ToggleMode", {
        Text = "Toggle Mode",
        Default = false,
        Callback = function(v)
            self.Env.Settings.Toggle = v
            self:SetupConnections()
        end
    })

    Main:AddToggle("TeamCheck", {
        Text = "Team Check",
        Default = false,
        Callback = function(v) self.Env.Settings.TeamCheck = v end
    })

    Main:AddToggle("AliveCheck", {
        Text = "Alive Check",
        Default = true,
        Callback = function(v) self.Env.Settings.AliveCheck = v end
    })

    Main:AddToggle("WallCheck", {
        Text = "Wall Check",
        Default = false,
        Callback = function(v) self.Env.Settings.WallCheck = v end
    })

    Right:AddSlider("Sensitivity", {
        Text = "Smoothness",
        Default = 0,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) self.Env.Settings.Sensitivity = v end
    })

    Right:AddToggle("FOVEnabled", {
        Text = "Show FOV",
        Default = false,
        Callback = function(v) self.Env.FOVSettings.Enabled = v end
    })

    Right:AddSlider("FOVAmount", {
        Text = "FOV Size",
        Default = 90,
        Min = 10,
        Max = 500,
        Callback = function(v) self.Env.FOVSettings.Amount = v end
    })

    Right:AddSlider("FOVTransparency", {
        Text = "Transparency",
        Default = 0.5,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) self.Env.FOVSettings.Transparency = v end
    })

    Right:AddSlider("FOVThickness", {
        Text = "Thickness",
        Default = 1,
        Min = 1,
        Max = 10,
        Callback = function(v) self.Env.FOVSettings.Thickness = v end
    })

    Right:AddToggle("FOVFilled", {
        Text = "Filled Circle",
        Default = false,
        Callback = function(v) self.Env.FOVSettings.Filled = v end
    })

    Right:AddLabel("FOV Color"):AddColorPicker("FOVColor", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(v) self.Env.FOVSettings.Color = v end
    })

    Right:AddLabel("Locked FOV Color"):AddColorPicker("FOVLockedColor", {
        Default = Color3.fromRGB(255, 70, 70),
        Callback = function(v) self.Env.FOVSettings.LockedColor = v end
    })
end

function Aimbot:Cleanup()
    self.Running = false
    self:CancelLock()
    self:DisconnectAll()
    if self.FOVCircle then
        pcall(function() self.FOVCircle:Remove() end)
        self.FOVCircle = nil
    end
end

return Aimbot
