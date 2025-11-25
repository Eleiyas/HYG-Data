local M = G.Class("UIManager")
local UISceneLayerConfig = require("Gen/UISceneLayerConfig")
local main_page_cls = "UI/MainPage/MainPage"

function M:__ctor()
  self._ui_root_prefab_path = "Launch/UI/UI"
  self._ui_root = nil
  self.canvas = nil
  self.canvas_rect = nil
  self.ui_camera = nil
  self._layers = {
    [EUIType.Scene] = {
      path = "Canvas/SceneLayer",
      trans = nil,
      order_trans = {}
    },
    [EUIType.BackgroundBoard] = {
      path = "Canvas/BackgroundBoardLayer",
      trans = nil,
      order_trans = {}
    },
    [EUIType.Page] = {
      path = "Canvas/PageLayer",
      trans = nil,
      order_trans = {}
    },
    [EUIType.Dialog] = {
      path = "Canvas/DialogLayer",
      trans = nil,
      order_trans = {}
    },
    [EUIType.Info] = {
      path = "Canvas/InfoLayer",
      trans = nil,
      order_trans = {}
    },
    [EUIType.Tip] = {
      path = "Canvas/TipLayer",
      trans = nil,
      order_trans = {}
    },
    [EUIType.Top] = {
      path = "Canvas/TopLayer",
      trans = nil,
      order_trans = {}
    }
  }
  self._is_init = false
  self._window_stack = {}
  self._window_not_in_stack = {}
  self._window_input_action_stack = {}
  self:_init_window_input_action_stack()
  self._singleton_windows = {}
  self._windows = {}
  self._cur_show_widows = {}
  self._loading_windows = {}
  self._opening_windows = {}
  self._closing_windows = {}
  self._canvas_sizes = {
    [LayoutVersion.Mobile] = {width = 1920, height = 1080},
    [LayoutVersion.PC] = {width = 2208, height = 1242},
    [LayoutVersion.PS] = {width = 2208, height = 1242}
  }
  self._layout_version = nil
  self._lua_events = nil
  self._ui_lock_countdown = 0
  self.main_page_guid = 0
  self:_add_lua_listener()
end

function M:init_ui(callback)
  local go_name = "UIRoot"
  local go, handle
  go = GameObject.Find(go_name)
  if is_null(go) then
    go, handle = CsUIUtil.LoadPrefab(self._ui_root_prefab_path, nil, 0)
    go.name = go_name
    GameObject.DontDestroyOnLoad(go)
  end
  self._ui_root = go.transform
  self.canvas = UIUtil.find_cmpt(self._ui_root, "Canvas", typeof(MonoBaseCanvas))
  self.canvas_rect = UIUtil.find_rect_trans(self._ui_root, "Canvas")
  self.ui_camera = UIUtil.find_cmpt(self._ui_root, "UICamera", typeof(Camera))
  for _, v in pairs(self._layers) do
    v.trans = UIUtil.find_trans(self._ui_root, v.path)
  end
  self._init_bg_mask = UIUtil.find_image(self._layers[EUIType.Scene].trans, "InitBGMask/img")
  self._ui_scene_root = UIUtil.find_trans(self._ui_root, "UISceneRoot")
  self:init_default_layout_version()
  CsUIUtil.uiCanvas = self:get_canvas()
  self._is_init = true
  Logger.Log("UIManager InitUI: 初始化成功")
  self._mask_info = self:pre_open("UI/Item/MaskInfo")
  self._mask_texture_min_holder = 0
  if callback then
    callback()
  end
end

function M:pre_open(class_name, extra_data, guid)
  if not self:_safe_check(class_name) then
    return
  end
  local target = self:_create_window_if_need(class_name, extra_data, guid)
  self:_prepare_window(target)
  self:_set_window_active(target, false)
  return target
end

function M:set_touch_lock(is_lock, mask_type)
  if self._mask_info == nil then
    return
  end
  if not self._windows[self._mask_info.guid] then
    self._mask_info = self:pre_open("UI/Item/MaskInfo")
  end
  if is_lock then
    self._mask_info:set_extra_data(mask_type)
    self._mask_info:change_state(EUIState.Show)
  else
    self._mask_info:change_state(EUIState.Hide)
  end
end

function M:set_mask_texture(texture)
  self._mask_info:set_mask_texture(texture)
end

