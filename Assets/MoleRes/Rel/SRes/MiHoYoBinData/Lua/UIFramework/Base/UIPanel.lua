local M = G.Class("UIPanel", G.UIBase)
local base = G.UIBase
local ButtonType = typeof(Button)
local ButtonExType = typeof(ButtonEx)
local InvokeType = {Func = 1, Button = 2}

function M:__ctor()
  self.config = {prefab_path = "", input_penetrate = true}
  self.container = {}
  self.input_actions = {}
  self.input_action_functions = {}
  self.input_action_bind_btns = {}
  self._prefab_load_proxy = nil
  self._asset_load_proxy = nil
end

function M:add_panel(content, trans, extra_data)
  local target = content
  if string.is_valid(content) then
    target = G.New(content)
    target:init()
  end
  target.holder = self
  target:set_gameobject(trans.gameObject)
  target.is_active = false
  target:set_extra_data(extra_data)
  target:on_create()
  if target.game_obj.activeSelf ~= target.is_active then
    target:set_active(target.game_obj.activeSelf)
  end
  table.insert(self.container, target)
  self._input_actions_dirty = true
  return target
end

function M:add_panel_async(content, extra_data, callback, parent)
  local target = content
  if string.is_valid(content) then
    target = G.New(content)
    target:init()
  end
  if string.is_valid(target.config.prefab_path) then
    local prefab_load_proxy = target:get_prefab_load_proxy()
    prefab_load_proxy:LoadPrefabAsync(target.config.prefab_path, function(gameObject)
      if not is_null(gameObject) then
        local panel = self:add_panel(target, gameObject, extra_data, 0)
        if callback then
          callback(panel)
        end
      end
    end, parent, false)
  else
    Logger.LogError("无效的prefab路径")
  end
end

function M:remove_panel(instance)
  assert(instance)
  instance:Delete()
  table.removewhere(self.container, function(t)
    return t == instance
  end)
  self._input_actions_dirty = true
end

function M:on_create()
  base.on_create(self)
  self:check_adaptive()
  self:bind_input_action()
end

function M:on_enable()
  base.on_enable(self)
  for _, panel in pairs(self.container) do
    if panel.is_active then
      panel:on_enable()
    end
  end
end

function M:on_disable()
  base.on_disable(self)
  for _, panel in pairs(self.container) do
    if panel.is_active then
      panel:on_disable()
    end
  end
end

function M:on_destroy()
  base.on_destroy(self)
  for _, panel in pairs(self.container) do
    panel:on_destroy()
  end
  if not is_null(self._prefab_load_proxy) then
    ResourcesUtil.DeallocatePrefabLoadProxy(self._prefab_load_proxy)
  end
  if not is_null(self._asset_load_proxy) then
    ResourcesUtil.DeallocateAssetLoadProxy(self._asset_load_proxy)
  end
end

function M:_clear()
  base._clear(self)
  for _, panel in pairs(self.container) do
    panel:_clear()
  end
  self.container = {}
end

function M:bind_input_action()
end

function M:bind_input_and_fun(action_type, func, ...)
  if action_type then
    local actions
    if type(action_type) ~= "table" then
      actions = {}
      table.insert(actions, action_type)
    else
      actions = action_type
    end
    for _, type in ipairs(actions) do
      local list = {
        ...
      }
      if #list == 0 then
        self:_add_input_action(type, func, nil, InvokeType.Func)
      else
        for _, val in pairs(list) do
          self:_add_input_action(type, func, val, InvokeType.Func)
        end
      end
    end
  end
end

function M:bind_input_and_btn(action_type, btn, ...)
  if action_type and btn then
    local actions
    if type(action_type) ~= "table" then
      actions = {}
      table.insert(actions, action_type)
    else
      actions = action_type
    end
    local type = btn:GetType()
    if type == ButtonExType or type == ButtonType then
      local btn_invoke_data = {
        obj = btn.gameObject,
        button = btn
      }
      for _, type in ipairs(actions) do
        local list = {
          ...
        }
        if #list == 0 then
          self:_add_input_action(type, btn_invoke_data, ActionType.EType.ButtonPressed, InvokeType.Button)
        else
          for _, val in pairs(list) do
            self:_add_input_action(type, btn_invoke_data, val, InvokeType.Button)
          end
        end
      end
    else
      Logger.LogError("绑定的按钮类型错误，请检查")
    end
  end
end

function M:_add_input_action(action_type, func_or_btn, event_type, invoke_type)
  if action_type then
    local input_action = G.New(InputAction)
    input_action:init(action_type, event_type)
    self.input_actions[input_action.id] = input_action
    if invoke_type == InvokeType.Button then
      if self.input_action_functions[input_action.id] ~= nil then
        self.input_action_functions[input_action.id] = nil
      end
      self.input_action_bind_btns[input_action.id] = func_or_btn
    elseif invoke_type == InvokeType.Func then
      if self.input_action_bind_btns[input_action.id] ~= nil then
        self.input_action_bind_btns[input_action.id] = nil
      end
      self.input_action_functions[input_action.id] = func_or_btn
    end
  end
end

function M:handle_input_action(action)
  if action and not action.handled then
    self:_inter_handle_input_action(action)
  end
end

function M:_inter_handle_input_action(action)
  if self.input_action_functions and self.input_action_bind_btns[action.id] and self.input_action_bind_btns[action.id].obj.activeInHierarchy then
    action.handled = true
    self.input_action_bind_btns[action.id].button.onClick:Invoke()
  end
  if self.input_action_functions and self.input_action_functions[action.id] then
    action.handled = true
    self.input_action_functions[action.id](self, action)
  end
end

function M:update(deltaTime)
  if self.is_active == false then
    return
  end
  if base.update then
    base.update(self, deltaTime)
  end
  for _, panel in pairs(self.container) do
    if panel.is_active and panel.update then
      panel:update(deltaTime)
    end
  end
end

function M:late_update(deltaTime)
  if self.is_active == false then
    return
  end
  if base.late_update then
    base.late_update(self, deltaTime)
  end
  for _, panel in pairs(self.container) do
    if panel.is_active and panel.late_update then
      panel:late_update(deltaTime)
    end
  end
end

function M:on_animation_event(key_tag)
  base.on_animation_event(self, key_tag)
end

function M:enter_anim_call_back()
  base.enter_anim_call_back(self)
end

function M:exit_anim_call_back()
  base.exit_anim_call_back(self)
end

function M:check_adaptive()
  local layout_version = UIManagerInstance:get_layout_version()
  UIAdaptiveUtils.ApplyFix(self.trans, layout_version, self.config.prefab_path)
  for _, panel in pairs(self.container) do
    if panel.check_adaptive then
      panel:check_adaptive()
    end
  end
end

function M:is_panel_showing(class_name)
  for _, panel in pairs(self.container) do
    if panel:is_showing() and panel.__cname == class_name then
      return panel
    end
  end
  return nil
end

function M:is_panel_showing_by_hash(class_name_hash)
  for _, panel in pairs(self.container) do
    if panel:is_showing() and panel.cname_hash == class_name_hash then
      return panel
    end
  end
  return nil
end

function M:is_showing()
  return self.is_active
end

function M:get_load_proxy()
  if self._asset_load_proxy == nil then
    self._asset_load_proxy = ResourcesUtil.AllocateAssetLoadProxy()
  end
  return self._asset_load_proxy
end

function M:get_prefab_load_proxy()
  if self._prefab_load_proxy == nil then
    self._prefab_load_proxy = ResourcesUtil.AllocatePrefabLoadProxy()
  end
  return self._prefab_load_proxy
end

return M
