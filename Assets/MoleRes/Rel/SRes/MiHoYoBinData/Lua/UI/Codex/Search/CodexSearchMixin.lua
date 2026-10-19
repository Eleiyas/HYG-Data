local search_panel_class = "UI/Codex/Search/CodexSearchPanel"
local Mixin = {}

function Mixin.ensure_search_panel(host, context_provider)
  if host._search_panel then
    if context_provider and host._search_panel.set_context_provider then
      host._search_panel:set_context_provider(context_provider)
    end
    return true
  end
  local search_root = host._trans_search_group
  if is_null(search_root) then
    return false
  end
  host._search_panel_root = search_root
  host._search_panel = host:add_panel(search_panel_class, search_root.gameObject)
  host._search_panel:set_callbacks(nil, function()
    Mixin.close_search_panel(host)
  end)
  if context_provider and host._search_panel.set_context_provider then
    host._search_panel:set_context_provider(context_provider)
  end
  return true
end

function Mixin.close_search_panel(host, silent)
  if host._search_panel then
    if silent and host._search_panel.collapse then
      host._search_panel:collapse()
    elseif not silent then
      host._search_panel:reset_state()
    end
  end
end

function Mixin.is_search_field_open(host)
  return host._search_panel and host._search_panel.is_search_field_open and host._search_panel:is_search_field_open()
end

return Mixin
