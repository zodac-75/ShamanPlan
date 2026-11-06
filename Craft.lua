-- ShamanPlan: crafting assistant for your two main professions (chosen in the settings
-- window, or detected from what you've learned). Crafting professions show the next
-- step of the route with what you have and miss in bags and bank; gathering
-- professions show what you can gather now, what comes next and where to go.
local _, ns = ...

local win

---------------------------------------------------------------------------
-- Which professions
---------------------------------------------------------------------------
local function IsProf(name)
  for _, p in ipairs(ns.PROFS) do if p == name then return true end end
  return false
end

-- The two main professions: the ones picked in the settings, otherwise the ones you've
-- learned, otherwise the addon's defaults.
function ns.SelectedProfs()
  local picked = ns.db and ns.db.profs or {}
  local out, used = {}, {}
  for i = 1, 2 do
    local p = picked[i]
    if p and IsProf(p) and not used[p] then out[i] = p; used[p] = true end
  end
  for i = 1, 2 do
    if not out[i] then
      for _, p in ipairs(ns.PROFS) do
        if not used[p] and ns.GetProfSkill(p) then out[i] = p; used[p] = true; break end
      end
    end
  end
  for i = 1, 2 do
    if not out[i] then
      for _, p in ipairs(ns.DEFAULT_PROFS or {}) do
        if not used[p] then out[i] = p; used[p] = true; break end
      end
    end
  end
  return out
end

function ns.HasProf(name)
  for _, p in ipairs(ns.SelectedProfs()) do if p == name then return true end end
  return false
end

-- Plan entries that name a profession ("... (Tailoring)") only show when it's one of yours.
function ns.GearVisible(item)
  local text = type(item) == "table" and item[1] or item
  if type(text) ~= "string" then return true end
  for _, p in ipairs(ns.PROFS) do
    if text:find(p, 1, true) and not ns.HasProf(p) then return false end
  end
  return true
end

-- Steps through "auto" + all professions for the settings window.
function ns.StepProf(slot, dir)
  ns.db.profs = ns.db.profs or {}
  local list = { false }
  for _, p in ipairs(ns.PROFS) do table.insert(list, p) end
  local cur = 1
  for i, p in ipairs(list) do if p == (ns.db.profs[slot] or false) then cur = i end end
  ns.db.profs[slot] = list[((cur - 1 + dir) % #list) + 1] or nil
  ns.RefreshMain()
  if ns.RefreshCraft then ns.RefreshCraft() end
end

function ns.ProfLabel(slot)
  local p = ns.db.profs and ns.db.profs[slot]
  if p then return p end
  return ns.T("PROF_AUTO", ns.SelectedProfs()[slot] or "?")
end

---------------------------------------------------------------------------
-- Crafting routes
---------------------------------------------------------------------------
local function StepFor(route, skill)
  for i, s in ipairs(route) do
    if skill < s.to then return s, route[i + 1] end
  end
end

local function Remaining(s, skill)
  if s.batch then return s.crafts end
  local span = s.to - s.from
  if span <= 0 then return s.crafts end
  local frac = (s.to - math.max(skill, s.from)) / span
  return math.max(1, math.ceil(s.crafts * frac))
end

-- Does the current or next Enchanting step need this item?
function ns.EnchantNeedsMat(itemID)
  local skill = ns.GetProfSkill("Enchanting")
  if not skill or skill >= 300 or not ns.ROUTES.Enchanting then return false end
  local s, nxt = StepFor(ns.ROUTES.Enchanting, skill)
  for _, step in ipairs({ s, nxt }) do
    if step then
      for _, m in ipairs(step.mats) do
        if m[1] == itemID then return true end
      end
    end
  end
  return false
end

local function MatLine(m, crafts)
  local id, per, fallback = m[1], m[2], m[3]
  local need = math.ceil(per * crafts)
  local have = ns.ItemCount(id)
  local color = have >= need and "|cff60ff60" or "|cffff6060"
  local line = string.format("    %s%s %d/%d|r", color, ns.ItemName(id, fallback), have, need)
  local bolt = ns.BOLTS and ns.BOLTS[id]
  if bolt and have < need then
    local rawNeed = (need - have) * bolt.ratio
    local rawHave = ns.ItemCount(bolt.raw)
    local c = rawHave >= rawNeed and "|cff60ff60" or "|cffaaaaaa"
    line = line .. " " .. c .. ns.T("CR_EQUALS", rawNeed, bolt.name, rawHave) .. "|r"
  end
  return line
end

local function Header(prof, lines)
  local skill, maxRank = ns.GetProfSkill(prof)
  table.insert(lines, "|cffffffff" .. prof .. "|r")
  if not skill then
    table.insert(lines, "  |cff888888" .. ns.T("CR_NOT_LEARNED") .. "|r")
    return nil
  end
  if skill >= 300 then
    table.insert(lines, "  |cff60ff60" .. ns.T("CR_DONE") .. "|r")
    return nil
  end
  local header = "  " .. (maxRank and maxRank > 0 and ns.T("CR_SKILL", skill, maxRank) or ns.T("CR_SKILL_ONLY", skill))
  if maxRank and maxRank < 300 and skill >= maxRank - 25 then
    local lvl = ns.RANK_LEVEL[maxRank]
    header = header .. "  |cffff9900" .. (lvl and ns.T("CR_TRAIN_LVL", lvl) or ns.T("CR_TRAIN")) .. "|r"
  end
  table.insert(lines, header)
  return skill
end

local function RouteSection(prof, lines)
  local skill = Header(prof, lines)
  if not skill then return end
  local s, nxt = StepFor(ns.ROUTES[prof], skill)
  if not s then return end
  local crafts = Remaining(s, skill)
  local what = s.batch and ns.T("CR_BATCH", crafts) or ns.T("CR_LEFT", crafts)
  table.insert(lines, string.format("  |cffffd100%d-%d:|r %s, %s", s.from, s.to, s.craft, what))
  for _, m in ipairs(s.mats) do table.insert(lines, MatLine(m, crafts)) end
  if s.note then table.insert(lines, "    |cffaaaaaa" .. ns.Tx(s.note) .. "|r") end
  if nxt then
    table.insert(lines, "  |cff888888" .. ns.T("CR_THEN", nxt.from, nxt.to, nxt.craft) .. "|r")
  end
end

---------------------------------------------------------------------------
-- Gathering
---------------------------------------------------------------------------
local function NodeSection(prof, lines, nodes, zones)
  local skill = Header(prof, lines)
  if not skill then return end
  local can, nextNode = {}, nil
  for _, n in ipairs(nodes) do
    if skill >= n[3] then table.insert(can, n[2])
    elseif not nextNode then nextNode = n end
  end
  local top = {}
  for i = math.max(1, #can - 2), #can do table.insert(top, can[i]) end
  table.insert(lines, "  |cffaaaaaa" .. ns.T("HB_CAN", table.concat(top, ", ")) .. "|r")
  if nextNode then
    table.insert(lines, "  |cff888888" .. ns.T("HB_NEXT", nextNode[2], nextNode[3]) .. "|r")
  end
  for _, z in ipairs(zones) do
    if skill < z.to then
      table.insert(lines, "  |cffffd100" .. ns.T("GA_ZONES") .. "|r " .. z.zones)
      break
    end
  end
end

local function SkinSection(lines)
  local skill = Header("Skinning", lines)
  if not skill then return end
  table.insert(lines, "  |cffaaaaaa" .. ns.T("SK_LEVEL", ns.SkinLevel(skill)) .. "|r")
  local best
  for _, l in ipairs(ns.LEATHER) do if skill >= l[3] then best = l[2] end end
  if best then table.insert(lines, "  |cff888888" .. ns.T("SK_LEATHER", best) .. "|r") end
end

local function Section(prof, lines)
  if prof == "Herbalism" then NodeSection(prof, lines, ns.HERBS, ns.HERB_ZONES)
  elseif prof == "Mining" then NodeSection(prof, lines, ns.ORES, ns.MINING_ZONES)
  elseif prof == "Skinning" then SkinSection(lines)
  elseif ns.ROUTES[prof] then RouteSection(prof, lines) end
end

-- Materials in bags and bank that matter for your professions.
local function MatsSummary(lines)
  local groups = {}
  if ns.HasProf("Tailoring") then table.insert(groups, { ns.T("CR_CLOTH"), ns.CLOTH, 1, 2 }) end
  if ns.HasProf("Herbalism") or ns.HasProf("Alchemy") then table.insert(groups, { ns.T("CR_HERBS"), ns.HERBS, 1, 2 }) end
  if ns.HasProf("Mining") or ns.HasProf("Blacksmithing") or ns.HasProf("Engineering") then
    table.insert(groups, { ns.T("CR_ORES"), ns.ORES, 1, 2 })
  end
  if ns.HasProf("Skinning") or ns.HasProf("Leatherworking") then table.insert(groups, { ns.T("CR_LEATHER"), ns.LEATHER, 1, 2 }) end
  for _, g in ipairs(groups) do
    local found = {}
    for _, e in ipairs(g[2]) do
      local n = ns.ItemCount(e[g[3]])
      if n > 0 then table.insert(found, e[g[4]] .. " " .. n) end
    end
    table.insert(lines, "|cffffffff" .. g[1] .. "|r " .. (#found > 0 and table.concat(found, ", ") or ns.T("CR_NONE")))
  end
  if #groups > 0 then table.insert(lines, "|cff888888" .. ns.T("CR_BANK") .. "|r") end
end

local function Build()
  local lines = { "|cff3fa9ff" .. ns.T("CR_TITLE") .. "|r" }
  for _, prof in ipairs(ns.SelectedProfs()) do Section(prof, lines) end
  MatsSummary(lines)
  return table.concat(lines, "\n")
end

function ns.RefreshCraft()
  if win and win:IsShown() then win:SetContent(Build()) end
end

ns.RegisterModule(function()
  win = ns.MakeWindow("ShamanPlanCraftFrame", 380, "craftPos", { "RIGHT", "RIGHT", -400, 120 })
  win.closeButton:SetScript("OnClick", function()
    win:Hide()
    ns.db.craftShown = false
  end)
  ns.craftWindow = win
  ns.windows = ns.windows or {}
  table.insert(ns.windows, win)
  if ns.db.craftShown then win:Show() else win:Hide() end

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("BAG_UPDATE")
  ev:RegisterEvent("BANKFRAME_OPENED")
  ev:RegisterEvent("SKILL_LINES_CHANGED")
  ev:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  ev:SetScript("OnEvent", function()
    ns.Debounce("craft", 1, ns.RefreshCraft)
  end)
  ns.RefreshCraft()
end)

ns.RegisterCommand("craft", true, function()
  if win:IsShown() then
    win:Hide(); ns.db.craftShown = false
  else
    win:Show(); ns.db.craftShown = true; ns.RefreshCraft()
  end
end)
