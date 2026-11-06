-- Profession data shared by the Plan addons (MagePlan, ShamanPlan, DruidPlan).
-- Leveling routes 1-300 for the crafting professions, and what the gathering professions
-- can gather at each skill, for WoW Forever (Alliance trainers).
-- Routes: Tailoring and Enchanting follow ConquestCapped's guides; Alchemy follows
-- ConquestCapped's Forever guide; Blacksmithing, Leatherworking and Engineering follow
-- wow-professions.com's Forever guides (their 225-300 parts were written during the beta).
-- mats = { {itemID, amount per craft, name}, ... }; batch = true: make the whole batch.
local _, ns = ...

-- Primary professions, in the order the settings window cycles through them.
ns.PROFS = { "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Herbalism",
  "Leatherworking", "Mining", "Skinning", "Tailoring" }
ns.GATHERING = { Herbalism = true, Mining = true, Skinning = true }

-- Rank cap -> character level needed for the next rank.
ns.RANK_LEVEL = { [75] = 10, [150] = 20, [225] = 35 }

-- Where to train each rank (Alliance). [50] = Journeyman, [125] = Expert, [200] = Artisan.
ns.PROF_TRAINERS = {
  Alchemy = { [50] = "Tally Berryfizz (Ironforge) / Lilyssia Nightbreeze (Stormwind) / Sylvanna Forestmoon (Darnassus)", [125] = "Ainethil (Darnassus)", [200] = "Kylanna Windwhisper (Feathermoon, Feralas)" },
  Blacksmithing = { [50] = "Rotgath Stonebeard (Ironforge) / Therum Deepforge (Stormwind)", [125] = "Bengus Deepforge (Ironforge)", [200] = "Brikk Keencraft (Booty Bay)" },
  Enchanting = { [50] = "your capital's Enchanting trainer", [125] = "Kitta Firewind (Tower of Azora, Elwynn)", [200] = "Annora (Uldaman)" },
  Engineering = { [50] = "Trixie Quikswitch (Ironforge) / Lilliam Sparkspindle (Stormwind)", [125] = "Springspindle Fizzlegear (Ironforge)", [200] = "Buzzek Bracketswing (Gadgetzan)" },
  Leatherworking = { [50] = "Fimble Finespindle (Ironforge) / Simon Tanner (Stormwind) / Faldron (Darnassus)", [125] = "Telonis (Darnassus)", [200] = "Drakk Stonehand (Aerie Peak, Hinterlands)" },
  Tailoring = { [50] = "your capital's Tailoring trainer (Stormwind)", [125] = "Georgio Bolero (Stormwind)", [200] = "Timothy Worthington (Theramore)" },
  Herbalism = { [50] = "a Herbalism trainer in a capital", [125] = "a Herbalism trainer in a capital", [200] = "a Herbalism trainer in a capital" },
  Mining = { [50] = "a Mining trainer (Ironforge, Stormwind)", [125] = "a Mining trainer (Ironforge, Stormwind)", [200] = "a Mining trainer (Ironforge, Stormwind)" },
  Skinning = { [50] = "a Skinning trainer in a capital", [125] = "a Skinning trainer in a capital", [200] = "a Skinning trainer in a capital" },
}

ns.ROUTES = {}

-- Bolts -> råtyg (för att räkna ut hur mycket cloth som saknas).
ns.BOLTS = {
  [2996]  = { raw = 2589,  ratio = 2, name = "Linen Cloth" },
  [2997]  = { raw = 2592,  ratio = 3, name = "Wool Cloth" },
  [4305]  = { raw = 4306,  ratio = 4, name = "Silk Cloth" },
  [4339]  = { raw = 4338,  ratio = 5, name = "Mageweave Cloth" },
  [14048] = { raw = 14047, ratio = 4, name = "Runecloth" },
}

-- Cloth som visas i sammanfattningen.
ns.CLOTH = {
  { 2589,  "Linen" }, { 2592, "Wool" }, { 4306, "Silk" },
  { 4338,  "Mageweave" }, { 14047, "Runecloth" },
}

