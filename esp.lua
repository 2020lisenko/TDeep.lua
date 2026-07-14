--[[
    Deep.lua — ESP Module
    Sections: Player ESP | Self ESP | HUD | Game
]]

local ESP = {}
ESP.__index = ESP

local GRAD_N = 8  -- segments per box edge

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")

-- ══════════════════════════════════════════════════════════════════════
-- INITIALIZE
-- ══════════════════════════════════════════════════════════════════════

function ESP:Initialize(Tab)
    local self = setmetatable({}, ESP)

    if not getgenv().DeepESP then getgenv().DeepESP = {} end
    self.env         = getgenv().DeepESP
    self.LocalPlayer = Players.LocalPlayer
    self.Camera      = workspace.CurrentCamera
    self.Active      = false
    self.DB          = false
    self.globalTime  = 0

    -- Player ESP state
    self.playerESP   = {}  -- { box, fill, name, weapon, dist, hpBg, hpFill }
    self.highlights  = {}  -- Highlight instances (enemies)
    self.chams       = {}  -- Chams Highlight instances

    -- Self ESP state
    self.selfHighlight   = nil
    self.selfAura        = nil
    self.selfWalkParts   = {}
    self.selfTrail       = nil
    self.selfChinaHat    = nil
    self.selfConnections = {}

    -- HUD state
    self.crosshairLines  = nil
    self.blurInstance    = nil
    self.origMinZoom     = self.LocalPlayer.CameraMinZoomDistance
    self.origMaxZoom     = self.LocalPlayer.CameraMaxZoomDistance
    self.origFOV         = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70

    -- Game / hit state
    self.hitSound        = Instance.new("Sound")
    self.hitSound.SoundId = "rbxassetid://4612165786"
    self.hitSound.Volume  = 0.5
    self.hitSound.Parent  = workspace
    self.hitMarker2DObjs = nil
    self.hitMarker2DAlpha = 0
    self.hitConnections  = {}
    self.dmgNumbers      = {}

    self:LoadDefaults()
    self:CreateUI(Tab)
    self:SetupConnections()

    return self
end

-- ══════════════════════════════════════════════════════════════════════
-- DEFAULTS
-- ══════════════════════════════════════════════════════════════════════

function ESP:LoadDefaults()
    local S = {}

    -- ─ Box ─
    S.Box           = false
    S.BoxColor1     = Color3.fromRGB(255, 60,  60)
    S.BoxColor2     = Color3.fromRGB(60,  60,  255)
    S.BoxFilled     = false
    S.BoxFillColor  = Color3.fromRGB(200, 50, 50)
    S.BoxFillTransp = 0.7
    S.BoxMaterial   = "Normal"   -- Normal | Glow | Rainbow | Health
    S.BoxThickness  = 1.5

    -- ─ Highlight ─
    S.Highlight           = false
    S.HighlightFill       = Color3.fromRGB(255, 60, 60)
    S.HighlightOutline    = Color3.fromRGB(255, 255, 255)
    S.HighlightFillTransp    = 0.5
    S.HighlightOutlineTransp = 0

    -- ─ Chams ─
    S.Chams               = false
    S.ChamsMaterial       = "Neon"
    S.ChamsFill           = Color3.fromRGB(255, 0, 200)
    S.ChamsOutline        = Color3.fromRGB(255, 255, 255)
    S.ChamsFillTransp     = 0.5
    S.ChamsOutlineTransp  = 0

    -- ─ Labels ─
    S.Name          = false
    S.NameColor     = Color3.fromRGB(255, 255, 255)
    S.NameOutline   = Color3.fromRGB(0, 0, 0)
    S.Weapon        = false
    S.WeaponColor   = Color3.fromRGB(255, 200, 100)
    S.Distance      = false
    S.DistColor     = Color3.fromRGB(180, 180, 180)
    S.TextSize      = 13

    -- ─ Healthbar ─
    S.Healthbar     = false
    S.HpHigh        = Color3.fromRGB(0,   230, 70)
    S.HpMid         = Color3.fromRGB(255, 200, 0)
    S.HpLow         = Color3.fromRGB(255, 40,  40)

    -- ─ Misc ─
    S.TeamCheck     = false
    S.MaxDist       = 2000
    S.ResizeOutline = false

    -- ─ Self ESP ─
    S.SelfHL           = false
    S.SelfHLFill       = Color3.fromRGB(100, 200, 255)
    S.SelfHLOutline    = Color3.fromRGB(255, 255, 255)
    S.SelfHLFillTransp    = 0.5
    S.SelfHLOutlineTransp = 0
    S.SelfMaterial     = "Neon"
    S.ToolMaterial     = "Neon"
    S.ChinaHat         = false
    S.ParticleAura     = false
    S.AuraColor        = Color3.fromRGB(100, 200, 255)
    S.WalkSteps        = false
    S.WalkColor        = Color3.fromRGB(255, 255, 255)
    S.Trail            = false
    S.TrailColor1      = Color3.fromRGB(255, 80, 80)
    S.TrailColor2      = Color3.fromRGB(80, 80, 255)
    S.Headless         = false
    S.Korblox          = false

    -- ─ HUD ─
    S.Crosshair        = false
    S.CrosshairColor   = Color3.fromRGB(255, 255, 255)
    S.CrosshairOutline = Color3.fromRGB(0, 0, 0)
    S.CrosshairSize    = 10
    S.CrosshairGap     = 4
    S.CrosshairThick   = 1.5
    S.CenterPanel      = false
    S.CenterPanelMode  = "Dot"
    S.CenterPanelColor = Color3.fromRGB(255, 255, 255)
    S.UnlockZoom       = false
    S.DisableRender    = false
    S.HudFOV           = false
    S.HudFOVAmount     = 90
    S.AspectRatio      = "Default"
    S.MotionBlur       = false
    S.MotionBlurSize   = 24

    -- ─ Game ─
    S.DmgNumber        = false
    S.DmgColor         = Color3.fromRGB(255, 255, 80)
    S.HitMarker2D      = false
    S.HitMarker2DColor = Color3.fromRGB(255, 255, 255)
    S.HitMarker2DOutl  = Color3.fromRGB(0, 0, 0)
    S.HitMarker3D      = false
    S.HitMarker3DColor = Color3.fromRGB(255, 120, 0)
    S.HitScreen        = false
    S.HitScreenColor   = Color3.fromRGB(255, 0, 0)
    S.HitEffect        = false
    S.HitEffectColor   = Color3.fromRGB(255, 200, 50)
    S.HitSound         = false
    S.HitSoundId       = "Default"
    S.HitNotif         = false

    self.env.S = S
end

-- ══════════════════════════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════════════════════════

local function lerp(a, b, t) return a + (b - a) * t end
local function lerpC3(a, b, t)
    return Color3.new(a.R+(b.R-a.R)*t, a.G+(b.G-a.G)*t, a.B+(b.B-a.B)*t)
end

function ESP:smoothLerp(cur, tgt, factor)
    if cur == nil then return tgt end
    return cur + (tgt - cur) * factor
end

function ESP:hpColor(ratio)
    local S = self.env.S
    if ratio >= 0.5 then
        return lerpC3(S.HpMid, S.HpHigh, (ratio - 0.5) * 2)
    else
        return lerpC3(S.HpLow, S.HpMid, ratio * 2)
    end
end

function ESP:rainbowAt(t)
    local hue = (t + self.globalTime * 0.12) % 1
    return Color3.fromHSV(hue, 1, 1)
