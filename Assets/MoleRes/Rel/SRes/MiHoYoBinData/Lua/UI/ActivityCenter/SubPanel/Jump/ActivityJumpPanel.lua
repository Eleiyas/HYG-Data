local M = G.Class("ActivityJumpPanel", "UI/ActivityCenter/SubPanel/ActivityBasePanel")
local base = G.ActivityBasePanel
local jump_item_cls = "UI/ActivityCenter/SubPanel/Jump/ActivityCenterJumpItem"

function M:init()
  base.init(self)
  self._reward_items = self._reward_items or {}
  self._jump_items = self._jump_items or {}
end

function M:update(deltaTime)
  base.update(self, deltaTime)
end

function M:refresh()
  base.refresh(self)
  self:_refresh_rewards()
  self:_refresh_jump_buttons()
  self:_refresh_unlock_text()
  self:_refresh_dynamic_bg(self._img_bg)
end

function M:_refresh_rewards()
  if is_null(self._layout_items_binder) then
    return
  end
  local reward_list = self:_get_reward_list() or {}
  if #reward_list == 0 then
    UIUtil.set_active(self._scroll_reward, false)
    UIUtil.set_active(self._trans_reward_title, false)
    return
  end
  UIUtil.set_active(self._scroll_reward, true)
  UIUtil.set_active(self._trans_reward_title, true)
  for i = 1, #reward_list do
    local entry = reward_list[i]
    local cls = self._reward_items[i]
    if cls == nil then
      local obj = self._layout_items_binder:AddItem(0)
      if not_null(obj) then
        cls = self:add_panel(item_module.item_v2_panel_cls_name, obj)
        self._reward_items[i] = cls
        UIUtil.set_active(obj, true)
      end
    end
    cls:set_item_data(entry.item_id, entry.count)
    cls:bind_item_info_btn(entry.item_id)
    cls:set_active(true)
  end
  for i = #reward_list + 1, #self._reward_items do
    self._reward_items[i]:set_active(false)
  end
end

function M:_get_reward_list()
  local list = {}
  local ui_cfg = activity_center_module:get_ui_cfg(self._activity_id)
  if ui_cfg == nil then
    return list
  end
  local raw = ui_cfg.rewardlist
  if not string.is_valid(raw) then
    return list
  end
  for entry in string.gmatch(raw, "([^;]+)") do
    local s = string.gsub(entry, "%s+", "")
    if s ~= "" then
      local id_str, count_str = string.match(s, "^([%-%d]+),([%-%d]+)$")
      local item_id = tonumber(id_str)
      local count = tonumber(count_str)
      if item_id and count then
        table.insert(list, {item_id = item_id, count = count})
      else
        Logger.LogWarning(string.format("[ActivityJumpPanel] activity=%s rewardlist invalid entry: '%s'", tostring(self._activity_id), tostring(entry)))
      end
    end
  end
  return list
end

function M:_refresh_jump_buttons()
  if is_null(self._layout_btn_binder) then
    return
  end
  local ui_cfg = activity_center_module:get_ui_cfg(self._activity_id)
  local jump_count = ui_cfg ~= nil and ui_cfg.jumptolistLength or 0
  local btn_names = lua_str_split(ui_cfg.jumptobuttonname, ",")
  local state = activity_center_module:get_activity_state(self._activity_id)
  local is_unlock = state ~= activity_center_module.activity_state.Opened and state ~= activity_center_module.activity_state.None
  for i = 1, jump_count do
    local jump_id = ui_cfg:jumptolist(i - 1)
    local jump_btn_name = btn_names[i]
    local cls = self._jump_items[i]
    if cls == nil then
      local obj = self._layout_btn_binder:AddItem(0)
      if not_null(obj) then
        cls = self:add_panel(jump_item_cls, obj)
        self._jump_items[i] = cls
        UIUtil.set_active(obj, true)
      end
    end
    cls:refresh(jump_id, jump_btn_name)
    cls:set_active(true)
    cls:set_btn_enable(is_unlock)
  end
  for i = jump_count + 1, #self._jump_items do
    local cls = self._jump_items[i]
    if cls ~= nil then
      cls:set_active(false)
    end
  end
end

function M:_refresh_unlock_text()
  if is_null(self._text_lock) then
    return
  end
  UIUtil.set_text(self._text_lock, "")
  local data = self:get_activity_data()
  if data == nil or data.State ~= activity_center_module.activity_state.Opened then
    UIUtil.set_active(self._trans_lock, false)
    return
  end
  UIUtil.set_active(self._trans_lock, true)
  local ui_cfg = activity_center_module:get_ui_cfg(self._activity_id)
  if ui_cfg and string.is_valid(ui_cfg.activitystarttips) then
    UIUtil.set_text(self._text_lock, ui_cfg.activitystarttips)
  end
end

return M