ns.ROUTES.Tailoring = {
  { from = 1,   to = 30,  crafts = 30,  craft = "Bolt of Linen Cloth", mats = { {2589, 2, "Linen Cloth"} }, note = { "Save the bolts for Linen Belt", "Spara bolts till Linen Belt" } },
  { from = 30,  to = 55,  crafts = 28,  craft = "Linen Belt", mats = { {2996, 1, "Bolt of Linen Cloth"}, {2320, 1, "Coarse Thread"} } },
  { from = 55,  to = 80,  crafts = 45,  craft = "Bolt of Woolen Cloth", batch = true, mats = { {2592, 3, "Wool Cloth"} }, note = { "Train Journeyman first (lvl 10)", "Träna Journeyman först (lvl 10)" } },
  { from = 80,  to = 85,  crafts = 6,   craft = "Woolen Cape", mats = { {2997, 1, "Bolt of Woolen Cloth"}, {2321, 1, "Fine Thread"} } },
  { from = 85,  to = 95,  crafts = 11,  craft = "Gray Woolen Shirt", mats = { {2997, 2, "Bolt of Woolen Cloth"}, {2321, 1, "Fine Thread"}, {4340, 1, "Gray Dye"} } },
  { from = 95,  to = 100, crafts = 5,   craft = "Double-stitched Woolen Shoulders", mats = { {2997, 3, "Bolt of Woolen Cloth"}, {2321, 2, "Fine Thread"} } },
  { from = 100, to = 120, crafts = 170, craft = "Bolt of Silk Cloth", batch = true, mats = { {4306, 4, "Silk Cloth"} }, note = { "All 170 bolts get used up to 180", "Alla 170 bolts går åt fram till 180" } },
  { from = 120, to = 135, crafts = 17,  craft = "Azure Silk Hood", mats = { {4305, 2, "Bolt of Silk Cloth"}, {6260, 2, "Blue Dye"}, {2321, 1, "Fine Thread"} }, note = { "Train Expert at 125 (lvl 20)", "Träna Expert vid 125 (lvl 20)" } },
  { from = 135, to = 140, crafts = 5,   craft = "Formal White Shirt", mats = { {4305, 3, "Bolt of Silk Cloth"}, {2324, 2, "Bleach"}, {2321, 1, "Fine Thread"} } },
  { from = 140, to = 150, crafts = 192, craft = "Bolt of Mageweave", batch = true, mats = { {4338, 5, "Mageweave Cloth"} }, note = { "All bolts get used up to 225", "Alla bolts går åt fram till 225" } },
  { from = 150, to = 170, crafts = 20,  craft = "Crimson Silk Vest", mats = { {4305, 4, "Bolt of Silk Cloth"}, {2604, 2, "Red Dye"}, {2321, 2, "Fine Thread"} } },
  { from = 170, to = 180, crafts = 10,  craft = "Crimson Silk Pantaloons", mats = { {4305, 4, "Bolt of Silk Cloth"}, {2604, 2, "Red Dye"}, {4291, 2, "Silken Thread"} } },
  { from = 180, to = 190, crafts = 12,  craft = "Orange Mageweave Shirt", mats = { {4339, 1, "Bolt of Mageweave"}, {6261, 1, "Orange Dye"}, {8343, 1, "Heavy Silken Thread"} } },
  { from = 190, to = 215, crafts = 38,  craft = "Black Mageweave Gloves", mats = { {4339, 2, "Bolt of Mageweave"}, {8343, 2, "Heavy Silken Thread"} } },
  { from = 215, to = 230, crafts = 33,  craft = "Mageweave Bag", mats = { {4339, 4, "Bolt of Mageweave"}, {4291, 2, "Silken Thread"} }, note = { "Train Artisan at 200 (lvl 35, Theramore)", "Träna Artisan vid 200 (lvl 35, Theramore)" } },
  { from = 230, to = 235, crafts = 12,  craft = "Black Mageweave Headband", mats = { {4339, 3, "Bolt of Mageweave"}, {8343, 2, "Heavy Silken Thread"} } },
  { from = 235, to = 240, crafts = 12,  craft = "Red Mageweave Bag", mats = { {4339, 4, "Bolt of Mageweave"}, {2604, 2, "Red Dye"}, {8343, 2, "Heavy Silken Thread"} } },
  { from = 240, to = 243, crafts = 4,   craft = "Admiral's Hat", mats = { {4339, 3, "Bolt of Mageweave"}, {4589, 6, "Long Elegant Feather"}, {8343, 2, "Heavy Silken Thread"} } },
  { from = 243, to = 255, crafts = 18,  craft = "Earthenweave Boots", mats = { {14048, 4, "Bolt of Runecloth"}, {7076, 2, "Essence of Earth"}, {8170, 2, "Rugged Leather"}, {14341, 1, "Rune Thread"} } },
  { from = 255, to = 260, crafts = 6,   craft = "Earthenweave Mantle", mats = { {14048, 6, "Bolt of Runecloth"}, {7076, 1, "Essence of Earth"}, {14341, 1, "Rune Thread"} } },
  { from = 260, to = 267, crafts = 8,   craft = "Earthenweave Leggings", mats = { {14048, 6, "Bolt of Runecloth"}, {7076, 2, "Essence of Earth"}, {14341, 1, "Rune Thread"} } },
  { from = 267, to = 270, crafts = 4,   craft = "Runecloth Cuffs", mats = { {14048, 5, "Bolt of Runecloth"}, {14227, 1, "Ironweb Spider Silk"}, {14341, 1, "Rune Thread"} } },
  { from = 270, to = 285, crafts = 21,  craft = "Earthenweave Cuffs", mats = { {14048, 5, "Bolt of Runecloth"}, {7076, 1, "Essence of Earth"}, {14341, 1, "Rune Thread"} } },
  { from = 285, to = 296, crafts = 24,  craft = "Earthenweave Crown", mats = { {14048, 6, "Bolt of Runecloth"}, {7076, 3, "Essence of Earth"}, {14341, 1, "Rune Thread"} } },
  { from = 296, to = 300, crafts = 6,   craft = "Mooncloth Boots", mats = { {14048, 6, "Bolt of Runecloth"}, {14342, 4, "Mooncloth"}, {7971, 2, "Black Pearl"}, {14341, 1, "Rune Thread"} } },
}

