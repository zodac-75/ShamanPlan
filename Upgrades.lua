-- ShamanPlan: gear upgrade check. Adds a tooltip line comparing an item with what
-- you have equipped, scored in "attack power" using Enhancement leveling stat weights.
local _, ns = ...

-- Stat weights, in attack power per point. Weapon DPS matters most (Stormstrike,
-- Windfury and white hits all scale with it); Intellect counts through Mental Dexterity.
local WEIGHTS = {
  wdps = 14, ap = 1.0, str = 2.0, agi = 1.2, int = 1.4, spi = 0.3, sta = 0.3,
  crit = 20, hit = 15, sp = 0.4, mp5 = 1.5,
}

-- First matching pattern wins per tooltip line, so specific ones come first.
local PATTERNS = {
  { "%((%d+%.?%d*) damage per second%)", "wdps" },
  { "[Aa]ttack [Pp]ower by (%d+)", "ap" },
  { "^%+(%d+) Attack Power", "ap" },
  { "critical strike with spells by (%d+)%%", "none" },
  { "chance to hit with spells by (%d+)%%", "none" },
  { "critical strike by (%d+)%%", "crit" },
  { "chance to hit by (%d+)%%", "hit" },
  { "magical spells and effects by up to (%d+)", "sp" },
  { "[Ss]pell [Pp]ower by (%d+)", "sp" },
  { "^%+(%d+) Spell Damage", "sp" },
  { "^%+(%d+) Damage and Healing Spells", "sp" },
  { "(%d+) mana per 5 sec", "mp5" },
  { "^%+(%d+) Strength", "str" },
  { "^%+(%d+) Agility", "agi" },
  { "^%+(%d+) Intellect", "int" },
  { "^%+(%d+) Spirit", "spi" },
  { "^%+(%d+) Stamina", "sta" },
}

local SLOTS = {
  INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CLOAK = { 15 },
  INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
  INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 },
  INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 },
  INVTYPE_WEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_2HWEAPON = { 16 },
  INVTYPE_HOLDABLE = { 17 }, INVTYPE_WEAPONOFFHAND = { 17 },
  INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 },
}

-- What a shaman can use: cloth, leather, mail, shields and misc armor;
-- axes, maces, staves, fist weapons and daggers (one- and two-handed).
local USABLE_ARMOR = { [0] = true, [1] = true, [2] = true, [3] = true, [6] = true }
local USABLE_WEAPON = { [0] = true, [1] = true, [4] = true, [5] = true, [10] = true, [13] = true, [15] = true }

local scanTip
local cache = {}

local function TooltipLines(link)
  local out = {}
  if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
    local ok, data = pcall(C_TooltipInfo.GetHyperlink, link)
    if ok and type(data) == "table" and data.lines then
      for _, l in ipairs(data.lines) do
        if type(l.leftText) == "string" then table.insert(out, l.leftText) end
      end
      return out
    end
  end
  if not scanTip then
    scanTip = CreateFrame("GameTooltip", "ShamanPlanScanTooltip", UIParent, "GameTooltipTemplate")
  end
  scanTip:SetOwner(UIParent, "ANCHOR_NONE")
  scanTip:ClearLines()
  scanTip:SetHyperlink(link)
  for i = 1, (scanTip:NumLines() or 0) do
    local fs = _G["ShamanPlanScanTooltipTextLeft" .. i]
    local t = fs and fs:GetText()
    if type(t) == "string" then table.insert(out, t) end
  end
  scanTip:Hide()
  return out
end

local function Stats(link)
  if cache[link] then return cache[link] end
  local lines = TooltipLines(link)
  if #lines == 0 then return {} end
  local s = {}
  for _, line in ipairs(lines) do
    if not line:find("Set:") then -- set bonuses only count with the full set
      for _, p in ipairs(PATTERNS) do
        local v = line:match(p[1])
        if v then
          s[p[2]] = (s[p[2]] or 0) + (tonumber(v) or 0)
          break
        end
      end
    end
  end
  cache[link] = s
  return s
