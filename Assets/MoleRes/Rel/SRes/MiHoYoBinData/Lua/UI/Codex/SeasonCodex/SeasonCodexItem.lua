local M = G.Class("SeasonCodexItem", G.UIPanel)
local base = G.UIPanel
local codex_anim = require("UI/Codex/SeasonCodex/SeasonCodexAnim")
local ICON_LAYER_NAME_PREFIX = "img_icon_dynamic"
local lock_state = {
  locked = 0,
  unlocked_not_owned = 1,
  unlocked_owned = 1
}
local star_state = {
  not_full = 0,
  full = 1,
  none = 2
}
local RANK_GOLD = 3
local light_state = {off = 0, on = 1}
local red_point_type_season = red_point_module.red_point_type.season_codex

function M:init()
  base.init(self)
  self._data = nil
  self._index = 0
  self._on_click = nil
  self._on_new_cleared = nil
  self._is_new = false
  self._img_icon_layers = {}
  self._item_stars = {}
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self:_init_icon_layers()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:_add_ui_listener()
  if not_null(self._btn_content) then
    self:bind_callback(self._btn_content, pack(self, M._on_btn_content_click))
  end
end

function M:_on_btn_content_click()
  if self._on_click and self._data then
    self._on_click(self._data)
  end
end

function M:_init_icon_layers()
  self._img_icon_layers = {}
  if is_null(self._img_icon_dynamic) then
    return
  end
  local root = self._img_icon_dynamic.transform
  for i = 0, root.childCount - 1 do
    local child = root:GetChild(i)
    if string.find(child.name, ICON_LAYER_NAME_PREFIX, 1, true) == 1 then
      local img = UIUtil.find_image(child, nil)
      if not is_null(img) then
        table.insert(self._img_icon_layers, img)
      end
    end
  end
end

function M:refresh(item_data)
  self._data = item_data.data
  self._index = item_data.index or 0
  self._on_click = item_data.on_click
  self._on_new_cleared = item_data.on_new_cleared
  self:_refresh_lock_state()
  self:_refresh_icon()
  self:_refresh_name()
  self:_refresh_quality()
  self:_refresh_star()
  self:_refresh_unlock_anim()
end

function M:_refresh_lock_state()
  if is_null(self._ui_state_group_lock) then
    return
  end
  local is_unlocked = self._data and self._data.IsUnlocked
  self._ui_state_group_lock:SetState(is_unlocked and lock_state.unlocked_owned or lock_state.locked)
end

function M:_refresh_quality()
  local rank = 0
  if not_null(self._data) and not_null(self._data.ItemCfg) then
    rank = self._data.ItemCfg.rank or 0
  end
  if not_null(self._ui_state_group_quilty) then
    self._ui_state_group_quilty:SetState(rank)
  end
  if not_null(self._ui_state_group_light) then
    local show_light = self._data and self._data.IsUnlocked and rank >= RANK_GOLD
    self._ui_state_group_light:SetState(show_light and light_state.on or light_state.off)
  end
end

function M:_refresh_icon()
  if is_null(self._img_icon_dynamic) or is_null(self._data) then
    return
  end
  local codex_cfg = self._data.CodexCfg
  if is_null(codex_cfg) or not string.is_valid(codex_cfg.seasoncollectionicon) then
    return
  end
  local proxy = self:get_load_proxy()
  if is_null(proxy) then
    return
  end
  local sprite = proxy:LoadSprite(codex_cfg.seasoncollectionicon)
  if is_null(sprite) then
    return
  end
  UIUtil.set_image(self._img_icon_dynamic, sprite)
  self._img_icon_dynamic:SetNativeSize()
  for _, img in ipairs(self._img_icon_layers) do
    UIUtil.set_image(img, sprite)
    img:SetNativeSize()
  end
end

function M:_refresh_name()
  if is_null(self._txt_fish_name) then
    return
  end
  if not self._data or not self._data.IsUnlocked then
    return
  end
  local name = ""
  if not_null(self._data.IdCfg) then
    name = self._data.IdCfg.name or ""
  end
  UIUtil.set_text(self._txt_fish_name, name)
end

function M:_refresh_star()
  if is_null(self._ui_state_group_star) then
    return
  end
  if not (self._data and self._data.IsUnlocked) or self._data.Type ~= CodexDataType.Creature then
    self._ui_state_group_star:SetState(star_state.none)
    return
  end
  if self._data.IsMaxSizeScale then
    self._ui_state_group_star:SetState(star_state.full)
    return
  end
  self._ui_state_group_star:SetState(star_state.not_full)
  self:_fill_stars()
end

function M:_fill_stars()
  if is_null(self._trans_star_list) or is_null(self._trans_item_star) then
    return
  end
  local creature = self._data and self._data.ServerData and self._data.ServerData.Creature
  if is_null(creature) then
    return
  end
  UIUtil.set_active(self._trans_item_star, false)
  local all_count = creature.MaxStars or 0
  for i = 1, all_count do
    if i > #self._item_stars then
      local go = UIUtil.load_prefab_set_parent(self._trans_item_star, self._trans_star_list)
      table.insert(self._item_stars, go)
    end
    UIUtil.set_active(self._item_stars[i], true)
  end
  for i = all_count + 1, #self._item_stars do
    UIUtil.set_active(self._item_stars[i], false)
  end
end

function M:_refresh_red_point()
  if is_null(self._red_point) then
    return
  end
  local rp_type = RedPointType.None
  if self:is_newly_unlocked() then
    rp_type = RedPointType.NewRp
  end
  self._red_point:ShowRedPoint(rp_type)
end

function M:is_newly_unlocked()
  if not self._data or not self._data.IsUnlocked then
    return false
  end
  local id = self._data.IdCfg and self._data.IdCfg.id or 0
  return not red_point_module:is_recorded_with_id(red_point_type_season, id)
end

function M:_refresh_unlock_anim()
  if not self:is_newly_unlocked() then
    codex_anim.play(self._animator_helper_item, codex_anim.item, "locked")
    return
  end
  codex_anim.play(self._animator_helper_item, codex_anim.item, "unlocked", function()
    self:_on_unlock_anim_finished()
  end)
end

function M:_on_unlock_anim_finished()
  local id = self._data and self._data.IdCfg and self._data.IdCfg.id or 0
  if id <= 0 then
    return
  end
  red_point_module:record_with_id(red_point_type_season, id)
  self:_refresh_red_point()
  if self._on_new_cleared then
    self._on_new_cleared()
  end
end

return M
