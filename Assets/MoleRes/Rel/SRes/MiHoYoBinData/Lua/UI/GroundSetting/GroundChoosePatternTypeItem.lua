local M = G.Class("GroundChoosePatternTypeItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._set_id = 0
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._tog_click) then
    self:bind_callback(self._tog_click, pack(self, M._on_tog_click))
  end
end

function M:_on_tog_click(is_on)
  if not is_on or self._set_id <= 0 then
    return
  end
  if self.holder and self.holder.on_select_pattern_set then
    self.holder:on_select_pattern_set(self._set_id)
  end
end

function M:refresh(index, set_cfg)
  self._index = index
  if not set_cfg then
    self._set_id = 0
    return
  end
  self._set_id = set_cfg.decalsetid
  UIUtil.set_text(self._txt_name, set_cfg.name)
  self._tog_click:SetIsOnWithoutNotify(self._set_id == (self.holder._cur_pattern_set_id or 0))
end

return M
