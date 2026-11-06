-- ShamanPlan data: the leveling plan, per level.
-- Text entries are either a plain string or { "English", "Svenska" }.
local _, ns = ...

-- Talent point per level: Enhancement leveling (40/11/0 at 60).
-- Checked against the live tree (build 1.60.1.70790): every talent is taken only once
-- its row has 5 points per row spent in that tree, and Flurry (Mental Dexterity 3/3),
-- Improved Stormstrike (Stormstrike) and Rage of the Farseer (Mental Quickness 2/2)
-- come after what they need.
ns.talents = {
  [10] = "Thundering Strikes 1/5", [11] = "Thundering Strikes 2/5",
  [12] = "Thundering Strikes 3/5", [13] = "Thundering Strikes 4/5",
  [14] = "Thundering Strikes 5/5",
  [15] = "Mental Dexterity 1/3", [16] = "Mental Dexterity 2/3", [17] = "Mental Dexterity 3/3",
  [18] = "Ancestral Knowledge 1/5", [19] = "Ancestral Knowledge 2/5",
  [20] = "Shamanistic Focus 1/1",
  [21] = "Elemental Weapons 1/3", [22] = "Elemental Weapons 2/3", [23] = "Elemental Weapons 3/3",
  [24] = "Anticipation 1/3",
  [25] = "Stormstrike 1/1",
  [26] = "Flurry 1/5", [27] = "Flurry 2/5", [28] = "Flurry 3/5", [29] = "Flurry 4/5",
  [30] = "Flurry 5/5",
  [31] = "Improved Stormstrike 1/2", [32] = "Improved Stormstrike 2/2",
  [33] = "Improved Ghost Wolf 1/2", [34] = "Improved Ghost Wolf 2/2",
  [35] = "Mental Quickness 1/2", [36] = "Mental Quickness 2/2",
  [37] = "Ancestral Knowledge 3/5",
  [38] = "Maelstrom Weapon 1/5", [39] = "Maelstrom Weapon 2/5", [40] = "Maelstrom Weapon 3/5",
  [41] = "Maelstrom Weapon 4/5", [42] = "Maelstrom Weapon 5/5",
  [43] = "Rage of the Farseer 1/1",
  [44] = "Ancestral Knowledge 4/5", [45] = "Ancestral Knowledge 5/5",
  -- 46-60: Elemental for more Earth Shock / Lightning Bolt damage and melee crit after spell crits.
  [46] = "Concussion 1/5", [47] = "Concussion 2/5", [48] = "Concussion 3/5",
  [49] = "Concussion 4/5", [50] = "Concussion 5/5",
  [51] = "Elemental Devastation 1/3", [52] = "Elemental Devastation 2/3",
  [53] = "Elemental Devastation 3/3",
  [54] = "Call of Flame 1/3", [55] = "Call of Flame 2/3", [56] = "Call of Flame 3/3",
  [57] = "Toughness 1/5", [58] = "Toughness 2/5", [59] = "Toughness 3/5", [60] = "Toughness 4/5",
}

-- Gear, quests and consumables worth knowing about at the level.
ns.gear = {
  [4]  = { { "Earth totem: class quest from your shaman trainer", "Jordtotem: klassquest hos din shaman-trainer" } },
  [10] = { { "Fire totem: class quest (Searing Totem)", "Eldtotem: klassquest (Searing Totem)" },
           { "Elixir of Minor Agility (Alchemy)", "Elixir of Minor Agility (Alchemy)" } },
  [20] = { { "Water totem: class quest (Healing Stream Totem)", "Vattentotem: klassquest (Healing Stream Totem)" },
           { "Elixir of Ogre Strength (Alchemy)", "Elixir of Ogre Strength (Alchemy)" } },
  [30] = { { "Air totem: Call of Air quest - pick Rage of the Storm (Enhancement weapon)", "Lufttotem: Call of Air-questen - välj Rage of the Storm (Enhancement-vapen)" },
           { "Windfury Weapon: put it on your two-hander instead of Rockbiter", "Windfury Weapon: lägg den på tvåhandaren i stället för Rockbiter" } },
  [35] = { { "Elixir of Agility (Alchemy)", "Elixir of Agility (Alchemy)" } },
  [40] = { { "Elixir of Greater Agility / Greater Strength (Alchemy)", "Elixir of Greater Agility / Greater Strength (Alchemy)" } },
  [50] = { { "Elixir of the Mongoose / Brute Force (Alchemy 290+)", "Elixir of the Mongoose / Brute Force (Alchemy 290+)" } },
}

-- Spells to train (exact spell names, so the addon can check what you already know).
ns.spells = {
  [4]  = { "Earth Shock", "Stoneskin Totem" },
  [6]  = { "Earthbind Totem" },
  [8]  = { "Lightning Shield" },
  [10] = { "Flame Shock", "Searing Totem", "Strength of Earth Totem" },
  [12] = { "Fire Nova", "Purge", "Ancestral Spirit" },
  [16] = { "Cure Poison" },
  [18] = { "Tremor Totem" },
  [20] = { "Ghost Wolf", "Frost Shock", "Call of the Elements", "Healing Stream Totem", "Lesser Healing Wave", "Totemic Recall" },
  [22] = { "Cure Disease" },
  [26] = { "Magma Totem", "Mana Spring Totem" },
  [28] = { "Flametongue Totem" },
  [30] = { "Windfury Weapon", "Grounding Totem", "Reincarnation" },
  [32] = { "Windfury Totem", "Chain Lightning" },
  [40] = { "Chain Heal" },
  [42] = { "Grace of Air Totem" },
}

-- Profession goals: at this level you want at least this skill.
ns.profTargets = {
  { level = 10, skill = 50,  note = { "Train Journeyman (Tally Berryfizz, Ironforge)", "Träna Journeyman (Tally Berryfizz, Ironforge)" } },
  { level = 20, skill = 125, note = { "Train Expert (Ainethil, Darnassus)", "Träna Expert (Ainethil, Darnassus)" } },
  { level = 35, skill = 200, note = { "Train Artisan (Kylanna Windwhisper, Feathermoon, Feralas)", "Träna Artisan (Kylanna Windwhisper, Feathermoon, Feralas)" } },
  { level = 50, skill = 260, note = { "Keep pace towards 300", "Håll takten mot 300" } },
  { level = 58, skill = 300, note = { "300 for Elixir of the Mongoose", "300 för Elixir of the Mongoose" } },
}
