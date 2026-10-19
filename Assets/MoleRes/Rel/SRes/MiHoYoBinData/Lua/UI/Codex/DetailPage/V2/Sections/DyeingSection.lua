local base_path = "UI/Codex/DetailPage/V2/DetailSectionBase"
local M = G.Class("DyeingSection", base_path)

function M:should_show(item_data)
  if item_data.Type ~= CodexDataType.Furniture then
    return false
  end
  if codex_module:is_package_sub_type(item_data.SubType) then
    return false
  end
  local dye_cfg = ExcelDataUtil.get_value(typeof(BDyeableFurnCfg), item_data.IdCfg.id)
  return dye_cfg and dye_cfg.canbedyed == 1
end

return M
