-- ShamanPlan: zone tips. A short note when you enter a place that matters for the plan:
-- Alchemy trainers, recipe vendors and shaman trainers.
local _, ns = ...

local TIPS = {
  { zone = "Ironforge", prof = "Alchemy",
    text = { "Alchemy here: Vosur Brakthel (Apprentice, Tinker Town) and Tally Berryfizz (Journeyman, level 10).", "Alchemy här: Vosur Brakthel (Apprentice, Tinker Town) och Tally Berryfizz (Journeyman, level 10)." } },
  { zone = "Darnassus", prof = "Alchemy",
    text = { "Ainethil trains Expert Alchemy here (level 20). Ulthir sells the Superior Mana Potion recipe.", "Ainethil tränar Expert Alchemy här (level 20). Ulthir säljer receptet på Superior Mana Potion." } },
  { zone = "Feathermoon", prof = "Alchemy",
    text = { "Kylanna Windwhisper trains Artisan Alchemy here (level 35), and Logannas sells the Nature Protection Potion recipe.", "Kylanna Windwhisper tränar Artisan Alchemy här (level 35), och Logannas säljer receptet på Nature Protection Potion." } },
  { zone = "Stormwind", prof = "Alchemy",
    text = { "Algernon sells the Superior Mana Potion recipe (Alchemy 265).", "Algernon säljer receptet på Superior Mana Potion (Alchemy 265)." } },
  { zone = "Three Corners", prof = "Alchemy",
    text = { "Nina Surefire sells Alchemy recipes for Merchant's Favor here, including Major Frenzy Potion (290-300).", "Nina Surefire säljer Alchemy-recept för Merchant's Favor här, bland annat Major Frenzy Potion (290-300)." } },
  { zone = "Kharanos",
    text = { "There's a shaman trainer here, closer than Ironforge.", "Här finns en shaman-trainer, närmare än Ironforge." } },
  { zone = "Shadowfang Keep", prof = "Tailoring",
    text = { "The Filigreed Silky Gown and Leggings patterns drop here.", "Mönstren för Filigreed Silky Gown och Leggings droppar här." } },
  { zone = "Deadmines", prof = "Tailoring",
    text = { "The Filigreed Silky Gown pattern drops here.", "Mönstret för Filigreed Silky Gown droppar här." } },
  { zone = "Three Corners",
    text = { "Merchant's Favor vendors are here: Mivin Shadowweave (Tailoring patterns) and Alynsia (Enchanting).", "Här finns Merchant's Favor-försäljarna: Mivin Shadowweave (Tailoring-mönster) och Alynsia (Enchanting)." } },
  { zone = "Tower of Azora", prof = "Enchanting",
    text = { "Kitta Firewind trains Expert Enchanting here (level 20).", "Kitta Firewind tränar Expert Enchanting här (level 20)." } },
  { zone = "Theramore", prof = "Tailoring",
    text = { "Timothy Worthington trains Artisan Tailoring here (level 35).", "Timothy Worthington tränar Artisan Tailoring här (level 35)." } },
  { zone = "Uldaman", prof = "Enchanting",
    text = { "Annora, the Artisan Enchanting trainer, is in here. Clear the way to her room.", "Annora, Artisan-trainern i Enchanting, finns här inne. Rensa vägen till hennes rum." } },
  { zone = "Silithus", prof = "Enchanting",
    text = { "Kania sells the Lesser Mana Oil formula here (Enchanting 250-265).", "Kania säljer formeln för Lesser Mana Oil här (Enchanting 250-265)." } },
  { zone = "Moonglade", prof = "Enchanting",
    text = { "Lorelae Wintersong sells the Runed Arcanite Rod formula here.", "Lorelae Wintersong säljer formeln för Runed Arcanite Rod här." } },
  { zone = "Mount Hyjal", prof = "Tailoring",
    text = { "Aisarra Nightmeadow sells the Malleable Essence of Nature pattern here (for Manaflare).", "Aisarra Nightmeadow säljer mönstret för Malleable Essence of Nature här (för Manaflare)." } },
}

local shown = {}

local function Places()
  local list = {}
  if GetZoneText then table.insert(list, GetZoneText() or "") end
  if GetSubZoneText then table.insert(list, GetSubZoneText() or "") end
  if GetRealZoneText then table.insert(list, GetRealZoneText() or "") end
  if GetInstanceInfo then
    local ok, name = pcall(GetInstanceInfo)
    if ok and name then table.insert(list, name) end
  end
  return table.concat(list, " | ")
end

local function Check()
  if ns.db.zoneTipsOff then return end
  local here = Places()
  for i, tip in ipairs(TIPS) do
    if not shown[i] and here:find(tip.zone, 1, true) then
      local relevant = true
      if tip.prof then
        local skill = ns.GetProfSkill(tip.prof)
        relevant = ns.HasProf(tip.prof) and (skill == nil or skill < 300)
      end
      if relevant then
        shown[i] = true
        local text = ns.Tx(tip.text)
        if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage(text, 0.4, 0.8, 1) end
        ns.Print("|cff66ccff" .. text .. "|r")
      end
    end
  end
end

ns.RegisterModule(function()
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("ZONE_CHANGED")
  ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  ev:RegisterEvent("ZONE_CHANGED_INDOORS")
  ev:SetScript("OnEvent", function() ns.Debounce("zonetips", 1, Check) end)
end)

ns.RegisterCommand("zonetips", true, function()
  ns.db.zoneTipsOff = not ns.db.zoneTipsOff
  ns.Print(ns.db.zoneTipsOff and ns.T("ZONE_OFF") or ns.T("ZONE_ON"))
end)