end

function ESP:boxSegColor(perimT, ratio)
    local S = self.env.S
    local m = S.BoxMaterial
    if m == "Rainbow" then
        return self:rainbowAt(perimT)
    elseif m == "Health" then
        return self:hpColor(ratio)
    else
        -- Normal / Glow: gradient Color1 (top) → Color2 (bottom)
        -- perimT=0 is top, 0.5 is bottom
        local gradT = math.clamp(math.abs(perimT - 0.5) * 2, 0, 1)
        gradT = 1 - gradT  -- 0 at top/bottom edges start, 1 at bottom middle
        -- simpler: top half uses C1, bottom half uses C2, sides interpolate
        if perimT < 0.25 then          -- top (L→R)
            return S.BoxColor1
        elseif perimT < 0.50 then      -- right (T→B): C1→C2
            return lerpC3(S.BoxColor1, S.BoxColor2, (perimT - 0.25) * 4)
        elseif perimT < 0.75 then      -- bottom (R→L)
            return S.BoxColor2
        else                           -- left (B→T): C2→C1
            return lerpC3(S.BoxColor2, S.BoxColor1, (perimT - 0.75) * 4)
        end
    end
end

function ESP:isVisible(char)
    local lc = self.LocalPlayer.Character
    if not lc then return false end
    local from = (lc:FindFirstChild("Head") or lc:FindFirstChild("HumanoidRootPart"))
    local to   = char:FindFirstChild("Head")
    if not from or not to then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {lc}
    local res = workspace:Raycast(from.Position, (to.Position - from.Position).Unit * 5000, params)
    return res ~= nil and res.Instance ~= nil and res.Instance:IsDescendantOf(char)
end

-- ══════════════════════════════════════════════════════════════════════
-- DRAWING HELPERS
-- ══════════════════════════════════════════════════════════════════════

local function newLine(thick)
    local l = Drawing.new("Line")
    l.Visible = false; l.Transparency = 1; l.Thickness = thick or 1.5
    return l
end

local function newText(size)
    local t = Drawing.new("Text")
    t.Visible = false; t.Size = size or 13
    t.Center = true; t.Outline = true
    t.OutlineColor = Color3.fromRGB(0,0,0); t.Font = 2
    return t
end

local function newSquare(filled)
    local s = Drawing.new("Square")
    s.Visible = false; s.Filled = filled or false; s.Transparency = 1
    return s
end

local function makeSegArr(n, thick)
    local arr = {}
    for i = 1, n do arr[i] = newLine(thick) end
    return arr
end

local function setArrVisible(arr, v)
    if not arr then return end
    for _, l in ipairs(arr) do l.Visible = v end
end

local function removeArr(arr)
    if not arr then return end
    for _, l in ipairs(arr) do pcall(function() l:Remove() end) end
end

-- ══════════════════════════════════════════════════════════════════════
-- PLAYER ESP — OBJECT LIFECYCLE
-- ══════════════════════════════════════════════════════════════════════

function ESP:newPlayerDrawings()
    local S = self.env.S
    local e = {}
    -- Gradient box segments
    e.top    = makeSegArr(GRAD_N, S.BoxThickness)
    e.right  = makeSegArr(GRAD_N, S.BoxThickness)
    e.bottom = makeSegArr(GRAD_N, S.BoxThickness)
    e.left   = makeSegArr(GRAD_N, S.BoxThickness)
    -- Filled rect
    e.fill   = newSquare(true)
    -- HP bar
    e.hpBg   = newSquare(true)
    e.hpBg.Color = Color3.fromRGB(10,10,10)
    e.hpBar  = newSquare(true)
    -- Labels
    e.name   = newText(S.TextSize)
    e.weapon = newText(S.TextSize - 2)
    e.weapon.Color = Color3.fromRGB(255, 200, 100)
    e.dist   = newText(S.TextSize - 1)
    -- Smooth fields
    e.cx = nil; e.ty = nil; e.by = nil; e.bh = nil; e.bw = nil
    return e
end

function ESP:hidePlayerDrawings(e)
    if not e then return end
    setArrVisible(e.top, false)
    setArrVisible(e.right, false)
    setArrVisible(e.bottom, false)
    setArrVisible(e.left, false)
    e.fill.Visible  = false
    e.hpBg.Visible  = false
    e.hpBar.Visible = false
    e.name.Visible  = false
    e.weapon.Visible = false
    e.dist.Visible  = false
end

function ESP:removePlayerDrawings(e)
    if not e then return end
    removeArr(e.top); removeArr(e.right)
    removeArr(e.bottom); removeArr(e.left)
    for _, k in ipairs({"fill","hpBg","hpBar","name","weapon","dist"}) do
        pcall(function() e[k]:Remove() end)
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- PLAYER ESP — DRAW BOX (GRADIENT)
-- ══════════════════════════════════════════════════════════════════════

function ESP:drawBox(e, lx, rx, ty, by, bw, bh, ratio)
    local S  = self.env.S
    local th = S.BoxMaterial == "Glow" and S.BoxThickness * 2 or S.BoxThickness
    local n  = GRAD_N

    for i = 1, n do
        local t0 = (i - 1) / n
        local t1 = i / n
        local tm = (t0 + t1) * 0.5

        -- top 0–0.25, right 0.25–0.5, bottom 0.5–0.75, left 0.75–1
        local cs = self:boxSegColor(0.00 + 0.25 * tm, ratio)
        e.top[i].Color = cs
        e.top[i].From  = Vector2.new(lx + t0 * bw, ty)
        e.top[i].To    = Vector2.new(lx + t1 * bw, ty)
        e.top[i].Thickness = th
        e.top[i].Visible = true

        cs = self:boxSegColor(0.25 + 0.25 * tm, ratio)
        e.right[i].Color = cs
        e.right[i].From  = Vector2.new(rx, ty + t0 * bh)
        e.right[i].To    = Vector2.new(rx, ty + t1 * bh)
        e.right[i].Thickness = th
        e.right[i].Visible = true

        cs = self:boxSegColor(0.50 + 0.25 * tm, ratio)
        e.bottom[i].Color = cs
        e.bottom[i].From  = Vector2.new(rx - t0 * bw, by)
        e.bottom[i].To    = Vector2.new(rx - t1 * bw, by)
        e.bottom[i].Thickness = th
        e.bottom[i].Visible = true

        cs = self:boxSegColor(0.75 + 0.25 * tm, ratio)
        e.left[i].Color = cs
        e.left[i].From  = Vector2.new(lx, by - t0 * bh)
        e.left[i].To    = Vector2.new(lx, by - t1 * bh)
        e.left[i].Thickness = th
        e.left[i].Visible = true
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- PLAYER ESP — WORLD BOUNDS
-- ══════════════════════════════════════════════════════════════════════

function ESP:getBounds(char)
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hrp or not head then return nil end

    local topPos    = head.Position + Vector3.new(0, 0.6, 0)
    local lf = char:FindFirstChild("LeftFoot") or char:FindFirstChild("LeftLeg")
    local rf = char:FindFirstChild("RightFoot") or char:FindFirstChild("RightLeg")
    local botPos = lf and rf
        and (lf.Position + rf.Position) / 2
        or hrp.Position - Vector3.new(0, 3, 0)

    local top2D,    topOn    = self.Camera:WorldToViewportPoint(topPos)
    local bot2D,    botOn    = self.Camera:WorldToViewportPoint(botPos)
    local center2D, centerOn = self.Camera:WorldToViewportPoint(hrp.Position)

    if not topOn and not botOn and not centerOn then return nil end

    local dist = 1
    local lhrp = self.LocalPlayer.Character and self.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if lhrp then dist = (lhrp.Position - hrp.Position).Magnitude end

    return {
        cx   = center2D.X,
        ty   = top2D.Y,
        by   = bot2D.Y,
        h    = math.abs(bot2D.Y - top2D.Y),
        dist = dist,
    }
