local M = G.Class("GeLianMarketLeaveMessagePanel", G.UIPanel)
local base = G.UIPanel
local message_item_cls = "UI/GeLianMarket/Panel/GeLianMarketLeaveMessageItem"

function M:init()
  base.init(self)
  self._page_service = nil
  self._view_data = nil
  self._message_items = {}
  self._show_mine = false
end

function M:on_create()
  base.on_create(self)
  local context = self:get_extra_data()
  self._page_service = context and context.page_service or nil
  self:bind_callback(self._btn_back, pack(self, M._on_btn_back))
  self:bind_callback(self._btn_send, pack(self, M._on_btn_send))
  self:bind_callback(self._tog_friend, pack(self, M._on_tog_friend))
  self:bind_callback(self._tog_mine, pack(self, M._on_tog_mine))
end

function M:on_enable()
  base.on_enable(self)
  self._tog_friend.isOn = true
  self._tog_mine.isOn = false
  self._show_mine = false
  self:_refresh_list()
end

function M:on_destroy()
  self._page_service = nil
  self._view_data = nil
  self._message_items = {}
  base.on_destroy(self)
end

function M:render(view_data)
  self._view_data = view_data
  if self.is_active then
    self:_refresh_list()
  end
end

function M:hide_all_visit_btn()
  for i = 1, #self._message_items do
    self._message_items[i]:hide_visit_btn()
  end
end

function M:_on_btn_back()
  if self._page_service ~= nil then
    self._page_service:enter_market_overview()
  end
end

function M:_on_btn_send()
  UIManagerInstance:open("UI/GeLianMarket/New/GeLianFoodMarketLeaveMessageDialog")
end

function M:_on_tog_friend(is_on)
  if is_on then
    self._show_mine = false
    self:_refresh_list()
  end
end

function M:_on_tog_mine(is_on)
  if is_on then
    self._show_mine = true
    self:_refresh_list()
  end
end

function M:_refresh_list()
  local view_data = self._view_data
  local messages = {}
  if view_data ~= nil then
    messages = self._show_mine and view_data.mine or view_data.other or {}
  end
  local is_social = player_module:get_player_uid() ~= player_module:get_scene_owner_uid()
  self._state_group_can_message:SetState(is_social and 1 or 0)
  self._btn_send.interactable = not is_social
  if #messages == 0 then
    self._state_group_message:SetState(0)
    self:_hide_all_items()
    return
  end
  self._state_group_message:SetState(1)
  self:_ensure_items(#messages)
  local crop_map = view_data and view_data.crop_config_by_tag or nil
  for i = 1, #self._message_items do
    self._message_items[i]:render(messages[i], crop_map)
  end
end

function M:_ensure_items(count)
  for i = #self._message_items + 1, count do
    local trans
    if i == 1 then
      trans = self._trans_message
    else
      local go = UIUtil.load_prefab_set_parent(self._trans_message, self._trans_message_group)
      if not_null(go) then
        trans = go.transform
      end
    end
    if trans == nil then
      return
    end
    self._message_items[i] = self:add_panel(message_item_cls, trans)
  end
end

function M:_hide_all_items()
  for i = 1, #self._message_items do
    self._message_items[i]:set_active(false)
  end
end

return M
