-- ShamanPlan: talent plans. Enhancement leveling comes from Data.lua. More plans can be
-- added here with Build(); every plan must be checked against the live tree.
local _, ns = ...

-- Builds a level -> "Talent n/max" table from steps of { name, maxRank, count }.
local function Build(startLevel, steps)
  local t, lvl, have = {}, startLevel, {}
  for _, s in ipairs(steps) do
    local name, max, n = s[1], s[2], s[3] or s[2]
    for _ = 1, n do
      have[name] = (have[name] or 0) + 1
      t[lvl] = string.format("%s %d/%d", name, have[name], max)
      lvl = lvl + 1
    end
  end
  return t
end

ns.PLANS = {
  enhancement = { talents = ns.talents },
}
ns.PLAN_ORDER = { "enhancement" }

function ns.PlanKey()
  local k = ns.db and ns.db.plan
  if k and ns.PLANS[k] then return k end
  return "enhancement"
end

function ns.ApplyPlan()
  ns.talents = ns.PLANS[ns.PlanKey()].talents
end

function ns.CyclePlan()
  local cur, nextKey = ns.PlanKey(), ns.PLAN_ORDER[1]
  for i, k in ipairs(ns.PLAN_ORDER) do
    if k == cur then nextKey = ns.PLAN_ORDER[(i % #ns.PLAN_ORDER) + 1] end
  end
  ns.db.plan = nextKey
  ns.ApplyPlan()
  ns.Print(ns.T("PLAN_SET", ns.T("PLAN_" .. nextKey)))
  ns.RefreshMain()
  if ns.RefreshTalentGlow then ns.RefreshTalentGlow() end
  if ns.RefreshMenu then ns.RefreshMenu() end
end

ns.RegisterModule(function() ns.ApplyPlan() end)