function M:can_start_window_ability(class_name)
  local target = self:_create_window_if_need(class_name)
  if target then
    return target:can_start_ability()
  end
  return false
end

function M:open(class_name, extra_data, guid)
  if not self:_safe_check(class_name) then
    return nil, nil
  end
  Logger.Log("UIManager open " .. class_name)
  local target = self:_create_window_if_need(class_name, extra_data, guid)
  if not self:_check_3c_lock(target) then
    return nil, nil
  end
  self._ui_lock_countdown = 10
  self:_reset_mask_texture_holder()
  self:_prepare_window(target)
  self:_check_ui_stack(target)
  self:_play_audio(target)
  self:_set_window_active(target, true)
  if self.main_page_guid == 0 and target ~= nil and target.full_class_name == main_page_cls then
    self.main_page_guid = target.guid
  end
  return target.guid, target
end

function M:_reset_mask_texture_holder()
  self._mask_texture_min_holder = 3
end

function M:_safe_check(class_name)
  if not self._is_init then
    Logger.LogError("UIManager safe_check: 尚未初始化成功")
    return false
  end
  if type(class_name) ~= "string" then
    Logger.LogError("UIManager safe_check: class_name传入类型不是string")
    return false
  end
  return true
end

function M:_create_window_if_need(class_name, extra_data, guid)
  local is_new_create = false
  local target = self:get_window_by_class(class_name)
  if not target then
    target = G.New(class_name)
    target:init()
    target.guid = guid or self:_create_guid()
    target.full_class_name = class_name
    target.full_class_name_hash = CsUIUtil.GetHashCode(class_name)
    target.parent_trans = self:_try_get_order_trans(target.config)
    target.ui_scene_root = self._ui_scene_root
    self._windows[target.guid] = target
    if target.config.is_singleton then
      self._singleton_windows[class_name] = target
    end
    is_new_create = true
  end
  target:set_extra_data(extra_data)
  return target, is_new_create
end

function M:_try_get_order_trans(config)
  local order_trans = self._layers[config.type].order_trans[config.order_in_layer]
  if is_null(order_trans) then
    order_trans = UIUtil.find_trans(self._layers[config.type].trans, "order_trans_" .. config.order_in_layer)
    if is_null(order_trans) then
      order_trans = GameObject("order_trans_" .. config.order_in_layer)
      order_trans:AddComponent(typeof(RectTransform))
      order_trans = order_trans.transform
      order_trans:SetParent(self._layers[config.type].trans)
    end
    order_trans = UIUtil.find_cmpt(order_trans, nil, typeof(RectTransform))
    UIUtil.reset_trans_pos(order_trans)
    order_trans:SetAnchorMin(0, 0)
    order_trans:SetAnchorMax(1, 1)
    local index = 0
    for k, _ in pairs(self._layers[config.type].order_trans) do
      if k < config.order_in_layer then
        index = index + 1
      end
    end
    order_trans:SetSiblingIndex(index)
    self._layers[config.type].order_trans[config.order_in_layer] = order_trans
  end
  return order_trans
end

function M:_check_ui_stack(target)
  if target.config.type == EUIType.Page then
    self:_hide_top_page()
  end
  if self:_need_in_stack(target.config.type) then
    local find_in_stack = false
    for i, v in ipairs(self._window_stack or {}) do
      if v.__cname == target.__cname and target.config.is_singleton then
        find_in_stack = true
        Logger.Log(target.__cname .. "已经在UI栈中，不可重复打开")
        break
      end
    end
    if not find_in_stack then
      table.insert(self._window_stack, target)
    end
  elseif not self._window_not_in_stack[target.guid] then
    self._window_not_in_stack[target.guid] = target
  end
  if self:_need_in_input_action_stack(target.config) then
    self:_remove_input_stack(target)
    table.insert(self._window_input_action_stack[target.config.input_stack_level], target)
    self:_refresh_controller_ui_cfg()
  end
end

function M:_check_3c_lock(target)
  if target.config.input_lock_type ~= input_lock_type.none then
    InputManagerIns:lock_3C(target, target.config.input_lock_type)
  end
  return true
end

function M:_prepare_window(target)
  if target.game_obj == nil then
    target:change_state(EUIState.Prepare)
    table.insert(self._loading_windows, 1, target)
  end
end

function M:_play_audio(target)
  if not target:is_ready() and target:has_open_sfx() then
    AudioManagerIns:play_sfx(WType.event.None, target._open_sfx_priority - 1)
  end