ns.ROUTES.Enchanting = {
  { from = 1,   to = 2,   crafts = 1,  craft = "Runed Copper Rod", mats = { {6217, 1, "Copper Rod"}, {247786, 1, "Mote of Magic"} }, note = { "Keep all rods", "Spara alla rods" } },
  { from = 2,   to = 20,  crafts = 18, craft = "Enchant Bracer - Inferior Stamina", mats = { {247786, 1, "Mote of Magic"} } },
  { from = 20,  to = 70,  crafts = 50, craft = "Enchant Chest - Inferior Stamina", mats = { {10940, 1, "Strange Dust"} }, note = { "Disenchant low greens instead of buying dust", "Disenchanta låga gröna istället för att köpa dust" } },
  { from = 70,  to = 130, crafts = 67, craft = "Greater Magic Wand", mats = { {4470, 1, "Simple Wood"}, {10938, 2, "Lesser Magic Essence"} }, note = { "Vendor the wands (~15s). Journeyman first (lvl 10)", "Vendora wandsen (~15s). Journeyman först (lvl 10)" } },
  { from = 130, to = 131, crafts = 1,  craft = "Runed Silver Rod", mats = { {6338, 1, "Silver Rod"}, {10940, 3, "Strange Dust"}, {10938, 4, "Lesser Magic Essence"}, {1210, 1, "Shadowgem"} } },
  { from = 131, to = 150, crafts = 19, craft = "Enchant Bracer - Lesser Stamina", mats = { {11083, 1, "Soul Dust"} }, note = { "Expert at 125 (lvl 20, Tower of Azora). Buy the Bracer - Lesser Strength formula from Dalria, Ashenvale", "Expert vid 125 (lvl 20, Tower of Azora). Köp formel Bracer - Lesser Strength hos Dalria, Ashenvale" } },
  { from = 150, to = 151, crafts = 1,  craft = "Runed Golden Rod", mats = { {11128, 1, "Golden Rod"}, {5500, 1, "Iridescent Pearl"}, {11082, 1, "Greater Astral Essence"}, {11083, 1, "Soul Dust"} } },
  { from = 151, to = 165, crafts = 14, craft = "Enchant Bracer - Lesser Strength", mats = { {11083, 1, "Soul Dust"} } },
  { from = 165, to = 185, crafts = 22, craft = "Enchant Boots - Lesser Agility", mats = { {11083, 1, "Soul Dust"} } },
  { from = 185, to = 200, crafts = 15, craft = "Enchant Bracer - Strength", mats = { {11137, 1, "Vision Dust"} } },
  { from = 200, to = 201, crafts = 1,  craft = "Runed Truesilver Rod", mats = { {11144, 1, "Truesilver Rod"}, {7971, 1, "Black Pearl"}, {11135, 1, "Greater Mystic Essence"}, {11137, 1, "Vision Dust"} }, note = { "Artisan from Annora in Uldaman (lvl 35)", "Artisan hos Annora i Uldaman (lvl 35)" } },
  { from = 201, to = 220, crafts = 35, craft = "Enchant Bracer - Strength", mats = { {11137, 1, "Vision Dust"} } },
  { from = 220, to = 230, crafts = 10, craft = "Cloak Greater Defense / Gloves Agility", mats = { {11137, 1, "Vision Dust"} } },
  { from = 230, to = 235, crafts = 5,  craft = "Enchant Boots - Stamina", mats = { {11137, 2, "Vision Dust"} } },
  { from = 235, to = 250, crafts = 20, craft = "Enchant Chest - Superior Stamina", mats = { {11137, 3, "Vision Dust"} } },
  { from = 250, to = 265, crafts = 20, craft = "Lesser Mana Oil", mats = { {11176, 1, "Dream Dust"}, {8831, 1, "Purple Lotus"}, {8925, 1, "Crystal Vial"} }, note = { "Formula from Kania in Silithus", "Formel hos Kania i Silithus" } },
  { from = 265, to = 294, crafts = 32, craft = "Enchant Shield - Greater Stamina", mats = { {11176, 6, "Dream Dust"} }, note = { "Formula from Mythrin'dir in Darnassus", "Formel hos Mythrin'dir i Darnassus" } },
  { from = 294, to = 295, crafts = 1,  craft = "Runed Arcanite Rod", mats = { {16206, 1, "Arcanite Rod"}, {13926, 1, "Golden Pearl"}, {16204, 10, "Illusion Dust"}, {16203, 4, "Greater Eternal Essence"}, {14343, 4, "Small Brilliant Shard"}, {14344, 2, "Large Brilliant Shard"} }, note = { "Formula from Lorelae Wintersong, Moonglade", "Formel hos Lorelae Wintersong, Moonglade" } },
  { from = 295, to = 300, crafts = 5,  craft = "Enchant Cloak - Superior Defense", mats = { {16204, 8, "Illusion Dust"} } },
}

