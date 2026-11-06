-- ShamanPlan: checks that your action bars have the highest rank and that new spells
-- are on a button. Forever no longer puts new spells on your bars by itself.
local _, ns = ...

-- Shaman spells with ranks. Healing Wave is left out on purpose: low ranks are often kept for mana.
local CHECK = {
  "Lightning Bolt", "Chain Lightning", "Earth Shock", "Flame Shock", "Frost Shock",
  "Lightning Shield", "Rockbiter Weapon", "Flametongue Weapon", "Frostbrand Weapon", "Windfury Weapon",
  "Searing Totem", "Magma Totem", "Fire Nova", "Flametongue Totem", "Strength of Earth Totem",
  "Stoneskin Totem", "Stoneclaw Totem", "Healing Stream Totem", "Mana Spring Totem", "Windfury Totem",
  "Grace of Air Totem", "Lesser Healing Wave", "Chain Heal", "Purge", "Ancestral Spirit",
  "Earthbind Totem", "Ghost Wolf", "Stormstrike",
}

local outdated, missing = {}, {}

local function RankNumber(id)
  if not GetSpellSubtext then return nil end
  local ok, s = pcall(GetSpellSubtext, id)
  if ok and type(s) == "string" then return tonumber(s:match("(%d+)")) end
  return nil
end

local function SpellsOnBars()
  local onBar = {}
  if not GetActionInfo then return onBar end
  for slot = 1, 120 do
    local ok, kind, id = pcall(GetActionInfo, slot)
    if ok and kind == "spell" and id then
      local name = ns.SpellInfo(id)
      if name then
        onBar[name] = onBar[name] or {}
        table.insert(onBar[name], { slot = slot, id = id })
      end
    end
  end
  return onBar
end

local function Scan(force)
  if InCombatLockdown and InCombatLockdown() then
    ns.rankScanPending = true
    return
  end
  ns.rankScanPending = false
  ns.db.missingSeen = ns.db.missingSeen or {}
  if force then ns.db.missingSeen = {} end

  local onBar = SpellsOnBars()
  local newOutdated, newMissing = {}, {}

  for _, spell in ipairs(CHECK) do
    local name, bestId = ns.SpellInfo(spell)
    if name and bestId then
      local slots = onBar[name]
      if not slots then
        if not ns.db.missingSeen[name] then
          table.insert(newMissing, name)
          ns.db.missingSeen[name] = true
        end
      else
        local bestRank = RankNumber(bestId)
        for _, s in ipairs(slots) do
          local r = RankNumber(s.id)
          -- Varna bara när båda ranks går att läsa och knappen ligger lägre.
          if s.id ~= bestId and r and bestRank and r < bestRank then
            table.insert(newOutdated, ns.T("RANKS_OLD_LINE", name, r, s.slot, bestRank))
          end
        end
      end
    end
  end

  outdated = newOutdated
  for _, n in ipairs(newMissing) do table.insert(missing, n) end

  if #newOutdated > 0 then
    ns.Print("|cffff9900" .. ns.T("RANKS_OLD_HDR") .. "|r")
    for _, l in ipairs(newOutdated) do ns.Print("  " .. l) end
    ns.Print("  " .. ns.T("RANKS_DRAG"))
  end
  if #newMissing > 0 then
    ns.Print("|cffff9900" .. ns.T("RANKS_MISSING") .. "|r " .. table.concat(newMissing, ", "))
  end
  if force and #newOutdated == 0 and #newMissing == 0 then
    ns.Print(ns.T("RANKS_OK"))
  end
  ns.RefreshMain()
end

ns.RegisterModule(function()
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("SPELLS_CHANGED")
  ev:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
  ev:RegisterEvent("PLAYER_REGEN_ENABLED")
  ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" and not ns.rankScanPending then return end
    ns.Debounce("ranks", 2, function() Scan(false) end)
  end)
  C_Timer.After(6, function() pcall(Scan, false) end)

  ns.AddStatusProvider(function()
    if #outdated > 0 then
      return "|cffff9900" .. ns.T("RANKS_STATUS", #outdated) .. "|r (/sp ranks)"
    end
  end)
end)

ns.RegisterCommand("ranks", true, function()
  missing = {}
  Scan(true)
end)
