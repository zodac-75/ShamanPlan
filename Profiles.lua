-- ShamanPlan: layout profiles.
-- A profile holds where every window sits, its size, the look and which features are on.
-- The active profile saves itself whenever you switch away or log out, so there is no
-- save button. Profiles and the choice of profile are account-wide: every character
-- uses the same one, so a change on one character shows up on all of them.
-- Optionally a profile loads by itself in dungeons, and the previous one comes back after.
local _, ns = ...

local DEFAULT = "Default"

-- Everything a profile remembers (all live in ns.db).
local KEYS = {
  -- windows
  "pos", "posW", "posS", "hidden",
  "craftPos", "craftPosW", "craftPosS",
  "shatterPos", "shatterScale",
  "arrowPos", "dungeonPos", "configPos",
  "minimapAngle", "minimapHidden",
  -- look
  "theme", "fontSize",
  -- features
  "shatterOff", "upgradeOff", "questOff",
  "drinkOff", "drinkPct", "xpOff", "zoneTipsOff", "locked", "dungeonAutoOpen",
}

local function Store()
  ShamanPlanGlobal = ShamanPlanGlobal or {}
  ShamanPlanGlobal.profiles = ShamanPlanGlobal.profiles or {}
  return ShamanPlanGlobal.profiles
end

local function Copy(v)
  if type(v) ~= "table" then return v end
  local t = {}
  for k, x in pairs(v) do t[k] = Copy(x) end
  return t
end

