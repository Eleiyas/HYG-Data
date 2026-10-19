local M = G.Class("CookProficiencyDetailsDialog", G.UIWindow)
local base = G.UIWindow
local item_v2_cls = item_module.item_v2_panel_cls_name
local star_item_cls = cooking_module.cook_proficiency_details_item_cls_name

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Cooking/CookProficiencyDetailsDialog"
  self.config.type = EUIType.Dialog
  self._recipe_id = 0
  self._item_panel = nil
  self._star_cfg_items = nil
  self._sorted_star_cfgs = nil
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._obj_item) then
    self._item_panel = self:add_panel(item_v2_cls, self._obj_item)
  end
  self:_add_ui_listener()
  self:_build_sorted_star_cfgs()
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data() or {}
  self._recipe_id = data.recipe_id or cooking_module:get_selected_recipe_id() or 0
  self:_refresh()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  base.on_destroy(self)
  self._item_panel = nil
  self._star_cfg_items = nil
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
end

function M:_refresh()
  self:_refresh_recipe_header()
  self:_refresh_exp_slider()
  self:_refresh_star_cfg_list()
end

function M:_refresh_recipe_header()
  local recipe_id = self._recipe_id or 0
  local recipe_cfg = 0 < recipe_id and ExcelDataUtil.get_value(typeof(BCookRecipeCfg), recipe_id) or nil
  local item_id = not is_null(recipe_cfg) and (recipe_cfg.itemid or 0) or 0
  if not is_null(self._item_panel) then
    if 0 < item_id then
      self._item_panel:set_item_data(item_id, nil)
      self._item_panel:bind_item_info_btn(item_id, false)
      UIUtil.set_active(self._obj_item, true)
    else
      self._item_panel:set_empty()
      UIUtil.set_active(self._obj_item, false)
    end
  end
  if not is_null(self._txt_name) then
    if 0 < item_id then
      item_module:set_item_name(self._txt_name, item_id)
    else
      UIUtil.set_text(self._txt_name, "")
    end
  end
end

function M:_refresh_exp_slider()
  if is_null(self._slider_exp) then
    return
  end
  if self._sorted_star_cfgs == nil then
    self:_build_sorted_star_cfgs()
  end
  local value = self:_calc_exp_slider_value()
  self._slider_exp.minValue = 0
  self._slider_exp.maxValue = 1
  self._slider_exp.interactable = false
  self._slider_exp.value = value
end

function M:_calc_exp_slider_value()
  local cfgs = self._sorted_star_cfgs or {}
  local max_level = #cfgs
  if max_level <= 0 then
    return 0
  end
  if max_level <= 1 then
    return 1
  end
  local recipe_id = self._recipe_id or 0
  local recipe_data = 0 < recipe_id and CsCookModuleUtil.GetCookRecipeDataById(recipe_id) or nil
  if is_null(recipe_data) then
    return 0
  end
  local ratio = recipe_data.ProficiencyRatio or 0
  local cur_lv = recipe_data.Lv or 1
  if cur_lv < 1 then
    cur_lv = 1
  end
  if max_level <= cur_lv then
    return 1
  end
  local segment = 1 / (max_level - 1)
  local cur_cfg = cfgs[cur_lv]
  local next_cfg = cfgs[cur_lv + 1]
  if is_null(cur_cfg) or is_null(next_cfg) then
    return 0
  end
  local cur_from = cur_cfg.fromproficiency or 0
  local next_from = next_cfg.fromproficiency or 0
  local seg_progress = 0
  if cur_from < next_from then
    seg_progress = (ratio - cur_from) / (next_from - cur_from)
  elseif ratio >= next_from then
    seg_progress = 1
  end
  if seg_progress < 0 then
    seg_progress = 0
  elseif 1 < seg_progress then
    seg_progress = 1
  end
  local value = segment * (cur_lv - 1) + segment * seg_progress
  if value < 0 then
    return 0
  elseif 1 < value then
    return 1
  end
  return value
end

function M:_build_sorted_star_cfgs()
  local cfg_table = ExcelDataUtil.get_table(typeof(BCookStarCfg))
  self._sorted_star_cfgs = {}
  if cfg_table == nil then
    return
  end
  for _, cfg in pairs(cfg_table) do
    table.insert(self._sorted_star_cfgs, cfg)
  end
  table.sort(self._sorted_star_cfgs, function(a, b)
    return (a.cooklv or 0) < (b.cooklv or 0)
  end)
end

function M:_refresh_star_cfg_list()
  local binder = self._list_item_content
  if is_null(binder) then
    return
  end
  if self._sorted_star_cfgs == nil then
    self:_build_sorted_star_cfgs()
  end
  if self._star_cfg_items == nil then
    self._star_cfg_items = {}
  end
  local current_lv = 1
  local recipe_id = self._recipe_id or 0
  if 0 < recipe_id then
    local recipe_data = CsCookModuleUtil.GetCookRecipeDataById(recipe_id)
    if not is_null(recipe_data) then
      current_lv = recipe_data.Lv or 1
    end
  end
  local cfgs = self._sorted_star_cfgs or {}
  local count = #cfgs
  for i = 1, count do
    local entry = self._star_cfg_items[i]
    if entry == nil then
      local obj = binder:AddItem(0)
      if not is_null(obj) then
        local panel = self:add_panel(star_item_cls, obj)
        entry = {obj = obj, panel = panel}
        self._star_cfg_items[i] = entry
      end
    end
    if entry and not is_null(entry.obj) and entry.panel then
      UIUtil.set_active(entry.obj, true)
      entry.panel:refresh(cfgs[i], current_lv)
    end
  end
  for i = count + 1, #self._star_cfg_items do
    local entry = self._star_cfg_items[i]
    if entry and not is_null(entry.obj) then
      UIUtil.set_active(entry.obj, false)
    end
  end
end

return M
