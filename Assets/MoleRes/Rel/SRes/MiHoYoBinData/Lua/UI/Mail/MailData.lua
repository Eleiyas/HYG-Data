mails_module = mails_module or {}
mails_module._cname = "mails_module"

function mails_module:mail_has_reward_not_taken(mail_data)
  if is_null(mail_data) then
    return false
  end
  local has_reward_not_taken = mail_data.attachment ~= nil and mail_data.attachment.item_list ~= nil and #mail_data.attachment.item_list > 0 and mail_data.attachment.is_taken == false
  return has_reward_not_taken
end

function mails_module:mail_has_rewards(mail_data)
  if is_null(mail_data) then
    return false
  end
  local has_reward = mail_data.attachment ~= nil and mail_data.attachment.item_list ~= nil and #mail_data.attachment.item_list > 0
  return has_reward
end

function mails_module:has_mail()
  return #self._mail_datas > 0
end

function mails_module:_get_mail_red_point(mail_data)
  local red_num = 0
  if not mail_data.is_read then
    return RedPointType.NewRp.value__, red_num
  end
  local mail_has_reward_not_taken = mails_module:mail_has_reward_not_taken(mail_data)
  if mail_has_reward_not_taken then
    return RedPointType.StrongRP.value__, red_num
  end
  return RedPointType.None.value__, red_num
end

return mails_module or {}
