local M = G.Class("PlayerTitleContainer", G.UIPanel)
local base = G.UIPanel
local default_title_prefab_path = "UI/Title/StarFriendTitleItem"
local default_title_item_cls = "UI/Friend/StarFriendTitleItem"
local independent_title_display_order = 2

function M:init()
  base.init(self)
  self._title_item = nil
  self._host_title_item = nil
  self._title_go = nil
  self._loaded_prefab_path = nil
  self._loading_prefab_path = nil
  self._is_custom_prefab = false
  self._use_host_as_default = false
  self._original_children_hidden = false
  self._load_token = 0
  self._pending_title_list = nil
  self._pending_title = nil
  self._pending_text_color = nil
  self._trans = nil
end

function M:on_create()
  base.on_create(self)
  self._use_host_as_default = not_null(self._txt_title)
end

function M:on_destroy()
  self._load_token = self._load_token + 1
  self._loading_prefab_path = nil
  if self._title_item and self._title_item ~= self._host_title_item then
    self:remove_panel(self._title_item)
  end
  if not_null(self._title_go) then
    UIUtil.destroy_go(self._title_go)
  end
  self._title_item = nil
  self._host_title_item = nil
  self._title_go = nil
  self._loaded_prefab_path = nil
  self._pending_title_list = nil
  self._pending_title = nil
  self._pending_text_color = nil
  base.on_destroy(self)
end

function M:refresh(title_list, title)
  self._pending_title_list = title_list
  self._pending_title = title or ""
  local prefab_path, is_custom = self:_resolve_prefab_path(title_list)
  if self._loading_prefab_path == prefab_path then
    return
  end
  if self._loaded_prefab_path == prefab_path then
    if is_custom then
      if not_null(self._title_go) then
        self:_set_custom_text(self._title_go, self._pending_title)
        return
      end
    elseif self._title_item then
      self._title_item:refresh(title_list, self._pending_title)
      return
    elseif self._use_host_as_default then
      self:_refresh_host_default(title_list, self._pending_title)
      return
    end
  end
  if is_custom then
    self:_show_custom(prefab_path)
    return
  end
  self:_show_default(prefab_path, title_list)
end

function M:_get_parent_trans()
  return self._trans or self.trans
end

function M:_resolve_prefab_path(title_list)
  local title_res_cfg = self:_get_title_res_cfg(title_list)
  local prefab_path = self:_get_cfg_prefab_path(title_res_cfg)
  if string.is_valid(prefab_path) then
    return prefab_path, true
  end
  return default_title_prefab_path, false
end

function M:_get_cfg_prefab_path(title_res_cfg)
  if is_null(title_res_cfg) then
    return nil
  end
  local ok, prefab_path = pcall(function()
    return title_res_cfg.titleprefabpath
  end)
  if ok and string.is_valid(prefab_path) then
    return prefab_path
  end
  return nil
end

function M:_lookup_title_res_cfg(title_id)
  local title_res_cfg = ExcelDataUtil.get_value(typeof(BPlayerTitleResCfg), title_id)
  if not_null(title_res_cfg) then
    return title_res_cfg
  end
  local title_cfg = ExcelDataUtil.get_value(typeof(BPlayerTitleCfg), title_id)
  if not_null(title_cfg) and title_cfg.itemid and title_cfg.itemid ~= 0 then
    return ExcelDataUtil.get_value(typeof(BPlayerTitleResCfg), title_cfg.itemid)
  end
  return nil
end

function M:_get_title_res_cfg(title_list)
  local fallback_res_cfg
  for _, title_id in ipairs(title_list or {}) do
    if title_id and title_id ~= 0 then
      local title_cfg = ExcelDataUtil.get_value(typeof(BPlayerTitleCfg), title_id)
      local res_cfg = self:_lookup_title_res_cfg(title_id)
      if not_null(title_cfg) and title_cfg.displayorder == independent_title_display_order then
        return res_cfg
      end
      if not fallback_res_cfg and string.is_valid(self:_get_cfg_prefab_path(res_cfg)) then
        fallback_res_cfg = res_cfg
      end
    end
  end
  return fallback_res_cfg
