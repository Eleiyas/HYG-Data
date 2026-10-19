new_blueprint_module = new_blueprint_module or {}
local _official_sorted_cache

function new_blueprint_module:get_all_official_cfg()
  return ExcelDataUtil.get_table(typeof(BNewBlueprintCfg)) or {}
end

function new_blueprint_module:get_official_cfg(blueprint_id)
  return ExcelDataUtil.get_value(typeof(BNewBlueprintCfg), blueprint_id)
end

function new_blueprint_module:get_official_sorted_list()
  if _official_sorted_cache then
    return _official_sorted_cache
  end
  local list = {}
  local all_cfg = self:get_all_official_cfg()
  for _, cfg in pairs(all_cfg) do
    table.insert(list, cfg)
  end
  table.sort(list, function(a, b)
    return (a.sortid or 0) < (b.sortid or 0)
  end)
  _official_sorted_cache = list
  return list
end

function new_blueprint_module:get_discovered_sorted_list()
  local all = self:get_official_sorted_list()
  local list = {}
  for i = 1, #all do
    local cfg = all[i]
    if self:is_blueprint_unlocked(cfg.id) then
      list[#list + 1] = cfg
    end
  end
  return list
end

local _preview_param_define = {
  model_width_ratio = {
    key = "PREVIEW_MODEL_WIDTH_RATIO",
    default = 0.6,
    min = 0,
    max = 1
  },
  fill_ratio = {
    key = "PREVIEW_FILL_RATIO",
    default = 1,
    min = 0,
    max = 1
  },
  assumed_height_cells = {
    key = "PREVIEW_ASSUMED_HEIGHT_CELLS",
    default = 4,
    min = 0
  },
  base_yaw = {
    key = "PREVIEW_BASE_YAW",
    default = 180
  }
}
local _preview_value_cache
local _preview_warned_keys = {}

local function _build_preview_value_cache()
  local map = {}
  for _, cfg in pairs(ExcelDataUtil.get_table(typeof(BNewBlueprintPreviewCfg)) or {}) do
    local param = cfg.param and string.match(cfg.param, "^%s*(.-)%s*$")
    if param and param ~= "" then
      map[param] = cfg.value
    end
  end
  return map
end

local function _get_preview_value(define)
  if not _preview_value_cache then
    _preview_value_cache = _build_preview_value_cache()
  end
  local value = _preview_value_cache[define.key]
  local is_valid = value ~= nil and (define.min == nil or value > define.min) and (define.max == nil or value <= define.max)
  if is_valid then
    return value
  end
  if not _preview_warned_keys[define.key] then
    _preview_warned_keys[define.key] = true
    Logger.LogError("NewBlueprintPreviewCfg 参数缺失或越界: " .. define.key .. ", 读到 " .. tostring(value) .. ", 回退默认值 " .. tostring(define.default))
  end
  return define.default
end

function new_blueprint_module:get_preview_model_width_ratio()
  return _get_preview_value(_preview_param_define.model_width_ratio)
end

function new_blueprint_module:get_preview_fill_ratio()
  return _get_preview_value(_preview_param_define.fill_ratio)
end

function new_blueprint_module:get_preview_assumed_height_cells()
  return _get_preview_value(_preview_param_define.assumed_height_cells)
end

function new_blueprint_module:get_preview_base_yaw()
  return _get_preview_value(_preview_param_define.base_yaw)
end

return new_blueprint_module
