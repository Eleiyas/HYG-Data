local M = G.Class("GachaAllCollectItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._on_click = nil
  self._collect_cfg = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._tog_select) then
    self:bind_callback(self._tog_select, pack(self, M._on_select_click))
  end
  if not_null(self._btn_select) then
    self:bind_callback(self._btn_select, pack(self, M._on_btn_select_click))
  end
end

function M:set_on_click(on_click)
  self._on_click = on_click
end

function M:refresh(collect_cfg, is_disable)
  self._collect_cfg = collect_cfg
  if collect_cfg == nil then
    return
  end
  self:_refresh_icon(collect_cfg)
  self._tog_select.isOn = false
  UIUtil.set_active(self._btn_select, not is_disable and collect_cfg.rewardtype == GachaConst.all_collect_reward_type.video)
  UIUtil.set_active(self._tog_select, not is_disable and collect_cfg.rewardtype == GachaConst.all_collect_reward_type.effect)
end

function M:_refresh_icon(collect_cfg)
  local is_recipe = item_module:item_is_recipe(collect_cfg.rewardid)
  local is_hair_color = item_module:is_appearance_color_unlock_card(collect_cfg.rewardid)
  UIUtil.set_active(self._img_icon, not is_recipe)
  UIUtil.set_active(self._img_bg_recipe, is_recipe)
  UIUtil.set_active(self._img_bg_unlock_card, is_hair_color)
  local img_icon = is_recipe and self._img_icon_recipe or self._img_icon
  item_module:set_item_icon_with_prismatic(img_icon, collect_cfg.rewardid, nil, nil, self:get_load_proxy(), self._img_icon_prismatic)
  if is_hair_color then
    item_module:set_appearance_unlock_card(self._img_bg_unlock_card, collect_cfg.rewardid, self:get_load_proxy())
  end
end

function M:_on_select_click(is_on)
  if self._on_click ~= nil then
    self._on_click(self._collect_cfg, is_on)
  end
end

function M:_on_btn_select_click()
  if self._on_click ~= nil then
    self._on_click(self._collect_cfg, true)
  end
end

return M