end

function ESP:dynWidth(h, dist)
    local base  = math.max(55, h * 0.7)
    local scale = math.clamp(50 / math.max(dist, 1), 0.5, 1.5)
    return base * scale
end

function ESP:getWeapon(char)
    local t = char:FindFirstChildOfClass("Tool")
    return t and t.Name or ""
end

-- ══════════════════════════════════════════════════════════════════════
-- PLAYER ESP — HIGHLIGHT / CHAMS
-- ══════════════════════════════════════════════════════════════════════

function ESP:applyHighlight(player)
    local char = player.Character
    if not char then return end
    local S = self.env.S
    if not self.highlights[player] then
        local h = Instance.new("Highlight")
        h.FillColor             = S.HighlightFill
        h.OutlineColor          = S.HighlightOutline
        h.FillTransparency      = S.HighlightFillTransp
        h.OutlineTransparency   = S.HighlightOutlineTransp
        h.DepthMode             = Enum.HighlightDepthMode.Occluded
        h.Parent                = char
        self.highlights[player] = h
    end
end

function ESP:removeHighlight(player)
    if self.highlights[player] then
        pcall(function() self.highlights[player]:Destroy() end)
        self.highlights[player] = nil
    end
end

function ESP:applyChams(player)
    local char = player.Character
    if not char then return end
    local S = self.env.S
    if not self.chams[player] then
        local h = Instance.new("Highlight")
        h.FillColor           = S.ChamsFill
        h.OutlineColor        = S.ChamsOutline
        h.FillTransparency    = S.ChamsFillTransp
        h.OutlineTransparency = S.ChamsOutlineTransp
        h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent              = char
        self.chams[player]    = h
    end
end

function ESP:removeChams(player)
    if self.chams[player] then
        pcall(function() self.chams[player]:Destroy() end)
        self.chams[player] = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- PLAYER ESP — UPDATE LOOP
-- ══════════════════════════════════════════════════════════════════════

function ESP:StartESP()
    self.Active = true
    task.spawn(function()
        local last = tick()
        while self.Active do
            if not self.DB then
                self.DB = true
                local now = tick()
                local dt  = now - last
                last = now
                pcall(function() self:Update(dt) end)
                self.DB = false
            end
            task.wait()
        end
    end)
end

function ESP:StopESP()
    self.Active = false
    for p, e in pairs(self.playerESP) do
        self:removePlayerDrawings(e)
        self:removeHighlight(p)
        self:removeChams(p)
    end
    self.playerESP  = {}
    self.highlights = {}
    self.chams      = {}
end

function ESP:Update(dt)
    local S  = self.env.S
    self.globalTime = self.globalTime + dt

    local lchar = self.LocalPlayer.Character
    local lhrp  = lchar and lchar:FindFirstChild("HumanoidRootPart")

    local smooth = math.min(0.6 * dt * 60, 1)

    local alive = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player == self.LocalPlayer then continue end
        alive[player] = true

        local char = player.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        -- Team check
        if S.TeamCheck and player.Team and self.LocalPlayer.Team
            and player.Team == self.LocalPlayer.Team then
            self:hidePlayerDrawings(self.playerESP[player])
            self:removeHighlight(player)
            self:removeChams(player)
            continue
        end

        -- Distance check
        if lhrp and char and char:FindFirstChild("HumanoidRootPart") then
            if (lhrp.Position - char.HumanoidRootPart.Position).Magnitude > S.MaxDist then
                self:hidePlayerDrawings(self.playerESP[player])
                self:removeHighlight(player)
                self:removeChams(player)
                continue
            end
        end

        if not char or not hum or hum.Health <= 0 then
            self:hidePlayerDrawings(self.playerESP[player])
            self:removeHighlight(player)
            self:removeChams(player)
            continue
        end

        -- Highlight / Chams
        if S.Highlight then self:applyHighlight(player)
        else self:removeHighlight(player) end

        if S.Chams then self:applyChams(player)
        else self:removeChams(player) end

        -- Sync highlight settings every frame (color may have changed)
        if self.highlights[player] then
            local h = self.highlights[player]
            h.FillColor           = S.HighlightFill
            h.OutlineColor        = S.HighlightOutline
            h.FillTransparency    = S.HighlightFillTransp
            h.OutlineTransparency = S.HighlightOutlineTransp
        end
        if self.chams[player] then
            local c = self.chams[player]
            c.FillColor           = S.ChamsFill
            c.OutlineColor        = S.ChamsOutline
            c.FillTransparency    = S.ChamsFillTransp
            c.OutlineTransparency = S.ChamsOutlineTransp
        end

        -- Box + labels
        local anyDrawing = S.Box or S.BoxFilled or S.Name or S.Weapon or S.Distance or S.Healthbar
        if not anyDrawing then
            self:hidePlayerDrawings(self.playerESP[player])
            continue
        end

        local bounds = self:getBounds(char)
        if not bounds then
            self:hidePlayerDrawings(self.playerESP[player])
            continue
        end

        if not self.playerESP[player] then
            self.playerESP[player] = self:newPlayerDrawings()
        end
        local e = self.playerESP[player]

        -- Smooth positions
        if e.cx == nil then
            e.cx = bounds.cx; e.ty = bounds.ty; e.by = bounds.by
            e.bh = bounds.h;  e.bw = self:dynWidth(bounds.h, bounds.dist)
        end
        e.cx = self:smoothLerp(e.cx, bounds.cx,   smooth)
        e.ty = self:smoothLerp(e.ty, bounds.ty,   smooth)
        e.by = self:smoothLerp(e.by, bounds.by,   smooth)
        e.bh = self:smoothLerp(e.bh, bounds.h,    smooth)
        local tw = self:dynWidth(bounds.h, bounds.dist)
        e.bw = self:smoothLerp(e.bw or tw, tw,    smooth)

        local bh  = math.max(e.bh, 25)
        local bw  = math.max(e.bw, 30)
        local cy  = e.cx
        local ty  = e.ty
        local by  = ty + bh
        local lx  = cy - bw * 0.5
        local rx  = cy + bw * 0.5
        local ratio = hum.Health / math.max(hum.MaxHealth, 1)

        -- ── Box ──────────────────────────────────────
        if S.Box then
            self:drawBox(e, lx, rx, ty, by, bw, bh, ratio)
        else
            setArrVisible(e.top, false); setArrVisible(e.right, false)
            setArrVisible(e.bottom, false); setArrVisible(e.left, false)
        end

        -- ── Fill ─────────────────────────────────────
        if S.BoxFilled then
            e.fill.Color        = S.BoxFillColor
            e.fill.Transparency = S.BoxFillTransp
            e.fill.Position     = Vector2.new(lx, ty)
            e.fill.Size         = Vector2.new(bw, bh)
            e.fill.Visible      = true
        else
            e.fill.Visible = false
        end

        -- ── Healthbar ────────────────────────────────
        local HP_W = S.ResizeOutline and math.max(2, bw * 0.04) or 3
        local HP_OFF = 5
        if S.Healthbar then
            local barX  = lx - HP_OFF - HP_W
            local fillH = bh * ratio
            e.hpBg.Position    = Vector2.new(barX, ty)
            e.hpBg.Size        = Vector2.new(HP_W, bh)
            e.hpBg.Visible     = true
            e.hpBar.Color      = self:hpColor(ratio)
            e.hpBar.Position   = Vector2.new(barX, ty + bh - fillH)
            e.hpBar.Size       = Vector2.new(HP_W, fillH)
            e.hpBar.Transparency = 1
            e.hpBar.Visible    = true
        else
            e.hpBg.Visible  = false
            e.hpBar.Visible = false
        end

        -- ── Name ─────────────────────────────────────
        if S.Name then
            e.name.Text         = player.DisplayName
            e.name.Color        = S.NameColor
            e.name.OutlineColor = S.NameOutline
            e.name.Size         = S.TextSize
            e.name.Position     = Vector2.new(cy, ty - 18)
            e.name.Visible      = true
        else
            e.name.Visible = false
        end

        -- ── Weapon ───────────────────────────────────
        local wep = self:getWeapon(char)
        if S.Weapon and wep ~= "" then
            e.weapon.Text     = wep
            e.weapon.Color    = S.WeaponColor
            e.weapon.Size     = S.TextSize - 2
            e.weapon.Position = Vector2.new(cy, by + 4)
            e.weapon.Visible  = true
        else
            e.weapon.Visible = false
        end

        -- ── Distance ─────────────────────────────────
        if S.Distance then
            local m = math.floor(bounds.dist * 0.28 * 10) / 10
            e.dist.Text     = string.format("%.1f m", m)
            e.dist.Color    = S.DistColor
            e.dist.Size     = S.TextSize - 1
            e.dist.Position = Vector2.new(cy, by + (wep ~= "" and S.Weapon and 18 or 4))
            e.dist.Visible  = true
        else
            e.dist.Visible = false
        end
    end

    -- Clean up left players
    for p, e in pairs(self.playerESP) do
        if not alive[p] then
            self:removePlayerDrawings(e)
            self:removeHighlight(p)
            self:removeChams(p)
            self.playerESP[p] = nil
        end
    end

    -- Update hit markers
    self:UpdateHitMarker2D(dt)
    self:UpdateDmgNumbers(dt)
    if S.Crosshair then self:UpdateCrosshair() end