end

function M:_show_default(prefab_path, title_list)
  self:_clear_custom()
  self:_set_original_children_active(true)
  self._is_custom_prefab = false
  if self._use_host_as_default then
    self._loaded_prefab_path = prefab_path
    self:_refresh_host_default(title_list, self._pending_title)
    return
  end
  if self._title_item then
    self._loaded_prefab_path = prefab_path
    self._title_item:refresh(title_list, self._pending_title)
    return
  end
  self:_load_prefab(prefab_path, false)
end

function M:_refresh_host_default(title_list, title)
  if not self._host_title_item then
    self._host_title_item = self:add_panel(default_title_item_cls, self.trans)
  end
  self._title_item = self._host_title_item
  self._title_item:refresh(title_list, title)
  self._title_item:set_text_color(self._pending_text_color)
end

function M:_show_custom(prefab_path)
  if self._title_item == self._host_title_item then
    self._title_item = nil
  elseif self._title_item then
    self:remove_panel(self._title_item)
    self._title_item = nil
  end
  self:_clear_custom()
  self:_set_original_children_active(false)
  self._is_custom_prefab = true
  self:_load_prefab(prefab_path, true)
end

function M:_clear_custom()
  if not_null(self._title_go) then
    UIUtil.set_active(self._title_go, false)
    UIUtil.destroy_go(self._title_go)
    self._title_go = nil
  end
  self._load_token = self._load_token + 1
  self._loading_prefab_path = nil
end

function M:_set_original_children_active(active)
  local parent = self:_get_parent_trans()
  if is_null(parent) then
    return
  end
  if active and not self._original_children_hidden then
    return
  end
  for i = 0, parent.childCount - 1 do
    local child = parent:GetChild(i)
    if is_null(self._title_go) or child ~= self._title_go.transform then
      UIUtil.set_active(child, active)
    end
  end
  self._original_children_hidden = not active
end

function M:_load_prefab(prefab_path, is_custom)
  self._load_token = self._load_token + 1
  local token = self._load_token
  self._loading_prefab_path = prefab_path
  local parent = self:_get_parent_trans()
  if is_null(parent) then
    self._loading_prefab_path = nil
    self._loaded_prefab_path = nil
    if is_custom then
      self:_set_original_children_active(true)
    end
    return
  end
  self:get_prefab_load_proxy():LoadPrefabAsync(prefab_path, function(go)
    if token ~= self._load_token then
      if not_null(go) then
        UIUtil.destroy_go(go)
      end
      return
    end
    self._loading_prefab_path = nil
    if is_null(go) then
      self._loaded_prefab_path = nil
      if is_custom then
        self:_show_default(default_title_prefab_path, self._pending_title_list)
      end
      return
    end
    self._loaded_prefab_path = prefab_path
    self._title_go = go
    if is_custom then
      self:_set_custom_text(go, self._pending_title)
    else
      self._title_item = self:add_panel(default_title_item_cls, go.transform)
      self._title_item:refresh(self._pending_title_list, self._pending_title)
      self._title_item:set_text_color(self._pending_text_color)
    end
  end, parent, true)
end

function M:_set_custom_text(go, title)
  if is_null(go) then
    return
  end
  local txt = UIUtil.find_text(go.transform, "txt_title")
  if is_null(txt) then
    UIUtil.set_text(go.transform, title or "")
    UIUtil.set_text_color(go.transform, self._pending_text_color)
    return
  end
  UIUtil.set_text(txt, title or "")
  UIUtil.set_text_color(txt, self._pending_text_color)
end

function M:set_text_color(color)
  self._pending_text_color = color
  if self._title_item then
    self._title_item:set_text_color(color)
    return
  end
  if not_null(self._title_go) then
    self:_set_custom_text(self._title_go, self._pending_title)
  end
end

return M