ns.ROUTES.Alchemy = {
  { from = 1,   to = 10,  crafts = 9,  craft = "Minor Arcane Elixir", mats = { {2447, 1, "Peacebloom"}, {3371, 1, "Empty Vial"} }, note = { "Apprentice has no level requirement in Forever", "Apprentice har inget level-krav i Forever" } },
  { from = 10,  to = 55,  crafts = 45, craft = "Elixir of Minor Defense", mats = { {765, 1, "Silverleaf"}, {2447, 1, "Peacebloom"}, {3371, 1, "Empty Vial"} } },
  { from = 55,  to = 65,  crafts = 10, craft = "Minor Mana Potion", mats = { {785, 1, "Mageroyal"}, {2447, 1, "Peacebloom"}, {3371, 1, "Empty Vial"} }, note = { "Journeyman at 50 (lvl 10): Tally Berryfizz (Ironforge), Lilyssia Nightbreeze (Stormwind) or Sylvanna Forestmoon (Darnassus)", "Journeyman vid 50 (lvl 10): Tally Berryfizz (Ironforge), Lilyssia Nightbreeze (Stormwind) eller Sylvanna Forestmoon (Darnassus)" } },
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

ns.ROUTES.Blacksmithing = {
  { from = 1, to = 25, crafts = 30, craft = "Rough Sharpening Stone", mats = { {2835, 1, "Rough Stone"} }, note = { "Apprentice has no level requirement in Forever", "Apprentice har inget level-krav i Forever" } },
  { from = 25, to = 50, crafts = 30, craft = "Rough Grinding Stone", mats = { {2835, 2, "Rough Stone"} } },
  { from = 50, to = 67, crafts = 36, craft = "Coarse Grinding Stone", mats = { {2836, 2, "Coarse Stone"} }, note = { "Journeyman at 50 (lvl 10): Rotgath Stonebeard (Ironforge) / Therum Deepforge (Stormwind)", "Journeyman vid 50 (lvl 10): Rotgath Stonebeard (Ironforge) / Therum Deepforge (Stormwind)" } },
  { from = 67, to = 75, crafts = 8, craft = "Runed Copper Gauntlets", mats = { {2840, 8, "Copper Bar"}, {3470, 2, "Rough Grinding Stone"} } },
  { from = 75, to = 80, crafts = 5, craft = "Runed Copper Belt", mats = { {2840, 10, "Copper Bar"} } },
  { from = 80, to = 95, crafts = 15, craft = "Rough Bronze Leggings", mats = { {2841, 6, "Bronze Bar"} } },
  { from = 95, to = 100, crafts = 5, craft = "Patterned Bronze Bracers", mats = { {2841, 5, "Bronze Bar"}, {3478, 2, "Coarse Grinding Stone"} } },
  { from = 100, to = 112, crafts = 20, craft = "Heavy Grinding Stone", mats = { {2838, 3, "Heavy Stone"} } },
  { from = 112, to = 125, crafts = 13, craft = "Patterned Bronze Bracers", mats = { {2841, 5, "Bronze Bar"}, {3478, 2, "Coarse Grinding Stone"} } },
  { from = 125, to = 140, crafts = 24, craft = "Bronze Shortsword", mats = { {2841, 5, "Bronze Bar"}, {2880, 4, "Weak Flux"}, {2319, 2, "Medium Leather"} }, note = { "Expert at 125 (lvl 20): Bengus Deepforge, Ironforge", "Expert vid 125 (lvl 20): Bengus Deepforge, Ironforge" } },
  { from = 140, to = 165, crafts = 29, craft = "Bronze Warhammer", mats = { {2841, 8, "Bronze Bar"}, {3466, 1, "Strong Flux"}, {2319, 1, "Medium Leather"} } },
  { from = 165, to = 175, crafts = 15, craft = "Green Iron Bracers", mats = { {3575, 6, "Iron Bar"}, {2605, 1, "Green Dye"} }, note = { "Green Dye from Bombus Finespindle, Ironforge", "Green Dye hos Bombus Finespindle, Ironforge" } },
  { from = 175, to = 185, crafts = 10, craft = "Golden Scale Bracers", mats = { {3859, 5, "Steel Bar"}, {3486, 2, "Heavy Grinding Stone"} } },
  { from = 185, to = 215, crafts = 36, craft = "Mithril Plate Pants", mats = { {3860, 12, "Mithril Bar"} }, note = { "Artisan at 200 (lvl 35): Brikk Keencraft, Booty Bay", "Artisan vid 200 (lvl 35): Brikk Keencraft, Booty Bay" } },
  { from = 215, to = 225, crafts = 10, craft = "Heavy Mithril Breastplate", mats = { {3860, 16, "Mithril Bar"} } },
  { from = 225, to = 230, crafts = 5, craft = "Dense Sharpening Stone", mats = { {12365, 1, "Dense Stone"} } },
  { from = 230, to = 240, crafts = 16, craft = "Heavy Mithril Boots", mats = { {3860, 14, "Mithril Bar"}, {4304, 4, "Thick Leather"} } },
  { from = 240, to = 245, crafts = 5, craft = "Imperial Plate Belt", mats = { {12359, 22, "Thorium Bar"}, {8170, 6, "Rugged Leather"}, {7909, 1, "Aquamarine"} } },
  { from = 245, to = 270, crafts = 27, craft = "Imperial Plate Bracers", mats = { {12359, 20, "Thorium Bar"}, {7910, 1, "Star Ruby"} } },
  { from = 270, to = 290, crafts = 20, craft = "Imperial Plate Boots", mats = { {12359, 34, "Thorium Bar"}, {7910, 1, "Star Ruby"}, {7909, 1, "Aquamarine"} } },
  { from = 290, to = 300, crafts = 10, craft = "Imperial Plate Leggings", mats = { {12359, 44, "Thorium Bar"}, {7910, 2, "Star Ruby"} } },
}
ns.ROUTES.Leatherworking = {
  { from = 1, to = 30, crafts = 33, craft = "Light Leather", mats = { {2934, 3, "Ruined Leather Scraps"} }, note = { "Apprentice has no level requirement in Forever", "Apprentice har inget level-krav i Forever" } },
  { from = 30, to = 55, crafts = 25, craft = "Small Leather Ammo Pouch", mats = { {2318, 3, "Light Leather"}, {2320, 4, "Coarse Thread"} } },
  { from = 55, to = 75, crafts = 21, craft = "Embossed Leather Gloves", mats = { {2318, 3, "Light Leather"}, {2320, 2, "Coarse Thread"} }, note = { "Journeyman at 50 (lvl 10): Fimble Finespindle (Ironforge) / Simon Tanner (Stormwind) / Faldron (Darnassus)", "Journeyman vid 50 (lvl 10): Fimble Finespindle (Ironforge) / Simon Tanner (Stormwind) / Faldron (Darnassus)" } },
  { from = 75, to = 80, crafts = 8, craft = "Medium Leather", mats = { {2318, 4, "Light Leather"} } },
  { from = 80, to = 90, crafts = 10, craft = "Cured Medium Hide", mats = { {4232, 1, "Medium Hide"}, {4289, 1, "Salt"} } },
  { from = 90, to = 100, crafts = 19, craft = "Fine Leather Belt", mats = { {2318, 6, "Light Leather"}, {2320, 2, "Coarse Thread"} }, note = { "Keep 10 belts for Dark Leather Belt", "Spara 10 bälten till Dark Leather Belt" } },
  { from = 100, to = 115, crafts = 15, craft = "Dark Leather Pants", mats = { {2319, 12, "Medium Leather"}, {4340, 1, "Gray Dye"}, {2321, 1, "Fine Thread"} } },
  { from = 115, to = 125, crafts = 10, craft = "Dark Leather Belt", mats = { {4246, 1, "Fine Leather Belt"}, {4233, 1, "Cured Medium Hide"}, {2321, 2, "Fine Thread"}, {4340, 1, "Gray Dye"} } },
  { from = 125, to = 130, crafts = 7, craft = "Heavy Leather", mats = { {2319, 5, "Medium Leather"} }, note = { "Expert at 125 (lvl 20): Telonis, Darnassus", "Expert vid 125 (lvl 20): Telonis, Darnassus" } },
  { from = 130, to = 155, crafts = 30, craft = "Hillman's Leather Gloves", mats = { {2319, 14, "Medium Leather"}, {2321, 4, "Fine Thread"} } },
  { from = 155, to = 170, crafts = 17, craft = "Barbaric Leggings", mats = { {4234, 10, "Heavy Leather"}, {2321, 2, "Fine Thread"}, {1206, 1, "Moss Agate"} }, note = { "Pattern: Hammon Karwn (Arathi) or Lardan (Ashenvale)", "Mönster: Hammon Karwn (Arathi) eller Lardan (Ashenvale)" } },
  { from = 170, to = 175, crafts = 5, craft = "Barbaric Harness", mats = { {4234, 14, "Heavy Leather"}, {2321, 2, "Fine Thread"}, {7071, 1, "Iron Buckle"} } },
  { from = 175, to = 195, crafts = 26, craft = "Guardian Gloves", mats = { {4234, 4, "Heavy Leather"}, {4236, 1, "Cured Heavy Hide"}, {4291, 1, "Silken Thread"} } },
  { from = 195, to = 210, crafts = 21, craft = "Nightscape Headband", mats = { {4304, 5, "Thick Leather"}, {4291, 2, "Silken Thread"} }, note = { "Artisan at 200 (lvl 35): Drakk Stonehand, Aerie Peak (Hinterlands)", "Artisan vid 200 (lvl 35): Drakk Stonehand, Aerie Peak (Hinterlands)" } },
  { from = 210, to = 225, crafts = 15, craft = "Nightscape Pants", mats = { {4304, 14, "Thick Leather"}, {4291, 4, "Silken Thread"} } },
  { from = 225, to = 235, crafts = 12, craft = "Nightscape Boots", mats = { {4304, 16, "Thick Leather"}, {8343, 2, "Heavy Silken Thread"} } },
  { from = 235, to = 265, crafts = 36, craft = "Wicked Leather Gauntlets", mats = { {8170, 8, "Rugged Leather"}, {2325, 1, "Black Dye"}, {14341, 1, "Rune Thread"} }, note = { "Pattern: Leonard Porter, Western Plaguelands", "Mönster: Leonard Porter, Western Plaguelands" } },
  { from = 265, to = 300, crafts = 53, craft = "Runic Leather Headband", mats = { {8170, 14, "Rugged Leather"}, {14047, 10, "Runecloth"}, {14341, 1, "Rune Thread"} }, note = { "Pattern: Jase Farlane, Light's Hope Chapel", "Mönster: Jase Farlane, Light's Hope Chapel" } },
}
ns.ROUTES.Engineering = {
  { from = 1, to = 30, crafts = 60, craft = "Rough Blasting Powder", mats = { {2835, 1, "Rough Stone"} }, note = { "Buy a Blacksmith Hammer first", "Köp en Blacksmith Hammer först" } },
  { from = 30, to = 50, crafts = 30, craft = "Handful of Copper Bolts", mats = { {2840, 1, "Copper Bar"} } },
  { from = 50, to = 51, crafts = 1, craft = "Arclight Spanner", mats = { {2840, 6, "Copper Bar"} } },
  { from = 51, to = 75, crafts = 30, craft = "Rough Copper Bomb", mats = { {2840, 1, "Copper Bar"}, {4359, 1, "Handful of Copper Bolts"}, {4357, 2, "Rough Blasting Powder"}, {2589, 1, "Linen Cloth"} }, note = { "Journeyman at 50 (lvl 10): Trixie Quikswitch (Ironforge) / Lilliam Sparkspindle (Stormwind)", "Journeyman vid 50 (lvl 10): Trixie Quikswitch (Ironforge) / Lilliam Sparkspindle (Stormwind)" } },
  { from = 75, to = 90, crafts = 60, craft = "Coarse Blasting Powder", mats = { {2836, 1, "Coarse Stone"} } },
  { from = 90, to = 100, crafts = 20, craft = "Coarse Dynamite", mats = { {4364, 3, "Coarse Blasting Powder"}, {2589, 1, "Linen Cloth"} } },
  { from = 100, to = 105, crafts = 5, craft = "Silver Contact", mats = { {2842, 1, "Silver Bar"} } },
  { from = 105, to = 125, crafts = 25, craft = "Bronze Tube", mats = { {2841, 2, "Bronze Bar"}, {2880, 1, "Weak Flux"} } },
  { from = 125, to = 135, crafts = 10, craft = "Standard Scope", mats = { {4371, 1, "Bronze Tube"}, {1206, 1, "Moss Agate"} }, note = { "Expert at 125 (lvl 20): Springspindle Fizzlegear, Ironforge", "Expert vid 125 (lvl 20): Springspindle Fizzlegear, Ironforge" } },
  { from = 135, to = 150, crafts = 30, craft = "Heavy Blasting Powder", mats = { {2838, 1, "Heavy Stone"} }, note = { "Also 15 Whirring Bronze Gizmo - both are needed for Explosive Sheep", "Gör också 15 Whirring Bronze Gizmo - båda behövs till Explosive Sheep" } },
  { from = 150, to = 160, crafts = 15, craft = "Bronze Framework", mats = { {2841, 2, "Bronze Bar"}, {2319, 1, "Medium Leather"}, {2592, 1, "Wool Cloth"} } },
  { from = 160, to = 175, crafts = 15, craft = "Explosive Sheep", mats = { {4377, 2, "Heavy Blasting Powder"}, {4375, 1, "Whirring Bronze Gizmo"}, {4382, 1, "Bronze Framework"}, {2592, 2, "Wool Cloth"} } },
  { from = 175, to = 195, crafts = 60, craft = "Solid Blasting Powder", mats = { {7912, 2, "Solid Stone"} }, note = { "Keep the powder for later steps", "Spara pudret till senare steg" } },
  { from = 195, to = 200, crafts = 6, craft = "Mithril Tube", mats = { {3860, 3, "Mithril Bar"} } },
  { from = 200, to = 215, crafts = 20, craft = "Unstable Trigger", mats = { {3860, 1, "Mithril Bar"}, {4338, 1, "Mageweave Cloth"}, {10505, 1, "Solid Blasting Powder"} }, note = { "Artisan at 200 (lvl 35): Buzzek Bracketswing, Gadgetzan", "Artisan vid 200 (lvl 35): Buzzek Bracketswing, Gadgetzan" } },
  { from = 215, to = 238, crafts = 40, craft = "Mithril Casing", mats = { {3860, 3, "Mithril Bar"} } },
  { from = 238, to = 250, crafts = 20, craft = "Hi-Explosive Bomb", mats = { {10561, 2, "Mithril Casing"}, {10560, 1, "Unstable Trigger"}, {10505, 2, "Solid Blasting Powder"} } },
  { from = 250, to = 260, crafts = 30, craft = "Dense Blasting Powder", mats = { {12365, 2, "Dense Stone"} } },
  { from = 260, to = 285, crafts = 35, craft = "Thorium Widget", mats = { {12359, 3, "Thorium Bar"}, {14047, 1, "Runecloth"} }, note = { "Schematic: Gearcutter Cogspinner, Ironforge", "Ritning: Gearcutter Cogspinner, Ironforge" } },
  { from = 285, to = 300, crafts = 20, craft = "Thorium Tube", mats = { {12359, 6, "Thorium Bar"} }, note = { "Schematic (BoP): Xizzer Fizzbolt, Everlook", "Ritning (BoP): Xizzer Fizzbolt, Everlook" } },
}

-- Disenchant-utfall per item level (Classic-tabeller; Forever kan avvika).
-- dust/ess = {itemID, min, max}; pd/pe/ps = chans för dust/essence/shard (armor).
-- Vapen byter chans mellan dust och essence. rare = shard från blå föremål.
ns.DE_BRACKETS = {
  { max = 15,  req = 1,   dust = {10940, 1, 2}, ess = {10938, 1, 2}, pd = 0.80, pe = 0.20, ps = 0,    rare = 10978 },
  { max = 20,  req = 1,   dust = {10940, 2, 3}, ess = {10939, 1, 2}, pd = 0.75, pe = 0.20, ps = 0.05, shard = 10978, rare = 10978 },
  { max = 25,  req = 25,  dust = {10940, 4, 6}, ess = {10998, 1, 2}, pd = 0.75, pe = 0.15, ps = 0.10, shard = 10978, rare = 10978 },
  { max = 30,  req = 50,  dust = {11083, 1, 2}, ess = {11082, 1, 2}, pd = 0.75, pe = 0.20, ps = 0.05, shard = 11084, rare = 11084 },
  { max = 35,  req = 75,  dust = {11083, 2, 5}, ess = {11134, 1, 2}, pd = 0.75, pe = 0.20, ps = 0.05, shard = 11138, rare = 11138 },
  { max = 40,  req = 100, dust = {11137, 1, 2}, ess = {11135, 1, 2}, pd = 0.75, pe = 0.20, ps = 0.05, shard = 11139, rare = 11139 },
  { max = 45,  req = 125, dust = {11137, 2, 5}, ess = {11174, 1, 2}, pd = 0.75, pe = 0.20, ps = 0.05, shard = 11177, rare = 11177 },
  { max = 50,  req = 150, dust = {11176, 1, 2}, ess = {11175, 1, 2}, pd = 0.75, pe = 0.20, ps = 0.05, shard = 11178, rare = 11178 },
  { max = 55,  req = 175, dust = {11176, 2, 5}, ess = {16202, 1, 2}, pd = 0.75, pe = 0.20, ps = 0.05, shard = 14343, rare = 14343 },
  { max = 60,  req = 200, dust = {16204, 1, 2}, ess = {16203, 1, 2}, pd = 0.75, pe = 0.20, ps = 0.05, shard = 14344, rare = 14344 },
  { max = 999, req = 225, dust = {16204, 2, 5}, ess = {16203, 2, 3}, pd = 0.75, pe = 0.20, ps = 0.05, shard = 14344, rare = 14344 },
}

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
  { to = 50,  zones = "Elwynn Forest, Dun Morogh, Teldrassil, Zephras Isle" },
  { to = 100, zones = "Westfall, Loch Modan, Darkshore" },
  { to = 150, zones = "Wetlands, Redridge Mountains, Ashenvale, Duskwood" },
  { to = 200, zones = "Arathi Highlands, Hillsbrad Foothills, Stranglethorn Vale" },
  { to = 250, zones = "Stranglethorn Vale, The Hinterlands, Feralas" },
  { to = 300, zones = "Un'Goro Crater, Felwood, Western Plaguelands, Eastern Plaguelands" },
}

