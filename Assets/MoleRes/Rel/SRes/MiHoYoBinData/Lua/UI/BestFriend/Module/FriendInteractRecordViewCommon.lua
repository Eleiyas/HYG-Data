friend_level_module = friend_level_module or {}
local view = {}
local PAGE_RECORD = 0
local PAGE_SUMMARY = 1
local PAGE_MIN = PAGE_RECORD
local PAGE_LOOP = true
local SUMMARY_DEFAULT_MIN_RECORD_COUNT = 3
local in_progress_item_cls = "UI/BestFriend/InteractRecordInProgressItem"
local complete_item_cls = "UI/BestFriend/InteractRecordCompleteItem"
local summary_page_cls = "UI/BestFriend/InteractRecordSummaryPage"
local ANIM_TRIGGER_OUT = "out"
local NEW_UNLOCK_ANIM = "new_refresh"
local NEW_UNLOCK_ANIM_DELAY = 0.1
local SWITCH_ANIM = {
  [PAGE_SUMMARY] = {
    trigger = "interaction",
    event = "satellite_interaction_switch"
  },
  [PAGE_RECORD] = {
    trigger = "satellite",
    event = "interaction_satellite_switch"
  }
}
local SWITCH_ANIM_TIMEOUT = 1.5

function view.init_panel_state(panel)
  panel._record_item_list = {}
  panel._cur_friend_data = nil
  panel._summary_page = nil
  panel._cur_page = PAGE_RECORD
  panel._summary_dirty = true
  panel._is_closing = false
  panel._pending_page = nil
  panel._new_unlock_slot = nil
end

function view.on_create_panel(panel)
  UIUtil.set_active(panel._item_activated, false)
  UIUtil.set_active(panel._item_progress, false)
end

local function _get_default_page(panel)
  if friend_level_module.force_record_page_once then
    friend_level_module.force_record_page_once = false
    return PAGE_RECORD
  end
  if not panel._summary_unlocked then
    return PAGE_RECORD
  end
  local friend_data = panel._cur_friend_data
  if is_null(friend_data) then
    return PAGE_RECORD
  end
  local moonlets = friend_data:get_moonlets()
  local record_count = not_null(moonlets) and moonlets.Count or 0
  if record_count > SUMMARY_DEFAULT_MIN_RECORD_COUNT then
    return PAGE_SUMMARY
  end
  return PAGE_RECORD
end

function view.on_enable_panel(panel)
  panel._summary_dirty = true
  panel._pending_page = nil
  panel:refresh_view(panel:get_extra_data())
  view.switch_page(panel, _get_default_page(panel))
end

local function _get_game_object(obj)
  if is_null(obj) then
    return nil
  end
  return obj.gameObject or obj
end

local function _is_row_template(panel, trans)
  local go = _get_game_object(trans)
  if is_null(go) then
    return false
  end
  return go == _get_game_object(panel._item_activated) or go == _get_game_object(panel._item_progress)
end

local function _hide_row_templates(panel)
  if not_null(panel._item_activated) then
    UIUtil.set_active(panel._item_activated, false)
  end
  if not_null(panel._item_progress) then
    UIUtil.set_active(panel._item_progress, false)
  end
end

local function _destroy_record_entry(entry)
  if entry and not_null(entry.trans) then
    GameObject.Destroy(entry.trans)
  end
end

local function _clear_dynamic_content_children(panel)
  if is_null(panel._trans_content) then
    panel._record_item_list = {}
    return
  end
  local content = panel._trans_content
  local to_destroy = {}
  for i = 0, content.childCount - 1 do
    local child = content:GetChild(i)
    if not _is_row_template(panel, child) then
      table.insert(to_destroy, child.gameObject)
    end
  end
  for _, go in ipairs(to_destroy) do
    if not is_null(go) then
      GameObject.Destroy(go)
    end
  end
  panel._record_item_list = {}
end

function view.get_record_item(panel, slot_index, item_cls, template_trans)
  local entry = panel._record_item_list[slot_index]
  if entry and (entry.cls ~= item_cls or _is_row_template(panel, entry.trans)) then
    _destroy_record_entry(entry)
    panel._record_item_list[slot_index] = nil
    entry = nil
  end
  if entry == nil or is_null(entry.trans) then
    local obj = UIUtil.load_prefab_set_parent(template_trans, panel._trans_content)
    local item = panel:add_panel(item_cls, obj)
    entry = {
      item = item,
      cls = item_cls,
      trans = obj
    }
    panel._record_item_list[slot_index] = entry
  end
  UIUtil.set_active(entry.trans, true)
  return entry.item
end

function view.refresh_record_items(panel, is_bestie)
  local friend_data = panel._cur_friend_data
  if is_null(friend_data) then
    return
  end
  _hide_row_templates(panel)
  _clear_dynamic_content_children(panel)
  local level_count = friend_level_module:get_friendship_level_count()
  local moonlets_cs = friend_data:get_moonlets()
  local completed_count = moonlets_cs and moonlets_cs.Count or 0
  local starling = friend_data:get_current_starling()
  panel._new_unlock_slot = nil
  if 0 < completed_count and level_count >= completed_count and friend_level_module:has_pending_new_unlock(friend_data.uid) then
    panel._new_unlock_slot = completed_count
  end
  for display_slot = 1, level_count do
    local level_index = display_slot - 1
    local display_level = level_index + 1
    if completed_count > level_index then
      local moonlet_data = moonlets_cs[level_index]
      local item = view.get_record_item(panel, display_slot, complete_item_cls, panel._item_activated)
      item:refresh_view(display_level, moonlet_data, is_bestie, level_index)
    elseif level_index == completed_count then
      local item = view.get_record_item(panel, display_slot, in_progress_item_cls, panel._item_progress)
      item:refresh_view(starling, friend_data, level_index)
    else
      local item = view.get_record_item(panel, display_slot, in_progress_item_cls, panel._item_progress)
      item:refresh_view(nil, friend_data, level_index)
    end
    local entry = panel._record_item_list[display_slot]
    if entry and entry.item and entry.item.rect_trans then
      entry.item.rect_trans:SetSiblingIndex(display_slot - 1)
    end
  end
