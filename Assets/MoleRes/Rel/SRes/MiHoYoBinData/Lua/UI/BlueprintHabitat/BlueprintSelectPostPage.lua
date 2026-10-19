local base_cls = require("UI/BlueprintHabitat/BlueprintSelectPageBase")
local M = G.Class("BlueprintSelectPostPage", base_cls)

function M:_mode_state()
  return new_blueprint_module.SELECT_MODE_STATE.post
end

function M:_on_item_click(data)
  local ctx = new_blueprint_module:try_make_little_corner_post_ctx(data)
  if ctx == nil then
    return
  end
  if little_corner_module:post_blueprint_in_corner(ctx) then
    self:close_self()
  end
end

return M
