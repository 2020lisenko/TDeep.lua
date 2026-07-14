--[[
    Deep.lua — Main
    UI Library: Obsidian (github.com/deividcomsono/Obsidian)
]]

local originalRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local myRepo       = "https://raw.githubusercontent.com/2020lisenko/Deep.lua/refs/heads/main/"

local Library      = loadstring(game:HttpGet(originalRepo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(originalRepo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(originalRepo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

-- ── Library flags ──────────────────────────────────────────────────
Library.ForceCheckbox             = false
Library.ShowToggleFrameInKeybinds = true

-- ══════════════════════════════════════════════════════════════════
-- MODULE LOADER
-- ══════════════════════════════════════════════════════════════════

local ModuleLoader = {
    Repo          = myRepo,
    LoadedModules = {},
}

function ModuleLoader:Load(moduleName, ...)
    local url = self.Repo .. moduleName .. ".lua"
    local ok, result = pcall(function()
        local fn, err = loadstring(game:HttpGet(url))
        if not fn then error("Syntax: " .. tostring(err)) end
        return fn()
    end)
    if ok and result then
        self.LoadedModules[moduleName] = result:Initialize(...)
        return self.LoadedModules[moduleName]
    else
        warn("[Deep.lua] Failed to load " .. moduleName .. ":", result)
        Library:Notify({
            Title       = "Deep.lua — Load Error",
            Description = moduleName .. " failed to load.",
            Time        = 6,
            Icon        = "triangle-alert",
        })
    end
    return nil
end

function ModuleLoader:CleanupAll()
    for _, module in pairs(self.LoadedModules) do
        if module and module.Cleanup then
            pcall(module.Cleanup, module)
        end
    end
    self.LoadedModules = {}
end

-- ══════════════════════════════════════════════════════════════════
-- WINDOW
-- ══════════════════════════════════════════════════════════════════

local Window = Library:CreateWindow({
    Title             = "Deep.lua",
    Footer            = "v1.67  ·  by Zeptome",
    Icon              = 11717093063,
    NotifySide        = "Right",
    ShowCustomCursor  = true,
    Resizable         = true,
    EnableSidebarResize = true,
    CornerRadius      = 8,
    Animations        = true,
})

-- ── Tabs ───────────────────────────────────────────────────────────
local Tabs = {
    Combat     = Window:AddTab("Combat",     "swords"),
    ESP        = Window:AddTab("ESP",        "eye"),
    Visuals    = Window:AddTab("Visuals",    "palette"),
    Player     = Window:AddTab("Player",     "user"),
    UISettings = Window:AddTab("UI",         "settings"),
}

-- ══════════════════════════════════════════════════════════════════
-- THEME / SAVE SETUP
-- ══════════════════════════════════════════════════════════════════

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("Deep.lua")
SaveManager:SetFolder("Deep.lua/specific-game")
SaveManager:SetSubFolder("specific-place")

-- ══════════════════════════════════════════════════════════════════
-- WATERMARK  (draggable label, top-left)
-- ══════════════════════════════════════════════════════════════════

local Watermark = Library:AddDraggableLabel(
    "Deep.lua  |  — fps  |  — ms",
    11717093063,
    "Left"
)
Watermark:SetVisible(true)

-- ── FPS / Ping updater ─────────────────────────────────────────────
local FrameTimer   = tick()
local FrameCounter = 0
local FPS          = 60

local WatermarkConnection = game:GetService("RunService").RenderStepped:Connect(function()
    FrameCounter += 1
    if (tick() - FrameTimer) >= 1 then
        FPS        = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end

    local ping = math.floor(
        game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    )
    Watermark:SetText(("Deep.lua  |  %d fps  |  %d ms"):format(math.floor(FPS), ping))
end)

-- ══════════════════════════════════════════════════════════════════
-- LOAD MODULES
-- ══════════════════════════════════════════════════════════════════

local AimbotModule  = ModuleLoader:Load("aimbot",  Tabs.Combat)
local HitboxModule  = ModuleLoader:Load("hitbox",  Tabs.Combat)
local ESPModule     = ModuleLoader:Load("esp",     Tabs.ESP)
local VisualsModule = ModuleLoader:Load("visuals", Tabs.Visuals)
local PlayerModule  = ModuleLoader:Load("player",  Tabs.Player)

-- ══════════════════════════════════════════════════════════════════
-- UI SETTINGS TAB  — two sub-tabs via Tabbox
-- ══════════════════════════════════════════════════════════════════

-- Left column: Interface tabbox
local LeftTabbox  = Tabs.UISettings:AddLeftTabbox()
local TabInterface = LeftTabbox:AddTab("Interface", "monitor")
local TabConfigs   = LeftTabbox:AddTab("Configs",   "save")

-- Right column: Menu groupbox
local MenuGroup = Tabs.UISettings:AddRightGroupbox("Menu", "wrench")

-- ─ Interface sub-tab ──────────────────────────────────────────────

TabInterface:AddToggle("ShowCustomCursor", {
    Text    = "Custom Cursor",
    Default = Library.ShowCustomCursor,
    Tooltip = "Shows a custom cursor while the menu is open.",
    Callback = function(v)
        Library.ShowCustomCursor = v
    end,
})

TabInterface:AddToggle("ShowWatermark", {
    Text    = "Show Watermark",
    Default = true,
    Tooltip = "Toggles the FPS / ping label in the top-left corner.",
    Callback = function(v)
        Watermark:SetVisible(v)
    end,
})

TabInterface:AddDivider()

TabInterface:AddDropdown("NotificationSide", {
    Values  = {"Left", "Right"},
    Default = "Right",
    Text    = "Notification Side",
    Tooltip = "Which side of the screen notifications pop up on.",
    Callback = function(v)
        Library:SetNotifySide(v)
    end,
})

TabInterface:AddDropdown("DPIDropdown", {
    Values  = {"50%", "75%", "100%", "125%", "150%", "175%", "200%"},
    Default = "100%",
    Text    = "DPI Scale",
    Tooltip = "Scales the entire UI. Useful on high-resolution monitors.",
    Callback = function(v)
        local dpi = tonumber(v:gsub("%%", ""))
        Library:SetDPIScale(dpi)
    end,
})

TabInterface:AddSlider("UICornerSlider", {
    Text     = "Corner Radius",
    Default  = 8,
    Min      = 0,
    Max      = 20,
    Rounding = 0,
    Tooltip  = "Controls how rounded the UI corners are (0 = sharp, 20 = pill).",
    Callback = function(v)
        Window:SetCornerRadius(v)
    end,
})

-- ─ Configs sub-tab ────────────────────────────────────────────────

SaveManager:BuildConfigSection(TabConfigs)
ThemeManager:ApplyToTab(TabConfigs)

-- ─ Menu groupbox (right column) ───────────────────────────────────

MenuGroup:AddToggle("KeybindMenuOpen", {
    Text    = "Open Keybind Menu",
    Default = Library.KeybindFrame.Visible,
    Tooltip = "Shows or hides the floating keybind list.",
    Callback = function(v)
        Library.KeybindFrame.Visible = v
    end,
})

MenuGroup:AddDivider()

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI    = true,
    Text    = "Menu keybind",
})

MenuGroup:AddDivider()

-- Unload: opens a confirmation Dialog before actually unloading
MenuGroup:AddButton({
    Text = "Unload Deep.lua",
    Func = function()
        local Dialog = Window:AddDialog("UnloadConfirm", {
            Title = "Unload Deep.lua?",
            Icon  = "triangle-alert",
            FooterButtons = {
                {
                    Text = "Unload",
                    Callback = function()
                        Library:Unload()
                    end,
                },
                {
                    Text = "Cancel",
                    Callback = function() end,
                },
            },
        })
        -- Dialogs inherit Groupbox methods — add a description label
        Dialog:AddLabel("All active features will be disabled and\nthe UI will be removed from the game.")
    end,
    Tooltip = "Completely removes Deep.lua from the game.",
})

-- ══════════════════════════════════════════════════════════════════
-- FLOATING PANIC BUTTON  (visible even when menu is closed)
-- ══════════════════════════════════════════════════════════════════

local PanicButton = Library:AddDraggableButton(
    "⬛ Panic",   -- text
    "x",          -- lucide icon
    "Right",      -- position side
    function()
        Library:Unload()
    end
)

-- ══════════════════════════════════════════════════════════════════
-- FINALIZE
-- ══════════════════════════════════════════════════════════════════

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:ApplyTheme("Material")
SaveManager:LoadAutoloadConfig()

-- ── Welcome notification ───────────────────────────────────────────
task.delay(0.5, function()
    local place = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    Library:Notify({
        Title       = "Deep.lua",
        Description = ("Loaded in %s\nPress %s to toggle the menu."):format(
            place,
            "RightShift"
        ),
        Time        = 7,
        BigIcon     = tostring(11717093063),
        Icon        = "zap",
    })
end)

-- ══════════════════════════════════════════════════════════════════
-- UNLOAD HANDLER
-- ══════════════════════════════════════════════════════════════════

Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    Watermark:Destroy()
    pcall(function() PanicButton:Destroy() end)
    ModuleLoader:CleanupAll()
    getgenv().Deep        = nil
    getgenv().DeepESP     = nil
    getgenv().DeepVisuals = nil
    getgenv().DeepPlayer  = nil
end)
