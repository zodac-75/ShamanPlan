-- ShamanPlan: minimap button.
-- Left-click: plan window. Right-click: settings window. Drag: move it around the minimap.
local _, ns = ...

local btn

local function UpdatePosition()
  local a = math.rad(ns.db.minimapAngle or 225)
  local r = (Minimap:GetWidth() / 2) + 5
  btn:ClearAllPoints()
  btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

local function OnDragUpdate()
  local mx, my = Minimap:GetCenter()
  local px, py = GetCursorPosition()
  local s = Minimap:GetEffectiveScale()
  px, py = px / s, py / s
  ns.db.minimapAngle = math.deg(atan2(py - my, px - mx))
  UpdatePosition()
end

local function CreateButton()
  btn = CreateFrame("Button", "ShamanPlanMinimapButton", Minimap)
  btn:SetSize(31, 31)
  btn:SetFrameStrata("MEDIUM")
  btn:SetFrameLevel(8)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  btn:RegisterForDrag("LeftButton")
  btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local bg = btn:CreateTexture(nil, "BACKGROUND")
  bg:SetSize(20, 20)
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetPoint("TOPLEFT", 7, -5)

  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetSize(20, 20)
  icon:SetTexture(ns.MEDIA .. "Icon")
  icon:SetPoint("TOPLEFT", 7, -5)

  local border = btn:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53)
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetPoint("TOPLEFT")

  btn:SetScript("OnClick", function(_, mouse)
    GameTooltip:Hide()
    if mouse == "RightButton" then
      ns.ToggleConfig()
    else
      ns.ToggleMain()
    end
  end)
  btn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", OnDragUpdate)
  end)
  btn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
  end)
  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff3fa9ffShamanPlan|r")
    GameTooltip:AddLine(ns.T("MM_TIP_LEFT"), 1, 1, 1)
    GameTooltip:AddLine(ns.T("MM_TIP_RIGHT"), 1, 1, 1)
    GameTooltip:AddLine(ns.T("MM_TIP_DRAG"), 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  UpdatePosition()
  if ns.db.minimapHidden then btn:Hide() end
end

-- Used by profiles after they change the icon's place or visibility.
function ns.UpdateMinimapButton()
  if not btn then return end
  UpdatePosition()
  if ns.db.minimapHidden then btn:Hide() else btn:Show() end
end

ns.RegisterModule(CreateButton)

ns.RegisterCommand("minimap", true, function()
  ns.db.minimapHidden = not ns.db.minimapHidden
  if ns.db.minimapHidden then
    btn:Hide()
    ns.Print(ns.T("MM_HIDDEN"))
  else
    btn:Show()
    ns.Print(ns.T("MM_SHOWN"))
  end
  if ns.RefreshMenu then ns.RefreshMenu() end
end)
