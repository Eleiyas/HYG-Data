local M = G.Class("LittleCornerAwardPage", G.UIWindow)
local base = G.UIWindow
local level_item_cls = "UI/LittleCorner/LittleCornerAwardLevelItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LittleCorner/LittleCornerAwardPage"
  self.config.type = EUIType.Page
end

function M:on_create()
  base.on_create(self)
  self._level_items = {}
  self:bind_callbacks()
end

function M:on_open()
  base.on_open(self)
  little_corner_module:query_creator_level_info()
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh()
  little_corner_module:try_show_creator_level_up_dialog()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnXhsCreatorLevelUpdated, pack(self, M._on_level_updated))
  self:add_evt_listener(EventID.OnXhsCreatorLevelRewardReceived, pack(self, M._on_reward_received))
end

function M:bind_callbacks()
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._btn_info, function()
    common_ui_module:show_introduction_dialog(common_ui_module.introduction_dialog_type.little_corner_level)
  end)
end

function M:_on_level_updated(arg)
  self:_refresh()
  little_corner_module:try_show_creator_level_up_dialog()
end

function M:_on_reward_received()
  self:_refresh()
end

function M:_refresh()
  local current_level = self:_refresh_level()
  self:_refresh_level_list(current_level)
end

function M:_refresh_level()
  local level, exp, exp_to_next = little_corner_module:get_creator_level()
  UIUtil.set_text(self._txt_level, tostring(level))
  UIUtil.set_text(self._txt_exp, tostring(exp) .. "/" .. tostring(exp_to_next))
  local level_cfg = little_corner_module:get_creator_level_cfg(level)
  UIUtil.set_text(self._txt_title, level_cfg and level_cfg.name or "")
  return level
end

function M:_refresh_level_list(current_level)
  local cfgs = little_corner_module:get_creator_level_cfgs()
  local total = #cfgs
  for i, cfg in ipairs(cfgs) do
    local item = self._level_items[i]
    if item == nil then
      local obj = self._list_item:AddItem(0)
      item = self:add_panel(level_item_cls, obj)
      self._level_items[i] = item
      obj:SetAsFirstSibling()
    end
    item:refresh(cfg, current_level, i, total, cfgs[i - 1])
    item:set_active(true)
  end
  for i = total + 1, #self._level_items do
    self._level_items[i]:set_active(false)
  end
end

return M