end

-- ══════════════════════════════════════════════════════════════════════
-- SELF ESP
-- ══════════════════════════════════════════════════════════════════════

function ESP:ApplySelfHighlight()
    local char = self.LocalPlayer.Character
    if not char then return end
    local S = self.env.S
    if self.selfHighlight then pcall(function() self.selfHighlight:Destroy() end) end
    local h = Instance.new("Highlight")
    h.FillColor           = S.SelfHLFill
    h.OutlineColor        = S.SelfHLOutline
    h.FillTransparency    = S.SelfHLFillTransp
    h.OutlineTransparency = S.SelfHLOutlineTransp
    h.DepthMode           = Enum.HighlightDepthMode.Occluded
    h.Parent              = char
    self.selfHighlight    = h
end

function ESP:RemoveSelfHighlight()
    if self.selfHighlight then
        pcall(function() self.selfHighlight:Destroy() end)
        self.selfHighlight = nil
    end
end

function ESP:ApplySelfMaterial()
    local char = self.LocalPlayer.Character
    if not char then return end
    local mat = Enum.Material[self.env.S.SelfMaterial] or Enum.Material.Neon
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            p.Material = mat
        end
    end
end

function ESP:RestoreSelfMaterial()
    local char = self.LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.Material = Enum.Material.SmoothPlastic end
    end
end

function ESP:ApplyParticleAura()
    local char = self.LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if self.selfAura then pcall(function() self.selfAura:Destroy() end) end
    local pe = Instance.new("ParticleEmitter")
    pe.Color = ColorSequence.new(self.env.S.AuraColor)
    pe.LightEmission = 1
    pe.LightInfluence = 0
    pe.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0)
    })
    pe.Lifetime = NumberRange.new(0.5, 1.2)
    pe.Rate = 60
    pe.SpreadAngle = Vector2.new(180, 180)
    pe.Speed = NumberRange.new(2, 5)
    pe.Parent = hrp
    self.selfAura = pe
end

function ESP:RemoveParticleAura()
    if self.selfAura then
        pcall(function() self.selfAura:Destroy() end)
        self.selfAura = nil
    end
end

function ESP:ApplyWalkSteps()
    local char = self.LocalPlayer.Character
    if not char then return end
    self:RemoveWalkSteps()
    for _, footName in ipairs({"LeftFoot","RightFoot","LeftLeg","RightLeg"}) do
        local foot = char:FindFirstChild(footName)
        if foot then
            local pe = Instance.new("ParticleEmitter")
            pe.Color = ColorSequence.new(self.env.S.WalkColor)
            pe.LightEmission = 0.5
            pe.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.2),
                NumberSequenceKeypoint.new(1, 0)
            })
            pe.Lifetime = NumberRange.new(0.2, 0.5)
            pe.Rate = 40
            pe.SpreadAngle = Vector2.new(30, 30)
            pe.Speed = NumberRange.new(1, 3)
            pe.Parent = foot
            table.insert(self.selfWalkParts, pe)
        end
    end
end

function ESP:RemoveWalkSteps()
    for _, pe in ipairs(self.selfWalkParts) do
        pcall(function() pe:Destroy() end)
    end
    self.selfWalkParts = {}
end

function ESP:ApplyTrail()
    local char = self.LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    self:RemoveTrail()
    local S = self.env.S
    local a0 = Instance.new("Attachment", hrp)
    a0.Position = Vector3.new(0, 1, 0)
    local a1 = Instance.new("Attachment", hrp)
    a1.Position = Vector3.new(0, -1, 0)
    local t = Instance.new("Trail")
    t.Attachment0 = a0; t.Attachment1 = a1
    t.Color = ColorSequence.new(S.TrailColor1, S.TrailColor2)
    t.LightEmission = 0.8
    t.Lifetime = 0.5
    t.MinLength = 0
    t.FaceCamera = true
    t.Parent = hrp
    self.selfTrail = {trail = t, a0 = a0, a1 = a1}
end

function ESP:RemoveTrail()
    if self.selfTrail then
        pcall(function() self.selfTrail.trail:Destroy() end)
        pcall(function() self.selfTrail.a0:Destroy() end)
        pcall(function() self.selfTrail.a1:Destroy() end)
        self.selfTrail = nil
    end
end

function ESP:ApplyChinaHat()
    local char = self.LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    self:RemoveChinaHat()
    local hat = Instance.new("Part")
    hat.Name = "_DeepChinaHat"
    hat.Size = Vector3.new(2.5, 0.05, 2.5)
    hat.Shape = Enum.PartType.Cylinder
    hat.Material = Enum.Material.SmoothPlastic
    hat.Color = Color3.fromRGB(180, 140, 60)
    hat.CanCollide = false
    hat.CastShadow = false
    hat.Parent = char
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = head; weld.Part1 = hat
    weld.Parent = hat
    hat.CFrame = head.CFrame * CFrame.new(0, 0.9, 0) * CFrame.Angles(0, 0, math.rad(90))
    -- Cone shape via SpecialMesh
    local mesh = Instance.new("SpecialMesh", hat)
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://1033714"
    mesh.Scale = Vector3.new(1.5, 0.8, 1.5)
    self.selfChinaHat = hat
