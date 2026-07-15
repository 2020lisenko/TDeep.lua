local Visuals = {}
Visuals.__index = Visuals

function Visuals:Initialize(Tab)
    local self = setmetatable({}, Visuals)

    if not getgenv().DeepVisuals then
        getgenv().DeepVisuals = {}
    end

    self.VisualsEnv = getgenv().DeepVisuals
    self.Lighting = game:GetService("Lighting")
    self.LocalPlayer = game:GetService("Players").LocalPlayer

    
    self.OriginalValues = {
        Brightness = self.Lighting.Brightness,
        FogEnd = self.Lighting.FogEnd,
        FogStart = self.Lighting.FogStart,
        GlobalShadows = self.Lighting.GlobalShadows,
        OutdoorAmbient = self.Lighting.OutdoorAmbient,
        ClockTime = self.Lighting.ClockTime,
        ExposureCompensation = self.Lighting.ExposureCompensation,
        Ambient = self.Lighting.Ambient,
        ColorShift_Top = self.Lighting.ColorShift_Top,
        ColorShift_Bottom = self.Lighting.ColorShift_Bottom,
        EnvironmentDiffuseScale = self.Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = self.Lighting.EnvironmentSpecularScale,
        ShadowSoftness = self.Lighting.ShadowSoftness
    }

    
    self.OriginalCameraMinZoom = self.LocalPlayer.CameraMinZoomDistance
    self.OriginalCameraMaxZoom = self.LocalPlayer.CameraMaxZoomDistance
    self.OriginalFOV = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70
    self.loopFBConnection = nil

    self:LoadDefaultSettings()
    self:CreateUI(Tab)

    return self
end

function Visuals:LoadDefaultSettings()
    self.VisualsEnv.Settings = {
        FullBright = false,
        LoopFullBright = false,
        NoFog = false,
        CustomTime = false,
        CustomTimeValue = 12,
        ThirdPerson = false,
        ThirdPersonDistance = 10,
        FOV = false,
        FOVAmount = 1.0
    }
end

function Visuals:StartLoopFullBright()
    self:StopLoopFullBright()
    local RunService = game:GetService("RunService")
    self.loopFBConnection = RunService.Heartbeat:Connect(function()
        if not self.VisualsEnv.Settings.LoopFullBright then return end
        self.Lighting.Brightness = 2
        self.Lighting.ClockTime = 14
        self.Lighting.FogEnd = 100000
        self.Lighting.GlobalShadows = false
        self.Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        self.Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    end)
end

function Visuals:StopLoopFullBright()
    if self.loopFBConnection then
        self.loopFBConnection:Disconnect()
        self.loopFBConnection = nil
    end
    
    if not self.VisualsEnv.Settings.FullBright then
        self:ApplyFullBright()
    end
end

function Visuals:ApplyFullBright()
    local s = self.VisualsEnv.Settings
    if s.FullBright then
        self.Lighting.Brightness = 2
        self.Lighting.ClockTime = 14
        self.Lighting.FogEnd = 100000
        self.Lighting.GlobalShadows = false
        self.Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        self.Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    else
        
        self.Lighting.Brightness = self.OriginalValues.Brightness
        self.Lighting.GlobalShadows = self.OriginalValues.GlobalShadows
        self.Lighting.OutdoorAmbient = self.OriginalValues.OutdoorAmbient
        self.Lighting.Ambient = self.OriginalValues.Ambient
        
        if not s.CustomTime then
            self.Lighting.ClockTime = self.OriginalValues.ClockTime
        end
        
        if not s.NoFog then
            self.Lighting.FogEnd = self.OriginalValues.FogEnd
        end
    end
end

function Visuals:ApplyNoFog()
    local s = self.VisualsEnv.Settings
    if s.NoFog then
        self.Lighting.FogEnd = 100000
        self.Lighting.FogStart = 100000
    else
        self.Lighting.FogEnd = self.OriginalValues.FogEnd
        self.Lighting.FogStart = self.OriginalValues.FogStart
    end
end

function Visuals:ApplyCustomTime()
    if self.VisualsEnv.Settings.CustomTime then
        self.Lighting.ClockTime = self.VisualsEnv.Settings.CustomTimeValue
    else
        self.Lighting.ClockTime = self.OriginalValues.ClockTime
    end
