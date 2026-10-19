local base_cls = require("UI/BlueprintHabitat/BlueprintSelectPageBase")
local M = G.Class("BlueprintSelectReplacePage", base_cls)
local base = base_cls

function M:_mode_state()
  return new_blueprint_module.SELECT_MODE_STATE.delete
end

function M:_get_list_source()
  return new_blueprint_module:get_copied_sorted_list()
end

function M:_refresh_content_text()
  UIUtil.set_text(self._txt_content, UIUtil.get_text_by_id("Blueprint_UI_019", new_blueprint_module:get_copied_used_count(), new_blueprint_module:get_copied_slot_limit()))
end

function M:_confirm_text(data)
  return UIUtil.get_text_by_id("Blueprint_ReplaceConfirm", data.Name)
end

function M:_on_item_click(data)
  new_blueprint_module:copy_shared_blueprint(data.BpGuid)
  self:close_self()
end

return M