end

function ns.ItemScore(link)
  if not link then return 0 end
  local total = 0
  for k, v in pairs(Stats(link)) do total = total + v * (WEIGHTS[k] or 0) end
  return total
end

local function Equipped(slot)
  if not GetInventoryItemLink then return nil end
  local ok, link = pcall(GetInventoryItemLink, "player", slot)
  return ok and link or nil
end

local function IsTwoHander(link)
  if not link then return false end
  local ok, _, _, _, _, _, _, _, _, equipLoc = pcall(ns.ItemInfo, link)
  return ok and equipLoc == "INVTYPE_2HWEAPON"
end

-- Returns diff (or nil if not comparable) and the required level.
function ns.CompareToEquipped(link)
  local ok, name, _, _, _, minLevel, _, _, _, equipLoc, _, _, classID, subclassID = pcall(ns.ItemInfo, link)
  if not ok or not name or not equipLoc then return nil end
  local slots = SLOTS[equipLoc]
  if not slots then return nil end
  if classID == 4 and not USABLE_ARMOR[subclassID] then return nil end
  if classID == 2 and not USABLE_WEAPON[subclassID] then return nil end
  if classID ~= 2 and classID ~= 4 then return nil end

  local newScore = ns.ItemScore(link)
  local oldScore
  if equipLoc == "INVTYPE_2HWEAPON" then
    oldScore = ns.ItemScore(Equipped(16)) + ns.ItemScore(Equipped(17))
  elseif (equipLoc == "INVTYPE_HOLDABLE" or equipLoc == "INVTYPE_WEAPONOFFHAND") and IsTwoHander(Equipped(16)) then
    return nil -- would need to swap out the two-hander as well
  elseif #slots == 2 then
    local a, b = Equipped(slots[1]), Equipped(slots[2])
    if link == a or link == b then return nil end
    oldScore = math.min(ns.ItemScore(a), ns.ItemScore(b))
  else
    local cur = Equipped(slots[1])
    if link == cur then return nil end
    oldScore = ns.ItemScore(cur)
  end
  return newScore - oldScore, minLevel
end

local function OnTooltip(tt)
  if ns.db and ns.db.upgradeOff then return end
  if not tt or tt == scanTip or not tt.GetItem then return end
  local ok, _, link = pcall(tt.GetItem, tt)
  if not ok or not link then return end
  local diff, minLevel = ns.CompareToEquipped(link)
  if not diff then return end
  local line
  if diff >= 0.5 then
    line = "|cff60ff60" .. ns.T("UP_UP", math.floor(diff + 0.5)) .. "|r"
  elseif diff <= -0.5 then
    line = "|cffff6060" .. ns.T("UP_DOWN", math.floor(diff - 0.5)) .. "|r"
  else
    line = "|cffaaaaaa" .. ns.T("UP_SAME") .. "|r"
  end
  local level = UnitLevel("player") or 1
  if minLevel and minLevel > level then
    line = line .. " |cffaaaaaa" .. ns.T("UP_LEVEL", minLevel) .. "|r"
  end
  tt:AddLine("|cff3fa9ffShamanPlan:|r " .. line)
end

ns.RegisterModule(function()
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt) pcall(OnTooltip, tt) end)
  elseif GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetItem", function(tt) pcall(OnTooltip, tt) end)
    if ItemRefTooltip then ItemRefTooltip:HookScript("OnTooltipSetItem", function(tt) pcall(OnTooltip, tt) end) end
  end
  -- Gear changes don't change item stats, but a fresh cache keeps memory small.
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  ev:SetScript("OnEvent", function()
    local n = 0
    for _ in pairs(cache) do n = n + 1 end
    if n > 500 then cache = {} end
  end)
end)

ns.RegisterCommand("upgrade", true, function()
  ns.db.upgradeOff = not ns.db.upgradeOff
  ns.Print(ns.db.upgradeOff and ns.T("UP_OFF") or ns.T("UP_ON"))
end)
