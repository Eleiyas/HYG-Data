local item_v2_cls = item_module.item_v2_panel_cls_name
local M = G.Class("HUDGetCardTipsUI", "UI/HUDInfo/HUDInfoUI/HUDInfoBaseUI")
local base = G.HUDInfoBaseUI
local SHOW_TIME = 5
local card_item_type = back_bag_module.batch_use_card_item_type

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/PacketView/HUDGetCardTipsUI"
  self._card_type = card_item_type.idea_card
  self._lst_item = nil
  self._item_v2_panel = nil
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._obj_item_v2_basic) then
    self._item_v2_panel = self:add_panel(item_v2_cls, self._obj_item_v2_basic)
  end
  self:bind_callback(self._btn_learn_more, pack(self, M._on_btn_learn_more_click))
end

function M:on_enable()
  base.on_enable(self)
  local extra_data = self:get_extra_data() or {}
  self._card_type = extra_data.card_type or card_item_type.idea_card
  self._lst_item = extra_data.lst_item
  self.is_unlock = true
  self:_refresh_ui()
  self:start_close_timer(SHOW_TIME)
end

function M:on_disable()
  base.on_disable(self)
  self._lst_item = nil
end

function M:_refresh_ui()
  local lst_item = self._lst_item
  if lst_item == nil or #lst_item <= 0 then
    self:close_self()
    return
  end
  local first_item = lst_item[1]
  if self._item_v2_panel ~= nil and first_item ~= nil then
    self._item_v2_panel:set_item_data(first_item.ConFigID, nil, first_item)
  end
  if self._card_type == card_item_type.cook_recipe then
    UIUtil.set_text_by_id(self._txt_title, "GetItemTips_Recipe")
  else
    UIUtil.set_text_by_id(self._txt_title, "GetItemTips_LearnBook")
  end
  if self:_need_show_learn_more() then
    UIUtil.set_text_by_id(self._txt_btn_title, "LearnBookButton_Multi")
  else
    UIUtil.set_text_by_id(self._txt_btn_title, "LearnBookButton_Single")
  end
end

function M:_need_show_learn_more()
  if self._card_type == card_item_type.idea_card then
    local lst_guid = list_to_table(CsPacketModuleUtil.GetUnlearnedCardItemGuids(false))
    return 1 < #lst_guid
  end
  return self._lst_item ~= nil and 1 < #self._lst_item
end

function M:_on_btn_learn_more_click()
  if not item_module:can_operate_card_item(true) then
    return
  end
  local first_item = self._lst_item and self._lst_item[1] or nil
  if first_item == nil then
    self:close_self()
    return
  end
  local optionfunction = self._card_type == card_item_type.cook_recipe and item_module.item_option_function_type.learn_recipe or item_module.item_option_function_type.remember
  self:close_self()
  item_module:use_item_new(first_item, {optionfunction = optionfunction})
end

return M
