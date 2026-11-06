-- ShamanPlan: crafting assistant. Shows the next Alchemy step, what you have and
-- miss in bags and bank, and for Herbalism which herbs and zones fit your skill.
local _, ns = ...

local win

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

local function MatLine(m, crafts)
  local id, per, fallback = m[1], m[2], m[3]
  local need = per * crafts
  local have = ns.ItemCount(id)
  local color = have >= need and "|cff60ff60" or "|cffff6060"
  local line = string.format("    %s%s %d/%d|r", color, ns.ItemName(id, fallback), have, need)
  return line
end

local function ProfSection(prof, lines)
  local skill, maxRank = ns.GetProfSkill(prof)
  table.insert(lines, "|cffffffff" .. prof .. "|r")
  if not skill then
    table.insert(lines, "  |cff888888" .. ns.T("CR_NOT_LEARNED") .. "|r")
    return
  end
  if skill >= 300 then
    table.insert(lines, "  |cff60ff60" .. ns.T("CR_DONE") .. "|r")
    return
  end
  local header = "  " .. (maxRank and maxRank > 0 and ns.T("CR_SKILL", skill, maxRank) or ("Skill " .. skill))
  if maxRank and maxRank < 300 and skill >= maxRank - 25 then
    local lvl = ns.RANK_LEVEL[maxRank]
    header = header .. "  |cffff9900" .. (lvl and ns.T("CR_TRAIN_LVL", lvl) or ns.T("CR_TRAIN")) .. "|r"
  end
  table.insert(lines, header)

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

-- Herbalism: the best herbs you can pick now, the next one, and where to go.
local function HerbSection(lines)
  local skill = ns.GetProfSkill("Herbalism")
  table.insert(lines, "|cffffffffHerbalism|r")
  if not skill then
    table.insert(lines, "  |cff888888" .. ns.T("CR_NOT_LEARNED") .. "|r")
    return
  end
  local can, nextHerb = {}, nil
  for _, h in ipairs(ns.HERBS) do
    if skill >= h[3] then table.insert(can, h[2])
    elseif not nextHerb then nextHerb = h end
  end
  local top = {}
  for i = math.max(1, #can - 2), #can do table.insert(top, can[i]) end
  table.insert(lines, "  " .. ns.T("CR_SKILL_ONLY", skill) .. "  |cffaaaaaa" .. ns.T("HB_CAN", table.concat(top, ", ")) .. "|r")
  if nextHerb then
    table.insert(lines, "  |cff888888" .. ns.T("HB_NEXT", nextHerb[2], nextHerb[3]) .. "|r")
  end
  for _, z in ipairs(ns.HERB_ZONES) do
    if skill < z.to then
      table.insert(lines, "  |cffffd100" .. ns.T("HB_ZONES") .. "|r " .. z.zones)
      break
    end
  end
end

local function Build()
  local lines = { "|cff3fa9ff" .. ns.T("CR_TITLE") .. "|r" }
  ProfSection("Alchemy", lines)
  HerbSection(lines)

  local herbs = {}
  for _, h in ipairs(ns.HERBS) do
    local n = ns.ItemCount(h[1])
    if n > 0 then table.insert(herbs, h[2] .. " " .. n) end
  end
  table.insert(lines, "|cffffffff" .. ns.T("CR_HERBS") .. "|r " .. (#herbs > 0 and table.concat(herbs, ", ") or ns.T("CR_NONE")))
  table.insert(lines, "|cff888888" .. ns.T("CR_BANK") .. "|r")
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
