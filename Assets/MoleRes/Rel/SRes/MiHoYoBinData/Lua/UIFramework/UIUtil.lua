local UIUtil = {}

local function get_child(trans, index)
  assert(not_null(trans))
  local target_trans = trans
  if not trans.GetChild then
    target_trans = trans.transform
  end
  return target_trans:GetChild(index)
end

local function remove_all_child(trans)
  assert(not_null(trans))
  for i = trans.childCount - 1, 0, -1 do
    GameObject.Destroy(trans:GetChild(i).gameObject)
  end
end

local function get_child_cmpt(trans, index, ctype)
  local child = get_child(trans, index)
  return child:GetComponent(ctype)
end

local function find_trans(trans, path)
  assert(not_null(trans))
  local target_trans = trans
  if not trans.Find then
    target_trans = trans.transform
  end
  if path == nil then
    return trans.transform
  end
  return target_trans:Find(path)
end

local function find_cmpt(trans, path, ctype)
  assert(not_null(trans))
  assert(ctype ~= nil)
  local target_trans = trans
  if string.is_valid(path) then
    target_trans = find_trans(trans, path)
  end
  if target_trans == nil then
    return nil
  end
  if target_trans:GetType() == ctype then
    return target_trans
  end
  local cmpt = target_trans:GetComponent(ctype)
  if not is_null(cmpt) then
    return cmpt
  end
  return target_trans:GetComponentInChildren(ctype)
end

local function find_cmpts(trans, path, ctype)
  assert(not_null(trans))
  assert(ctype ~= nil)
  local target_trans = trans
  if string.is_valid(path) then
    target_trans = find_trans(trans, path)
  end
  if target_trans == nil then
    return nil
  end
  if target_trans:GetType() == ctype then
    return target_trans
  end
  local cmpts = {}
  cmpts = target_trans:GetComponents(ctype)
  if not is_null(cmpts) then
    return cmpts
  end
  return target_trans:GetComponentInChildren(ctype)
end

local function find_gameobject(trans, path)
  local target_trans = find_trans(trans, path)
  if target_trans ~= nil then
    return target_trans.gameObject
  end
end

local function find_rect_trans(trans, path)
  return find_cmpt(trans, path, typeof(RectTransform))
end

local function find_text(trans, path)
  local txt = find_cmpt(trans, path, typeof(TextMeshProUGUI))
  if is_null(txt) then
    txt = find_cmpt(trans, path, typeof(TextMesh))
    if is_null(txt) then
      txt = find_cmpt(trans, path, typeof(Text))
      if is_null(txt) then
        txt = find_cmpt(trans, path, typeof(TextEx))
      end
    end
  end
  return txt
end

local function find_localization_text(trans, path)
  local loc_text = find_cmpt(trans, path, typeof(TextEx))
  if is_null(loc_text) then
    return find_cmpt(trans, path, typeof(MonoLocalizedText))
  end
  return loc_text
end

local function find_image(trans, path)
  local img = find_cmpt(trans, path, typeof(Image))
  if is_null(img) then
    img = find_cmpt(trans, path, typeof(HoYoImage))
  end
  return img
end

local function find_localization_image(trans, path)
  local loc_img = find_cmpt(trans, path, typeof(ImageEx))
  if is_null(loc_img) then
    return find_cmpt(trans, path, typeof(MonoLocalizedImage))
  end
  return loc_img
end

local function find_button(trans, path)
  return find_cmpt(trans, path, typeof(Button))
end

local function find_button_ex(trans, path)
  return find_cmpt(trans, path, typeof(ButtonEx))
end

local function find_toggle(trans, path)
  return find_cmpt(trans, path, typeof(Toggle))
end

local function find_toggle_ex(trans, path)
  return find_cmpt(trans, path, typeof(ToggleEx))
end

local function find_input(trans, path)
  return find_cmpt(trans, path, typeof(InputField))
end

local function find_slider(trans, path)
  return find_cmpt(trans, path, typeof(Slider))
end

local function find_scroll_rect(trans, path)
  return find_cmpt(trans, path, typeof(ScrollRect))
end

local function find_drop_down(trans, path)
  return find_cmpt(trans, path, typeof(Dropdown))
end

local function find_ui_state_group(trans, path)
  return find_cmpt(trans, path, typeof(UIStateChangeGroup))
end

local function find_canvas_group(trans, path)
  return find_cmpt(trans, path, typeof(CanvasGroup))
end

local function find_animation(trans, path)
  return find_cmpt(trans, path, typeof(Animation))
end

local function find_animator(trans, path)
  return find_cmpt(trans, path, typeof(Animator))
end

local function find_red_point_container(trans, path)
  return find_cmpt(trans, path, typeof(MonoRedPointContainer))
