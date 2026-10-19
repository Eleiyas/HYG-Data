local M = G.Class("GeLianMarketLeaveMessageItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._message = nil
  self._is_visit_btn_active = false
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_like, pack(self, M._on_btn_like))
  self:bind_callback(self._btn_head_icon, pack(self, M._on_btn_head_icon))
  self:bind_callback(self._btn_visit, pack(self, M._on_btn_visit))
end

function M:on_destroy()
  self._message = nil
  base.on_destroy(self)
end

function M:hide_visit_btn()
  self._is_visit_btn_active = false
  UIUtil.set_active(self._trans_btn_visit, false)
end

function M:render(message, crop_config_by_tag)
  if message == nil then
    self._message = nil
    self:set_active(false)
    return
  end
  self._message = message
  self:set_active(true)
  self:hide_visit_btn()
  local avatar_id = 1
  if message.user_id == player_module:get_player_uid() then
    avatar_id = player_module:get_player_data().playerServerData.AvatarID
  end
  local head_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), avatar_id)
  if head_cfg then
    UIUtil.set_image(self._img_head_icon, head_cfg.respath, self:get_load_proxy())
  end
  UIUtil.set_text(self._txt_message, message.content)
  UIUtil.set_text(self._txt_player_name, message.username)
  UIUtil.set_text(self._txt_date, TextMapFormatUtil.FormatDateYMD(TimeUtil.ChangeServerUtcTimeToServerLocalTime(message.create_time)))
  UIUtil.set_text(self._txt_like_num, message.likes)
  local tag_text_id = message.zone == "0" and "Market_Message_Type_2" or "Market_Message_Type_1"
  UIUtil.set_text_by_id(self._txt_tag, tag_text_id)
  self._img_like.enabled = message.is_liked == true
  local config_id = message.tag_name and crop_config_by_tag and crop_config_by_tag[message.tag_name] or nil
  if config_id ~= nil then
    item_module:set_item_icon(self._img_foodicon, config_id, nil, nil, self:get_load_proxy())
  end
end

function M:_on_btn_like()
  local message = self._message
  if message == nil then
    return
  end
  local player_uid = player_module:get_player_uid()
  local message_type = tonumber(message.zone) or 0
  if message.is_liked then
    CsGeLianMarketModuleUtil.UnlikeMessage(player_uid, message_type, message.message_id, message.market_id, nil)
  else
    CsGeLianMarketModuleUtil.LikeMessage(player_uid, message_type, message.message_id, message.market_id, nil)
  end
end

function M:_on_btn_head_icon()
  local message = self._message
  if message == nil or message.user_id == player_module:get_player_uid() then
    return
  end
  self._is_visit_btn_active = not self._is_visit_btn_active
  if self._is_visit_btn_active then
    self.holder:hide_all_visit_btn()
    self._is_visit_btn_active = true
  end
  UIUtil.set_active(self._trans_btn_visit, self._is_visit_btn_active)
end

function M:_on_btn_visit()
  local message = self._message
  if message == nil then
    return
  end
  self:hide_visit_btn()
  social_module:request_visit_player_mainland(social_module.social_transport_entry_source.gelian_food_market_message, message.user_id)
  UIUtil.show_tips_by_text_id("Visit_quest")
end

return M