end

function ESP:RemoveChinaHat()
    if self.selfChinaHat then
        pcall(function() self.selfChinaHat:Destroy() end)
        self.selfChinaHat = nil
    end
    local char = self.LocalPlayer.Character
    if char then
        local h = char:FindFirstChild("_DeepChinaHat")
        if h then h:Destroy() end
    end
end

function ESP:ApplyHeadless()
    local char = self.LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 1
        for _, d in ipairs(head:GetDescendants()) do
            if d:IsA("Decal") or d:IsA("SpecialMesh") then
                d.Transparency = 1
            end
        end
    end
    -- Hide head accessories
    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") then
            local handle = acc:FindFirstChild("Handle")
            if handle then handle.Transparency = 1 end
        end
    end
end

function ESP:RemoveHeadless()
    local char = self.LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 0
        for _, d in ipairs(head:GetDescendants()) do
            if d:IsA("Decal") then d.Transparency = 0 end
            if d:IsA("SpecialMesh") then d.Transparency = 0 end
        end
    end
    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") then
            local handle = acc:FindFirstChild("Handle")
            if handle then handle.Transparency = 0 end
        end
    end
end

function ESP:ApplyKorblox()
    local char = self.LocalPlayer.Character
    if not char then return end
    -- Make left leg invisible (classic "Korblox" look)
    local leftParts = {"LeftUpperLeg","LeftLowerLeg","LeftFoot","LeftLeg"}
    for _, name in ipairs(leftParts) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then p.Transparency = 1 end
    end
end

function ESP:RemoveKorblox()
    local char = self.LocalPlayer.Character
    if not char then return end
    local leftParts = {"LeftUpperLeg","LeftLowerLeg","LeftFoot","LeftLeg"}
    for _, name in ipairs(leftParts) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then p.Transparency = 0 end
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- HUD
-- ══════════════════════════════════════════════════════════════════════

function ESP:CreateCrosshair()
    self:DestroyCrosshair()
    local function cl()
        local l = Drawing.new("Line")
        l.Visible = true; l.Transparency = 1
        return l
    end
    self.crosshairLines = { cl(), cl(), cl(), cl(),  -- inner lines
                            cl(), cl(), cl(), cl() }  -- outline lines
end

function ESP:DestroyCrosshair()
    if self.crosshairLines then
        for _, l in ipairs(self.crosshairLines) do pcall(function() l:Remove() end) end
        self.crosshairLines = nil
    end
end

function ESP:UpdateCrosshair()
    local S  = self.env.S
    if not self.crosshairLines then self:CreateCrosshair() end
    local vp  = workspace.CurrentCamera.ViewportSize
    local cx  = vp.X / 2
    local cy  = vp.Y / 2
    local sz  = S.CrosshairSize
    local gap = S.CrosshairGap
    local th  = S.CrosshairThick
    -- Order: top, bottom, left, right (4 lines) + outline (4 lines)
    local dirs = {
        {Vector2.new(cx, cy - gap - sz), Vector2.new(cx, cy - gap)},      -- top
        {Vector2.new(cx, cy + gap),      Vector2.new(cx, cy + gap + sz)},  -- bottom
        {Vector2.new(cx - gap - sz, cy), Vector2.new(cx - gap, cy)},       -- left
        {Vector2.new(cx + gap, cy),      Vector2.new(cx + gap + sz, cy)},  -- right
    }
    for i, d in ipairs(dirs) do
        -- Outline
        local ol = self.crosshairLines[i + 4]
        ol.Color = S.CrosshairOutline
        ol.From  = d[1]; ol.To = d[2]
        ol.Thickness = th + 2
        ol.Visible = true
        -- Main
        local ml = self.crosshairLines[i]
        ml.Color = S.CrosshairColor
        ml.From  = d[1]; ml.To = d[2]
        ml.Thickness = th
        ml.Visible = true
    end
end

function ESP:SetUnlockZoom(enable)
    if enable then
        self.LocalPlayer.CameraMaxZoomDistance = 900
        self.LocalPlayer.CameraMinZoomDistance = 0
    else
        self.LocalPlayer.CameraMaxZoomDistance = self.origMaxZoom
        self.LocalPlayer.CameraMinZoomDistance = self.origMinZoom
    end
end

function ESP:SetDisableRendering(enable)
    workspace.StreamingEnabled = not enable  -- may error in some games, pcall'd by caller
end

function ESP:SetFOV(enable, amount)
    if workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = enable and amount or self.origFOV
    end
end

function ESP:SetMotionBlur(enable, size)
    if enable then
        if not self.blurInstance then
            local b = Instance.new("BlurEffect")
            b.Name = "_DeepBlur"
            b.Parent = workspace.CurrentCamera
            self.blurInstance = b
        end
        self.blurInstance.Size = size
    else
        if self.blurInstance then
            pcall(function() self.blurInstance:Destroy() end)
            self.blurInstance = nil
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- GAME — HIT DETECTION
-- ══════════════════════════════════════════════════════════════════════

function ESP:SetupHitDetection()
    for _, conn in pairs(self.hitConnections) do conn:Disconnect() end
    self.hitConnections = {}

    local function hookPlayer(player)
        local function hookChar(char)
            local hum = char:WaitForChild("Humanoid", 5)
            if not hum then return end
            local lastHP = hum.Health
            local conn = hum.HealthChanged:Connect(function(hp)
                if hp < lastHP then
                    local dmg = lastHP - hp
                    self:OnHit(player, char, dmg)
                end
                lastHP = hp
            end)
            table.insert(self.hitConnections, conn)
        end
        if player.Character then hookChar(player.Character) end
        local c = player.CharacterAdded:Connect(hookChar)
        table.insert(self.hitConnections, c)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= self.LocalPlayer then hookPlayer(p) end
    end
    local c = Players.PlayerAdded:Connect(function(p)
        if p ~= self.LocalPlayer then hookPlayer(p) end
    end)
    table.insert(self.hitConnections, c)
end

function ESP:OnHit(player, char, damage)
    local S = self.env.S
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if S.DmgNumber then self:SpawnDmgNumber(damage, hrp) end
    if S.HitMarker2D then self:TriggerHitMarker2D() end
    if S.HitMarker3D and hrp then self:TriggerHitMarker3D(hrp.Position) end
    if S.HitScreen then self:TriggerHitScreen() end
    if S.HitEffect and hrp then self:TriggerHitEffect(hrp.Position) end
    if S.HitSound then self:PlayHitSound() end
    if S.HitNotif then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title   = "Hit",
                Text    = string.format("-%d on %s", math.floor(damage), player.Name),
                Duration = 1.5,
            })
        end)
    end
end

-- ─ Damage Numbers ─

function ESP:SpawnDmgNumber(damage, hrp)
    local S = self.env.S
    if not hrp then return end
    local pos3D = hrp.Position + Vector3.new(math.random(-20, 20) * 0.05, 1.5, 0)
    local t = Drawing.new("Text")
    t.Text     = "-" .. math.floor(damage)
    t.Color    = S.DmgColor
    t.Size     = 15
    t.Center   = true
    t.Outline  = true
    t.OutlineColor = Color3.fromRGB(0,0,0)
    t.Font     = 2
    t.Transparency = 1
    t.Visible  = true
    table.insert(self.dmgNumbers, {
        obj   = t,
        pos3D = pos3D,
        life  = 1.2,
        timer = 0,
    })
