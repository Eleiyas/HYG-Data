local M = G.Class("CommonGroupedFilterGroupItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._scroller = nil
  self._node_index = nil
  self._is_refreshing = false
end

function M:on_create()
  base.on_create(self)
  if not_null(self._tog_fold) then
    self:bind_callback(self._tog_fold, pack(self, M._on_fold_changed))
  end
end

function M:refresh(data)
  data = data or {}
  self._scroller = data.scroller
  self._node_index = data.node_index
  if string.is_valid(data.title_text_id) then
    UIUtil.set_text_by_id(self._txt_title_root, data.title_text_id)
  else
    UIUtil.set_text(self._txt_title_root, data.title or "")
  end
  self:_refresh_fold(data.is_expanded == true)
  self:set_active(true)
end

function M:_refresh_fold(is_expanded)
  if is_null(self._tog_fold) then
    return
  end
  self._is_refreshing = true
  self._tog_fold.isOn = not is_expanded
  self._is_refreshing = false
end

function M:_on_fold_changed()
  if self._is_refreshing then
    return
  end
  if is_null(self._scroller) or self._node_index == nil or is_null(self._tog_fold) then
    return
  end
  if self._tog_fold.isOn then
    self._scroller:CollapseNode(self._node_index, 0)
  else
    self._scroller:ExpandNode(self._node_index, 0)
  end
end

return M
