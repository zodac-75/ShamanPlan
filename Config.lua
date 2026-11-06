-- ShamanPlan: settings window with the logo.
-- Opens with right-click on the minimap icon, /sp config, or from the game's
-- AddOns settings. Features on the left, plan and look on the right, tools below.
local _, ns = ...

local LOGO = ns.MEDIA .. "Logo"
local LOGO_H = 1 -- the round logo fills the whole 512x512 texture

local win
local checks, selectors, labels = {}, {}, {}

local function Run(cmd, arg)
  local fn = ns.commands[cmd]
  if not fn then return end
  local ok, err = pcall(fn, arg or "")
  if not ok then ns.Print(ns.T("ERROR", tostring(err))) end
end

local function Val(s) return "|cff3fa9ff" .. s .. "|r" end

-- Steps through a list of {key=...} by dir (+1 / -1) and returns the new key.
local function Step(list, current, dir)
  local i = 1
  for n, item in ipairs(list) do
    local k = type(item) == "table" and item.key or item
    if k == current then i = n end
  end
  i = ((i - 1 + dir) % #list) + 1
  local item = list[i]
  return type(item) == "table" and item.key or item
end

---------------------------------------------------------------------------
-- What the window controls
---------------------------------------------------------------------------
local FEATURES = {
  { key = "MM_SHATTER", on = function() return not ns.db.shatterOff end, cmd = "combat" },
  { key = "MM_MOVE", on = function() return ns.db.shatterUnlocked end, cmd = "move" },
  { key = "MM_UPGRADE", on = function() return not ns.db.upgradeOff end, cmd = "upgrade" },
  { key = "MM_QUEST", on = function() return not ns.db.questOff end, cmd = "quest" },
  { key = "MM_DRINK", on = function() return not ns.db.drinkOff end, cmd = "drink" },
  { key = "MM_XP", on = function() return not ns.db.xpOff end, cmd = "xp" },
  { key = "MM_ZONE", on = function() return not ns.db.zoneTipsOff end, cmd = "zonetips" },
  { key = "CFG_DGAUTO", on = function() return ns.db.dungeonAutoOpen end, cmd = "dungeonauto" },
  { key = "MM_LOCK", on = function() return ns.db.locked end, cmd = "lock" },
  { key = "CFG_MINIMAP", on = function() return not ns.db.minimapHidden end, cmd = "minimap" },
}

local SELECTORS = {
  { key = "MM_THEME",
    value = function() return ns.T("THEME_" .. ns.CurrentTheme().key) end,
    step = function(dir)
      ns.db.theme = Step(ns.THEMES, ns.CurrentTheme().key, dir)
      ns.ApplyThemeAll()
    end },
  { key = "MM_FONT",
    value = function() return ns.T("FONT_" .. ns.CurrentFont().key) end,
    step = function(dir)
      ns.db.fontSize = Step(ns.FONTS, ns.CurrentFont().key, dir)
      ns.ApplyFontAll()
    end },
  { key = "MM_LANG",
    value = function() return ns.Lang() == "svSE" and "Svenska" or "English" end,
    step = function() ns.CycleLang() end },
  { key = "CFG_DRINKAT",
    value = function() return (ns.db.drinkPct or 40) .. "%" end,
    step = function(dir)
      local n = math.max(10, math.min(90, (ns.db.drinkPct or 40) + dir * 5))
      Run("drinkat", tostring(n))
    end },
}

local PROFILE_SELECTORS = {
  { key = "CFG_PROFILE",
    value = function() return ns.ActiveProfile() end,
    step = function(dir) ns.StepProfile(dir) end },
  { key = "CFG_DGPROFILE",
    value = function() return ns.DungeonProfile() or ns.T("CFG_OFF") end,
    step = function(dir) ns.StepDungeonProfile(dir) end },
}

local TOOLS = {
  { key = "MM_PLAN", func = function() ns.ToggleMain() end },
  { key = "MM_DUNGEONS", func = function() ns.ToggleDungeons() end },
  { key = "MM_CRAFT", func = function() Run("craft") end },
  { key = "MM_RANKS", func = function() Run("ranks") end },
  { key = "MM_ALL", func = function() Run("all") end },
  { key = "MM_RESET", func = function() Run("reset") end },
  { key = "CFG_HELP", func = function() Run("help") end },
}

---------------------------------------------------------------------------
-- Refresh: texts follow the language, checkboxes follow the saved settings.
---------------------------------------------------------------------------
local function Refresh()
  if not win then return end
  for _, fs in ipairs(labels) do fs:SetText(ns.T(fs.key)) end
  for _, cb in ipairs(checks) do
    local ok, on = pcall(cb.item.on)
    cb:SetChecked(ok and on and true or false)
    cb.label:SetText(ns.T(cb.item.key))
  end
  for _, s in ipairs(selectors) do
    s.label:SetText((ns.T(s.item.key):gsub(":$", "")))
    local ok, v = pcall(s.item.value)
    s.value:SetText(Val(ok and v or "?"))
  end
  for _, b in ipairs(win.tools) do b:SetText(ns.T(b.key)) end
end
ns.RefreshMenu = function() if win and win:IsShown() then Refresh() end end

---------------------------------------------------------------------------
-- Building blocks
---------------------------------------------------------------------------
local function Header(parent, key, x, y)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetPoint("TOPLEFT", x, y)
  fs:SetTextColor(0.41, 0.8, 0.94)
  fs.key = key
  table.insert(labels, fs)
  local line = parent:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(0.41, 0.8, 0.94, 0.35)
  line:SetPoint("TOPLEFT", x, y - 16)
  line:SetSize(236, 1)
  return fs
end

local function CheckRow(parent, item, x, y)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetSize(22, 22)
  cb:SetPoint("TOPLEFT", x, y)
  local label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
  label:SetWidth(205)
  label:SetJustifyH("LEFT")
  cb.label = label
  cb.item = item
  cb:SetScript("OnClick", function()
    Run(item.cmd)
    Refresh()
  end)
  table.insert(checks, cb)
end

local function ArrowButton(parent, dir)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(22, 22)
  local base = dir < 0 and "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-" or "Interface\\Buttons\\UI-SpellbookIcon-NextPage-"
  b:SetNormalTexture(base .. "Up")
  b:SetPushedTexture(base .. "Down")
  b:SetDisabledTexture(base .. "Disabled")
  b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  return b
end

local function SelectorRow(parent, item, x, y)
  local s = {}
  s.item = item
  s.label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  s.label:SetPoint("TOPLEFT", x, y - 5)
  s.label:SetWidth(92)
  s.label:SetJustifyH("LEFT")

  local prev = ArrowButton(parent, -1)
  prev:SetPoint("TOPLEFT", x + 94, y)
  local nextB = ArrowButton(parent, 1)
  nextB:SetPoint("TOPLEFT", x + 214, y)

  s.value = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  s.value:SetPoint("LEFT", prev, "RIGHT", 0, 0)
  s.value:SetPoint("RIGHT", nextB, "LEFT", 0, 0)
  s.value:SetJustifyH("CENTER")

  local function Go(dir)
    local ok, err = pcall(item.step, dir)
    if not ok then ns.Print(ns.T("ERROR", tostring(err))) end
    Refresh()
  end
  prev:SetScript("OnClick", function() Go(-1) end)
  nextB:SetScript("OnClick", function() Go(1) end)
  table.insert(selectors, s)
end

local function Version()
  local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local v = get and get("ShamanPlan", "Version")
  if v and not v:find("@") then return "v" .. v end
  return ""
end

---------------------------------------------------------------------------
-- The window
---------------------------------------------------------------------------
local function CreateConfig()
  win = CreateFrame("Frame", "ShamanPlanConfig", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  win:SetSize(540, 500)
  win:SetFrameStrata("DIALOG")
  win:SetToplevel(true)
  win:SetClampedToScreen(true)
  win:SetClampRectInsets(0, 0, 70, 0) -- keep the logo on screen too
  win:EnableMouse(true)
  win:SetMovable(true)
  win:RegisterForDrag("LeftButton")
  win:SetScript("OnDragStart", win.StartMoving)
  win:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    ns.db.configPos = { p, rp, x, y }
  end)
  local p = ns.db.configPos
  if p then
    win:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  else
    win:SetPoint("CENTER", 0, -30)
  end
  table.insert(ns.themedFrames, win)
  ns.ApplyTheme(win)
  table.insert(UISpecialFrames, "ShamanPlanConfig") -- Esc closes it

  -- The logo sits on the top edge and sticks out above the window.
  local logo = win:CreateTexture(nil, "OVERLAY")
  logo:SetTexture(LOGO)
  logo:SetTexCoord(0, 1, 0, LOGO_H)
  logo:SetSize(200, 200 * LOGO_H)
  logo:SetPoint("TOP", 0, 62)

  local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -2, -2)

  local version = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  version:SetPoint("TOPLEFT", 12, -10)
  version:SetText(Version())

  local top = -142
  -- Left: features
  Header(win, "CFG_FEATURES", 16, top)
  for i, item in ipairs(FEATURES) do CheckRow(win, item, 14, top - 22 - (i - 1) * 22) end

  -- Right: plan and look
  Header(win, "CFG_LOOK", 288, top)
  for i, item in ipairs(SELECTORS) do SelectorRow(win, item, 288, top - 24 - (i - 1) * 28) end
  local hint = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("TOPLEFT", 288, top - 24 - #SELECTORS * 28 - 2)
  hint:SetWidth(236)
  hint:SetJustifyH("LEFT")
  hint.key = "MM_HINT"
  table.insert(labels, hint)

  -- Right, below: profiles (shared by all characters)
  local py = top - 24 - #SELECTORS * 28 - 34
  Header(win, "CFG_PROFILES", 288, py)
  for i, item in ipairs(PROFILE_SELECTORS) do SelectorRow(win, item, 288, py - 24 - (i - 1) * 28) end
  py = py - 24 - #PROFILE_SELECTORS * 28
  local function SmallButton(key, x, fn)
    local b = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    b:SetSize(115, 22)
    b:SetPoint("TOPLEFT", x, py)
    b.key = key
    b:SetScript("OnClick", function()
      local ok, err = pcall(fn)
      if not ok then ns.Print(ns.T("ERROR", tostring(err))) end
      Refresh()
    end)
    table.insert(win.tools, b)
  end
  win.tools = {}
  SmallButton("CFG_NEW", 288, function() ns.AskNewProfile() end)
  SmallButton("CFG_DELETE", 409, function() ns.AskDeleteProfile() end)
  py = py - 26

  -- Bottom: tools, three columns of buttons
  local toolsTop = math.min(top - 22 - #FEATURES * 22, py) - 14
  Header(win, "CFG_TOOLS", 16, toolsTop)
  local line = win:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(0.41, 0.8, 0.94, 0.35)
  line:SetPoint("TOPLEFT", 252, toolsTop - 16)
  line:SetSize(272, 1)
  for i, t in ipairs(TOOLS) do
    local b = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    b:SetSize(164, 22)
    local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
    b:SetPoint("TOPLEFT", 16 + col * 172, toolsTop - 24 - row * 26)
    b.key = t.key
    b:SetScript("OnClick", function()
      local ok, err = pcall(t.func)
      if not ok then ns.Print(ns.T("ERROR", tostring(err))) end
      Refresh()
    end)
    table.insert(win.tools, b)
  end
  local rows = math.ceil(#TOOLS / 3)
  win:SetHeight(-(toolsTop - 24 - rows * 26) + 12)

  win:SetScript("OnShow", Refresh)
  win:Hide()
end

function ns.ToggleConfig()
  if not win then return end
  if win:IsShown() then win:Hide() else win:Show() end
end

---------------------------------------------------------------------------
-- Entry in the game's own AddOns settings
---------------------------------------------------------------------------
local function RegisterBlizzardPanel()
  local panel = CreateFrame("Frame")
  panel.name = "ShamanPlan"

  local logo = panel:CreateTexture(nil, "ARTWORK")
  logo:SetTexture(LOGO)
  logo:SetTexCoord(0, 1, 0, LOGO_H)
  logo:SetSize(260, 260 * LOGO_H)
  logo:SetPoint("TOP", 0, -16)

  local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  b:SetSize(240, 26)
  b:SetPoint("TOP", logo, "BOTTOM", 0, -12)
  b:SetText(ns.T("CFG_OPEN"))
  b:SetScript("OnClick", function()
    if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then HideUIPanel(InterfaceOptionsFrame) end
    if win and not win:IsShown() then win:Show() end
  end)
  panel:SetScript("OnShow", function() b:SetText(ns.T("CFG_OPEN")) end)

  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local cat = Settings.RegisterCanvasLayoutCategory(panel, "ShamanPlan")
    Settings.RegisterAddOnCategory(cat)
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
end

ns.RegisterModule(function()
  CreateConfig()
  local ok, err = pcall(RegisterBlizzardPanel)
  if not ok then ns.Print(ns.T("ERROR", tostring(err))) end
end)

ns.RegisterCommand("config", true, function() ns.ToggleConfig() end)