end

function M:_need_in_stack(ui_type)
  if ui_type == EUIType.Page or ui_type == EUIType.Dialog then
    return true
  end
  return false
end

function M:_need_in_input_action_stack(config)
  local ui_type = config.type
  local handle_input = config.handle_input
  if ui_type == EUIType.Page or ui_type == EUIType.Dialog or handle_input then
    return true
  end
  return false
end

function M:close_all_stack_window()
  for i = #self._window_stack, 1, -1 do
    self:_close_window(self._window_stack[i])
    if not self._window_stack[i].config.is_singleton then
      self:_inner_destroy_window(self._window_stack[i])
    end
  end
  self._window_stack = {}
  self:_init_window_input_action_stack()
end

function M:close_all_stack_window_without_main_page()
  local phone_page = self:is_in_stack("UI/Phone/PhonePage")
  if phone_page and phone_page._exit_phone_page_state then
    phone_page:_exit_phone_page_state()
  end
  local first_close = false
  for i = #self._window_stack, 1, -1 do
    if not first_close then
      self:_close_window(self._window_stack[i])
      if self._window_stack[i].config.type == EUIType.Page then
        first_close = true
      end
    end
    if not self._window_stack[i].config.is_singleton then
      self:_inner_destroy_window(self._window_stack[i])
    end
    if self._window_stack[i].guid == self.main_page_guid then
      break
    end
    table.remove(self._window_stack, i)
  end
  for _, input_action_stack_level in pairs(self._window_input_action_stack) do
    for i = #input_action_stack_level, 1, -1 do
      if input_action_stack_level[i].guid == self.main_page_guid then
        break
      end
      table.remove(input_action_stack_level, i)
    end
  end
end

function M:close_all_stack_window_without_main_page_for_performance()
  local phone_page = self:is_in_stack("UI/Phone/PhonePage")
  if phone_page and phone_page._exit_phone_page_state then
    phone_page:_exit_phone_page_state()
  end
  local first_close = false
  for i = #self._window_stack, 1, -1 do
    if self._window_stack[i].guid == self.main_page_guid then
      break
    end
    if not first_close then
      if self._window_stack[i].config.type == EUIType.Page then
        first_close = true
      end
      self:destroy_window(self._window_stack[i].guid)
    end
    if self._window_stack[i] and not self._window_stack[i].config.is_singleton then
      self:_inner_destroy_window(self._window_stack[i])
    end
    table.remove(self._window_stack, i)
  end
  for _, input_action_stack_level in pairs(self._window_input_action_stack) do
    for i = #input_action_stack_level, 1, -1 do
      if input_action_stack_level[i].guid == self.main_page_guid then
        break
      end
      table.remove(input_action_stack_level, i)
    end
  end
  if self._windows[self.main_page_guid] and self._windows[self.main_page_guid].is_active == false then
    self:_show_top_page()
  end
end

