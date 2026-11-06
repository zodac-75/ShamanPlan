-- ShamanPlan: XP tracker. XP per hour, time to level and kills to level.
local _, ns = ...

local startTime, gained, lastXP, lastMax, lastKill

local function Reset()
  startTime = GetTime()
  gained = 0
  lastXP = UnitXP and UnitXP("player") or 0
  lastMax = UnitXPMax and UnitXPMax("player") or 1
end

local function Short(n)
  if n >= 1000 then return string.format("%.1fk", n / 1000) end
  return tostring(math.floor(n + 0.5))
end

local function Duration(sec)
  sec = math.max(0, math.floor(sec))
  local h, m = math.floor(sec / 3600), math.floor((sec % 3600) / 60)
  if h > 0 then return string.format("%dh %dm", h, m) end
  return string.format("%dm", math.max(1, m))
end

local function OnXP()
  local xp, max = UnitXP("player"), UnitXPMax("player")
  local delta = xp - lastXP
  if delta < 0 then delta = (lastMax - lastXP) + xp end -- dinged
  gained = gained + delta
  lastXP, lastMax = xp, max
  ns.Debounce("main", 0.5, ns.RefreshMain)
end

local function Status()
  if ns.db.xpOff then return nil end
  if (UnitLevel("player") or 1) >= 60 then return nil end
  local elapsed = GetTime() - startTime
  if elapsed < 120 or gained <= 0 then return nil end
  local rate = gained / elapsed * 3600
  local remaining = UnitXPMax("player") - UnitXP("player")
  local line = "|cffffffff" .. ns.T("XP_LINE", Short(rate), Duration(remaining / rate * 3600)) .. "|r"
  if lastKill and lastKill > 0 then
    line = line .. ns.T("XP_KILLS", math.ceil(remaining / lastKill))
  end
  local rested = GetXPExhaustion and GetXPExhaustion()
  if rested and rested > 0 then line = line .. "|cff66ccff" .. ns.T("XP_RESTED") .. "|r" end
  return line
end

ns.RegisterModule(function()
  if not (UnitXP and UnitXPMax) then return end
  Reset()
  ns.AddStatusProvider(Status)
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_XP_UPDATE")
  ev:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
  ev:SetScript("OnEvent", function(_, event, msg)
    if event == "PLAYER_XP_UPDATE" then
      OnXP()
    elseif type(msg) == "string" and msg:find("dies") then
      local n = tonumber(msg:match("(%d+) experience"))
      if n then lastKill = n end
    end
  end)
end)

ns.RegisterCommand("xp", true, function()
  ns.db.xpOff = not ns.db.xpOff
  ns.Print(ns.db.xpOff and ns.T("XP_OFF") or ns.T("XP_ON"))
  ns.RefreshMain()
end)

ns.RegisterCommand("xpreset", true, function()
  Reset()
  ns.Print(ns.T("XP_RESET"))
  ns.RefreshMain()
end)
