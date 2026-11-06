-- ShamanPlan crafting data: Alchemy route and Herbalism.
-- The Alchemy route follows ConquestCapped's WoW Forever guide (1-300); healing
-- potions moved to First Aid in Forever, so they aren't part of it.
-- mats = { {itemID, amount per craft, name}, ... }
local _, ns = ...

ns.ROUTES = {}

ns.ROUTES.Alchemy = {
  { from = 1,   to = 10,  crafts = 9,  craft = "Minor Arcane Elixir", mats = { {2447, 1, "Peacebloom"}, {3371, 1, "Empty Vial"} }, note = { "Apprentice: Vosur Brakthel, Tinker Town (Ironforge)", "Apprentice: Vosur Brakthel, Tinker Town (Ironforge)" } },
  { from = 10,  to = 55,  crafts = 45, craft = "Elixir of Minor Defense", mats = { {765, 1, "Silverleaf"}, {2447, 1, "Peacebloom"}, {3371, 1, "Empty Vial"} } },
  { from = 55,  to = 65,  crafts = 10, craft = "Minor Mana Potion", mats = { {785, 1, "Mageroyal"}, {2447, 1, "Peacebloom"}, {3371, 1, "Empty Vial"} }, note = { "Journeyman at 50 (lvl 10): Tally Berryfizz, Ironforge", "Journeyman vid 50 (lvl 10): Tally Berryfizz, Ironforge" } },
  { from = 65,  to = 90,  crafts = 27, craft = "Elixir of Minor Fortitude", mats = { {2449, 2, "Earthroot"}, {2447, 1, "Peacebloom"}, {3371, 1, "Empty Vial"} } },
  { from = 90,  to = 120, crafts = 30, craft = "Elixir of Wisdom", mats = { {785, 1, "Mageroyal"}, {2450, 2, "Briarthorn"}, {3371, 1, "Empty Vial"} } },
  { from = 120, to = 130, crafts = 10, craft = "Lesser Mana Potion", mats = { {785, 1, "Mageroyal"}, {3820, 1, "Stranglekelp"}, {3371, 1, "Empty Vial"} }, note = { "Expert at 125 (lvl 20): Ainethil, Darnassus", "Expert vid 125 (lvl 20): Ainethil, Darnassus" } },
  { from = 130, to = 150, crafts = 20, craft = "Lesser Mana Potion", mats = { {785, 1, "Mageroyal"}, {3820, 1, "Stranglekelp"}, {3371, 1, "Empty Vial"} }, note = { "Or Fire Oil from Firefin Snapper (keep 30 oils for Fire Power)", "Eller Fire Oil av Firefin Snapper (spara 30 oils till Fire Power)" } },
  { from = 150, to = 165, crafts = 22, craft = "Lesser Mana Potion", mats = { {785, 1, "Mageroyal"}, {3820, 1, "Stranglekelp"}, {3371, 1, "Empty Vial"} }, note = { "Or 15 Elixir of Fire Power if you made Fire Oil", "Eller 15 Elixir of Fire Power om du gjorde Fire Oil" } },
  { from = 165, to = 180, crafts = 15, craft = "Mana Potion", mats = { {3820, 1, "Stranglekelp"}, {3356, 1, "Kingsblood"}, {3372, 1, "Leaded Vial"} } },
  { from = 180, to = 195, crafts = 15, craft = "Elixir of Lesser Fortitude", mats = { {3355, 1, "Wild Steelbloom"}, {3821, 1, "Goldthorn"}, {3372, 1, "Leaded Vial"} } },
  { from = 195, to = 215, crafts = 20, craft = "Elixir of Defense", mats = { {3355, 1, "Wild Steelbloom"}, {3821, 1, "Goldthorn"}, {3372, 1, "Leaded Vial"} }, note = { "Artisan at 200 (lvl 35): Kylanna Windwhisper, Feathermoon (Feralas)", "Artisan vid 200 (lvl 35): Kylanna Windwhisper, Feathermoon (Feralas)" } },
  { from = 215, to = 230, crafts = 17, craft = "Greater Mana Potion", mats = { {3358, 1, "Khadgar's Whisker"}, {3821, 1, "Goldthorn"}, {3372, 1, "Leaded Vial"} } },
  { from = 230, to = 265, crafts = 45, craft = "Draught of Detect Undead", mats = { {8836, 1, "Arthas' Tears"}, {8925, 1, "Crystal Vial"} } },
  { from = 265, to = 290, crafts = 30, craft = "Superior Mana Potion", mats = { {8838, 2, "Sungrass"}, {8839, 2, "Blindweed"}, {8925, 1, "Crystal Vial"} }, note = { "Recipe from Algernon (Stormwind) or Ulthir (Darnassus)", "Recept hos Algernon (Stormwind) eller Ulthir (Darnassus)" } },
  { from = 290, to = 300, crafts = 17, craft = "Major Frenzy Potion", mats = { {13466, 3, "Plaguebloom"}, {8839, 2, "Blindweed"}, {18256, 1, "Imbued Vial"} }, note = { "Recipe from Nina Surefire, Three Corners (Redridge), for Merchant's Favor", "Recept hos Nina Surefire, Three Corners (Redridge), för Merchant's Favor" } },
}

-- Rank cap -> character level needed for the next rank.
ns.RANK_LEVEL = { [75] = 10, [150] = 20, [225] = 35 }

-- Herbs: {itemID, name, Herbalism skill needed}. Classic values; Forever may differ a little.
ns.HERBS = {
  { 2447, "Peacebloom", 1 }, { 765, "Silverleaf", 1 }, { 2449, "Earthroot", 15 },
  { 785, "Mageroyal", 50 }, { 2450, "Briarthorn", 70 }, { 3820, "Stranglekelp", 85 },
  { 2453, "Bruiseweed", 100 }, { 3355, "Wild Steelbloom", 115 }, { 3356, "Kingsblood", 125 },
  { 3357, "Liferoot", 150 }, { 3818, "Fadeleaf", 160 }, { 3821, "Goldthorn", 170 },
  { 3358, "Khadgar's Whisker", 185 }, { 3819, "Wintersbite", 195 }, { 4625, "Firebloom", 205 },
  { 8831, "Purple Lotus", 210 }, { 8836, "Arthas' Tears", 220 }, { 8838, "Sungrass", 230 },
  { 8839, "Blindweed", 235 }, { 8845, "Ghost Mushroom", 245 }, { 8846, "Gromsblood", 250 },
  { 13464, "Golden Sansam", 260 }, { 13463, "Dreamfoil", 270 }, { 13465, "Mountain Silversage", 280 },
  { 13466, "Plaguebloom", 285 }, { 13467, "Icecap", 290 },
}

-- Where to pick herbs, Alliance side: up to this Herbalism skill.
ns.HERB_ZONES = {
  { to = 50,  zones = "Dun Morogh, Loch Modan, Elwynn Forest" },
  { to = 100, zones = "Loch Modan, Westfall, Redridge Mountains" },
  { to = 150, zones = "Wetlands, Redridge Mountains, Duskwood" },
  { to = 200, zones = "Arathi Highlands, Hillsbrad Foothills, Stranglethorn Vale" },
  { to = 250, zones = "Stranglethorn Vale, The Hinterlands, Feralas" },
  { to = 300, zones = "Un'Goro Crater, Felwood, Western Plaguelands, Eastern Plaguelands" },
}