end

local function get_mono_binder_field(trans)
  local binder = UIUtil.find_cmpt(trans, nil, typeof(MonoViewBinder))
  if is_null(binder) then
    Logger.LogError("init_mono_binder error!!")
    return {}
  end
  local field = {}
  for _, v in pairs(binder.fields) do
    field[v.name] = v:GetObject()
  end
  return field
end

local function set_child_active(trans, path, active)
  local go_trans = find_trans(trans, path)
  assert(not_null(go_trans), "set_child_active null path=" .. path)
  local go = go_trans.gameObject
  if go ~= nil and go.activeSelf ~= active then
    go:SetActive(active)
  end
end

local function set_active(trans, active)
  assert(not_null(trans), "set_active null")
  local go = trans.gameObject
  if go ~= nil and go.activeSelf ~= active then
    go:SetActive(active)
  end
end

local function set_light_active(trans, active)
  assert(not_null(trans), "set_light_active null")
  local go = trans.gameObject
  if go ~= nil and go.lightWeightActive ~= active then
    go.lightWeightActive = active
  end
end

local function get_text_by_id(text_id, ...)
  if text_id.ToStringExplicit then
    text_id = text_id:ToStringExplicit()
    return text_id
  end
  return LocManagerIns:get_text_by_id(text_id, ...)
end

local function set_text_by_id(trans, text_id, ...)
  local loc_text = find_localization_text(trans, nil)
  if not is_null(loc_text) then
    if text_id.ToStringExplicit then
      text_id = text_id:ToStringExplicit()
    end
    loc_text:SetupText(text_id, ...)
  end
end

local function handle_text(text, ...)
  return LocManagerIns:handle_text(text, ...)
end

local function set_text(trans, text, color)
  local ui_text = find_text(trans, nil)
  if ui_text ~= nil then
    if type(text) == "number" then
      text = tostring(text)
    end
    if text and text.ToStringExplicit then
      text = text:ToStringExplicit()
    end
    ui_text.text = text
    if color then
      ui_text.color = ColorUtil.get_color(color)
    end
  end
end

local function set_text_with_dynamic_sprite(trans, text, callback)
  local ui_text = find_text(trans, nil)
  if ui_text ~= nil then
    if type(text) == "number" then
      text = tostring(text)
    end
    if text and text.ToStringExplicit then
      text = text:ToStringExplicit()
    end
    ui_text:SetTextWithDynamicSprite(text, callback)
  end
end

local function set_image(trans, sprite, proxy)
  local ui_image = find_image(trans, nil)
  if ui_image ~= nil then
    local ui_sprite = sprite
    if string.is_valid(sprite) then
      if proxy == nil then
        Logger.LogError("sprite load proxy is null!")
      else
        ui_sprite = proxy:LoadSprite(sprite)
      end
    end
    if ui_sprite ~= nil then
      ui_image.sprite = ui_sprite
    end
  end
end

local function get_sprite(icon_path, proxy)
  local ui_sprite
  if string.is_valid(icon_path) then
    if proxy == nil then
      Logger.LogError("sprite load proxy is null!")
    else
      ui_sprite = proxy:LoadSprite(icon_path)
    end
  end
  if ui_sprite then
    return ui_sprite
  end
end

local function get_material(path, proxy)
  local mat
  if string.is_valid(path) then
    if proxy == nil then
      Logger.LogError("material load proxy is null!")
    else
      mat = proxy:LoadMaterial(path)
    end
  end
  return mat
end

local function set_image_by_id(trans, relative_path)
  local loc_image = find_localization_image(trans, nil)
  if loc_image ~= nil then
    loc_image:SetupImage(relative_path)
  end
end

local function destroy_go(go)
  if go ~= nil then
    GameObject.Destroy(go)
    go = nil
  end
end

local function reset_trans_pos(trans)
  trans = UIUtil.find_rect_trans(trans)
  if is_null(trans) then
    return
  end
  trans:SetLocalPosition(0, 0, 0)
  trans:SetLocalScale(1, 1, 1)
  trans:SetOffsetMax(0, 0)
  trans:SetOffsetMin(0, 0)
end

local function set_camera_active(state)
end

local function get_camera_active()
  return true
end

local function load_prefab_set_parent(go, parent, name, is_hide)
  local go_ins = GameObject.Instantiate(go)
  if string.is_valid(name) then
    go_ins.name = name
  end
  local target_trans = go_ins.transform
  target_trans:SetParentAndReset(parent)
  go_ins:SetActive(is_hide == nil or not is_hide)
  return go_ins
end

local function set_text_color(trans, color)
  local ui_text = find_text(trans, nil)
  if not is_null(ui_text) then
    if type(color) == "string" then
      ui_text.color = ColorUtil.get_color(color)
    elseif color ~= nil then
      ui_text.color = color
    end
  end