function ns.ProfileNames()
  local names = {}
  for name in pairs(Store()) do names[#names + 1] = name end
  table.sort(names, function(a, b)
    if a == DEFAULT then return true elseif b == DEFAULT then return false end
    return a:lower() < b:lower()
  end)
  return names
end

-- Account-wide choices.
local function G()
  ShamanPlanGlobal = ShamanPlanGlobal or {}
  return ShamanPlanGlobal
end
function ns.ActiveProfile() return G().activeProfile or DEFAULT end
function ns.DungeonProfile() return G().dungeonProfile end

local function SaveInto(name)
  local p = {}
  for _, k in ipairs(KEYS) do p[k] = Copy(ns.db[k]) end
  Store()[name] = p
end

---------------------------------------------------------------------------
-- Putting the windows where the settings say
---------------------------------------------------------------------------
local function Place(f, pos, default)
  if not f then return end
  f:ClearAllPoints()
  local p = pos or default
  f:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end

local function ApplyAll()
  local db = ns.db
  for _, f in ipairs({ _G.ShamanPlanFrame, _G.ShamanPlanCraftFrame }) do
    if f and f.posKey then
      local k = f.posKey
      f:SetScale(db[k .. "S"] or 1)
      if db[k .. "W"] then f:SetWidth(db[k .. "W"]) end
      Place(f, db[k], f.defaultPoint)
    end
  end
  local main = _G.ShamanPlanFrame
  if main then
    if db.hidden then main:Hide() else main:Show() end
  end
  local sh = _G.ShamanPlanShatterFrame
  if sh then
    sh:SetScale(db.shatterScale or 1)
    Place(sh, db.shatterPos, { "CENTER", "CENTER", 0, -150 })
  end
  Place(_G.ShamanPlanArrow, db.arrowPos, { "TOP", "TOP", 0, -120 })
  Place(_G.ShamanPlanDungeons, db.dungeonPos, { "CENTER", "CENTER", 0, 40 })
  Place(_G.ShamanPlanConfig, db.configPos, { "CENTER", "CENTER", 0, -30 })
  if ns.UpdateMinimapButton then ns.UpdateMinimapButton() end
  ns.ApplyThemeAll()
  ns.ApplyFontAll()
  ns.RefreshMain()
  if ns.RefreshMenu then ns.RefreshMenu() end
end

local function LoadFrom(name)
  local p = Store()[name]
  if not p then return false end
  for _, k in ipairs(KEYS) do ns.db[k] = Copy(p[k]) end
  G().activeProfile = name
  ApplyAll()
  return true
end

---------------------------------------------------------------------------
-- Public
---------------------------------------------------------------------------
function ns.SwitchProfile(name, quiet)
  if not Store()[name] or name == ns.ActiveProfile() then return end
  SaveInto(ns.ActiveProfile())
  LoadFrom(name)
  if not quiet then ns.Print(ns.T("PR_LOADED", name)) end
end

function ns.StepProfile(dir)
  local names = ns.ProfileNames()
  local cur = 1
  for i, n in ipairs(names) do if n == ns.ActiveProfile() then cur = i end end
  ns.SwitchProfile(names[((cur - 1 + dir) % #names) + 1])
end

-- New profile from the current layout, and switch to it.
function ns.NewProfile(name)
  name = (name or ""):match("^%s*(.-)%s*$")
  if name == "" then return end
  if Store()[name] then
    ns.Print(ns.T("PR_EXISTS", name))
    return
  end
  SaveInto(ns.ActiveProfile())
  SaveInto(name)
  G().activeProfile = name
  ns.Print(ns.T("PR_CREATED", name))
  if ns.RefreshMenu then ns.RefreshMenu() end
end

function ns.DeleteProfile(name)
  name = name or ns.ActiveProfile()
  local names = ns.ProfileNames()
  if #names <= 1 or not Store()[name] then
    ns.Print(ns.T("PR_LAST"))
    return
  end
  Store()[name] = nil
  if G().dungeonProfile == name then G().dungeonProfile = nil end
  if name == ns.ActiveProfile() then
    G().activeProfile = nil
    LoadFrom(ns.ProfileNames()[1])
  end
  ns.Print(ns.T("PR_DELETED", name))
  if ns.RefreshMenu then ns.RefreshMenu() end
end

-- The profile to use in dungeons ("off" when nil).
function ns.StepDungeonProfile(dir)
  local list = { false }
  for _, n in ipairs(ns.ProfileNames()) do list[#list + 1] = n end
  local cur = 1
  for i, n in ipairs(list) do if n == (G().dungeonProfile or false) then cur = i end end
  G().dungeonProfile = list[((cur - 1 + dir) % #list) + 1] or nil
end

---------------------------------------------------------------------------
-- Name prompt and delete confirmation
---------------------------------------------------------------------------
local function EditBoxOf(popup)
  return popup.editBox or popup.EditBox or (popup.GetEditBox and popup:GetEditBox())
end

local function SetupPopups()
  if not StaticPopupDialogs then return end
  StaticPopupDialogs.SHAMANPLAN_NEW_PROFILE = {
    text = ns.T("PR_ASK_NAME"),
    button1 = ACCEPT or "OK",
    button2 = CANCEL or "Cancel",
    hasEditBox = true,
    maxLetters = 24,
    OnShow = function(self)
      local eb = EditBoxOf(self)
      if eb then eb:SetText(""); eb:SetFocus() end
    end,
    OnAccept = function(self)
      local eb = EditBoxOf(self)
      ns.NewProfile(eb and eb:GetText())
    end,
    EditBoxOnEnterPressed = function(self)
      ns.NewProfile(self:GetText())
      self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0, whileDead = true, hideOnEscape = true,
  }
  StaticPopupDialogs.SHAMANPLAN_DELETE_PROFILE = {
    text = ns.T("PR_ASK_DELETE"),
    button1 = YES or "Yes",
    button2 = NO or "No",
    OnAccept = function() ns.DeleteProfile() end,
    timeout = 0, whileDead = true, hideOnEscape = true,
  }
end

function ns.AskNewProfile()
  if StaticPopup_Show and StaticPopupDialogs and StaticPopupDialogs.SHAMANPLAN_NEW_PROFILE then
    StaticPopupDialogs.SHAMANPLAN_NEW_PROFILE.text = ns.T("PR_ASK_NAME")
    StaticPopup_Show("SHAMANPLAN_NEW_PROFILE")
  else
    ns.Print(ns.T("PR_USAGE"))
  end
end

function ns.AskDeleteProfile()
  if #ns.ProfileNames() <= 1 then ns.Print(ns.T("PR_LAST")) return end
  if StaticPopup_Show and StaticPopupDialogs and StaticPopupDialogs.SHAMANPLAN_DELETE_PROFILE then
    StaticPopupDialogs.SHAMANPLAN_DELETE_PROFILE.text = ns.T("PR_ASK_DELETE", ns.ActiveProfile())
    StaticPopup_Show("SHAMANPLAN_DELETE_PROFILE")
  else
    ns.DeleteProfile()
  end
end

---------------------------------------------------------------------------
-- Start-up, logout and dungeons
---------------------------------------------------------------------------
local function OnZone()
  local want = G().dungeonProfile
  local _, instType = GetInstanceInfo()
  local inDungeon = instType == "party" or instType == "raid"
  if inDungeon and want and Store()[want] then
    if ns.ActiveProfile() ~= want then
      G().profileBeforeDungeon = ns.ActiveProfile()
      ns.SwitchProfile(want)
    end
  elseif not inDungeon and G().profileBeforeDungeon then
    local back = G().profileBeforeDungeon
    G().profileBeforeDungeon = nil
    if Store()[back] then ns.SwitchProfile(back) end
  end
end

ns.RegisterModule(function()
  SetupPopups()
  local store = Store()
  if not next(store) then
    SaveInto(DEFAULT) -- first time: today's layout becomes "Default"
  elseif not store[ns.ActiveProfile()] then
    G().activeProfile = nil
    if not store[DEFAULT] then SaveInto(DEFAULT) end
  end
  -- Another character may have changed the shared profile: apply it once everything exists.
  C_Timer.After(0, function() LoadFrom(ns.ActiveProfile()) end)

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_LOGOUT")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGOUT" then
      SaveInto(ns.ActiveProfile())
    else
      C_Timer.After(1, OnZone)
    end
  end)
end)

ns.RegisterCommand("profile", true, function(rest)
  local cmd, arg = (rest or ""):match("^(%S*)%s*(.-)$")
  cmd = (cmd or ""):lower()
  if cmd == "new" then
    ns.NewProfile(arg)
  elseif cmd == "delete" then
    ns.DeleteProfile(arg ~= "" and arg or nil)
  elseif cmd ~= "" then
    local want = rest:match("^%s*(.-)%s*$")
    for _, n in ipairs(ns.ProfileNames()) do
      if n:lower() == want:lower() then ns.SwitchProfile(n) return end
    end
    ns.Print(ns.T("PR_UNKNOWN", want))
  else
    ns.Print(ns.T("PR_LIST", ns.ActiveProfile(), table.concat(ns.ProfileNames(), ", ")))
    ns.Print(ns.T("PR_USAGE"))
  end
end)
