-- ShamanPlan: trainer reminder. Mages get new spell ranks at every even level.
-- Shows a reminder until you've opened your class trainer at that level.
local _, ns = ...

local function LastEven(level)
  return level - (level % 2)
end

local function Due()
  local level = UnitLevel("player") or 1
  local lastEven = LastEven(level)
  return lastEven >= 2 and (ns.db.trainerVisited or 0) < lastEven, lastEven
end

local function IsProfessionTrainer()
  if IsTradeskillTrainer then
    local ok, v = pcall(IsTradeskillTrainer)
    if ok then return v end
  end
  return false
end

ns.RegisterModule(function()
  -- First run: don't nag about levels you had before installing the addon.
  if ns.db.trainerVisited == nil then
    ns.db.trainerVisited = LastEven(UnitLevel("player") or 1)
  end

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("TRAINER_SHOW")
  ev:RegisterEvent("PLAYER_LEVEL_UP")
  ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "TRAINER_SHOW" then
      if IsProfessionTrainer() then return end
      ns.db.trainerVisited = UnitLevel("player") or 1
      ns.Debounce("main", 0.3, ns.RefreshMain)
    elseif event == "PLAYER_LEVEL_UP" then
      local lvl = tonumber(arg1)
      if lvl and lvl % 2 == 0 then
        ns.Print("|cff9d9dff" .. ns.T("TRAINER_LVLUP") .. "|r")
      end
    end
  end)

  ns.AddStatusProvider(function()
    local due, lvl = Due()
    if due then return "|cff9d9dff" .. ns.T("TRAINER_DUE", lvl) .. "|r" end
  end)
end)
