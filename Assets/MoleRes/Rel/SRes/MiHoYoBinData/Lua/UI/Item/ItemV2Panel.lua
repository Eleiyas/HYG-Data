local EMarkWarning = item_module.EMarkWarning
local M = G.Class("ItemV2Panel", G.UIPanel)
local base = G.UIBase

function M:init()
  base.init(self)
  self._cfg_id = 0
  self._star_list_inited = false
  self._player_buff_item = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._trans_player_buff_item) then
    self._player_buff_item = self:add_panel(player_module.player_buff_item_cls_name, self._trans_player_buff_item)
  end
end

function M:on_destroy()
  if not_null(self._star_list) then
    self._star_list:Close()
  end
  base.on_destroy(self)
end

function M:set_item_data(cfg_id, num, server_data)
  if cfg_id == nil or cfg_id <= 0 then
    self:set_empty()
    return
  end
  local cfg = item_module:get_cfg_by_id(cfg_id)
  if cfg == nil then
    Logger.LogError("ItemV2Panel: 找不到道具配置, cfg_id=" .. tostring(cfg_id))
    self:set_empty()
    return
  end
  self._cfg_id = cfg_id
  self:set_quality(cfg.rank)
  self:set_num(num)
  self:refresh_icon_type(cfg_id, server_data)
  self:set_star(server_data)
  self:set_npc_cloth_state(cfg_id)
  self:set_food_perfect(server_data)
  self:_refresh_buff_ui(server_data)
end

function M:set_empty()
  self._cfg_id = 0
  if not_null(self._ui_state_group_quality) then
    self._ui_state_group_quality:SetState(0)
  end
  UIUtil.set_active(self._txt_num, false)
  self:set_star(nil)
  self:set_red_point(false)
  self:_set_all_icon_active(false)
  if not is_null(self._img_icon_prismatic) then
    self._img_icon_prismatic.sprite = nil
  end
  self:set_npc_cloth_state(0)
  self:set_food_perfect(nil)
  self:_refresh_buff_ui(nil)
end

function M:set_quality(rank)
  if is_null(self._ui_state_group_quality) then
    return
  end
  self._ui_state_group_quality:SetState(rank or 0)
end

function M:set_npc_cloth_state(cfg_id)
  if is_null(self._ui_state_group_npc) then
    return
  end
  local is_npc_cloth = item_module:is_npc_cloth(cfg_id or 0)
  self._ui_state_group_npc:SetState(is_npc_cloth and 1 or 0)
end

function M:set_num(num, max_num)
  if is_null(self._txt_num) then
    return
  end
  num = num or 0
  max_num = max_num or 0
  if num <= 1 and max_num <= 1 then
    UIUtil.set_active(self._txt_num, false)
    return
  end
  local str
  if num < max_num then
    str = string.format("%s~%s", item_module:get_item_num_str(num), item_module:get_item_num_str(max_num))
  else
    str = tostring(item_module:get_item_num_str(num))
  end
  UIUtil.set_text(self._txt_num, str)
  UIUtil.set_active(self._txt_num, true)
end

function M:set_num_required(cur, need, mark_warning)
  if is_null(self._txt_num) then
    return
  end
  cur = cur or 0
  need = need or 0
  local mode = mark_warning
  if mode == true then
    mode = EMarkWarning.WhenZero
  else
    mode = mode or EMarkWarning.None
  end
  local should_warn = false
  if mode == EMarkWarning.WhenZero then
    should_warn = cur <= 0
  elseif mode == EMarkWarning.WhenInsufficient then
    should_warn = cur < need
  end
  local cur_str = tostring(item_module:get_item_num_str(cur))
  if should_warn then
    cur_str = string.format("<style=TextWarning_Dark>%s</style>", cur_str)
  end
  local str
  str = string.format("%s/%s", cur_str, tostring(need))
  UIUtil.set_text(self._txt_num, str)
  UIUtil.set_active(self._txt_num, true)
end

function M:set_num_with_warning(cur, mark_warning)
  if is_null(self._txt_num) then
    return
  end
  cur = cur or 0
  local mode = mark_warning
  if mode == true then
    mode = EMarkWarning.WhenZero
  else
    mode = mode or EMarkWarning.None
  end
  local should_warn = false
  if mode == EMarkWarning.WhenZero then
    should_warn = cur <= 0
  end
  local cur_str = tostring(item_module:get_item_num_str(cur))
  if should_warn then
    cur_str = string.format("<style=TextWarning_Dark>%s</style>", cur_str)
  end
  UIUtil.set_text(self._txt_num, cur_str)
  UIUtil.set_active(self._txt_num, true)
end

