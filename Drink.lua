-- ShamanPlan: drink reminder. Out of combat with low mana and not drinking: show a nudge.
local _, ns = ...

local f, txt
local DRINK_BUFFS = { ["Drink"] = true, ["Food & Drink"] = true, ["Refreshment"] = true }

-- Mana in percent, or nil when the game hides the value from addons ("secret" values).
local function Readable(v)
  return type(v) == "number" and not (issecretvalue and issecretvalue(v))
end

function ns.ManaPct()
  local ok, pct = pcall(function()
    local cur, max = UnitPower("player", 0), UnitPowerMax("player", 0)
    if Readable(cur) and Readable(max) and max > 0 then return cur / max * 100 end
  end)
  if ok and pct then return pct end
  if UnitPowerPercent then
    local scale = CurveConstants and CurveConstants.ScaleTo100
    local ok2, p = pcall(UnitPowerPercent, "player", 0, false, scale)
    if ok2 and Readable(p) then
      if not scale and p <= 1 then p = p * 100 end
      return p
    end
  end
  return nil
end

local function Check()
  if not f then return end
  if ns.db.drinkOff or UnitAffectingCombat("player") or (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) then
    f:Hide()
    return
  end
  local pct = ns.ManaPct()
  if not pct then f:Hide() return end
  local drinking = ns.ForEachAura("player", "HELPFUL", function(n) return DRINK_BUFFS[n] end)
  if pct < (ns.db.drinkPct or 40) and not drinking then
    txt:SetText("|cff66ccff" .. ns.T("DRINK", math.floor(pct)) .. "|r")
    f:Show()
  else
    f:Hide()
  end
end

ns.RegisterModule(function()
  f = CreateFrame("Frame", "ShamanPlanDrinkFrame", UIParent)
  f:SetSize(300, 24)
  f:SetPoint("TOP", _G.ShamanPlanShatterFrame or UIParent, _G.ShamanPlanShatterFrame and "BOTTOM" or "CENTER", 0, _G.ShamanPlanShatterFrame and -6 or -210)
  txt = f:CreateFontString(nil, "OVERLAY")
  txt:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
  txt:SetPoint("CENTER")
  f:Hide()

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_REGEN_ENABLED")
  ev:RegisterEvent("PLAYER_REGEN_DISABLED")
  ev:RegisterEvent("UNIT_POWER_UPDATE")
  ev:RegisterEvent("UNIT_AURA")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:SetScript("OnEvent", function(_, event, unit)
    if (event == "UNIT_POWER_UPDATE" or event == "UNIT_AURA") and unit ~= "player" then return end
    ns.Debounce("drink", 0.2, Check)
  end)
end)

ns.RegisterCommand("drink", true, function()
  ns.db.drinkOff = not ns.db.drinkOff
  ns.Print(ns.db.drinkOff and ns.T("DRINK_OFF") or ns.T("DRINK_ON"))
  pcall(Check)
end)

ns.RegisterCommand("drinkat", true, function(rest)
  local n = tonumber((rest or ""):match("(%d+)"))
  if n and n > 0 and n < 100 then
    ns.db.drinkPct = n
    ns.Print(ns.T("DRINK_SET", n))
    pcall(Check)
  end
end)
