local search_engine = require("UI/Codex/Search/CodexSearchEngine")
local M = G.Class("CodexSearchSuggestionPanel", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  self._item_pool = {}
  self._on_select_callback = nil
  self._context = nil
  if not_null(self._trans_item) then
    self._trans_item.gameObject:SetActive(false)
  end
end

function M:set_on_select(callback)
  self._on_select_callback = callback
end

function M:set_context(context)
  self._context = context
end

function M:refresh(keyword, context)
  self._context = context or self._context
  local suggestions = search_engine.suggest(keyword, self._context)
  local count = #suggestions
  for i = 1, count do
    local item_go = self:_get_or_create(i)
    item_go:SetActive(true)
    self:_refresh_item(item_go, suggestions[i], keyword)
  end
  for i = count + 1, #self._item_pool do
    self._item_pool[i]:SetActive(false)
  end
end

function M:_on_item_click(name)
  if self._on_select_callback then
    self._on_select_callback(name)
  end
end

function M:_refresh_item(item_go, suggestion, keyword)
  local txt = item_go:GetComponentInChildren(typeof(CS.TMPro.TextMeshProUGUI))
  if not_null(txt) then
    local display = self:_highlight_text(suggestion.name, keyword)
    txt.text = display
  end
  local btn = item_go:GetComponent(typeof(CS.miHoYo.HYG.UI.ButtonEx))
  if not_null(btn) then
    btn.onClick:RemoveAllListeners()
    btn.onClick:AddListener(function()
      self:_on_item_click(suggestion.name)
    end)
  end
end

function M:_highlight_text(name, keyword)
  if not keyword or keyword == "" then
    return name
  end
  local lower_name = string.lower(name)
  local lower_kw = string.lower(keyword)
  local s, e = string.find(lower_name, lower_kw, 1, true)
  if not s then
    return name
  end
  local before = string.sub(name, 1, s - 1)
  local match = string.sub(name, s, e)
  local after = string.sub(name, e + 1)
  return before .. "<color=#FFD700>" .. match .. "</color>" .. after
end

function M:_get_or_create(index)
  if self._item_pool[index] then
    return self._item_pool[index]
  end
  local go = UIUtil.load_prefab_set_parent(self._trans_item.gameObject, self._trans_list)
  self._item_pool[index] = go
  return go
end

return M