end

function ESP:UpdateDmgNumbers(dt)
    local cam = workspace.CurrentCamera
    local toRemove = {}
    for i, n in ipairs(self.dmgNumbers) do
        n.timer = n.timer + dt
        local t = n.timer / n.life
        n.pos3D = n.pos3D + Vector3.new(0, dt * 2, 0)
        local pos2D, onScreen = cam:WorldToViewportPoint(n.pos3D)
        if onScreen then
            n.obj.Position     = Vector2.new(pos2D.X, pos2D.Y)
            n.obj.Transparency = 1 - t  -- fade out
        end
        if n.timer >= n.life then
            pcall(function() n.obj:Remove() end)
            table.insert(toRemove, i)
        end
    end
    for i = #toRemove, 1, -1 do table.remove(self.dmgNumbers, toRemove[i]) end
end

-- ─ 2D Hit Marker ─

function ESP:TriggerHitMarker2D()
    self.hitMarker2DAlpha = 1
    if not self.hitMarker2DObjs then
        self.hitMarker2DObjs = {}
        -- 4 lines + 4 outlines
        for i = 1, 8 do
            local l = Drawing.new("Line")
            l.Visible = false; l.Transparency = 1
            l.Thickness = i > 4 and 3 or 1.5
            table.insert(self.hitMarker2DObjs, l)
        end
    end
end

function ESP:UpdateHitMarker2D(dt)
    local S = self.env.S
    if not self.hitMarker2DObjs then return end
    self.hitMarker2DAlpha = math.max(0, self.hitMarker2DAlpha - dt * 5)
    local alpha = self.hitMarker2DAlpha

    local vp  = workspace.CurrentCamera.ViewportSize
    local cx  = vp.X / 2
    local cy  = vp.Y / 2
    local sz  = 10
    local gap = 4

    local dirs = {
        {Vector2.new(cx, cy - gap - sz), Vector2.new(cx, cy - gap)},
        {Vector2.new(cx, cy + gap),      Vector2.new(cx, cy + gap + sz)},
        {Vector2.new(cx - gap - sz, cy), Vector2.new(cx - gap, cy)},
        {Vector2.new(cx + gap, cy),      Vector2.new(cx + gap + sz, cy)},
    }

    for i, d in ipairs(dirs) do
        local ol = self.hitMarker2DObjs[i + 4]
        ol.Color = S.HitMarker2DOutl
        ol.From  = d[1]; ol.To = d[2]
        ol.Transparency = alpha
        ol.Visible = alpha > 0

        local ml = self.hitMarker2DObjs[i]
        ml.Color = S.HitMarker2DColor
        ml.From  = d[1]; ml.To = d[2]
        ml.Transparency = alpha
        ml.Visible = alpha > 0
    end
end

-- ─ 3D Hit Marker ─

function ESP:TriggerHitMarker3D(pos)
    local S = self.env.S
    local p = Instance.new("Part")
    p.Shape       = Enum.PartType.Ball
    p.Size        = Vector3.new(0.4, 0.4, 0.4)
    p.Color       = S.HitMarker3DColor
    p.Material    = Enum.Material.Neon
    p.CanCollide  = false
    p.CastShadow  = false
    p.Anchored    = true
    p.CFrame      = CFrame.new(pos)
    p.Parent      = workspace
    TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(2, 2, 2), Transparency = 1
    }):Play()
    task.delay(0.5, function() pcall(function() p:Destroy() end) end)
end

-- ─ Hit Screen Flash ─

function ESP:TriggerHitScreen()
    local S = self.env.S
    local gui = Instance.new("ScreenGui")
    gui.Name = "_DeepHitScreen"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = self.LocalPlayer.PlayerGui

    local frame = Instance.new("Frame", gui)
    frame.Size            = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = S.HitScreenColor
    frame.BackgroundTransparency = 0.6
    frame.BorderSizePixel = 0

    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    }):Play()

    task.delay(0.45, function() pcall(function() gui:Destroy() end) end)
end

-- ─ Hit Effect (Particles at point) ─

function ESP:TriggerHitEffect(pos)
    local S = self.env.S
    local p = Instance.new("Part")
    p.Size     = Vector3.new(0.1, 0.1, 0.1)
    p.Anchored = true
    p.CanCollide = false
    p.Transparency = 1
    p.CFrame   = CFrame.new(pos)
    p.Parent   = workspace

    local pe = Instance.new("ParticleEmitter", p)
    pe.Color = ColorSequence.new(S.HitEffectColor)
    pe.LightEmission = 1
    pe.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.25),
        NumberSequenceKeypoint.new(1, 0)
    })
    pe.Lifetime = NumberRange.new(0.3, 0.6)
    pe.Rate = 0  -- burst only
    pe.SpreadAngle = Vector2.new(180, 180)
    pe.Speed = NumberRange.new(5, 15)
    pe:Emit(20)

    task.delay(0.8, function() pcall(function() p:Destroy() end) end)
end

-- ─ Hit Sound ─

local HIT_SOUNDS = {
    Default  = "rbxassetid://4612165786",
    Punch    = "rbxassetid://186311262",
    Beep     = "rbxassetid://259536", 
    Ding     = "rbxassetid://4913687",
}

function ESP:PlayHitSound()
    local id = HIT_SOUNDS[self.env.S.HitSoundId] or HIT_SOUNDS.Default
    self.hitSound.SoundId = id
    self.hitSound:Play()
end

-- ══════════════════════════════════════════════════════════════════════
-- CONNECTIONS (respawn, player added/removed)
-- ══════════════════════════════════════════════════════════════════════

function ESP:SetupConnections()
    local function onCharAdded(char)
        task.wait(0.5)
        local S = self.env.S
        if S.SelfHL then self:ApplySelfHighlight() end
        if S.SelfMaterial and S.SelfMaterial ~= "SmoothPlastic" then self:ApplySelfMaterial() end
        if S.ParticleAura then self:ApplyParticleAura() end
        if S.WalkSteps    then self:ApplyWalkSteps() end
        if S.Trail        then self:ApplyTrail() end
        if S.ChinaHat     then self:ApplyChinaHat() end
        if S.Headless     then self:ApplyHeadless() end
        if S.Korblox      then self:ApplyKorblox() end
    end

    self.LocalPlayer.CharacterAdded:Connect(onCharAdded)

    self:SetupHitDetection()
end

-- ══════════════════════════════════════════════════════════════════════
-- UI
-- ══════════════════════════════════════════════════════════════════════

