-- Builds ShamanPlan's DungeonData.lua from QuestieDB's merged WoW Forever data.
dofile("tools/qload.lua")
local C = (os.getenv("QDB") or "QDB") .. "/src/corrections/Forever/combined/"
local Q = dofile(C .. "foreverQuestDB.lua")
local N = dofile(C .. "foreverNpcDB.lua")
local I = dofile(C .. "foreverItemDB.lua")
local O = dofile(C .. "foreverObjectDB.lua")
local Z = (os.getenv("QDB") or "QDB") .. "/support/Forever/Zones/areaIdToUiMapId.lua"
local toUi = QLoad(Z, "ZoneDB.private.areaIdToUiMapId")
for k, v in pairs(QLoad(Z, "ZoneDB.private.areaIdToUiMapIdOverride")) do toUi[k] = v end

-- Dungeon list from Questie's Forever dungeons.lua (name, alt area IDs, entrances).
local src = io.open((os.getenv("QDB") or "QDB") .. "/support/Forever/Zones/dungeons.lua"):read("a")
local DUN = {}
for id, name, alt, ent in src:gmatch("%[(%d+)%] = {\"([^\"]+)\",([^,]-%b{}),%d+,(%b{})") do
  DUN[tonumber(id)] = { name = name, alt = alt, ent = ent }
end
for id, name, ent in src:gmatch("%[(%d+)%] = {\"([^\"]+)\",nil,%d+,(%b{})") do
  DUN[tonumber(id)] = { name = name, ent = ent }
end

-- Alliance leveling dungeons, in level order, with the usual level ranges.
-- {areaID, low, high, instanceID}
local LIST = {
  {1581, 17, 26, 36}, {718, 17, 24, 43}, {209, 22, 30, 33}, {719, 24, 32, 48}, {717, 24, 32, 34},
  {721, 29, 38, 90}, {491, 30, 40, 47}, {796, 30, 45, 189}, {722, 40, 50, 129}, {1337, 41, 51, 70},
  {1176, 44, 54, 209}, {2100, 46, 55, 349}, {1477, 50, 60, 109}, {1584, 52, 60, 230}, {1583, 55, 60, 229},
  {2557, 56, 60, 429}, {2057, 58, 60, 289}, {2017, 58, 60, 329},
}

local ALLY, SKY, SHAMAN = 4294967373, 4294967296, 64
local RACECODE = { [1] = "H", [4] = "D", [8] = "N", [64] = "G", [SKY] = "S" }

local function allianceOK(q)
  local r = q[6]
  if r and r ~= 0 and (r & ALLY) == 0 then return false end
  local c = q[7]
  if c and c ~= 0 and (c & SHAMAN) == 0 then return false end
  if q[18] or q[31] or q[35] then return false end -- profession quests
  return true
end
local function raceCodes(q)
  local r = q[6]
  if not r or r == 0 or (r & ALLY) == ALLY then return nil end
  local s = ""
  for bit, code in pairs(RACECODE) do if (r & bit) ~= 0 then s = s .. code end end
  return s
end

local function inDungeon(zone, ids) return ids[zone] end

