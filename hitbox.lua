local Hitbox = {}
Hitbox.__index = Hitbox

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DEFAULT_SIZES = {
    HumanoidRootPart = Vector3.new(2, 2, 1),
    Head              = Vector3.new(2, 1, 1),
    UpperTorso        = Vector3.new(2, 1.5, 1),
    LowerTorso        = Vector3.new(2, 1.5, 1),
    Torso             = Vector3.new(2, 2, 1),
    LeftUpperArm      = Vector3.new(1, 1.5, 1),
    RightUpperArm     = Vector3.new(1, 1.5, 1),
    LeftLowerArm      = Vector3.new(1, 1.5, 1),
    RightLowerArm     = Vector3.new(1, 1.5, 1),
    LeftHand          = Vector3.new(1, 0.8, 1),
    RightHand         = Vector3.new(1, 0.8, 1),
    LeftUpperLeg      = Vector3.new(1, 1.5, 1),
    RightUpperLeg     = Vector3.new(1, 1.5, 1),
    LeftLowerLeg      = Vector3.new(1, 1.5, 1),
    RightLowerLeg     = Vector3.new(1, 1.5, 1),
    LeftFoot          = Vector3.new(1, 0.7, 1),
    RightFoot         = Vector3.new(1, 0.7, 1),
}

local PART_OPTIONS = {
    "HumanoidRootPart",
    "Head",
    "UpperTorso",
    "Torso",
    "All Body",
}

function Hitbox:Initialize(Tab)
    local self = setmetatable({}, Hitbox)

    self.Enabled      = false
    self.Size         = 10
    self.Transparency = 0.7
    self.ColorEnabled = true
    self.Color        = Color3.fromRGB(0, 105, 255)
    self.MatEnabled   = true
    self.CanCollide   = false
    self.TeamCheck    = false
    self.TargetPart   = "HumanoidRootPart"
    self.Connection   = nil
    
    self.originalSizes = {}

    local HitboxGroup = Tab:AddRightGroupbox("Hitbox Expander")

    
    local HitboxToggle = HitboxGroup:AddToggle("HitboxEnabled", {
        Text    = "Enable Hitbox Expander",
        Default = false,
        Callback = function(v)
            self.Enabled = v
            if v then self:Start() else self:Stop() end
        end
    })

    HitboxToggle:AddKeyPicker("HitboxKeybind", {
        Text           = "Hitbox Keybind",
        Default        = "H",
        Mode           = "Toggle",
        SyncToggleState = true,
        Callback = function(v)
            self.Enabled = v
            if v then self:Start() else self:Stop() end
        end
    })

    
    HitboxGroup:AddToggle("HitboxTeamCheck", {
        Text    = "Team Check",
        Default = false,
        Callback = function(v)
            self.TeamCheck = v
        end
    })

    
    HitboxGroup:AddDropdown("HitboxTargetPart", {
        Values  = PART_OPTIONS,
        Default = "HumanoidRootPart",
        Text    = "Target Part",
        Callback = function(v)
            
            local wasEnabled = self.Enabled
            if wasEnabled then self:Stop() end
            self.TargetPart = v
            if wasEnabled then
                self.Enabled = true
                self:Start()
            end
        end
    })

    
    HitboxGroup:AddSlider("HitboxSize", {
        Text     = "Hitbox Size",
        Default  = 10,
        Min      = 1,
        Max      = 15,
        Rounding = 0,
        Callback = function(v)
            self.Size = v
        end
    })

    
    HitboxGroup:AddSlider("HitboxTransparency", {
        Text     = "Transparency",
        Default  = 0.7,
        Min      = 0,
        Max      = 1,
        Rounding = 2,
        Callback = function(v)
            self.Transparency = v
        end
    })

    HitboxGroup:AddDivider()

    
    HitboxGroup:AddToggle("HitboxColorEnabled", {
        Text    = "Custom Color",
        Default = true,
        Callback = function(v)
            self.ColorEnabled = v
        end
    })

    HitboxGroup:AddLabel("Hitbox Color"):AddColorPicker("HitboxColor", {
        Default  = Color3.fromRGB(0, 105, 255),
        Callback = function(v)
            self.Color = v
        end
    })

    
    HitboxGroup:AddToggle("HitboxMaterialEnabled", {
        Text    = "Neon Material",
        Default = true,
        Callback = function(v)
            self.MatEnabled = v
        end
    })

    
    HitboxGroup:AddToggle("HitboxCanCollide", {
        Text    = "Can Collide",
        Default = false,
        Callback = function(v)
            self.CanCollide = v
        end
    })

    return self
end

function Hitbox:GetTargetParts(character)
    if self.TargetPart == "All Body" then
        local parts = {}
        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("BasePart") then
                table.insert(parts, obj)
            end
        end
        return parts
    else
        local part = character:FindFirstChild(self.TargetPart)
        if part and part:IsA("BasePart") then
            return { part }
        end
    end
    return {}
end

function Hitbox:SaveSize(player, part)
    local uid = player.UserId
    if not self.originalSizes[uid] then
        self.originalSizes[uid] = {}
    end
    if not self.originalSizes[uid][part.Name] then
        self.originalSizes[uid][part.Name] = part.Size
    end
end

function Hitbox:GetOriginalSize(player, part)
    local uid = player.UserId
    if self.originalSizes[uid] and self.originalSizes[uid][part.Name] then
        return self.originalSizes[uid][part.Name]
    end
    return DEFAULT_SIZES[part.Name] or Vector3.new(2, 2, 1)
end

function Hitbox:Start()
    self:Stop() 

    self.Connection = RunService.RenderStepped:Connect(function()
        if not self.Enabled then return end

        local localPlayer = Players.LocalPlayer

        for _, player in pairs(Players:GetPlayers()) do
            if player == localPlayer then continue end
            if not player.Character then continue end

            
            if self.TeamCheck then
                if player.Team ~= nil and localPlayer.Team ~= nil
                    and player.Team == localPlayer.Team then
                    continue
                end
            end

            
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then continue end

            local parts = self:GetTargetParts(player.Character)
            for _, part in ipairs(parts) do
                pcall(function()
                    self:SaveSize(player, part)

                    part.Size        = Vector3.new(self.Size, self.Size, self.Size)
                    part.Transparency = self.Transparency
                    part.CanCollide  = self.CanCollide

                    if self.ColorEnabled then
                        part.Color = self.Color
                    end

                    part.Material = self.MatEnabled
                        and Enum.Material.Neon
                        or  Enum.Material.Plastic
                end)
            end
        end
    end)
end

function Hitbox:Stop()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end

    
    for _, player in pairs(Players:GetPlayers()) do
        if player == Players.LocalPlayer then continue end
        if not player.Character then continue end

        pcall(function()
            local parts = self:GetTargetParts(player.Character)
            for _, part in ipairs(parts) do
                pcall(function()
                    part.Size        = self:GetOriginalSize(player, part)
                    part.Transparency = 0
                    part.CanCollide  = true
                    part.Material    = Enum.Material.Plastic
                end)
            end
        end)
    end

    self.originalSizes = {}
end

function Hitbox:Cleanup()
    self.Enabled = false
    self:Stop()
end

return Hitbox