function ESP:CreateUI(Tab)
    local S  = self.env.S
    local P  = Tab:AddLeftGroupbox("Player ESP")
    local SE = Tab:AddRightGroupbox("Self ESP")
    local H  = Tab:AddLeftGroupbox("HUD")
    local G  = Tab:AddRightGroupbox("Game")

    -- ════════════════════════════════════
    -- PLAYER ESP
    -- ════════════════════════════════════

    -- Box
    local BoxTog = P:AddToggle("ESPBox", {
        Text = "Box", Default = false,
        Callback = function(v) S.Box = v end
    })
    BoxTog:AddColorPicker("BoxColor1", {
        Default = S.BoxColor1,
        Callback = function(v) S.BoxColor1 = v end
    })
    BoxTog:AddColorPicker("BoxColor2", {
        Default = S.BoxColor2,
        Callback = function(v) S.BoxColor2 = v end
    })

    -- Filled
    local FilledTog = P:AddToggle("ESPFilled", {
        Text = "Filled", Default = false,
        Callback = function(v) S.BoxFilled = v end
    })
    FilledTog:AddColorPicker("FillColor", {
        Default = S.BoxFillColor,
        Callback = function(v) S.BoxFillColor = v end
    })

    -- Material (box style)
    P:AddDropdown("ESPMaterial", {
        Values  = {"Normal","Glow","Rainbow","Health"},
        Default = "Normal",
        Text    = "Material",
        Callback = function(v) S.BoxMaterial = v end
    })

    -- Highlight
    local HLTog = P:AddToggle("ESPHighlight", {
        Text = "Highlight", Default = false,
        Callback = function(v)
            S.Highlight = v
            if not v then
                for p in pairs(self.highlights) do self:removeHighlight(p) end
            end
        end
    })
    HLTog:AddColorPicker("HLFill", {
        Default = S.HighlightFill,
        Callback = function(v) S.HighlightFill = v end
    })
    HLTog:AddColorPicker("HLOutline", {
        Default = S.HighlightOutline,
        Callback = function(v) S.HighlightOutline = v end
    })

    -- Chams
    local ChamsTog = P:AddToggle("ESPChams", {
        Text = "Chams", Default = false,
        Callback = function(v)
            S.Chams = v
            if not v then
                for p in pairs(self.chams) do self:removeChams(p) end
            end
        end
    })
    ChamsTog:AddColorPicker("ChamsFill", {
        Default = S.ChamsFill,
        Callback = function(v) S.ChamsFill = v end
    })
    ChamsTog:AddColorPicker("ChamsOutline", {
        Default = S.ChamsOutline,
        Callback = function(v) S.ChamsOutline = v end
    })

    -- Name
    local NameTog = P:AddToggle("ESPName", {
        Text = "Name", Default = false,
        Callback = function(v) S.Name = v end
    })
    NameTog:AddColorPicker("NameColor", {
        Default = S.NameColor,
        Callback = function(v) S.NameColor = v end
    })
    NameTog:AddColorPicker("NameOutline", {
        Default = S.NameOutline,
        Callback = function(v) S.NameOutline = v end
    })

    -- Weapon
    local WepTog = P:AddToggle("ESPWeapon", {
        Text = "Weapon", Default = false,
        Callback = function(v) S.Weapon = v end
    })
    WepTog:AddColorPicker("WepColor", {
        Default = S.WeaponColor,
        Callback = function(v) S.WeaponColor = v end
    })

    -- Distance
    local DistTog = P:AddToggle("ESPDist", {
        Text = "Distance", Default = false,
        Callback = function(v) S.Distance = v end
    })
    DistTog:AddColorPicker("DistColor", {
        Default = S.DistColor,
        Callback = function(v) S.DistColor = v end
    })

    -- Healthbar
    local HpTog = P:AddToggle("ESPHealthbar", {
        Text = "Healthbar", Default = false,
        Callback = function(v) S.Healthbar = v end
    })
    HpTog:AddColorPicker("HpHigh", {
        Default = S.HpHigh,
        Callback = function(v) S.HpHigh = v end
    })
    HpTog:AddColorPicker("HpMid", {
        Default = S.HpMid,
        Callback = function(v) S.HpMid = v end
    })
    HpTog:AddColorPicker("HpLow", {
        Default = S.HpLow,
        Callback = function(v) S.HpLow = v end
    })

    -- Team Check
    P:AddToggle("ESPTeamCheck", {
        Text = "Team Check", Default = false,
        Callback = function(v) S.TeamCheck = v end
    })

    -- Resize Outline
    P:AddToggle("ESPResizeOutline", {
        Text = "Resize Outline", Default = false,
        Callback = function(v) S.ResizeOutline = v end
    })

    -- Enable / Start
    P:AddDivider()
    local mainTog = P:AddToggle("ESPEnabled", {
        Text = "Enable ESP", Default = false,
        Callback = function(v)
            if v then self:StartESP() else self:StopESP() end
        end
    })
    mainTog:AddKeyPicker("ESPKeybind", {
        Text = "ESP Keybind", Default = "None",
        Mode = "Toggle", SyncToggleState = true,
        Callback = function(v)
            if v then self:StartESP() else self:StopESP() end
        end
    })

    -- ════════════════════════════════════
    -- SELF ESP
    -- ════════════════════════════════════

    local SHLTog = SE:AddToggle("SelfHL", {
        Text = "Character Highlight", Default = false,
        Callback = function(v)
            S.SelfHL = v
            if v then self:ApplySelfHighlight() else self:RemoveSelfHighlight() end
        end
    })
    SHLTog:AddColorPicker("SelfHLFill", {
        Default = S.SelfHLFill,
        Callback = function(v)
            S.SelfHLFill = v
            if self.selfHighlight then self.selfHighlight.FillColor = v end
        end
    })
    SHLTog:AddColorPicker("SelfHLOutline", {
        Default = S.SelfHLOutline,
        Callback = function(v)
            S.SelfHLOutline = v
            if self.selfHighlight then self.selfHighlight.OutlineColor = v end
        end
    })

    SE:AddDropdown("SelfMaterial", {
        Values  = {"Neon","Glass","ForceField","SmoothPlastic"},
        Default = "Neon",
        Text    = "Character Material",
        Callback = function(v)
            S.SelfMaterial = v
            self:ApplySelfMaterial()
        end
    })

    SE:AddDropdown("ToolMaterial", {
        Values  = {"Neon","Glass","ForceField","SmoothPlastic"},
        Default = "Neon",
        Text    = "Material Tools",
        Callback = function(v)
            S.ToolMaterial = v
            local char = self.LocalPlayer.Character
            if char then
                local mat = Enum.Material[v] or Enum.Material.Neon
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        for _, p in ipairs(tool:GetDescendants()) do
                            if p:IsA("BasePart") then p.Material = mat end
                        end
                    end
                end
            end
        end
    })

    SE:AddToggle("ChinaHat", {
        Text = "China Hat", Default = false,
        Callback = function(v)
            S.ChinaHat = v
            if v then self:ApplyChinaHat() else self:RemoveChinaHat() end
        end
    })

    local AuraTog = SE:AddToggle("ParticleAura", {
        Text = "Particle Aura", Default = false,
        Callback = function(v)
            S.ParticleAura = v
            if v then self:ApplyParticleAura() else self:RemoveParticleAura() end
        end
    })
    AuraTog:AddColorPicker("AuraColor", {
        Default = S.AuraColor,
        Callback = function(v)
            S.AuraColor = v
            if self.selfAura then self.selfAura.Color = ColorSequence.new(v) end
        end
    })

    local WalkTog = SE:AddToggle("WalkSteps", {
        Text = "Walk Steps", Default = false,
        Callback = function(v)
            S.WalkSteps = v
            if v then self:ApplyWalkSteps() else self:RemoveWalkSteps() end
        end
    })
    WalkTog:AddColorPicker("WalkColor", {
        Default = S.WalkColor,
        Callback = function(v) S.WalkColor = v end
    })

    local TrailTog = SE:AddToggle("Trail", {
        Text = "Trail", Default = false,
        Callback = function(v)
            S.Trail = v
            if v then self:ApplyTrail() else self:RemoveTrail() end
        end
    })
    TrailTog:AddColorPicker("TrailColor1", {
        Default = S.TrailColor1,
        Callback = function(v) S.TrailColor1 = v end
    })
    TrailTog:AddColorPicker("TrailColor2", {
        Default = S.TrailColor2,
        Callback = function(v) S.TrailColor2 = v end
    })

    SE:AddToggle("Headless", {
        Text = "Headless", Default = false,
        Callback = function(v)
            S.Headless = v
            if v then self:ApplyHeadless() else self:RemoveHeadless() end
        end
    })

    SE:AddToggle("Korblox", {
        Text = "Korblox", Default = false,
        Callback = function(v)
            S.Korblox = v
            if v then self:ApplyKorblox() else self:RemoveKorblox() end
        end
    })

    -- ════════════════════════════════════
    -- HUD
    -- ════════════════════════════════════

    local CrossTog = H:AddToggle("HUDCrosshair", {
        Text = "Drawing Crosshair", Default = false,
        Callback = function(v)
            S.Crosshair = v
            if not v then self:DestroyCrosshair() end
        end
    })
    CrossTog:AddColorPicker("CrossColor", {
        Default = S.CrosshairColor,
        Callback = function(v) S.CrosshairColor = v end
    })
    CrossTog:AddColorPicker("CrossOutline", {
        Default = S.CrosshairOutline,
        Callback = function(v) S.CrosshairOutline = v end
    })

    H:AddDropdown("CenterPanel", {
        Values  = {"Off","Dot","Cross","Circle"},
        Default = "Off",
        Text    = "Center Panel",
        Callback = function(v)
            S.CenterPanelMode = v
            S.CenterPanel = v ~= "Off"
        end
    })

    H:AddToggle("UnlockZoom", {
        Text = "Unlock Max Zoom Distance", Default = false,
        Callback = function(v)
            S.UnlockZoom = v
            pcall(function() self:SetUnlockZoom(v) end)
        end
    })

    H:AddToggle("DisableRender", {
        Text = "Disable Rendering", Default = false,
        Callback = function(v)
            S.DisableRender = v
            pcall(function() self:SetDisableRendering(v) end)
        end
    })

    local FovTog = H:AddToggle("HudFOV", {
        Text = "Field Of View", Default = false,
        Callback = function(v)
            S.HudFOV = v
            pcall(function() self:SetFOV(v, S.HudFOVAmount) end)
        end
    })
    FovTog:AddSlider("HudFOVSlider", {
        Text = "FOV Amount", Default = 90,
        Min = 30, Max = 120, Rounding = 0,
        Callback = function(v)
            S.HudFOVAmount = v
            if S.HudFOV then pcall(function() self:SetFOV(true, v) end) end
        end
    })

    H:AddDropdown("AspectRatio", {
        Values  = {"Default","16:9","4:3","21:9"},
        Default = "Default",
        Text    = "Aspect Ratio",
        Callback = function(v)
            S.AspectRatio = v
            -- Applied via workspace.CurrentCamera.ViewportSize isn't directly settable;
            -- notify user this is informational in most executors
        end
    })

    local BlurTog = H:AddToggle("MotionBlur", {
        Text = "Motion Blur", Default = false,
        Callback = function(v)
            S.MotionBlur = v
            pcall(function() self:SetMotionBlur(v, S.MotionBlurSize) end)
        end
    })
    BlurTog:AddSlider("BlurSize", {
        Text = "Blur Size", Default = 24,
        Min = 0, Max = 56, Rounding = 0,
        Callback = function(v)
            S.MotionBlurSize = v
            if self.blurInstance then self.blurInstance.Size = v end
        end
    })

    -- ════════════════════════════════════
    -- GAME
    -- ════════════════════════════════════

    local DmgTog = G:AddToggle("DmgNumber", {
        Text = "Damage Number", Default = false,
        Callback = function(v) S.DmgNumber = v end
    })
    DmgTog:AddColorPicker("DmgColor", {
        Default = S.DmgColor,
        Callback = function(v) S.DmgColor = v end
    })

    local HM2Tog = G:AddToggle("HitMarker2D", {
        Text = "2D Hit Marker", Default = false,
        Callback = function(v) S.HitMarker2D = v end
    })
    HM2Tog:AddColorPicker("HM2Color", {
        Default = S.HitMarker2DColor,
        Callback = function(v) S.HitMarker2DColor = v end
    })
    HM2Tog:AddColorPicker("HM2Outline", {
        Default = S.HitMarker2DOutl,
        Callback = function(v) S.HitMarker2DOutl = v end
    })

    local HM3Tog = G:AddToggle("HitMarker3D", {
        Text = "3D Hit Marker", Default = false,
        Callback = function(v) S.HitMarker3D = v end
    })
    HM3Tog:AddColorPicker("HM3Color", {
        Default = S.HitMarker3DColor,
        Callback = function(v) S.HitMarker3DColor = v end
    })

    local HScrTog = G:AddToggle("HitScreen", {
        Text = "Hit Screen", Default = false,
        Callback = function(v) S.HitScreen = v end
    })
    HScrTog:AddColorPicker("HitScreenColor", {
        Default = S.HitScreenColor,
        Callback = function(v) S.HitScreenColor = v end
    })

    local HEffTog = G:AddToggle("HitEffect", {
        Text = "Hit Effect", Default = false,
        Callback = function(v) S.HitEffect = v end
    })
    HEffTog:AddColorPicker("HitEffColor", {
        Default = S.HitEffectColor,
        Callback = function(v) S.HitEffectColor = v end
    })

    local HSndTog = G:AddToggle("HitSound", {
        Text = "Hit Sound", Default = false,
        Callback = function(v) S.HitSound = v end
    })
    HSndTog:AddDropdown("HitSoundId", {
        Values  = {"Default","Punch","Beep","Ding"},
        Default = "Default",
        Text    = "Sound",
        Callback = function(v) S.HitSoundId = v end
    })

    G:AddToggle("HitNotif", {
        Text = "Hit Notification", Default = false,
        Callback = function(v) S.HitNotif = v end
    })
