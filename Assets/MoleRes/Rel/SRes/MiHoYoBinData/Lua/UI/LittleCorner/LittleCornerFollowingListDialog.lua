local M = G.Class("LittleCornerFollowingListDialog", G.UIWindow)
local base = G.UIWindow
local following_list_item_cls = "UI/LittleCorner/LittleCornerFollowingListItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LittleCorner/LittleCornerFollowingListDialog"
  self.config.type = EUIType.Dialog
  self._item_panel_dic = {}
  self._list_type = "following"
  self._target_uid = 0
  self._list_inited = false
  self._page_state = {
    page = 0,
    has_more = false,
    is_loading = false
  }
  self._btn_bg = nil
  self._btn_close_popup = nil
  self._txt_dialog_title = nil
  self._waterfall_scroller = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._waterfall_scroller:RegisterReachBottomAction(pack(self, M._on_reach_bottom))
end

function M:on_open()
  base.on_open(self)
  local extra_data = self:get_extra_data() or {}
  self._list_type = extra_data.list_type or "following"
  self._target_uid = extra_data.target_uid or 0
  UIUtil.set_text(self._txt_dialog_title, extra_data.title or "")
  self._list_inited = false
  self._page_state = {
    page = 0,
    has_more = false,
    is_loading = false
  }
  self._waterfall_scroller:ReLoad(pack(self, M._refresh_item), 0)
  self:_request_list()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
  self._list_inited = false
  self._page_state = {
    page = 0,
    has_more = false,
    is_loading = false
  }
end

function M:on_destroy()
  base.on_destroy(self)
  if not_null(self._waterfall_scroller) then
    self._waterfall_scroller:UnregisterReachBottomAction()
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnXhsFollowingListUpdated, function()
    if self._list_type == "following" then
      self:_on_list_data_updated()
    end
  end)
  self:add_evt_listener(EventID.OnXhsFollowerListUpdated, function()
    if self._list_type == "follower" then
      self:_on_list_data_updated()
    end
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_bg)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_bg, pack(self, M._on_btn_close))
  self:bind_callback(self._btn_close_popup, pack(self, M._on_btn_close))
end

function M:_on_btn_close()
  self:close_self()
end

function M:_request_list()
  local state = self._page_state
  if state.is_loading then
    return
  end
  state.is_loading = true
  if self._list_type == "follower" then
    CsLittleCornerModuleUtil.GetUserFollowerList(self._target_uid, state.page)
  else
    CsLittleCornerModuleUtil.GetUserFollowingList(self._target_uid, state.page)
  end
end

function M:_on_list_data_updated()
  local state = self._page_state
  state.is_loading = false
  state.page = state.page + 1
  if self._list_type == "follower" then
    state.has_more = CsLittleCornerModuleUtil.FollowerHasMore
  else
    state.has_more = CsLittleCornerModuleUtil.FollowingHasMore
  end
  self:_refresh_list()
end

function M:_on_reach_bottom()
  local state = self._page_state
  if not state.has_more or state.is_loading then
    return
  end
  self:_request_list()
end

function M:_get_data_source()
  if self._list_type == "follower" then
    return CsLittleCornerModuleUtil.FollowerList
  else
    return CsLittleCornerModuleUtil.FollowingList
  end
end

function M:_refresh_list()
  local data_source = self:_get_data_source()
  if is_null(data_source) then
    return
  end
  local count = data_source.Count
  if not self._list_inited then
    self._waterfall_scroller:Init(pack(self, M._refresh_item), count)
    self._list_inited = true
  else
    local current_count = self._waterfall_scroller.ItemCount
    if count > current_count then
      self._waterfall_scroller:AppendItems(count)
    elseif count == current_count then
      self._waterfall_scroller:RefreshCurrent()
    else
      self._waterfall_scroller:ReLoad(pack(self, M._refresh_item), count)
    end
  end
  UIUtil.set_active(self._empty_group, count == 0)
end

function M:_refresh_item(trans, index)
  local data_source = self:_get_data_source()
  if is_null(data_source) or data_source.Count == 0 then
    UIUtil.set_active(trans, false)
    return
  end
  local user_brief = data_source[index]
  if is_null(user_brief) then
    UIUtil.set_active(trans, false)
    return
  end
  local extra_data = {
    uid = user_brief.Uid,
    uname = user_brief.Uname,
    avatar_id = user_brief.AvatarId,
    is_followed = user_brief.IsFollowed,
    creator_level = user_brief.CreatorLevel,
    is_following_me = user_brief.IsFollowingMe
  }
  local instance_id = trans:GetInstanceID()
  local item = self._item_panel_dic[instance_id]
  if is_null(item) then
    item = self:add_panel(following_list_item_cls, trans, extra_data)
    self._item_panel_dic[instance_id] = item
  else
    item:set_extra_data(extra_data)
    item:force_refresh()
  end
  UIUtil.set_active(trans, true)
end

return M
