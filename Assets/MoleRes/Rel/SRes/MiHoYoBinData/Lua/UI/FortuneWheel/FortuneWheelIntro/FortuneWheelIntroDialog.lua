local M = G.Class("FortuneWheelIntroDialog", G.UIWindow)
local base = G.UIWindow
local item_v2_cls = item_module.item_v2_panel_cls_name
local xiwei_gift_details_dialog = require("UI/ConfirmView/XiweiGiftDetailsDialog")
local rule_data = {
  {
    title = "FortuneWheeNewPage_Text_26",
    content = "FortuneWheeNewPage_Text_27"
  }
}
local item_type_title = 0
local item_type_content = 1

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/FortuneWheelIntrodialog"
  self.config.type = EUIType.Dialog
  self._intro_items = {}
  self._reward_items = {}
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self:_refresh_rule_list()
  self:_refresh_reward_list()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close_1)
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close_1)
  self:bind_close_btn(self._btn_close_2)
  self:bind_close_btn(self._btn_close_3)
end

function M:_refresh_rule_list()
  self._intro_items = {}
  for _, rule in ipairs(rule_data) do
    local title_obj = self._list_rule:AddItem(item_type_title)
    local title_item = self:add_panel("UI/FortuneWheel/FortuneWheelIntro/FortuneWheelIntroItem", title_obj)
    title_item:refresh(UIUtil.get_text_by_id(rule.title))
    table.insert(self._intro_items, title_item)
    local content_obj = self._list_rule:AddItem(item_type_content)
    local content_item = self:add_panel("UI/FortuneWheel/FortuneWheelIntro/FortuneWheelIntroItem", content_obj)
    content_item:refresh(UIUtil.get_text_by_id(rule.content))
    table.insert(self._intro_items, content_item)
  end
end

function M:_refresh_reward_list()
  self._reward_items = {}
  for i, cfg_id in ipairs(fortune_wheel_module.gift_ids) do
    local obj = self._list_reward:AddItem(0)
    local panel = self:add_panel(item_v2_cls, obj)
    panel:set_item_data(cfg_id)
    self:bind_callback(panel:get_btn(), function()
      local data = {box_id = cfg_id}
      if xiwei_gift_details_dialog.try_open(cfg_id, data) then
        return
      end
      UIManagerInstance:open("UI/GachaGiftBox/GachaGiftBoxDialog", data)
    end)
    table.insert(self._reward_items, panel)
  end
end

return M
