local cell_cls = "UI/MainActivity_y1/SpringFestival/FukubagExchange/SpringFestivalCombineExchangeCell"
local M = G.Class("SpringFestivalCombineLuckyBagDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_NPCExChangeDialog"
  self.config.type = EUIType.Dialog
  self._target_item_id = 0
  self._other_ids = {}
  self._consume = {}
  self._add_order = {}
  self._cell_panels = {}
  self._target_item_panel = nil
  self._is_requesting = false
  self._last_target_count = 0
  self._list_binder = nil
  self._reserved_per_item = 0
  self._activity_ended = false
  self._cur_introduction_id = spring_festival_exchange_module.COMBINE_INTRODUCTION_ID or 0
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._btn_close) then
    self:bind_close_btn(self._btn_close, true)
  end
  if not is_null(self._btn_back) then
    self:bind_close_btn(self._btn_back)
  end
  if not is_null(self._btn_bg) then
    self:bind_close_btn(self._btn_bg, true)
  end
  if not is_null(self._btn_confim) then
    self:bind_callback(self._btn_confim, pack(self, M._on_click_confirm))
  end
  if not is_null(self._btn_introduction) then
    self:bind_callback(self._btn_introduction, pack(self, M._on_click_introduction))
  end
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data()
  self._target_item_id = data and data.target_item_id or 0
  self._reserved_per_item = math.max(0, tonumber(data and data.reserved_per_item) or 0)
  self._is_requesting = false
  self._activity_ended = false
  self._consume = {}
  self:_rebuild_cells()
  self:_refresh_all()
  self:_scroll_to_top()
  self:_refresh_introduction_btn()
end

function M:_get_effective_stock(fukubag_id)
  local stock = spring_festival_exchange_module:get_fukubag_stock(fukubag_id)
  local reserved = self._reserved_per_item or 0
  return math.max(0, stock - reserved)
end

function M:on_disable()
  base.on_disable(self)
  self._is_requesting = false
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaFukuBagCombineLuckyBagRsp, pack(self, M._on_combine_rsp))
  self:add_evt_listener(EventID.OnActivityRemoved, pack(self, M._on_activity_removed))
end

function M:_on_activity_removed(activity_id)
  if activity_id ~= spring_festival_activity_module:get_main_activity_id() then
    return
  end
  self._activity_ended = true
  self:_refresh_all()
end

function M:_is_interaction_locked()
  return self._is_requesting or self._activity_ended
end

function M:_get_list_binder()
  if self._list_binder ~= nil then
    return self._list_binder
  end
  if is_null(self._layout_list) then
    return nil
  end
  local trans = self._layout_list.transform ~= nil and self._layout_list.transform or self._layout_list
  local binder_type = CS.miHoYo.HYG.UI.ListItemBinder
  if binder_type == nil then
    return nil
  end
  self._list_binder = trans:GetComponent(typeof(binder_type))
  return self._list_binder
end

function M:_refresh_introduction_btn()
  if not is_null(self._btn_introduction) then
    UIUtil.set_active(self._btn_introduction, self._cur_introduction_id > 0)
  end
end

function M:_on_click_introduction()
  if self._cur_introduction_id > 0 then
    UIManagerInstance:open("UI/CommonUI/IntroductionDialog", self._cur_introduction_id)
  end
end

function M:_scroll_to_top()
  local scroll = self._scroll_list
  if scroll ~= nil and scroll.verticalNormalizedPosition ~= nil then
    scroll.verticalNormalizedPosition = 1
    if scroll.verticalScrollbar ~= nil then
      scroll.verticalScrollbar.value = 1
    end
    return
  end
  local trans
  if scroll ~= nil then
    trans = scroll.transform ~= nil and scroll.transform or scroll
  end
  if trans == nil or trans.GetComponent == nil then
    return
  end
  local scroll_rect
  local scroll_rect_ex_type = CS and CS.miHoYo and CS.miHoYo.HYG and CS.miHoYo.HYG.UI and CS.miHoYo.HYG.UI.ScrollRectEx
  if scroll_rect_ex_type ~= nil then
    scroll_rect = trans:GetComponent(typeof(scroll_rect_ex_type))
  end
  if is_null(scroll_rect) then
    local raw_scroll_rect_type = CS and CS.UnityEngine and CS.UnityEngine.UI and CS.UnityEngine.UI.ScrollRect
    if raw_scroll_rect_type ~= nil then
      scroll_rect = trans:GetComponent(typeof(raw_scroll_rect_type))
    end
  end
  if not_null(scroll_rect) then
    scroll_rect.verticalNormalizedPosition = 1
    if scroll_rect.verticalScrollbar ~= nil then
      scroll_rect.verticalScrollbar.value = 1
    end
  end
