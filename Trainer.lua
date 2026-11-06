-- ShamanPlan: trainer reminder. Compares the highest rank you know of each spell with
-- what your class trainer teaches at your level (TrainData.lua), lists what you can
-- train now, and pings you when something new becomes trainable.
-- If the game doesn't report spell ranks, it falls back to an "every even level" reminder.
local _, ns = ...

local lastPinged = ""

local function RankOf(id)
  if not (id and GetSpellSubtext) then return nil end
  local ok, s = pcall(GetSpellSubtext, id)
  if ok and type(s) == "string" then return tonumber(s:match("(%d+)")) end
  return nil
end

-- The highest rank of a spell the trainer teaches up to this level.
local function AvailableRank(list, level)
  local best
  for _, e in ipairs(list) do
    if e[1] <= level and (not best or e[2] > best) then best = e[2] end
  end
  return best
end

-- Returns a sorted list of "Spell N" you could train now, and whether ranks were readable.
function ns.Trainable()
  local level = UnitLevel("player") or 1
  local out, readable = {}, false
  for name, list in pairs(ns.RANK_TABLE or {}) do
    local known, id = ns.SpellInfo(name)
    if known then
      local have = RankOf(id)
      if have then
        readable = true
        local can = AvailableRank(list, level)
        if can and can > have then table.insert(out, { name = name, rank = can }) end
      end
    end
  end
  table.sort(out, function(a, b) return a.name < b.name end)
  local text = {}
  for _, e in ipairs(out) do table.insert(text, ns.T("TR_RANK", e.name, e.rank)) end
  return text, readable
end

local function LastEven(level)
  return level - (level % 2)
end

local function IsProfessionTrainer()
  if IsTradeskillTrainer then
    local ok, v = pcall(IsTradeskillTrainer)
    if ok then return v end
  end
  return false
end

local function Ping(force)
  local list, readable = ns.Trainable()
  if not readable or #list == 0 then return end
  local key = table.concat(list, ",")
  if key == lastPinged and not force then return end
  lastPinged = key
  local msg = ns.T("TR_PING", table.concat(list, ", "))
  ns.Print("|cff9d9dff" .. msg .. "|r")
  if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage(msg, 0.6, 0.6, 1) end
  if PlaySound and SOUNDKIT and SOUNDKIT.UI_TRAINER_SPELL_LEARNED_OR_PURCHASED then
    pcall(PlaySound, SOUNDKIT.UI_TRAINER_SPELL_LEARNED_OR_PURCHASED)
  end
end

ns.RegisterModule(function()
  if ns.db.trainerVisited == nil then
    ns.db.trainerVisited = LastEven(UnitLevel("player") or 1)
  end

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("TRAINER_SHOW")
  ev:RegisterEvent("PLAYER_LEVEL_UP")
  ev:RegisterEvent("SPELLS_CHANGED")
  ev:SetScript("OnEvent", function(_, event)
    if event == "TRAINER_SHOW" then
      if IsProfessionTrainer() then return end
      ns.db.trainerVisited = UnitLevel("player") or 1
      ns.Debounce("main", 0.3, ns.RefreshMain)
    elseif event == "PLAYER_LEVEL_UP" then
      -- UnitLevel updates a moment after the event.
      C_Timer.After(1.5, function() pcall(Ping, false) end)
    else
      ns.Debounce("main", 0.5, ns.RefreshMain)
    end
  end)
  C_Timer.After(8, function() pcall(Ping, true) end)

  ns.AddStatusProvider(function()
    local list, readable = ns.Trainable()
    if readable then
      if #list > 0 then
        return "|cff9d9dff" .. ns.T("TR_CAN") .. "|r " .. table.concat(list, ", ")
      end
      return nil
    end
    -- Fallback when ranks can't be read: nag once per even level until you visit a trainer.
    local level = UnitLevel("player") or 1
    local lastEven = LastEven(level)
    if lastEven >= 2 and (ns.db.trainerVisited or 0) < lastEven then
      return "|cff9d9dff" .. ns.T("TRAINER_DUE", lastEven) .. "|r"
    end
  end)
end)

ns.RegisterCommand("train", true, function() Ping(true) end)
