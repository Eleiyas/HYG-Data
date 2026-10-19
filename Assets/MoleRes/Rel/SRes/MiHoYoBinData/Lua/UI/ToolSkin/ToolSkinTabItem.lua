local M = G.Class("ToolSkinTabItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._tool_cfg_id = 0
end

function M:on_create()
  base.on_create(self)
end

function M:refresh(tool_cfg_id)
  if tool_cfg_id == 0 then
    self:set_active(false)
    return
  end
  self._tool_cfg_id = tool_cfg_id
  self:set_active(true)
  local effective_skin = CsToolSkinModuleUtil.GetEffectiveSkinId(tool_cfg_id)
  if effective_skin ~= 0 then
    self:refresh_icon(effective_skin)
  else
    self:refresh_icon(nil)
  end
end

function M:get_tog()
  return self._tog
end

function M:get_tool_cfg_id()
  return self._tool_cfg_id
end

function M:refresh_icon(skin_id)
  local cfg_id = skin_id or self._tool_cfg_id
  local cfg = item_module:get_cfg_by_id(cfg_id)
  if not is_null(cfg) then
    UIUtil.set_image(self._img_select_icon, cfg.icon, self:get_load_proxy())
    UIUtil.set_image(self._img_unselect_icon, cfg.icon, self:get_load_proxy())
  end
end

return M
