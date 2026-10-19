local M = G.Class("HabitatInfoTipItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._cfg_id = 0
  self._need_count = 0
end

function M:on_create()
  base.on_create(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:refresh(cfg_id, need_count)
  self._cfg_id = cfg_id or 0
  self._need_count = need_count or 0
  if self._cfg_id <= 0 then
    self:set_active(false)
    return
  end
  local cfg = item_module:get_cfg_by_id(self._cfg_id)
  if cfg == nil then
    self:set_active(false)
    return
  end
  UIUtil.set_text(self._txt_name, cfg.name or "")
  if string.is_valid(cfg.icon) then
    UIUtil.set_image(self._img_icon, cfg.icon, self:get_load_proxy())
  end
  UIUtil.set_text(self._txt_num, "x" .. tostring(self._need_count))
  if not_null(self._state_group_rank) then
    self._state_group_rank:SetState(cfg.rank)
  end
end

function M:_format_num_text(owned, need)
  local owned_str = tostring(owned)
  if owned < need then
    owned_str = "<color=#EA7354>" .. owned_str .. "</color>"
  end
  return owned_str .. "/" .. tostring(need)
end

return M
