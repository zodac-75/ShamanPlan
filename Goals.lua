-- ShamanPlan: gold goal and Merchant's Favor progress.
local _, ns = ...

-- Merchant's Favor costs for items in the plan.
-- (None for Alchemy yet; the line still shows how much Favor you have.)
local FAVOR_GOALS = {}

-- Merchant's Favor may be a currency or a bag item; check both by name.
local function FavorCount()
  if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize and C_CurrencyInfo.GetCurrencyListInfo then
    local okN, n = pcall(C_CurrencyInfo.GetCurrencyListSize)
    if okN and n then
      for i = 1, n do
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyListInfo, i)
        if ok and type(info) == "table" and info.name == "Merchant's Favor" then
          return info.quantity or 0
        end
      end
    end
  end
  if ns.favorItemID then return ns.ItemCount(ns.favorItemID) end
  local numSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
  local getLink = (C_Container and C_Container.GetContainerItemLink) or GetContainerItemLink
  if not (numSlots and getLink) then return nil end
  for bag = 0, 4 do
    for slot = 1, (numSlots(bag) or 0) do
      local link = getLink(bag, slot)
      if link and link:find("%[Merchant's Favor%]") then
        ns.favorItemID = tonumber(link:match("item:(%d+)"))
        if ns.favorItemID then return ns.ItemCount(ns.favorItemID) end
      end
    end
  end
  return nil
end

local function GoldLine()
  local goal = ns.db.goldGoal
  if not goal or not goal.amount or goal.amount <= 0 then return nil end
  local money = (GetMoney and GetMoney()) or 0
  local label = goal.label and goal.label ~= "" and (" (" .. goal.label .. ")") or ""
  local line = ns.T("GOAL_LINE", ns.Money(money), ns.Money(goal.amount), label)
  if money >= goal.amount then
    return "|cff60ff60" .. line .. ns.T("GOAL_REACHED") .. "|r"
  end
  return "|cffffd100" .. line .. "|r" .. ns.T("GOAL_LEFT", ns.Money(goal.amount - money))
end

local function FavorLine()
  local n = FavorCount()
  if not n then return nil end
  local line = "|cffffd100" .. ns.T("FAVOR_LINE", n) .. "|r"
  for _, g in ipairs(FAVOR_GOALS) do
    if n < g.cost then
      return line .. ns.T("FAVOR_NEXT", g.name, g.cost)
    end
  end
  return line
end

ns.RegisterModule(function()
  ns.AddStatusProvider(GoldLine)
  ns.AddStatusProvider(FavorLine)
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_MONEY")
  ev:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
  ev:RegisterEvent("BAG_UPDATE")
  ev:SetScript("OnEvent", function() ns.Debounce("main", 1, ns.RefreshMain) end)
end)

ns.RegisterCommand("goal", true, function(rest)
  rest = rest or ""
  local amount = tonumber(rest:match("^(%d+)"))
  if not amount then
    ns.Print(ns.T("GOAL_USAGE"))
    return
  end
  if amount == 0 then
    ns.db.goldGoal = nil
    ns.Print(ns.T("GOAL_CLEARED"))
  else
    local label = rest:match("^%d+%s+(.+)$")
    ns.db.goldGoal = { amount = amount * 10000, label = label }
    ns.Print(ns.T("GOAL_SET", amount .. "g", label and (" (" .. label .. ")") or ""))
  end
  ns.RefreshMain()
end)
