-- ShamanPlan: a small easter egg. When you /kiss a player who also runs one of the Plan
-- addons (ShamanPlan, ShamanPlan, DruidPlan), both of you get a big heart on screen.
-- The addons talk over a shared, hidden addon-message channel.
local _, ns = ...

local PREFIX = "ZodacPlan"
local heart, label, anim
local lastSent, lastShown = {}, 0

local function Short(name)
  return (name or ""):match("^([^%-]+)") or name or "?"
end

local function ShowHeart(from)
  if GetTime() - lastShown < 2 then return end
  lastShown = GetTime()
  label:SetText("|cffff88aa" .. ns.T("KISS_FROM", Short(from)) .. "|r")
  heart:Show()
  anim:Stop()
  anim:Play()
  if PlaySound and SOUNDKIT and SOUNDKIT.UI_GARRISON_FOLLOWER_LEARN_TRAIT then
    pcall(PlaySound, SOUNDKIT.UI_GARRISON_FOLLOWER_LEARN_TRAIT)
  end
end

local function Send(msg, target)
  local send = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
  if send and target then pcall(send, PREFIX, msg, "WHISPER", target) end
end

local function CreateHeart()
  heart = CreateFrame("Frame", "ShamanPlanHeart", UIParent)
  heart:SetSize(256, 256)
  heart:SetPoint("CENTER", 0, 80)
  heart:SetFrameStrata("FULLSCREEN_DIALOG")
  heart:EnableMouse(false)
  local tex = heart:CreateTexture(nil, "ARTWORK")
  tex:SetAllPoints()
  tex:SetTexture(ns.MEDIA .. "Heart")
  label = heart:CreateFontString(nil, "OVERLAY")
  label:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
  label:SetPoint("TOP", heart, "BOTTOM", 0, 10)

  anim = heart:CreateAnimationGroup()
  local fadeIn = anim:CreateAnimation("Alpha")
  fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.3); fadeIn:SetOrder(1)
  local grow = anim:CreateAnimation("Scale")
  if grow.SetScaleFrom then grow:SetScaleFrom(0.4, 0.4); grow:SetScaleTo(1, 1)
  elseif grow.SetFromScale then grow:SetFromScale(0.4, 0.4); grow:SetToScale(1, 1) end
  grow:SetDuration(0.3); grow:SetOrder(1)
  for i = 1, 3 do
    local up = anim:CreateAnimation("Scale")
    up:SetScale(1.12, 1.12); up:SetDuration(0.18); up:SetOrder(1 + i * 2)
    local down = anim:CreateAnimation("Scale")
    down:SetScale(1 / 1.12, 1 / 1.12); down:SetDuration(0.18); down:SetOrder(2 + i * 2)
  end
  local fadeOut = anim:CreateAnimation("Alpha")
  fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0); fadeOut:SetDuration(0.8); fadeOut:SetStartDelay(0.6); fadeOut:SetOrder(9)
  anim:SetScript("OnFinished", function() heart:Hide() end)
  heart:Hide()
end

-- /kiss on a player: tell their Plan addon (if they have one).
local function OnEmote(token, unit)
  if type(token) ~= "string" or token:upper() ~= "KISS" then return end
  unit = (type(unit) == "string" and unit ~= "" and unit) or "target"
  if not (UnitExists(unit) and UnitIsPlayer(unit)) or UnitIsUnit(unit, "player") then return end
  local name, realm = UnitName(unit)
  if not name then return end
  local full = (realm and realm ~= "") and (name .. "-" .. realm) or name
  if lastSent[full] and GetTime() - lastSent[full] < 5 then return end
  lastSent[full] = GetTime()
  Send("KISS", full)
end

ns.RegisterModule(function()
  CreateHeart()
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX)
  elseif RegisterAddonMessagePrefix then
    pcall(RegisterAddonMessagePrefix, PREFIX)
  end
  if DoEmote then hooksecurefunc("DoEmote", function(token, unit) pcall(OnEmote, token, unit) end) end
  if C_ChatInfo and C_ChatInfo.PerformEmote then
    hooksecurefunc(C_ChatInfo, "PerformEmote", function(token, unit) pcall(OnEmote, token, unit) end)
  end

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("CHAT_MSG_ADDON")
  ev:SetScript("OnEvent", function(_, _, prefix, msg, _, sender)
    if prefix ~= PREFIX then return end
    if msg == "KISS" then
      ShowHeart(sender)
      Send("KISSBACK", sender)
    elseif msg == "KISSBACK" then
      ShowHeart(sender)
    end
  end)
end)

ns.RegisterCommand("heart", false, function() ShowHeart(UnitName("player")) end)