-- Picks a spawn point outside the dungeon: {uiMap, x, y} or "inside".
local function spot(spawns, ids)
  if not spawns then return nil end
  local inside = false
  local zones = {}
  for zone in pairs(spawns) do zones[#zones + 1] = zone end
  table.sort(zones)
  for _, zone in ipairs(zones) do
    if inDungeon(zone, ids) then inside = true
    else
      local ui = toUi[zone]
      local p = spawns[zone][1]
      if ui and ui ~= 0 and p and p[1] and p[1] > 0 then return { ui, p[1], p[2] } end
    end
  end
  return inside and "inside" or nil
end

local function giver(q, ids)
  local sb = q[2]
  if not sb then return nil end
  for _, npc in ipairs(sb[1] or {}) do
    local n = N[npc]
    if n and (not n[13] or n[13]:find("A")) then
      local s = spot(n[7], ids)
      if s then return { name = n[1], at = s } end
    end
  end
  for _, obj in ipairs(sb[2] or {}) do
    local o = O[obj]
    if o then
      local s = spot(o[4], ids)
      if s then return { name = o[1], at = s } end
    end
  end
  for _, item in ipairs(sb[3] or {}) do
    local it = I[item]
    if it then return { name = it[1], item = item } end
  end
  return nil
end

local out, quests = {}, {}
local function addQuest(id, ids, depth)
  if quests[id] or depth > 12 then return end
  local q = Q[id]
  if not q or not allianceOK(q) then return end
  local e = { name = q[1], req = q[4] or 1, lvl = q[5] or q[4] or 1, races = raceCodes(q), g = giver(q, ids) }
  quests[id] = e
  local function filt(list)
    if not list then return nil end
    local r = {}
    for _, p in ipairs(list) do
      if Q[p] and allianceOK(Q[p]) then r[#r + 1] = p; addQuest(p, ids, depth + 1) end
    end
    return #r > 0 and r or nil
  end
  e.any = filt(q[13])
  e.all = filt(q[12])
  e.excl = filt(q[16])
end

-- Shaman gear: 1H/2H axes and maces, staves, fist weapons, daggers; leather, mail, shields, rings/necks/trinkets.
local MAGE_GEAR = { [2] = { [0] = true, [1] = true, [4] = true, [5] = true, [10] = true, [13] = true, [15] = true }, [4] = { [0] = true, [2] = true, [3] = true, [6] = true } }

local dungeons = {}
for _, d in ipairs(LIST) do
  local id, lo, hi = d[1], d[2], d[3]
  local D = DUN[id]
  local ids = { [id] = true }
  if D.alt then for a in D.alt:gmatch("%d+") do ids[tonumber(a)] = true end end
  if id == 2557 then for a = 10022, 10027 do ids[a] = true end end -- Dire Maul wings
  local qlist = {}
  for qid, q in pairs(Q) do
    if q[17] and ids[q[17]] and allianceOK(q) and not ((q[24] or 0) & 1 == 1) then
      addQuest(qid, ids, 0)
      if quests[qid] then qlist[#qlist + 1] = qid end
    end
  end
  table.sort(qlist, function(a, b)
    local A, B = quests[a], quests[b]
    if A.lvl ~= B.lvl then return A.lvl < B.lvl end
    return a < b
  end)
  -- Entrances: {areaId, x, y}
  local ent = {}
  for a, x, y in D.ent:gmatch("{(%d+),%s*([%d.]+),%s*([%d.]+)}") do
    local ui = toUi[tonumber(a)]
    if ui and ui ~= 0 then ent[#ent + 1] = { ui, tonumber(x), tonumber(y) } end
  end
  -- Boss loot usable by mages: dropped only by NPCs that live in this dungeon, by at most 2 of them.
  local loot = {}
  for iid, it in pairs(I) do
    local drops = it[2]
    local cls, sub = it[12], it[13]
    if drops and #drops <= 2 and cls and MAGE_GEAR[cls] and MAGE_GEAR[cls][sub] and (it[9] or 0) >= lo - 5 then
      local ok, boss = true, nil
      for _, npc in ipairs(drops) do
        local n = N[npc]
        if not n or not n[7] then ok = false break end
        local only = true
        local count = 0
        for zone, pts in pairs(n[7]) do
          if not ids[zone] then only = false end
          count = count + #pts
        end
        if not only or count > 2 then ok = false break end
        boss = boss or n[1]
      end
      if ok and boss then loot[#loot + 1] = { iid, boss, it[10] or 0 } end
    end
  end
  table.sort(loot, function(a, b) if a[3] ~= b[3] then return a[3] < b[3] end return a[1] < b[1] end)
  dungeons[#dungeons + 1] = { inst = d[4], id = id, name = D.name, lo = lo, hi = hi, ent = ent, quests = qlist, loot = loot }
  io.stderr:write(string.format("%-28s quests %2d  loot %2d  entrances %d\n", D.name, #qlist, #loot, #ent))
end

-- Write Lua
local function s(v) return string.format("%q", v) end
local function f(v) return (string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")) end
local L = {}
L[#L + 1] = "-- ShamanPlan: dungeon quests and loot for WoW Forever (Alliance)."
L[#L + 1] = "-- Generated from QuestieDB's Forever data (https://github.com/Questie/QuestieDB, GPL-3.0). Do not edit by hand."
L[#L + 1] = "local _, ns = ..."
L[#L + 1] = ""
L[#L + 1] = "-- q = quest IDs; ent = entrances {uiMapID, x, y}; loot = {itemID, boss, required level}"
L[#L + 1] = "ns.DUNGEONS = {"
for _, d in ipairs(dungeons) do
  local e = {}
  for _, p in ipairs(d.ent) do e[#e + 1] = string.format("{%d,%s,%s}", p[1], f(p[2]), f(p[3])) end
  local lt = {}
  for _, l in ipairs(d.loot) do lt[#lt + 1] = string.format("{%d,%s,%d}", l[1], s(l[2]), l[3]) end
  L[#L + 1] = string.format("  { id = %d, inst = %d, name = %s, lo = %d, hi = %d,\n    ent = {%s},\n    q = {%s},\n    loot = {%s} },",
    d.id, d.inst, s(d.name), d.lo, d.hi, table.concat(e, ","), table.concat(d.quests, ","), table.concat(lt, ","))
end
L[#L + 1] = "}"
L[#L + 1] = ""
L[#L + 1] = "-- n = name, req = required level, lvl = quest level, any/all = pre-quests, excl = exclusive with,"
L[#L + 1] = "-- races = allowed races (H D N G S) when restricted, g = giver {name, map, x, y} / {name, inside} / {name, item}"
L[#L + 1] = "ns.DQUESTS = {"
local ids = {}
for id in pairs(quests) do ids[#ids + 1] = id end
table.sort(ids)
for _, id in ipairs(ids) do
  local e = quests[id]
  local parts = { "n=" .. s(e.name), "req=" .. e.req, "lvl=" .. e.lvl }
  if e.any then parts[#parts + 1] = "any={" .. table.concat(e.any, ",") .. "}" end
  if e.all then parts[#parts + 1] = "all={" .. table.concat(e.all, ",") .. "}" end
  if e.excl then parts[#parts + 1] = "excl={" .. table.concat(e.excl, ",") .. "}" end
  if e.races then parts[#parts + 1] = "races=" .. s(e.races) end
  if e.g then
    if e.g.item then parts[#parts + 1] = string.format("g={%s,item=%d}", s(e.g.name), e.g.item)
    elseif e.g.at == "inside" then parts[#parts + 1] = string.format("g={%s,inside=true}", s(e.g.name))
    else parts[#parts + 1] = string.format("g={%s,%d,%s,%s}", s(e.g.name), e.g.at[1], f(e.g.at[2]), f(e.g.at[3])) end
  end
  L[#L + 1] = string.format("  [%d] = {%s},", id, table.concat(parts, ","))
end
L[#L + 1] = "}"
local fh = io.open(arg[1], "w"); fh:write(table.concat(L, "\n") .. "\n"); fh:close()
io.stderr:write("quests total " .. #ids .. "\n")
