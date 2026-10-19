coffee_rp_module = coffee_rp_module or {}

function coffee_rp_module:_on_evt_na_luo_letter_received(content)
  self:on_na_luo_letter_notify({is_leave = true, content = content})
end

function coffee_rp_module:_on_evt_na_luo_letter_recovered()
  self:on_na_luo_letter_notify({is_leave = false})
end

function coffee_rp_module:on_na_luo_letter_notify(data)
  if not data then
    return
  end
  if data.is_leave then
    self:_apply_na_luo_letter_leave(data.content)
  else
    self:_apply_na_luo_letter_recover()
  end
end

function coffee_rp_module:_apply_na_luo_letter_leave(content)
  if not string.is_valid(content) then
    return
  end
  local is_first = not self:has_na_luo_letter()
  self._na_luo_letter_content = content
  self._has_na_luo_letter = true
  self:_broadcast_na_luo_letter_visibility()
  if is_first and (not CsNetManagerUtil or not CsNetManagerUtil.isReLogin) then
    self:_open_na_luo_letter_page()
  end
end

function coffee_rp_module:_apply_na_luo_letter_recover()
  if not self:has_na_luo_letter() then
    return
  end
  self:clear_na_luo_letter()
  self:_broadcast_na_luo_letter_visibility()
end

function coffee_rp_module:_broadcast_na_luo_letter_visibility()
  EventCenter.Broadcast(EventID.NaLuoLetterVisibilityUpdate, nil)
end

function coffee_rp_module:should_show_na_luo_letter_btn()
  return self:has_na_luo_letter() and level_module:cur_level_is_coffee_rp()
end

function coffee_rp_module:open_na_luo_letter_page()
  if not self:has_na_luo_letter() then
    return
  end
  self:_open_na_luo_letter_page()
end

function coffee_rp_module:_open_na_luo_letter_page()
  local letter_data = self:_build_na_luo_letter_data(self:get_na_luo_letter_content())
  UIManagerInstance:open(self.NA_LUO_LETTER_PAGE_PATH, letter_data)
end

function coffee_rp_module:_build_na_luo_letter_data(content)
  local letter_data = G.New("InGameLetter/InGameSingleLetterData")
  letter_data.ConfigId = self.NA_LUO_LETTER_CONFIG_ID
  letter_data.IsRewardTaken = true
  letter_data.Rewards = {}
  letter_data.IsRead = true
  letter_data.SendTime = 0
  letter_data.LetterType = 0
  letter_data.IsBuffered = false
  letter_data.NpcFavorLevel = 0
  letter_data.NpcId = self.NA_LUO_NPC_ID
  letter_data.VarList = {content}
  letter_data.FromName = {
    NpcId = self.NA_LUO_NPC_ID,
    NicknameId = 0,
    CustomizedName = ""
  }
  letter_data.ToName = {NicknameId = 0, CustomizedName = ""}
  return letter_data
end

return coffee_rp_module
