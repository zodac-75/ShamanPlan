-- ShamanPlan: visar nästa talent enligt planen och markerar det i talentfönstret.
local _, ns = ...

local TREES = { "Elemental", "Enhancement", "Restoration" }
local glow, hint

-- Alla talents: namn -> {tab, index, tier, rank, max}
local function TalentMap()
  local map = {}
  if not (GetNumTalentTabs and GetNumTalents and GetTalentInfo) then return map end
  local okT, tabs = pcall(GetNumTalentTabs)
  if not okT or not tabs then return map end
  for tab = 1, tabs do
    local okN, n = pcall(GetNumTalents, tab)
    if okN and n then
      for i = 1, n do
        local ok, name, _, tier, _, rank, maxRank = pcall(GetTalentInfo, tab, i)
        if ok and name then
          map[name] = { tab = tab, index = i, tier = tier, rank = rank or 0, max = maxRank }
        end
      end
    end
  end
  return map
end

-- Första steget i planen som inte är gjort än.
-- Returns name, talent info, wanted rank; "done" when the plan is complete.
function ns.NextTalent()
  local map = TalentMap()
  if not next(map) then return nil end
  for lvl = 10, 60 do
    local entry = ns.talents[lvl]
    if entry then
      local name, want = entry:match("^(.-)%s+(%d+)/%d+$")
      want = tonumber(want)
      local t = name and map[name]
      if t and want and t.rank < want then
        return name, t, want
      end
    end
  end
  return "done"
end

local function Unspent()
  if UnitCharacterPoints then
    local ok, p = pcall(UnitCharacterPoints, "player")
    if ok and type(p) == "number" then return p end
  end
  return nil
end

local function NextText()
  local name, t, want = ns.NextTalent()
  if not name then return nil end
  if name == "done" then
    return "|cffffd100" .. ns.T("PLAN_DONE") .. "|r"
  end
  local tree = TREES[t.tab] or ns.T("TREE_N", t.tab)
  return "|cffffd100" .. ns.T("NEXT_TALENT") .. "|r " .. ns.T("NEXT_FMT", name, want, t.max or want, tree, t.tier or 0)
end

local function UpdateGlow()
  if not glow then return end
  glow:Hide()
  if hint then hint:SetText("") end
  if not (PlayerTalentFrame and PlayerTalentFrame:IsShown()) then return end

  local line = NextText()
  if hint and line then hint:SetText("ShamanPlan: " .. line:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

  local name, t = ns.NextTalent()
  if not t or name == "done" then return end
  local sel
  if PanelTemplates_GetSelectedTab then
    local ok, s = pcall(PanelTemplates_GetSelectedTab, PlayerTalentFrame)
    if ok then sel = s end
  end
  sel = sel or PlayerTalentFrame.selectedTab
  if sel and sel ~= t.tab then return end

  local btn = _G["PlayerTalentFrameTalent" .. t.index]
  if not btn or not btn:IsShown() then return end
  glow:SetParent(btn)
  glow:ClearAllPoints()
  glow:SetPoint("CENTER", btn, "CENTER", 0, 0)
  glow:SetSize(btn:GetWidth() * 1.9, btn:GetHeight() * 1.9)
  glow:SetFrameLevel(btn:GetFrameLevel() + 5)
  glow:Show()
end

local function SetupTalentUI()
  if glow or not PlayerTalentFrame then return end
  glow = CreateFrame("Frame", nil, UIParent)
  local tex = glow:CreateTexture(nil, "OVERLAY")
  tex:SetAllPoints()
  tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  tex:SetBlendMode("ADD")
  tex:SetVertexColor(0.3, 0.8, 1)
  local ag = glow:CreateAnimationGroup()
  local a = ag:CreateAnimation("Alpha")
  a:SetFromAlpha(1)
  a:SetToAlpha(0.3)
  a:SetDuration(0.6)
  ag:SetLooping("BOUNCE")
  ag:Play()
  glow:Hide()

  hint = PlayerTalentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  hint:SetPoint("BOTTOM", PlayerTalentFrame, "TOP", 0, 4)

  PlayerTalentFrame:HookScript("OnShow", function() C_Timer.After(0.05, UpdateGlow) end)
  if PlayerTalentFrame_Update then hooksecurefunc("PlayerTalentFrame_Update", UpdateGlow) end
  if PanelTemplates_SetTab then
    hooksecurefunc("PanelTemplates_SetTab", function(f)
      if f == PlayerTalentFrame then C_Timer.After(0.05, UpdateGlow) end
    end)
  end
end

function ns.RefreshTalentGlow() pcall(UpdateGlow) end

local function OnPointsChanged()
  ns.RefreshMain()
  UpdateGlow()
end

ns.RegisterModule(function()
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("ADDON_LOADED")
  ev:RegisterEvent("CHARACTER_POINTS_CHANGED")
  ev:RegisterEvent("PLAYER_LEVEL_UP")
  ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
      if arg1 == "Blizzard_TalentUI" then pcall(SetupTalentUI) end
    else
      ns.Debounce("talents", 0.3, OnPointsChanged)
    end
  end)
  if PlayerTalentFrame then pcall(SetupTalentUI) end

  ns.AddStatusProvider(function()
    local line = NextText()
    if not line then return nil end
    local u = Unspent()
    if u and u > 0 then
      line = line .. " |cff60ff60" .. ns.T("POINTS_TO_SPEND", u) .. "|r"
    end
    return line
  end)

  C_Timer.After(5, function()
    local u = Unspent()
    local line = NextText()
    if u and u > 0 and line then
      ns.Print(ns.T("LOGIN_POINTS", u, line))
    end
  end)
end)
