local search_engine = require("UI/Codex/Search/CodexSearchEngine")
local M = G.Class("CodexSearchHistoryPanel", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  self._item_pool = {}
  self._on_select_callback = nil
  if not_null(self._trans_history_item) then
    self._trans_history_item.gameObject:SetActive(false)
  end
  if not_null(self._btn_clear_history) then
    self:bind_callback(self._btn_clear_history, pack(self, M._on_clear_all))
  end
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:set_on_select(callback)
  self._on_select_callback = callback
end

function M:add_record(keyword)
  search_engine.add_search_history(keyword)
end

function M:refresh()
  local history = search_engine.get_search_history()
  local count = #history
  for i = 1, count do
    local item = self:_get_or_create(i)
    item.gameObject:SetActive(true)
    self:_refresh_item(item, history[i])
  end
  for i = count + 1, #self._item_pool do
    self._item_pool[i].gameObject:SetActive(false)
  end
  if not_null(self._btn_clear_history) then
    UIUtil.set_active(self._btn_clear_history, 0 < count)
  end
end

function M:has_records()
  return #search_engine.get_search_history() > 0
end

function M:_on_clear_all()
  search_engine.clear_search_history()
  self:refresh()
end

function M:_on_item_click(keyword)
  if self._on_select_callback then
    self._on_select_callback(keyword)
  end
end

function M:_refresh_item(item_go, keyword)
  local txt = item_go:GetComponentInChildren(typeof(CS.TMPro.TextMeshProUGUI))
  if not_null(txt) then
    txt.text = keyword
  end
  local btn = item_go:GetComponent(typeof(CS.miHoYo.HYG.UI.ButtonEx))
  if not_null(btn) then
    btn.onClick:RemoveAllListeners()
    btn.onClick:AddListener(function()
      self:_on_item_click(keyword)
    end)
  end
end

function M:_get_or_create(index)
  if self._item_pool[index] then
    return self._item_pool[index]
  end
  local go = UIUtil.load_prefab_set_parent(self._trans_history_item.gameObject, self._trans_history_list)
  self._item_pool[index] = go
  return go
end

return M