function M:set_star(server_data)
  if is_null(self._star_list) then
    return
  end
  local star_level = 0
  if not_null(server_data) then
    local is_show = item_module:is_show_star(server_data.GUID, server_data)
    if is_show and not_null(server_data.StarLevel) then
      star_level = server_data.StarLevel
    end
  end
  UIUtil.set_active(self._star_list, 0 < star_level)
  if star_level <= 0 then
    return
  end
  if not self._star_list_inited then
    self._star_list:Init(star_level, pack(self, M._on_star_item_update))
    self._star_list_inited = true
  else
    self._star_list:Reload(star_level, pack(self, M._on_star_item_update))
  end
end

function M:set_star_level(star_level)
  if is_null(self._star_list) then
    return
  end
  star_level = star_level or 0
  UIUtil.set_active(self._star_list, 0 < star_level)
  if star_level <= 0 then
    return
  end
  if not self._star_list_inited then
    self._star_list:Init(star_level, pack(self, M._on_star_item_update))
    self._star_list_inited = true
  else
    self._star_list:Reload(star_level, pack(self, M._on_star_item_update))
  end
end

function M:set_food_perfect(server_data)
  if is_null(self._img_food_perfect) then
    return
  end
  UIUtil.set_active(self._img_food_perfect, item_module:is_food_perfect(server_data))
end

function M:_refresh_buff_ui(server_data)
  if not self._player_buff_item then
    return
  end
  self._player_buff_item:refresh(item_module:get_item_show_buff_id(server_data), nil)
end

function M:set_red_point(show, red_point_type)
  if is_null(self._red_point) then
    return
  end
  if show then
    self._red_point:ShowRedPoint(red_point_type or RedPointType.NewRp)
  else
    self._red_point:ShowRedPoint(RedPointType.None)
  end
end

function M:refresh_icon_type(cfg_id, server_data)
  local is_recipe = item_module:item_is_recipe(cfg_id)
  local is_cooking = item_module:item_is_cooking_recipe(cfg_id)
  local is_unlock_card = item_module:is_appearance_color_unlock_card(cfg_id)
  UIUtil.set_active(self._img_bg_recipe, is_recipe)
  UIUtil.set_active(self._img_icon_recipe, is_recipe)
  UIUtil.set_active(self._img_bg_cooking, is_cooking)
  UIUtil.set_active(self._img_icon_cooking, is_cooking)
  UIUtil.set_active(self._img_bg_unlock_card, is_unlock_card)
  UIUtil.set_active(self._img_icon_unlock_card, is_unlock_card)
  UIUtil.set_active(self._img_icon, not is_recipe and not is_cooking and not is_unlock_card)
  if is_recipe then
    if not is_null(self._img_icon_prismatic) then
      self._img_icon_prismatic.sprite = nil
    end
    item_module:set_item_icon(self._img_icon_recipe, cfg_id, nil, server_data, self:get_load_proxy())
    item_module:set_recipe_card(self._img_bg_recipe, cfg_id, self:get_load_proxy())
  elseif is_cooking then
    if not is_null(self._img_icon_prismatic) then
      self._img_icon_prismatic.sprite = nil
    end
    item_module:set_item_icon(self._img_icon_cooking, cfg_id, nil, server_data, self:get_load_proxy())
    item_module:set_cooking_recipe_card(self._img_bg_cooking, cfg_id, self:get_load_proxy())
  elseif is_unlock_card then
    if not is_null(self._img_icon_prismatic) then
      self._img_icon_prismatic.sprite = nil
    end
    item_module:set_appearance_unlock_card(self._img_bg_unlock_card, cfg_id, self:get_load_proxy())
    item_module:set_appearance_unlock_icon(self._img_icon_unlock_card, cfg_id, self:get_load_proxy())
  else
    item_module:set_item_icon_with_prismatic(self._img_icon, cfg_id, nil, server_data, self:get_load_proxy(), self._img_icon_prismatic)
  end
end

function M:bind_item_info_btn(cfg_id, show_bag_num)
  if self._btn == nil then
    return
  end
  if show_bag_num == nil then
    show_bag_num = true
  end
  self:bind_callback(self._btn, function()
    local num = show_bag_num and back_bag_module:get_coin_or_item_num(cfg_id) or 0
    item_module:open_item_info_dialog(cfg_id, num)
  end)
end

function M:get_btn()
  return self._btn
end

function M:get_cfg_id()
  return self._cfg_id
end

function M:_on_star_item_update(go, index)
  if not is_null(go) then
    go:SetActive(true)
  end
end

function M:_set_all_icon_active(active)
  UIUtil.set_active(self._img_icon, active)
  UIUtil.set_active(self._img_bg_recipe, active)
  UIUtil.set_active(self._img_icon_recipe, active)
  UIUtil.set_active(self._img_bg_cooking, active)
  UIUtil.set_active(self._img_icon_cooking, active)
  UIUtil.set_active(self._img_bg_unlock_card, active)
  UIUtil.set_active(self._img_icon_unlock_card, active)
end

return M