end

function M:_rebuild_cells()
  self._other_ids = spring_festival_exchange_module:get_other_fukubag_id_list(self._target_item_id, self._reserved_per_item)
  for _, cell in pairs(self._cell_panels) do
    if cell ~= nil and not_null(cell.trans) then
      UIUtil.set_active(cell.trans, false)
    end
  end
  local binder = self:_get_list_binder()
  if binder == nil then
    Logger.Log("[SpringFestivalCombineLuckyBagDialog] ListItemBinder is nil, skip rebuild.")
    return
  end
  for _, fukubag_id in ipairs(self._other_ids) do
    local cell = self._cell_panels[fukubag_id]
    if cell == nil then
      local obj = binder:AddItem(0)
      if not_null(obj) then
        cell = self:add_panel(cell_cls, obj)
        if cell ~= nil then
          cell:set_data(fukubag_id, pack(self, M._on_btn_add), pack(self, M._on_btn_minus))
          self._cell_panels[fukubag_id] = cell
        end
      end
    end
    if cell ~= nil and not_null(cell.trans) then
      UIUtil.set_active(cell.trans, true)
      cell.trans:SetAsLastSibling()
    end
  end
end

function M:_refresh_all()
  self:_refresh_exchange_target()
  for _, fukubag_id in ipairs(self._other_ids) do
    self:_refresh_cell(fukubag_id)
  end
  self:_refresh_summary()
end

function M:_refresh_exchange_target()
  if self._target_item_id == 0 then
    return
  end
  if self._target_item_panel == nil and not is_null(self._trans_exchangetarget) then
    self._target_item_panel = self:add_panel(item_module.item_v2_panel_cls_name, self._trans_exchangetarget)
  end
  if self._target_item_panel ~= nil then
    self._target_item_panel:set_item_data(self._target_item_id, nil)
    self._target_item_panel:bind_item_info_btn(self._target_item_id)
    self._target_item_panel:set_active(true)
  end
  if not is_null(self._text_getnum) then
    UIUtil.set_text(self._text_getnum, spring_festival_exchange_module:get_fukubag_stock(self._target_item_id))
  end
end

function M:_refresh_cell(fukubag_id)
  local cell = self._cell_panels[fukubag_id]
  if cell == nil then
    return
  end
  local stock = self:_get_effective_stock(fukubag_id)
  local cur = self._consume[fukubag_id] or 0
  if stock < cur then
    cur = stock
    self._consume[fukubag_id] = cur
  end
  cell:refresh(stock, cur, self:_is_interaction_locked())
end

function M:_refresh_summary()
  local per = spring_festival_exchange_module:get_fukubag_per_combine()
  local sum = 0
  for _, fukubag_id in ipairs(self._other_ids) do
    sum = sum + (self._consume[fukubag_id] or 0)
  end
  local target_count = math.floor(sum / per)
  if not is_null(self._text_resultname) then
    if target_count == 0 then
      UIUtil.set_text_by_id(self._text_resultname, "SpringFestival_ExChangeCraft_NoCount")
    else
      UIUtil.set_text(self._text_resultname, target_count)
    end
  end
  if not is_null(self._btn_confim) then
    self._btn_confim.interactable = not self:_is_interaction_locked()
  end
  if not is_null(self._text_craftnum) then
    UIUtil.set_text_by_id(self._text_craftnum, "SpringFestival_ExChangeCraft_CraftNum")
  end
end

