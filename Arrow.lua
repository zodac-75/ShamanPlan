-- ShamanPlan: waypoint arrow and world map pin.
-- ns.SetWaypoint(uiMapID, x, y, title) points an on-screen arrow at a spot (x, y in 0-100)
-- and marks it on the world map. With TomTom installed, TomTom's arrow is used instead.
local _, ns = ...

local arrow, pin
local target -- { map, x, y, title, cont, wn, ww }
local ARRIVE_YARDS = 12

---------------------------------------------------------------------------
-- Positions in world coordinates. GetXY on a world position gives (north, west).
---------------------------------------------------------------------------
local function WorldPos(map, x, y)
  if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
  local ok, cont, pos = pcall(C_Map.GetWorldPosFromMapPos, map, CreateVector2D(x / 100, y / 100))
  if not ok or not cont or not pos then return nil end
  local n, w = pos:GetXY()
  return cont, n, w
end

local function PlayerWorldPos()
  if not (C_Map and C_Map.GetBestMapForUnit) then return nil end
  local map = C_Map.GetBestMapForUnit("player")
  if not map then return nil end
  local p = C_Map.GetPlayerMapPosition(map, "player")
  if not p then return nil end
  local x, y = p:GetXY()
  if not x or (x == 0 and y == 0) then return nil end
  return WorldPos(map, x * 100, y * 100)
end

local function MapName(map)
  local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(map)
  return info and info.name or "?"
end
ns.MapName = MapName

---------------------------------------------------------------------------
-- The arrow
---------------------------------------------------------------------------
local function UpdateArrow(self, elapsed)
  self.t = (self.t or 0) + elapsed
  if self.t < 0.05 then return end
  self.t = 0
  if not target then self:Hide() return end

  local cont, pn, pw = PlayerWorldPos()
  if not cont then
    self.tex:Hide()
    self.dist:SetText(ns.T("DG_NOPOS"))
    return
  end
  if not target.cont or cont ~= target.cont then
    self.tex:Hide()
    self.dist:SetText(ns.T("DG_OTHER_CONT", MapName(target.map)))
    return
  end
  local dn, dw = target.wn - pn, target.ww - pw
  local yards = math.sqrt(dn * dn + dw * dw)
  if yards < ARRIVE_YARDS then
    self.tex:Hide()
    self.dist:SetText("|cff33ff33" .. ns.T("DG_ARRIVED") .. "|r")
    if not self.arrivedAt then
      self.arrivedAt = GetTime()
      if PlaySound and SOUNDKIT and SOUNDKIT.MAP_PING then pcall(PlaySound, SOUNDKIT.MAP_PING) end
    elseif GetTime() - self.arrivedAt > 4 then
      ns.ClearWaypoint()
    end
    return
  end
  self.arrivedAt = nil
  local facing = GetPlayerFacing and GetPlayerFacing()
  if facing then
    -- Bearing counter-clockwise from north, like GetPlayerFacing.
    local bearing = math.atan2 and math.atan2(dw, dn) or math.atan(dw, dn)
    self.tex:SetRotation(bearing - facing)
    self.tex:Show()
  else
    self.tex:Hide()
  end
  self.dist:SetText(math.floor(yards + 0.5) .. " " .. ns.T("DG_YARDS"))
end

