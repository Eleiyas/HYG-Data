local base_cls = require("UI/BlueprintHabitat/BlueprintSelectPageBase")
local M = G.Class("BlueprintSelectDeletePage", base_cls)
local base = base_cls

function M:_mode_state()
  return new_blueprint_module.SELECT_MODE_STATE.delete
end

function M:_refresh_content_text()
  if is_null(self._txt_content) then
    return
  end
  local used = new_blueprint_module:get_custom_used_count()
  local limit = new_blueprint_module:get_custom_slot_limit()
  UIUtil.set_text(self._txt_content, UIUtil.get_text_by_id("Blueprint_UI_008", used, limit))
end

function M:_confirm_text(data)
  return UIUtil.get_text_by_id("Blueprint_DeleteConfirm", data.Name)
end

function M:_on_item_click(data)
  CsNewBlueprintModuleUtil.DeleteNewBlueprint(data.BpGuid)
end

function M:_on_data_changed(arg)
  if not new_blueprint_module:is_custom_slot_full() then
    self:close_self()
    return
  end
  base._on_data_changed(self, arg)
end

return M