function M:_on_btn_add(fukubag_id)
  if self:_is_interaction_locked() then
    return
  end
  local stock = self:_get_effective_stock(fukubag_id)
  local cur = self._consume[fukubag_id] or 0
  if stock <= cur then
    return
  end
  self._consume[fukubag_id] = cur + 1
  self:_refresh_cell(fukubag_id)
  self:_refresh_summary()
end

function M:_on_btn_minus(fukubag_id)
  if self:_is_interaction_locked() then
    return
  end
  local cur = self._consume[fukubag_id] or 0
  if cur <= 0 then
    return
  end
  self._consume[fukubag_id] = cur - 1
  self:_refresh_cell(fukubag_id)
  self:_refresh_summary()
end

function M:_on_click_confirm()
  if self:_is_interaction_locked() then
    return
  end
  if self._target_item_id == 0 then
    return
  end
  local per = spring_festival_exchange_module:get_fukubag_per_combine()
  local sum = 0
  for _, fukubag_id in ipairs(self._other_ids) do
    sum = sum + (self._consume[fukubag_id] or 0)
  end
  local target_count = math.floor(sum / per)
  if per > sum then
    EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id("SpringFestival_HUDCommonTip_NoEnough"))
    return
  end
  if target_count <= 0 then
    return
  end
  local aligned = target_count * per
  local trim_need = sum - aligned
  local consume_send = {}
  for _, fukubag_id in ipairs(self._other_ids) do
    consume_send[fukubag_id] = self._consume[fukubag_id] or 0
  end
  if 0 < trim_need then
    for i = #self._other_ids, 1, -1 do
      if trim_need <= 0 then
        break
      end
      local id = self._other_ids[i]
      local v = consume_send[id] or 0
      local cut = trim_need > v and v or trim_need
      consume_send[id] = v - cut
      trim_need = trim_need - cut
    end
  end
  local clear_out_id = self:_find_first_clear_out_id(consume_send)
  if clear_out_id ~= nil then
    self:_show_clear_out_confirm(clear_out_id, function()
      self:_do_send_combine(consume_send, target_count)
    end)
    return
  end
  self:_do_send_combine(consume_send, target_count)
end

function M:_do_send_combine(consume_send, target_count)
  if self:_is_interaction_locked() then
    return
  end
  CsSpringFestivalModuleUtil.ResetCombineConsume()
  for _, fukubag_id in ipairs(self._other_ids) do
    local cnt = consume_send[fukubag_id] or 0
    if 0 < cnt then
      CsSpringFestivalModuleUtil.AddCombineConsume(fukubag_id, cnt)
    end
  end
  CsSpringFestivalModuleUtil.SendCombineLuckyBagReq(self._target_item_id, target_count)
  self._is_requesting = true
  self._last_target_count = target_count
  self:_refresh_all()
end

function M:_find_first_clear_out_id(consume_send)
  for _, fukubag_id in ipairs(self._other_ids) do
    local stock = spring_festival_exchange_module:get_fukubag_stock(fukubag_id)
    local cnt = consume_send[fukubag_id] or 0
    if 0 < stock and stock <= cnt then
      return fukubag_id
    end
  end
  return nil
end

function M:_show_clear_out_confirm(item_id, on_yes)
  local popup = UIUtil.get_confirm_popup()
  local item_name = item_module:get_item_name_by_id(item_id) or ""
  local info = UIUtil.get_text_by_id("SpringFestival_ConfirmPopup_Redeem", item_name)
  local title = UIUtil.get_text_by_id("SpringFestival_ConfirmPopup_Title")
  local yes = UIUtil.get_text_by_id("Common_Accept")
  local no = UIUtil.get_text_by_id("Common_No")
  popup:set_texts(info, yes, no, title)
  popup:set_callbacks(on_yes, nil, nil)
  popup:show()
end

function M:_on_combine_rsp(arg)
  self._is_requesting = false
  local retcode = tonumber(arg) or -1
  if retcode == 0 then
    if 0 < self._last_target_count and self._target_item_id ~= 0 then
      local items = {
        {
          id = self._target_item_id,
          num = self._last_target_count
        }
      }
      common_ui_module:show_reward_dialog(nil, nil, items)
    end
    self:close_self()
  else
    self:_refresh_all()
  end
end

return M