end

-- ══════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ══════════════════════════════════════════════════════════════════════

function ESP:Cleanup()
    self:StopESP()

    -- Self ESP
    self:RemoveSelfHighlight()
    self:RemoveParticleAura()
    self:RemoveWalkSteps()
    self:RemoveTrail()
    self:RemoveChinaHat()
    self:RemoveHeadless()
    self:RemoveKorblox()
    self:RestoreSelfMaterial()

    -- HUD
    self:DestroyCrosshair()
    pcall(function() self:SetUnlockZoom(false) end)
    pcall(function() self:SetFOV(false) end)
    pcall(function() self:SetMotionBlur(false) end)

    -- Hit connections
    for _, c in pairs(self.hitConnections) do pcall(function() c:Disconnect() end) end
    self.hitConnections = {}

    -- Hit marker drawings
    if self.hitMarker2DObjs then
        for _, l in ipairs(self.hitMarker2DObjs) do pcall(function() l:Remove() end) end
        self.hitMarker2DObjs = nil
    end

    -- Damage numbers
    for _, n in ipairs(self.dmgNumbers) do pcall(function() n.obj:Remove() end) end
    self.dmgNumbers = {}

    -- Hit sound
    pcall(function() self.hitSound:Destroy() end)

    -- Self connections
    for _, c in pairs(self.selfConnections) do pcall(function() c:Disconnect() end) end
    self.selfConnections = {}
end

return ESP
