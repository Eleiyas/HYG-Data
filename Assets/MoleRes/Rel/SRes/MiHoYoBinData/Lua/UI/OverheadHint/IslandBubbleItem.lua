local M = G.Class("IslandBubbleItem", G.UIBase)
local base = G.UIBase

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

local function _is_all_codex_unlock(raw)
  local ids = _split_id_str(raw)
  for _, item_id in ipairs(ids) do
    if not CsCodexModuleUtil.IsCodexUnlock(item_id) then
      return false
    end
  end
  return true
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:set_data(data)
  data = data or {}
  local island_id = data.islandId or 0
  local cfg = 0 < island_id and ExcelDataUtil.get_value(typeof(BStellarSeaStarCfg), island_id) or nil
  local islandshotcut = cfg and cfg.islandshotcut or nil
  if not is_null(self._img_island_shotcut) and not is_null(islandshotcut) then
    UIUtil.set_image(self._img_island_shotcut, islandshotcut, self:get_load_proxy())
  end
  local icon_cfg = cfg and cfg.radartrackingtypeid and 0 < cfg.radartrackingtypeid and ExcelDataUtil.get_value(typeof(BStarIslandIconCfg), cfg.radartrackingtypeid) or nil
  if not is_null(self._img_icon) and icon_cfg and not_null(icon_cfg.icon) then
    UIUtil.set_image(self._img_icon, icon_cfg.icon, self:get_load_proxy())
  end
  if not is_null(self._txt_island_name) then
    UIUtil.set_text(self._txt_island_name, cfg and cfg.name or "")
  end
  if not is_null(self._ui_state_group) then
    local cur_collection = data.curCollection or 0
    local total_collection = data.totalCollection or 0
    local all_unlock = cfg ~= nil and _is_all_codex_unlock(cfg.displaybiologyicon) and _is_all_codex_unlock(cfg.displayspecialtyicon) and 0 < total_collection and cur_collection >= total_collection
    self._ui_state_group:SetState(all_unlock and 1 or 0)
  end
end

function M:get_trans()
  return self._trans_bubbles or self.trans
end

return M
