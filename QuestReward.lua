-- ShamanPlan: quest reward picker. Marks the best reward when a quest lets you choose:
-- the biggest upgrade, or the best item to sell when none of them is an upgrade.
local _, ns = ...

local marks = {}

local function RewardButton(i)
  if QuestInfoRewardsFrame and QuestInfoRewardsFrame.RewardButtons and QuestInfoRewardsFrame.RewardButtons[i] then
    return QuestInfoRewardsFrame.RewardButtons[i]
  end
  return _G["QuestInfoRewardsFrameQuestInfoItem" .. i] or _G["QuestInfoItem" .. i] or _G["QuestRewardItem" .. i]
end

local function ClearMarks()
  for _, m in ipairs(marks) do m:Hide() end
  marks = {}
end

local function Mark(btn, text)
  local m = btn.ShamanPlanMark
  if not m then
    m = CreateFrame("Frame", nil, btn)
    m:SetAllPoints(btn)
    local glow = m:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(0.3, 1, 0.3)
    glow:SetAllPoints(m)
    local check = m:CreateTexture(nil, "OVERLAY")
    check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetSize(22, 22)
    check:SetPoint("TOPLEFT", m, "TOPLEFT", -6, 6)
    m.label = m:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    m.label:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", -4, 3)
    btn.ShamanPlanMark = m
  end
  m.label:SetText(text or "")
  m:SetFrameLevel(btn:GetFrameLevel() + 3)
  m:Show()
  table.insert(marks, m)
end

local function Evaluate(isRetry)
  ClearMarks()
  if ns.db.questOff or not GetNumQuestChoices or not GetQuestItemLink then return end
  local n = GetNumQuestChoices() or 0
  if n < 2 then return end

  local bestUp, bestUpI, bestVal, bestValI, missing = 0.5, nil, 0, nil, false
  for i = 1, n do
    local link = GetQuestItemLink("choice", i)
    if link then
      local diff = ns.CompareToEquipped and ns.CompareToEquipped(link)
      if diff and diff > bestUp then bestUp, bestUpI = diff, i end
      local ok, name, _, _, _, _, _, _, _, _, _, sell = pcall(ns.ItemInfo, link)
      if not (ok and name) then missing = true end
      local count = GetQuestItemInfo and select(3, GetQuestItemInfo("choice", i)) or 1
      local value = (sell or 0) * (tonumber(count) or 1)
      if value > bestVal then bestVal, bestValI = value, i end
    else
      missing = true
    end
  end
  -- Item data may not be loaded on first view; try once more shortly after.
  if missing and not isRetry then
    C_Timer.After(0.5, function() pcall(Evaluate, true) end)
    return
  end

  local pick, label, msg
  if bestUpI then
    pick = bestUpI
    label = ns.T("QR_UPGRADE_SHORT", math.floor(bestUp + 0.5))
    msg = ns.T("QR_UPGRADE", GetQuestItemLink("choice", pick) or "?", math.floor(bestUp + 0.5))
  elseif bestValI then
    pick = bestValI
    label = ns.Money(bestVal)
    msg = ns.T("QR_VENDOR", GetQuestItemLink("choice", pick) or "?", ns.Money(bestVal))
  end
  if not pick then return end
  local btn = RewardButton(pick)
  if btn then pcall(Mark, btn, label) end
  ns.Print(msg)
end

ns.RegisterModule(function()
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("QUEST_COMPLETE")
  ev:RegisterEvent("QUEST_DETAIL")
  ev:RegisterEvent("QUEST_FINISHED")
  ev:SetScript("OnEvent", function(_, event)
    if event == "QUEST_FINISHED" then
      ClearMarks()
    else
      C_Timer.After(0.1, function()
        local ok, err = pcall(Evaluate, false)
        if not ok then ns.Print(ns.T("ERROR_IN", "QuestReward", tostring(err))) end
      end)
    end
  end)
end)

ns.RegisterCommand("quest", true, function()
  ns.db.questOff = not ns.db.questOff
  ns.Print(ns.db.questOff and ns.T("QR_OFF") or ns.T("QR_ON"))
end)
