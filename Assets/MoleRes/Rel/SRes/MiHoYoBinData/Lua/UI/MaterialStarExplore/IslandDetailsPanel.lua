local M = G.Class("IslandDetailsPanel", G.UIWindow)
local base = G.UIWindow
local item_v2_cls = item_module.item_v2_panel_cls_name

local function _split_id_str(raw)
  local ids = {}
  if not string.is_valid(raw) then
    return ids
  end
  for id_text in string.gmatch(raw, "[^,]+") do
    local trim_text = string.gsub(id_text, "^%s*(.-)%s*$", "%1")
    local item_id = tonumber(trim_text)
    if item_id and 0 < item_id then
      table.insert(ids, item_id)
    end
  end
  return ids
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MaterialStarExplore/IslandDetailsPanel"
  self.config.type = EUIType.Page
end

function M:on_create()
  base.on_create(self)
  self._biology_item_entries = {}
  self._specialty_item_entries = {}
  UIUtil.set_active(self._obj_item_biology, false)
  UIUtil.set_active(self._obj_item_specialty, false)
end

function M:on_open()
  base.on_open(self)
  self:_refresh_view(self:get_extra_data())
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  self:bind_callback(self._btn_goto_island, pack(self, M._on_btn_goto_island_click))
end

function M:_refresh_view(data)
  self._data = data or {}
  local island_id = self._data.islandId or 0
  local cfg = 0 < island_id and ExcelDataUtil.get_value(typeof(BStellarSeaStarCfg), island_id) or nil
  local islandshotcut = cfg and cfg.islandshotcut or nil
  if not is_null(islandshotcut) then
    UIUtil.set_image(self._img_island_shotcut, islandshotcut, self:get_load_proxy())
  end
  if cfg ~= nil and cfg.displaybiologyicon ~= nil then
    local biology_ids = _split_id_str(cfg.displaybiologyicon)
    self:_refresh_item_group(biology_ids, self._obj_item_biology, self._biology_item_entries)
  else
    self:_hide_item_group(self._biology_item_entries)
  end
  if cfg ~= nil and cfg.displayspecialtyicon ~= nil then
    local specialty_ids = _split_id_str(cfg.displayspecialtyicon)
    self:_refresh_item_group(specialty_ids, self._obj_item_specialty, self._specialty_item_entries)
  else
    self:_hide_item_group(self._specialty_item_entries)
  end
  UIUtil.set_text(self._txt_island_name, cfg and cfg.name or "")
  local cur_collection = self._data.curCollection or 0
  local total_collection = self._data.totalCollection or 0
  UIUtil.set_text(self._txt_star_num, tostring(cur_collection) .. "/" .. tostring(total_collection))
  local id_cfg = ExcelDataUtil.get_value(typeof(BIdCfg), 10504)
  UIUtil.set_text(self._txt_star_name, id_cfg and id_cfg.name or "")
  UIUtil.set_text_by_id(self._txt_biology, "UI_StarSea_Creature")
  UIUtil.set_text_by_id(self._txt_specialty, "UI_StarSea_Product")
  UIUtil.set_text_by_id(self._txt_goto_island, "UI_StarSea_IsletLanding")
  if back_bag_module:get_item_num(30200) == 0 then
    UIUtil.set_text_color(self._txt_batterynum, "#ea7354")
  else
    UIUtil.set_text_color(self._txt_batterynum, "#5a4632")
  end
end

function M:_refresh_item_group(id_list, template_obj, item_entries)
  if is_null(template_obj) then
    return
  end
  local item_info_map = {}
  for _, item_id in ipairs(id_list) do
    local item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), item_id)
    item_info_map[item_id] = {
      cfg = item_cfg,
      rank = item_cfg and item_cfg.rank or 0,
      unlock = CsCodexModuleUtil.IsCodexUnlock(item_id)
    }
  end
  table.sort(id_list, function(a, b)
    local a_info = item_info_map[a]
    local b_info = item_info_map[b]
    local a_unlock = a_info and a_info.unlock or false
    local b_unlock = b_info and b_info.unlock or false
    if a_unlock ~= b_unlock then
      return a_unlock
    end
    local a_rank = a_info and a_info.rank or 0
    local b_rank = b_info and b_info.rank or 0
    if a_rank ~= b_rank then
      return a_rank > b_rank
    end
    return a < b
  end)
  local parent = template_obj.transform.parent
  for i, item_id in ipairs(id_list) do
    local entry = item_entries[i]
    if entry == nil then
      local obj = GameObject.Instantiate(template_obj, parent)
      entry = {
        obj = obj,
        panel = self:add_panel(item_v2_cls, obj)
      }
      item_entries[i] = entry
    end
    local item_info = item_info_map[item_id]
    local item_cfg = item_info and item_info.cfg or nil
    if item_cfg ~= nil then
      local is_codex_unlock = item_info and item_info.unlock or false
      UIUtil.set_active(entry.obj, true)
      entry.panel:set_item_data(item_id, 1, nil)
      entry.panel:bind_item_info_btn(item_id)
      if not is_null(entry.panel._ui_state_group_lock) then
        entry.panel._ui_state_group_lock:SetState(is_codex_unlock and 1 or 0)
      end
    else
      UIUtil.set_active(entry.obj, false)
    end
  end
  for i = #id_list + 1, #item_entries do
    UIUtil.set_active(item_entries[i].obj, false)
  end
end

function M:_hide_item_group(item_entries)
  for i = 1, #item_entries do
    UIUtil.set_active(item_entries[i].obj, false)
  end
end

function M:_on_btn_close_click()
  UIManagerInstance:close(self.guid)
end

function M:_on_btn_goto_island_click()
  local island_guid = self._data and self._data.guid or 0
  if 0 < island_guid then
    GameplayUtilities_StarSea.GoIslandByInteraction(island_guid)
  end
end

return M