end

function view.on_disable_panel(panel)
  _hide_row_templates(panel)
  _clear_dynamic_content_children(panel)
  panel._is_closing = false
  panel._pending_page = nil
  panel._new_unlock_slot = nil
end

function view.bind_close_btn_with_out_anim(panel)
  if is_null(panel._btn_close) then
    return
  end
  panel:bind_callback(panel._btn_close, pack(panel, view.play_close_anim))
  panel:bind_input_and_btn(ActionType.Act.Back, panel._btn_close)
end

local function _on_close_anim_end(panel)
  if not panel._is_closing then
    return
  end
  panel._is_closing = false
  if is_null(panel.game_obj) then
    return
  end
  panel:close_self()
end

function view.play_close_anim(panel)
  if panel._is_closing then
    return
  end
  if is_null(panel._animator) then
    panel:close_self()
    return
  end
  panel._is_closing = true
  panel._animator:SetTrigger(ANIM_TRIGGER_OUT)
  panel._animator:Update(0)
  local state_info = panel._animator:IsInTransition(0) and panel._animator:GetNextAnimatorStateInfo(0) or panel._animator:GetCurrentAnimatorStateInfo(0)
  CsCoroutineManagerUtil.Invoke(state_info.length, pack(panel, _on_close_anim_end))
end

function view.get_page_max(panel)
  return panel._summary_unlocked and PAGE_SUMMARY or PAGE_RECORD
end

function view.on_page_left_click(panel)
  local page_max = view.get_page_max(panel)
  local target = panel._cur_page - 1
  if PAGE_LOOP then
    if target < PAGE_MIN then
      target = page_max or target
    end
  else
    target = math.max(target, PAGE_MIN)
  end
  view.request_switch_page(panel, target)
end

function view.on_page_right_click(panel)
  local page_max = view.get_page_max(panel)
  local target = panel._cur_page + 1
  if PAGE_LOOP then
    if page_max < target then
      target = PAGE_MIN or target
    end
  else
    target = math.min(target, page_max)
  end
  view.request_switch_page(panel, target)
end

local function _sample_new_unlock_anim_begin(go)
  local anim_cmpt = UIUtil.find_cmpt(go, nil, typeof(Animation))
  if is_null(anim_cmpt) then
    return
  end
  anim_cmpt:Play()
  anim_cmpt:Sample()
  anim_cmpt:Stop()
end

local function _try_play_new_unlock_anim(panel)
  local slot = panel._new_unlock_slot
  if slot == nil then
    return
  end
  local entry = panel._record_item_list[slot]
  if entry == nil or entry.item == nil then
    return
  end
  local go = _get_game_object(entry.trans)
  if is_null(go) or not go.activeInHierarchy then
    return
  end
  panel._new_unlock_slot = nil
  friend_level_module:consume_new_unlock(panel._cur_friend_data and panel._cur_friend_data.uid)
  _sample_new_unlock_anim_begin(go)
  CsCoroutineManagerUtil.Invoke(NEW_UNLOCK_ANIM_DELAY, function()
    if panel._record_item_list[slot] ~= entry then
      return
    end
    if is_null(_get_game_object(entry.trans)) then
      return
    end
    entry.item:play_anim(NEW_UNLOCK_ANIM)
  end)
end

function view.switch_page(panel, page)
  local page_max = view.get_page_max(panel)
  if page > page_max then
    page = PAGE_RECORD
  end
  panel._cur_page = page
  panel._ui_state_group:SetState(page)
  if page == PAGE_SUMMARY then
    view.ensure_summary_page(panel)
  else
    _try_play_new_unlock_anim(panel)
  end
end

local function _commit_pending_page(panel)
  local page = panel._pending_page
  if page == nil then
    return
  end
  panel._pending_page = nil
  if is_null(panel.game_obj) then
    return
  end
  view.switch_page(panel, page)
end

function view.on_switch_anim_event(panel, event_name)
  local page = panel._pending_page
  if page == nil then
    return
  end
  local cfg = SWITCH_ANIM[page]
  if cfg == nil or cfg.event ~= event_name then
    return
  end
  _commit_pending_page(panel)
end

function view.request_switch_page(panel, page)
  if panel._pending_page ~= nil then
    return
  end
  local cfg = SWITCH_ANIM[page]
  if not panel._use_switch_content_anim or cfg == nil or is_null(panel._animator) or page == panel._cur_page then
    view.switch_page(panel, page)
    return
  end
  panel._pending_page = page
  panel._animator:SetTrigger(cfg.trigger)
  CsCoroutineManagerUtil.Invoke(SWITCH_ANIM_TIMEOUT, function()
    if panel._pending_page ~= page then
      return
    end
    _commit_pending_page(panel)
  end)
end

function view.ensure_summary_page(panel)
  if panel._summary_page == nil then
    panel._summary_page = panel:add_panel(summary_page_cls, panel._trans_summary_page)
  end
  if panel._summary_dirty and panel._cur_friend_data then
    panel._summary_dirty = false
    panel._summary_page:refresh_view(panel._cur_friend_data)
  end
end

friend_level_module.interact_record_view = view
friend_interact_record_view = view
return friend_level_module or {}
