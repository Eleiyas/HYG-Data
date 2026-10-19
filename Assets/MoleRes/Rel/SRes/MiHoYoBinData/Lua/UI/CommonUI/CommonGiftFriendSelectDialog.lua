local M = G.Class("CommonGiftFriendSelectDialog", G.UIWindow)
local base = G.UIWindow
local TARGET_ITEM_CLS = "UI/CommonUI/CommonGiftFriendSelectItem"
local PREFAB_PATH = "UI/BattlePass/BattlePassSeasonGiftDialog"
local EMPTY_VISUAL = {
  HAS_TARGET = 0,
  NO_FRIEND = 1,
  NO_SEARCH_HIT = 2
}
local DEFAULT_FAILED_TEXT_ID = "ThemeSeason_UI_049"

local function get_gift_item_guid(gift_item_id)
  if gift_item_id <= 0 then
    return 0
  end
  local guids = list_to_table(CsPacketModuleUtil.GetItemGuidsByCfgId(gift_item_id, 1))
  if guids == nil or #guids == 0 then
    return 0
  end
  return guids[1]
end

function M:init()
  base.init(self)
  self.config.prefab_path = PREFAB_PATH
  self.config.type = EUIType.Dialog
  self._ctx = nil
  self._target_items = {}
  self._target_list = {}
  self._search_key = ""
  self._sending = false
  self._txt_dialog_title = nil
  self._list_item = nil
  self._ui_state_group_empty = nil
  self._input_field = nil
  self._btn_search = nil
  self._btn_clear = nil
  self._btn_info = nil
  self._btn_goto_friend = nil
  self._btn_close_2 = nil
  self._btn_close_popup_light = nil
end

function M:on_create()
  base.on_create(self)
  self:_bind_callbacks()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_close_btn(self._btn_close_2)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnSocialGiftSendRsp, pack(self, M._on_send_rsp))
  self:add_lua_listener(lua_event_module.event_type.on_friend_infos_update, pack(self, M.refresh))
end

function M:on_open()
  base.on_open(self)
  self._ctx = self:get_extra_data() or {}
  self._search_key = ""
  self._sending = false
  if not_null(self._input_field) then
    self._input_field.text = ""
  end
  UIUtil.set_text_by_id(self._txt_dialog_title, self._ctx.title_key)
  UIUtil.set_active(self._btn_info, self._ctx.on_info ~= nil)
end

function M:on_enable()
  base.on_enable(self)
  self:refresh()
end

function M:refresh()
  local build = self._ctx and self._ctx.build_targets
  local all_targets = build and build() or {}
  self._target_list = self:_filter_targets(all_targets)
  self:_refresh_list()
  self:_refresh_empty_visual(#all_targets, #self._target_list)
end

function M:_refresh_empty_visual(total_count, shown_count)
  if is_null(self._ui_state_group_empty) then
    return
  end
  local state = EMPTY_VISUAL.HAS_TARGET
  if total_count <= 0 then
    state = EMPTY_VISUAL.NO_FRIEND
  elseif shown_count <= 0 then
    state = EMPTY_VISUAL.NO_SEARCH_HIT
  end
  self._ui_state_group_empty:SetState(state)
end

function M:_bind_callbacks()
  if not_null(self._btn_close_popup_light) then
    self:bind_callback(self._btn_close_popup_light, pack(self, M.close_self))
  end
  if not_null(self._btn_search) then
    self:bind_callback(self._btn_search, pack(self, M._on_btn_search_click))
  end
  if not_null(self._btn_clear) then
    self:bind_callback(self._btn_clear, pack(self, M._on_btn_clear_click))
  end
  if not_null(self._btn_info) then
    self:bind_callback(self._btn_info, pack(self, M._on_btn_info_click))
  end
  if not_null(self._btn_goto_friend) then
    self:bind_callback(self._btn_goto_friend, pack(self, M._on_btn_goto_friend_click))
  end
end

function M:_filter_targets(all_targets)
  if not string.is_valid(self._search_key) then
    return all_targets
  end
  local key = string.lower(self._search_key)
  local result = {}
  for _, data in ipairs(all_targets) do
    local name = string.lower(data.name or "")
    if string.find(name, key, 1, true) or string.find(tostring(data.uid), key, 1, true) then
      result[#result + 1] = data
    end
  end
  return result
end

function M:_refresh_list()
  if is_null(self._list_item) then
    return
  end
  local on_click = pack(self, M._on_target_gift_click)
  for i = 1, #self._target_list do
    local panel = self._target_items[i]
    if panel == nil then
      local obj = self._list_item:AddItem(0)
      if not_null(obj) then
        panel = self:add_panel(TARGET_ITEM_CLS, obj)
        self._target_items[i] = panel
        UIUtil.set_active(obj, true)
      end
    end
    if panel ~= nil then
      panel:set_active(true)
      panel:refresh(self._target_list[i], on_click)
    end
  end
  for i = #self._target_list + 1, #self._target_items do
    local panel = self._target_items[i]
    if panel ~= nil then
      panel:set_active(false)
    end
  end
end

function M:_on_btn_search_click()
  self._search_key = not_null(self._input_field) and self._input_field.text or ""
  self:refresh()
end

function M:_on_btn_clear_click()
  self._search_key = ""
  if not_null(self._input_field) then
    self._input_field.text = ""
  end
  self:refresh()
end

function M:_on_btn_info_click()
  if self._ctx and self._ctx.on_info then
    self._ctx.on_info()
  end
end

function M:_on_btn_goto_friend_click()
  if social_module:open_star_friend_social_page() then
    self:close_self()
  end
end

function M:_on_target_gift_click(data)
  if data == nil or data.can_gift ~= true or self._sending then
    return
  end
  local ctx = self._ctx or {}
  if ctx.validate and not ctx.validate() then
    return
  end
  local confirm_text = ctx.build_confirm_text and ctx.build_confirm_text(data) or ""
  if not string.is_valid(confirm_text) then
    return
  end
  local items = {}
  if 0 < (ctx.gift_item_id or 0) then
    items[1] = {
      config_id = ctx.gift_item_id,
      num = ctx.gift_item_num or 1
    }
  end
  common_ui_module:show_item_common_confirm_dialog(string.is_valid(ctx.confirm_title_key) and UIUtil.get_text_by_id(ctx.confirm_title_key) or "", confirm_text, items, UIUtil.get_text_by_id("Common_No"), nil, UIUtil.get_text_by_id("Common_Yes"), function()
    self:_do_gift(data)
  end, true, nil)
end

function M:_do_gift(data)
  local ctx = self._ctx or {}
  local item_guid = get_gift_item_guid(ctx.gift_item_id or 0)
  if item_guid == 0 then
    UIUtil.show_tips_by_text_id(ctx.failed_text_id or DEFAULT_FAILED_TEXT_ID)
    self:refresh()
    return
  end
  self._sending = true
  CsSocialModuleUtil.SendSocialGift(data.uid, item_guid, ctx.gift_item_num or 1)
end

function M:_on_send_rsp(rsp)
  if rsp == nil then
    return
  end
  self._sending = false
  local ctx = self._ctx or {}
  if rsp.Retcode == 0 then
    if string.is_valid(ctx.success_text_id) then
      UIUtil.show_tips_by_text_id(ctx.success_text_id)
    end
    self:close_self()
    if ctx.on_sent then
      ctx.on_sent(rsp.ReceiverUid)
    end
    return
  end
  UIUtil.show_tips_by_text_id(ctx.failed_text_id or DEFAULT_FAILED_TEXT_ID)
  self:refresh()
end

return M