function M:close(guid)
  local target = self._windows[guid]
  if not target then
    Logger.LogError("UIManager close: illegal guid = " .. guid)
    return
  end
  Logger.Log("UIManager close:" .. target.full_class_name)
  self:_close_window(target)
  if self:_need_in_input_action_stack(target.config) and #self._window_input_action_stack[target.config.input_stack_level] > 0 then
    self:_remove_input_stack(target)
  end
  if self:_need_in_stack(target.config.type) then
    if 0 >= #self._window_stack then
      return
    end
    if target.config.type == EUIType.Page then
      local top_window = self._window_stack[#self._window_stack]
      if top_window ~= target then
        Logger.LogError("Page页面只可在栈顶时被关闭 切勿随意关闭,当前栈顶window:" .. top_window.__cname)
        return
      end
      table.remove(self._window_stack)
      self:_show_top_page()
    elseif target.config.type == EUIType.Dialog then
      table.remove(self._window_stack)
    end
  else
    self._window_not_in_stack[target.guid] = nil
  end
  if (not target.config.is_singleton or not GlobalVars.AlwaysCacheUI) and target ~= self._mask_info then
    self:_inner_destroy_window(target)
  end
end

function M:_hide_top_page()
  local peak_windows = self:_get_peak_windows()
  for i, v in pairs(peak_windows) do
    self:_set_window_active(v, false)
  end
end

function M:_show_top_page()
  local peak_windows = self:_get_peak_windows()
  for i, v in pairs(peak_windows) do
    self:_set_window_active(v, true)
    if v.config.input_lock_type ~= input_lock_type.none then
      InputManagerIns:lock_3C(v, v.config.input_lock_type)
    end
  end
end

function M:is_top(guid)
  if guid and #self._window_stack > 0 then
    return guid == self._window_stack[#self._window_stack].guid
  end
  return false
end

function M:_close_window(target)
  assert(target)
  self:_set_window_active(target, false)
end

function M:get_window_by_class(class_name)
  return self._singleton_windows[class_name]
end

function M:_set_window_active(target, active)
  if active then
    self:_check_scene_layer_config(target)
    self._cur_show_widows[target.guid] = target
    target:change_state(EUIState.Show)
    if self:_need_in_input_action_stack(target.config) then
      InputManagerIns:lock_input(input_lock_from.UIOpenAndClose, target.config.mask_type)
    end
    table.insert(self._opening_windows, 1, target)
  else
    if self._cur_show_widows[target.guid] then
      self._cur_show_widows[target.guid] = nil
    end
    target:change_state(EUIState.Hide)
    if self:_need_in_input_action_stack(target.config) then
      InputManagerIns:lock_input(input_lock_from.UIOpenAndClose, target.config.mask_type)
    end
    table.insert(self._closing_windows, 1, target)
  end
end

function M:_check_scene_layer_config(target)
  local scene_windows = UISceneLayerConfig[target.config.prefab_path]
  if scene_windows then
    for _, window in pairs(self._window_not_in_stack) do
      if window and not window:is_destroy() and window:is_ready() and window.config.type == EUIType.Scene then
        UIUtil.set_active(window.game_obj, scene_windows[window.config.prefab_path])
      end
    end
  end
end

function M:_get_peak_windows()
  local result = {}
  for i = #self._window_stack, 1, -1 do
    table.insert(result, self._window_stack[i])
    if self._window_stack[i].config.type == EUIType.Page then
      break
    end
  end
  return result
end

function M:get_windows_stack()
  return self._window_stack
end

function M:get_input_action_windows_stack()
  return self._window_input_action_stack
end

function M:is_in_stack(class_name)
  for k, v in pairs(self._window_stack) do
    if v.full_class_name == class_name then
      return v
    end
  end
  return nil
end

function M:is_show(class_name)
  for k, v in pairs(self._cur_show_widows) do
    if v.full_class_name == class_name then
      return v
    end
  end
  return nil
end

function M:is_show_by_hash(class_name_hash)
  for k, v in pairs(self._cur_show_widows) do
    if v.full_class_name_hash == class_name_hash then
      return v
    end
  end
  return nil
end

function M:is_show_by_guid(guid)
  for k, v in pairs(self._cur_show_widows) do
    if v.guid == guid then
      return v
    end
  end
  return nil
end

function M:is_active(class_name)
  for k, v in pairs(self._cur_show_widows) do
    if v.full_class_name == class_name and v.is_active then
      return v
    end
  end
  return nil
end

function M:_get_reload_windows_or_panel_id(cls_name, cls)
  local reload_id, panel_id
  for k, v in pairs(self._windows) do
    if v.full_class_name == cls_name then
      reload_id = k
      break
    elseif v.container then
      for kk, vv in pairs(v.container) do
        if cls.__cname == vv.__cname then
          reload_id = k
          panel_id = kk
          break
        end
      end
    end
  end
  return reload_id, panel_id
end

function M:reload_windows_class(cls_name, cls)
  local reload_id, panel_id = self:_get_reload_windows_or_panel_id(cls_name, cls)
  if reload_id then
    if panel_id == nil then
      local data = self._windows[reload_id]:get_extra_data()
      local is_show = false
      if self._cur_show_widows[reload_id] then
        is_show = true
      end
      self:destroy_window(reload_id)
      if is_show then
        self:open(cls_name, data)
      end
    else
      local data = self._windows[reload_id]:get_extra_data()
      local window_cls_name = self._windows[reload_id].full_class_name
      local is_show = false
      if self._cur_show_widows[reload_id] then
        is_show = true
      end
      self:destroy_window(reload_id)
      if is_show then
        self:open(window_cls_name, data)
      end
    end
  end
end

function M:get_windows_by_guid(guid)
  if string.is_valid(guid) and self._windows then
    return self._windows[guid]
  end
  return nil
end

function M:destroy_window(guid)
  local target = self._windows[guid]
  if not target then
    Logger.LogError("UIManager destroy_window: illegal guid = " .. guid)
    return
  end
  if self.main_page_guid == guid then
    self.main_page_guid = 0
  end
  self:_close_window(target)
  self:_inner_destroy_window(target)
end

function M:destroy_all()
  for _, v in pairs(self._windows) do
    if v then
      self:_inner_destroy_window(v, true)
    end
  end
  self._singleton_windows = {}
  self._window_stack = {}
  self:_init_window_input_action_stack()
  self._cur_show_widows = {}
end

function M:clear_on_light_relogin()
  for _, window in pairs(self._windows) do
    if window and window.config.destroy_when_light_refresh then
      if window.reset_state then
        window:reset_state()
      end
      self:_inner_destroy_window(window, true)
    end
  end
end

function M:clear_on_back_home()
  for _, v in pairs(self._windows) do
    if v and v.config.destroy_when_light_refresh then
      self:_inner_destroy_window(v, true)
    end
  end
end

function M:_inner_destroy_window(target, from_all_destroy)
  for k, v in pairs(self._opening_windows) do
    if v.guid == target.guid then
      table.remove(self._opening_windows, k)
      break
    end
  end
  if target.config.input_lock_type ~= input_lock_type.none then
    InputManagerIns:unlock_3C(target)
  end
  local index = -1
  for i, v in ipairs(self._window_stack) do
    if v.guid == target.guid then
      index = i
      break
    end
  end
  if index ~= -1 then
    table.remove(self._window_stack, index)
  end
  self:_remove_input_stack(target)
  self._windows[target.guid] = nil
  self._window_not_in_stack[target.guid] = nil
  self._singleton_windows[target.full_class_name] = nil
  self._cur_show_widows[target.guid] = nil
  self:_inner_delete(target)
end

function M:_inner_delete(instance)
  if instance.__ctype == ClassType.Instance then
    instance:change_state(EUIState.Destroy)
  end
end

function M:update(deltaTime)
  for _, window in pairs(self._windows) do
    if window.is_active then
      window:update(deltaTime)
    end
  end
  if #self._loading_windows > 0 then
    for i = #self._loading_windows, 1, -1 do
      if self._loading_windows[#self._loading_windows]:loading_finish() then
        self:_reset_mask_texture_holder()
        self._loading_windows[#self._loading_windows]:change_state(EUIState.Ready)
        self._loading_windows[#self._loading_windows]:check_next_state()
        table.remove(self._loading_windows, #self._loading_windows)
      else
        break
      end
    end
  end
  if 0 < #self._opening_windows then
    if self._opening_windows[#self._opening_windows]:is_ready() and 0 >= self._mask_texture_min_holder then
      self._mask_info:clear_mask_texture()
    end
    self._mask_texture_min_holder = self._mask_texture_min_holder - 1
    if self._opening_windows[#self._opening_windows]:is_ready() and not self._opening_windows[#self._opening_windows]:is_play_anim() then
      self._opening_windows[#self._opening_windows]:check_next_state()
      table.remove(self._opening_windows, #self._opening_windows)
      if #self._opening_windows == 0 and #self._closing_windows == 0 then
        InputManagerIns:unlock_input(input_lock_from.UIOpenAndClose)
        self._ui_lock_countdown = 0
      end
    end
  end
  if 0 < #self._closing_windows and not self._closing_windows[#self._closing_windows]:is_play_anim() then
    self._closing_windows[#self._closing_windows]:check_next_state()
    table.remove(self._closing_windows, #self._closing_windows)
    if #self._opening_windows == 0 and #self._closing_windows == 0 then
      InputManagerIns:unlock_input(input_lock_from.UIOpenAndClose)
      self._ui_lock_countdown = 0
    end
  end
  if 0 < self._ui_lock_countdown then
    self._ui_lock_countdown = self._ui_lock_countdown - deltaTime
    if 0 >= self._ui_lock_countdown then
      for _, v in pairs(self._opening_windows) do
        Logger.LogWarning("<opening_windows> UI 锁定超时, window = " .. v.__cname)
      end
      for _, v in pairs(self._closing_windows) do
        Logger.LogWarning("<_closing_windows> UI 锁定超时, window = " .. v.__cname)
      end
    end
  end
end

function M:late_update(deltaTime)
  for _, window in pairs(self._windows) do
    if window.is_active then
      window:late_update(deltaTime)
    end
  end
end

function M:on_level_prepare()
  for _, window in pairs(self._windows) do
    if not is_null(window.game_obj) then
      window:on_level_prepare()
    end
  end
end

function M:on_level_destroy()
  for _, window in pairs(self._windows) do
    if not is_null(window.game_obj) then
      window:on_level_destroy()
    end
  end
end

function M:check_adaptive()
  for _, window in pairs(self._windows) do
    if not is_null(window.game_obj) then
      window:check_adaptive()
    end
  end
end

function M:_create_guid()
  local seed = {
    "e",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "a",
    "b",
    "c",
    "d",
    "e",
    "f"
  }
  local tb = {}
  for i = 1, 32 do
    table.insert(tb, seed[math.random(1, 16)])
  end
  local sid = table.concat(tb)
  return string.format("%s-%s-%s-%ss-%s", string.sub(sid, 1, 8), string.sub(sid, 9, 12), string.sub(sid, 13, 16), string.sub(sid, 17, 20), string.sub(sid, 21, 32))
end

function M:set_init_bg_mask(active)
  UIUtil.set_active(self._init_bg_mask.transform.parent, active)
  if active then
    local sprite, handle = ResourcesUtil.LoadAsset(typeof(Sprite), "UISprite/Load/BigPic/Bg_loading_001.png", nil)
    CsUIUtil.InitBgMaskHandle = handle
    self._init_bg_mask.sprite = sprite
    self._init_bg_mask.color = ColorUtil.get_color(ColorUtil.C.white)
  elseif CsUIUtil.InitBgMaskHandle ~= 0 then
    ResourcesUtil.DismissResource(CsUIUtil.InitBgMaskHandle)
    CsUIUtil.InitBgMaskHandle = 0
    self._init_bg_mask.sprite = nil
  end
end

function M:destroy()
  self:_remove_lua_listener()
  self:destroy_all()
  self._is_init = false
  self:set_init_bg_mask(true)
  if not_null(self._culling_quad_fitter) then
    ResourcesUtil.DismissResource(self._culling_quad_fitter_handle)
    UIUtil.destroy_go(self._culling_quad_fitter.gameObject)
  end
end

function M:init_default_layout_version()
  local runtime_platform = ApplicationUtil.GetTargetPlatform()
  if runtime_platform == CS.Proto.PlatformType.Android or runtime_platform == CS.Proto.PlatformType.Ios then
    self:change_layout_version(LayoutVersion.Mobile, true)
  elseif runtime_platform == CS.Proto.PlatformType.Ps4 then
    self:change_layout_version(LayoutVersion.PS, true)
  else
    self:change_layout_version(LayoutVersion.PC, true)
  end
  self:init_indent()
end

function M:change_layout_version(layout_version, force)
  if not (self._layout_version ~= layout_version or force) or is_null(self.canvas) then
    return
  end
  UIAdaptiveUtils.layoutVersion = layout_version
  self._layout_version = layout_version
  local size = self._canvas_sizes[self._layout_version]
  self:set_canvas_size(size.width, size.height)
  UIAdaptiveUtils.ApplyFix(self._ui_root, layout_version, self._ui_root_prefab_path)
end

function M:reopen_all_windows()
  local reload_windows = {}
  for k, v in pairs(self._windows) do
    if not self:_need_in_stack(v.config.type) and v.is_active then
      table.insert(reload_windows, {
        class_name = v.full_class_name,
        extra_data = v:get_extra_data(),
        guid = v.guid
      })
    end
  end
  for i, v in ipairs(self._window_stack) do
    if v.is_active then
      table.insert(reload_windows, {
        class_name = v.full_class_name,
        extra_data = v:get_extra_data(),
        guid = v.guid
      })
    end
  end
  self:destroy_all()
  for i, v in ipairs(reload_windows) do
    self:open(v.class_name, v.extra_data, v.guid)
  end
end

function M:set_canvas_size(width, height)
  self.canvas:SetCanvasSize(width, height)
end

function M:get_canvas_size()
  return self.canvas:GetCanvasSize()
end

function M:get_canvas()
  return self.canvas:GetCanvas()
end

function M:get_canvas_sizes()
  return self._canvas_sizes
end

function M:get_layout_version()
  self._layout_version = UIAdaptiveUtils.layoutVersion
  return self._layout_version
end

function M:init_indent()
  local indent = self:get_indent()
  if indent == 0 then
    if Screen.safeArea and Screen.safeArea.width then
      indent = math.max(0, (Screen.width - Screen.safeArea.width) / 2)
    else
      indent = 0
    end
  end
  self:set_indent(math.floor(indent))
end

function M:set_indent(indent)
  UIAdaptiveUtils.indent = indent
  self.canvas:RefreshIndent()
end

function M:get_indent()
  return UIAdaptiveUtils.indent
end

function M:loading_page_showing()
  return self._loadingPage_showing
end

function M:_add_lua_listener()
  self:_remove_lua_listener()
  self._lua_events = {}
  self._lua_events[EventID.LuaSetLoadingState] = function(is_loading)
    if is_loading then
      self:close_all_stack_window()
    end
  end
  for event_id, func in pairs(self._lua_events) do
    EventCenter.LuaAddListener(event_id, func)
  end
end

function M:_remove_lua_listener()
  if self._lua_events then
    for event_id, func in pairs(self._lua_events) do
      EventCenter.LuaRemoveListener(event_id, func)
    end
  end
  self._lua_events = nil
end

function M:_refresh_controller_ui_cfg()
  local found_page
  local stop_by_page = false
  for i = EUIInputStackLevel.high, EUIInputStackLevel.low do
    local stack = self._window_input_action_stack[i]
    if 0 < #stack then
      local cur_window
      for i = #stack, 1, -1 do
        cur_window = stack[i]
        if cur_window.config.player_ctrl_cfg then
          found_page = cur_window
          break
        end
        if cur_window.config.type == EUIType.Page then
          stop_by_page = true
          break
        end
      end
    end
    if stop_by_page or found_page ~= nil then
      break
    end
  end
  if found_page then
    player_controller:apply_player_ctrl_cfg(found_page, found_page.config.player_ctrl_cfg)
  else
    player_controller:apply_player_ctrl_cfg()
  end
end

function M:_remove_input_stack(target)
  local index = -1
  local is_top = false
  local stack = self._window_input_action_stack[target.config.input_stack_level]
  local count = #stack
  if count == 0 then
    return
  end
  for i = count, 1, -1 do
    is_top = i == count
    if stack[i].guid == target.guid then
      index = i
      break
    end
  end
  if index ~= -1 then
    table.remove(stack, index)
    if is_top then
      self:_refresh_controller_ui_cfg()
    end
  end
end

function M:is_main_page_on_enable()
  local main_page = self:is_show_by_guid(self.main_page_guid)
  if main_page then
    return true
  end
  return false
end

function M:is_main_page_in_idle()
  local top_window = self:_find_first_stack_page()
  if top_window ~= nil and top_window.guid == self.main_page_guid then
    return true
  end
  return false
end

function M:_find_first_stack_page()
  for i = EUIInputStackLevel.high, EUIInputStackLevel.low do
    local stack = self._window_input_action_stack[i]
    if stack and 0 < #stack then
      local cur_window
      for i = #stack, 1, -1 do
        cur_window = stack[i]
        if cur_window and cur_window.config.input_penetrate == false then
          return cur_window
        end
      end
    end
  end
  return nil
end

function M:_init_window_input_action_stack()
  self._window_input_action_stack = {}
  self._window_input_action_stack[EUIInputStackLevel.high] = {}
  self._window_input_action_stack[EUIInputStackLevel.middle] = {}
  self._window_input_action_stack[EUIInputStackLevel.low] = {}
end

function M:set_ui_culling(ui_trans, fix_scale)
  if is_null(self._culling_quad_fitter) and not_null(ui_trans) then
    CsUIUtil.LoadPrefabAsync("UISceneObj/UICullingQuad.prefab", function(obj, handle)
      self._culling_quad_fitter = UIUtil.find_cmpt(obj.transform, nil, typeof(UIOcclusionQuadFitter))
      self._culling_quad_fitter_handle = handle
      self._culling_quad_fitter:FitToUI(ui_trans, self.ui_camera, fix_scale)
    end, self._ui_scene_root)
  elseif is_null(ui_trans) then
    self._culling_quad_fitter:Reset()
  else
    self._culling_quad_fitter:FitToUI(ui_trans, self.ui_camera, fix_scale)
  end
end

return M
