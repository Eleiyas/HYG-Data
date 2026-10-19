local M = G.Class("LittleCornerFollowingListItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._uid = 0
  self._uname = ""
  self._avatar_id = 0
  self._is_followed = false
  self._creator_level = 1
  self._is_following_me = false
  self._img_head = nil
  self._txt_name = nil
  self._ui_state_group_btn = nil
  self._btn_not_follow = nil
  self._btn_follow = nil
  self._trans_lv_bg = nil
  self._txt_lv = nil
  self._btn_head = nil
  self._btn_follow_group = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_data()
  self:_refresh_ui()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnXhsFollowChanged, function(data)
    local target_uid = data.value1
    local is_followed = data.value2
    if target_uid == self._uid then
      self._is_followed = is_followed
      self:_refresh_follow_state()
    end
  end)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_follow, pack(self, M._on_btn_follow))
  self:bind_callback(self._btn_not_follow, pack(self, M._on_btn_not_follow))
  self:bind_callback(self._btn_head, pack(self, M._on_btn_head))
end

function M:_on_btn_follow()
  if little_corner_module:try_block_little_corner_with_tip() then
    return
  end
  CsLittleCornerModuleUtil.FollowXhsUser(self._uid, true)
  self._is_followed = true
  self:_refresh_follow_state()
end

function M:_on_btn_not_follow()
  if little_corner_module:try_block_little_corner_with_tip() then
    return
  end
  CsLittleCornerModuleUtil.FollowXhsUser(self._uid, false)
  self._is_followed = false
  self:_refresh_follow_state()
end

function M:_on_btn_head()
  little_corner_module:open_user_id_card(self._uid)
end

function M:_refresh_data()
  local extra_data = self:get_extra_data() or {}
  self._uid = extra_data.uid or 0
  self._uname = extra_data.uname or ""
  self._avatar_id = extra_data.avatar_id or 0
  self._is_followed = extra_data.is_followed or false
  self._creator_level = extra_data.creator_level or 1
  self._is_following_me = extra_data.is_following_me or false
end

function M:_refresh_ui()
  UIUtil.set_text(self._txt_name, self._uname)
  local avatar_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), self._avatar_id)
  if not_null(avatar_cfg) then
    UIUtil.set_image(self._img_head, avatar_cfg.respath, self:get_load_proxy())
  end
  self:_refresh_creator_level()
  local is_self = self._uid == player_module:get_player_uid()
  UIUtil.set_active(self._btn_follow_group, not is_self)
  self:_refresh_follow_state()
end

function M:_refresh_creator_level()
  local level = math.max(self._creator_level, 1)
  UIUtil.set_active(self._trans_lv_bg, true)
  UIUtil.set_text(self._txt_lv, string.format("Lv. %d", level))
end

function M:_refresh_follow_state()
  local followed = self._is_followed
  self._ui_state_group_btn:SetState(followed and 1 or 0)
  if followed then
    self:_refresh_not_follow_btn_text()
  end
end

function M:_refresh_not_follow_btn_text()
  local is_mutual = self._is_followed and self._is_following_me
  local text_ids = little_corner_module.follow_btn_text_id
  local text_id = is_mutual and text_ids.mutual_follow or text_ids.unfollow
  UIUtil.set_text_by_id(self._btn_not_follow, text_id)
end

function M:force_refresh()
  self:_refresh_data()
  self:_refresh_ui()
end

return M