-- Ores: {itemID, name, Mining skill needed}. Classic values; Forever may differ a little.
ns.ORES = {
  { 2770, "Copper Ore", 1 }, { 2771, "Tin Ore", 65 }, { 2775, "Silver Ore", 75 },
  { 2772, "Iron Ore", 125 }, { 2776, "Gold Ore", 155 }, { 3858, "Mithril Ore", 175 },
  { 7911, "Truesilver Ore", 230 }, { 10620, "Thorium Ore", 245 },
}

ns.MINING_ZONES = {
  { to = 65,  zones = "Dun Morogh, Elwynn Forest, Darkshore, Loch Modan" },
  { to = 125, zones = "Redridge Mountains, Westfall, Wetlands, Ashenvale" },
  { to = 175, zones = "Arathi Highlands, Thousand Needles, Desolace, Stranglethorn Vale" },
  { to = 245, zones = "Badlands, Searing Gorge, The Hinterlands, Tanaris" },
  { to = 300, zones = "Un'Goro Crater, Burning Steppes, Winterspring, Eastern Plaguelands" },
}

-- Leather: {itemID, name, Skinning skill where it starts to drop}.
ns.LEATHER = {
  { 2934, "Ruined Leather Scraps", 1 }, { 2318, "Light Leather", 1 }, { 2319, "Medium Leather", 100 },
  { 4234, "Heavy Leather", 150 }, { 4304, "Thick Leather", 200 }, { 8170, "Rugged Leather", 250 },
}

-- Highest beast level you can skin with this skill (the Classic rule).
function ns.SkinLevel(skill)
  if skill < 100 then return math.floor(skill / 10) + 10 end
  return math.floor(skill / 5)
end