local function CreateArrow()
  arrow = CreateFrame("Button", "ShamanPlanArrow", UIParent)
  arrow:SetSize(64, 64)
  arrow:SetFrameStrata("HIGH")
  arrow:SetClampedToScreen(true)
  arrow:SetMovable(true)
  arrow:EnableMouse(true)
  arrow:RegisterForDrag("LeftButton")
  arrow:RegisterForClicks("RightButtonUp")
  local p = ns.db.arrowPos
  if p then arrow:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else arrow:SetPoint("TOP", 0, -120) end
  arrow:SetScript("OnDragStart", arrow.StartMoving)
  arrow:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local a, _, b, x, y = self:GetPoint()
    ns.db.arrowPos = { a, b, x, y }
  end)
  arrow:SetScript("OnClick", function() ns.ClearWaypoint() end) -- right-click hides it
  arrow:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("|cff3fa9ffShamanPlan|r " .. (target and target.title or ""))
    if target then GameTooltip:AddLine(MapName(target.map) .. string.format(" (%.1f, %.1f)", target.x, target.y), 1, 1, 1) end
    GameTooltip:AddLine(ns.T("DG_ARROW_TIP"), 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  arrow:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local tex = arrow:CreateTexture(nil, "ARTWORK")
  tex:SetTexture(ns.MEDIA .. "Arrow")
  tex:SetAllPoints()
  arrow.tex = tex

  local title = arrow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", arrow, "BOTTOM", 0, -2)
  arrow.title = title
  local dist = arrow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  dist:SetPoint("TOP", title, "BOTTOM", 0, -2)
  arrow.dist = dist

  arrow:SetScript("OnUpdate", UpdateArrow)
  arrow:Hide()
end

---------------------------------------------------------------------------
-- World map pin
---------------------------------------------------------------------------
local function UpdatePin()
  if not pin then return end
  local wm = WorldMapFrame
  if not (target and wm and wm:IsShown() and wm.GetMapID and wm:GetMapID() == target.map) then
    pin:Hide()
    return
  end
  local canvas = wm.GetCanvas and wm:GetCanvas()
  if not canvas then pin:Hide() return end
  if pin:GetParent() ~= canvas then pin:SetParent(canvas) end
  local w, h = canvas:GetWidth(), canvas:GetHeight()
  local scale = (wm.ScrollContainer and wm.ScrollContainer.GetCanvasScale and wm.ScrollContainer:GetCanvasScale()) or 1
  pin:SetScale(1 / scale)
  pin:ClearAllPoints()
  pin:SetPoint("CENTER", canvas, "TOPLEFT", (target.x / 100) * w * scale, -(target.y / 100) * h * scale)
  pin:SetFrameLevel(canvas:GetFrameLevel() + 2000)
  pin:Show()
end

local function CreatePin()
  if not WorldMapFrame then return end
  pin = CreateFrame("Frame", "ShamanPlanMapPin", WorldMapFrame)
  pin:SetSize(28, 28)
  local tex = pin:CreateTexture(nil, "OVERLAY")
  tex:SetTexture(ns.MEDIA .. "Icon")
  tex:SetAllPoints()
  pin:EnableMouse(true)
  pin:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("|cff3fa9ffShamanPlan|r")
    if target then GameTooltip:AddLine(target.title, 1, 1, 1) end
    GameTooltip:Show()
  end)
  pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
  pin:Hide()
  -- Follow the map while it is open.
  local driver = CreateFrame("Frame", nil, WorldMapFrame)
  driver:SetScript("OnUpdate", function(self, e)
    self.t = (self.t or 0) + e
    if self.t > 0.1 then self.t = 0; UpdatePin() end
  end)
end

---------------------------------------------------------------------------
-- Public
---------------------------------------------------------------------------
function ns.SetWaypoint(map, x, y, title)
  if not (map and x and y) then
    ns.Print(ns.T("DG_NOWAY"))
    return
  end
  if TomTom and TomTom.AddWaypoint then
    pcall(TomTom.AddWaypoint, TomTom, map, x / 100, y / 100, { title = title, from = "ShamanPlan" })
    ns.Print(ns.T("DG_WAY_TOMTOM", title, MapName(map)))
    return
  end
  local cont, wn, ww = WorldPos(map, x, y)
  target = { map = map, x = x, y = y, title = title, cont = cont, wn = wn, ww = ww }
  if not arrow then CreateArrow() end
  arrow.arrivedAt = nil
  arrow.title:SetText(title)
  arrow.dist:SetText("")
  arrow:Show()
  UpdatePin()
  ns.Print(ns.T("DG_WAY", title, MapName(map), x, y))
end

function ns.ClearWaypoint()
  target = nil
  if arrow then arrow:Hide() end
  if pin then pin:Hide() end
end

ns.RegisterModule(function()
  local ok = pcall(CreatePin)
  if not ok then pin = nil end
end)

ns.RegisterCommand("clearway", true, function() ns.ClearWaypoint() end)