end

local function set_image_color(img, color)
  if is_null(img) then
    Logger.LogError("图片不存在, 无法设置颜色!!!")
    return
  end
  if img.color == nil then
    img = find_image(img, nil)
  end
  if not is_null(img) then
    if type(color) == "string" then
      img.color = ColorUtil.get_color(color)
    elseif color ~= nil then
      img.color = color
    end
  end
end

local function set_image_material(img, mat)
  if img == nil then
    img = find_image(img, nil)
  end
  img.material = mat
end

local function set_toggle_ison(trans, ison)
  assert(not_null(trans), "set_toggle_ison trans null")
  local toggle = trans:GetComponent(typeof(ToggleEx))
  assert(not_null(toggle), "set_toggle_ison toggle null")
  if toggle ~= nil then
    toggle.isOn = ison
  end
end

local function set_drop_down_options(drop_down, options)
  if drop_down == nil then
    drop_down = find_drop_down(drop_down, nil)
  end
  drop_down:SetOptions(options)
end

local function world_to_ui(x, y, z)
  return CsUIUtil.WorldToUI(GameplayUtility.Camera.MainCamera, UIManagerInstance:get_canvas(), x, y, z)
end

local function show_tips(txt)
  EventCenter.Broadcast(EventID.LuaShowTips, txt)
end

local function show_tips_by_text_id(txt_id, ...)
  if string.is_valid(txt_id) then
    local txt = UIUtil.get_text_by_id(txt_id, ...)
    EventCenter.Broadcast(EventID.LuaShowTips, txt)
  end
end

local function get_scroll_view_move_value(item_pos_y, rect_item_parent, scroll_view_y, item_y)
  local rect_item_parent_y = rect_item_parent.anchoredPosition.y
  local rect_item_parent_height = rect_item_parent.rect.height
  local pos_dif_value = item_pos_y + rect_item_parent_y + scroll_view_y - item_y - item_y * 0.5
  local move_value = rect_item_parent_y
  if pos_dif_value < 0 then
    move_value = rect_item_parent_y - pos_dif_value
    if rect_item_parent_height < move_value then
      move_value = rect_item_parent_height
    end
  elseif item_y < pos_dif_value then
    move_value = item_y - pos_dif_value + rect_item_parent_y
    if move_value < 0 then
      move_value = 0
    end
  end
  return move_value
end

local function get_scroll_view_move_value_x(item_pos_x, rect_item_parent, scroll_view_x, item_x)
  local rect_item_parent_x = rect_item_parent.anchoredPosition.x
  local rect_item_parent_width = rect_item_parent.rect.width
  local pos_dif_value = item_pos_x + rect_item_parent_x + scroll_view_x - item_x
  local move_value = rect_item_parent_x
  if pos_dif_value < 0 then
    move_value = rect_item_parent_x - pos_dif_value
    if rect_item_parent_width < move_value then
      move_value = rect_item_parent_width
    end
  elseif item_x < pos_dif_value then
    move_value = item_x - pos_dif_value + rect_item_parent_x
    if move_value < 0 then
      move_value = 0
    end
  end
  return -move_value
end

local function do_anim_txt_number_add(txt, cur_number, to_number, timer, call_back)
  return DOTween.To(function(value)
    if is_null(txt) == false then
      UIUtil.set_text(txt, math.ceil(value))
    end
  end, cur_number, to_number, timer or 1):OnComplete(function()
    if call_back then
      call_back()
    end
  end)
end

local function do_anim_txt_number_ex(txt, cur_number, to_number, timer, str, call_back)
  return DOTween.To(function(value)
    if is_null(txt) == false then
      UIUtil.set_text(txt, string.format(str, math.ceil(value)))
    end
  end, cur_number, to_number, timer or 1):OnComplete(function()
    if call_back then
      call_back()
    end
  end)
end

local function dt_to_anim(cur_number, to_number, timer, update_callback, callback)
  return DOTween.To(function(value)
    if update_callback ~= nil then
      update_callback(value)
    end
  end, cur_number, to_number, timer or 1):OnComplete(function()
    if callback then
      callback()
    end
  end)
end

local function mouse_position_to_ui(offset_y, offset_x)
  local point = Vector2(InputUtil.mousePosition.x, InputUtil.mousePosition.y)
  local _, pos = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(UIManagerInstance.canvas_rect, point, UIManagerInstance.ui_camera)
  if offset_y ~= nil then
    pos.y = pos.y + offset_y
  end
  if offset_x ~= nil then
    pos.x = pos.x + offset_x
  end
  return pos
end