end

function Visuals:ApplyThirdPerson()
    local s = self.VisualsEnv.Settings
    if s.ThirdPerson then
        self.LocalPlayer.CameraMinZoomDistance = 0.5
        self.LocalPlayer.CameraMaxZoomDistance = s.ThirdPersonDistance
    else
        
        self.LocalPlayer.CameraMinZoomDistance = self.OriginalCameraMinZoom
        self.LocalPlayer.CameraMaxZoomDistance = self.OriginalCameraMaxZoom
    end
end

function Visuals:ApplyFOV()
    local cam = workspace.CurrentCamera
    if not cam then return end
    if self.VisualsEnv.Settings.FOV then
        
        local fov = math.clamp(70 * self.VisualsEnv.Settings.FOVAmount, 1, 120)
        cam.FieldOfView = fov
    else
        cam.FieldOfView = self.OriginalFOV
    end
end

function Visuals:RestoreAll()
    for k, v in pairs(self.OriginalValues) do
        self.Lighting[k] = v
    end
    
    self.LocalPlayer.CameraMinZoomDistance = self.OriginalCameraMinZoom
    self.LocalPlayer.CameraMaxZoomDistance = self.OriginalCameraMaxZoom
    if workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = self.OriginalFOV
    end
end

function Visuals:CreateUI(Tab)
    local Lighting = Tab:AddLeftGroupbox("Lighting")
    local Misc = Tab:AddRightGroupbox("Misc")

    Lighting:AddToggle("FullBright", {
        Text = "Full Bright",
        Default = false,
        Callback = function(v)
            self.VisualsEnv.Settings.FullBright = v
            self:ApplyFullBright()
        end
    })

    
    
    Lighting:AddToggle("LoopFullBright", {
        Text = "Loop Full Bright",
        Default = false,
        Callback = function(v)
            self.VisualsEnv.Settings.LoopFullBright = v
            if v then
                self:StartLoopFullBright()
            else
                self:StopLoopFullBright()
            end
        end
    })

    Lighting:AddToggle("NoFog", {
        Text = "No Fog",
        Default = false,
        Callback = function(v)
            self.VisualsEnv.Settings.NoFog = v
            self:ApplyNoFog()
        end
    })

    Lighting:AddToggle("CustomTime", {
        Text = "Custom Time",
        Default = false,
        Callback = function(v)
            self.VisualsEnv.Settings.CustomTime = v
            self:ApplyCustomTime()
        end
    })

    Lighting:AddSlider("CustomTimeValue", {
        Text = "Time (0-24)",
        Default = 12,
        Min = 0,
        Max = 24,
        Rounding = 1,
        Callback = function(v)
            self.VisualsEnv.Settings.CustomTimeValue = v
            self:ApplyCustomTime()
        end
    })

    Misc:AddToggle("ThirdPerson", {
        Text = "Third Person",
        Default = false,
        Callback = function(v)
            self.VisualsEnv.Settings.ThirdPerson = v
            self:ApplyThirdPerson()
        end
    })

    Misc:AddSlider("ThirdPersonDistance", {
        Text = "Distance",
        Default = 10,
        Min = 1,
        Max = 100,
        Rounding = 1,
        Callback = function(v)
            self.VisualsEnv.Settings.ThirdPersonDistance = v
            self:ApplyThirdPerson()
        end
    })

    Misc:AddDivider()

    Misc:AddToggle("FOV", {
        Text = "Custom FOV",
        Default = false,
        Callback = function(v)
            self.VisualsEnv.Settings.FOV = v
            self:ApplyFOV()
        end
    })

    
    Misc:AddSlider("FOVAmount", {
        Text = "FOV Scale",
        Default = 1.0,
        Min = 0.5,
        Max = 1.7,
        Rounding = 2,
        Callback = function(v)
            self.VisualsEnv.Settings.FOVAmount = v
            self:ApplyFOV()
        end
    })

    Misc:AddDivider()
    Misc:AddButton({
        Text = "Restore Defaults",
        Func = function()
            self:RestoreAll()
        end,
    })
end

function Visuals:Cleanup()
    self:StopLoopFullBright()
    self.VisualsEnv.Settings.LoopFullBright = false
    self:RestoreAll()
end

return Visuals