local function calculate_day_difference(timestamp1, timestamp2)
  local date1 = os.date("*t", timestamp1)
  local date2 = os.date("*t", timestamp2)
  local time1 = os.time({
    year = date1.year,
    month = date1.month,
    day = date1.day
  })
  local time2 = os.time({
    year = date2.year,
    month = date2.month,
    day = date2.day
  })
  local difference_in_days = os.difftime(time2, time1) / 86400
  return math.abs(math.floor(difference_in_days))
end

local function get_confirm_popup()
  local popup = {}
  popup.data = {}
  
  function popup:set_texts(info, yes, no, title)
    if self.data then
      self.data.info_txt = info
      self.data.yes_txt = yes
      self.data.no_txt = no
      self.data.title_txt = title
    end
  end
  
  function popup:set_callbacks(yes, no, close)
    if self.data then
      self.data.yes_callback = yes
      self.data.no_callback = no
      self.data.close_callback = close
    end
  end
  
  function popup:set_item(icon_path, current_number, max_number)
    if self.data then
      self.data.icon_path = icon_path
      self.data.current_number = current_number
      self.data.max_number = max_number
    end
  end
  
  function popup:set_countdown(countdown_time)
    if self.data then
      self.data.countdown_time = countdown_time
    end
  end
  
  function popup:set_style(style)
    if self.data then
      self.data.style = style
    end
  end
  
  function popup:show()
    if self.data then
      UIManagerInstance:open("UI/ConfirmDialog", self.data)
    end
  end
  
  return popup
end

local function get_ui_global_scale(rect_trans)
  local global_scale = rect_trans.localScale
  return global_scale, global_scale.x, global_scale.y, global_scale.z
end

UIUtil.world_to_ui = world_to_ui
UIUtil.get_child = get_child
UIUtil.remove_all_child = remove_all_child
UIUtil.get_child_cmpt = get_child_cmpt
UIUtil.find_cmpt = find_cmpt
UIUtil.find_cmpts = find_cmpts
UIUtil.find_trans = find_trans
UIUtil.find_gameobject = find_gameobject
UIUtil.find_rect_trans = find_rect_trans
UIUtil.find_text = find_text
UIUtil.find_image = find_image
UIUtil.find_button = find_button
UIUtil.find_button_ex = find_button_ex
UIUtil.find_toggle = find_toggle
UIUtil.find_toggle_ex = find_toggle_ex
UIUtil.find_input = find_input
UIUtil.find_slider = find_slider
UIUtil.find_scroll_rect = find_scroll_rect
UIUtil.find_animation = find_animation
UIUtil.find_animator = find_animator
UIUtil.find_red_point_container = find_red_point_container
UIUtil.find_drop_down = find_drop_down
UIUtil.find_ui_state_group = find_ui_state_group
UIUtil.find_canvas_group = find_canvas_group
UIUtil.set_child_active = set_child_active
UIUtil.set_active = set_active
UIUtil.set_light_active = set_light_active
UIUtil.set_text = set_text
UIUtil.set_text_with_dynamic_sprite = set_text_with_dynamic_sprite
UIUtil.set_text_by_id = set_text_by_id
UIUtil.get_text_by_id = get_text_by_id
UIUtil.handle_text = handle_text
UIUtil.set_image = set_image
UIUtil.get_sprite = get_sprite
UIUtil.set_image_by_id = set_image_by_id
UIUtil.set_text_color = set_text_color
UIUtil.set_image_color = set_image_color
UIUtil.set_image_material = set_image_material
UIUtil.set_toggle_ison = set_toggle_ison
UIUtil.set_drop_down_options = set_drop_down_options
UIUtil.reset_trans_pos = reset_trans_pos
UIUtil.get_camera_active = get_camera_active
UIUtil.set_camera_active = set_camera_active
UIUtil.load_prefab_set_parent = load_prefab_set_parent
UIUtil.destroy_go = destroy_go
UIUtil.show_tips = show_tips
UIUtil.show_tips_by_text_id = show_tips_by_text_id
UIUtil.get_scroll_view_move_value = get_scroll_view_move_value
UIUtil.get_scroll_view_move_value_x = get_scroll_view_move_value_x
UIUtil.do_anim_txt_number_add = do_anim_txt_number_add
UIUtil.do_anim_txt_number_ex = do_anim_txt_number_ex
UIUtil.dt_to_anim = dt_to_anim
UIUtil.mouse_position_to_ui = mouse_position_to_ui
UIUtil.get_mono_binder_field = get_mono_binder_field
UIUtil.calculate_day_difference = calculate_day_difference
UIUtil.get_confirm_popup = get_confirm_popup
UIUtil.get_ui_global_scale = get_ui_global_scale
UIUtil.get_material = get_material
return UIUtil
