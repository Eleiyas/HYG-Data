local M = G.Class("WorldEditorRoomNormalViewPanel", G.UIPanel)
local base = G.UIPanel

local function get_runtime_editor()
  local rt = RuntimeWorldEditor.Current
  if is_null(rt) then
    return nil
  end
  return rt
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_arrow_left, pack(self, M._on_arrow_left))
  self:bind_callback(self._btn_arrow_right, pack(self, M._on_arrow_right))
  self:bind_callback(self._btn_overview, pack(self, M._on_enter_overview))
  self._room_togs = {}
  self._floor_plan_go = nil
  self._floor_plan_path = nil
end

function M:on_enable()
  base.on_enable(self)
  self:_ensure_floor_plan()
  self._last_room_id = nil
  self:_refresh_room_topbar()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.WorldEditorBrushExpand, self._btn_arrow_right)
  self:bind_input_and_btn(ActionType.Act.WorldEditorBrushShrink, self._btn_arrow_left)
end

function M:update(_delta_time)
  if not self.is_active then
    return
  end
  self:_refresh_room_topbar()
end

function M:_ensure_floor_plan()
  if is_null(self._trans_floor_plan) then
    return
  end
  local path = EditorViewModeController.GetIndoorFloorPlanPrefabPath() or ""
  if path == self._floor_plan_path then
    return
  end
  self:_clear_floor_plan()
  self._floor_plan_path = path
  if not string.is_valid(path) then
    return
  end
  self:load_prefab_async(path, function(go)
    if is_null(go) then
      return
    end
    if is_null(self.trans) then
      UIUtil.destroy_go(go)
      return
    end
    if self._floor_plan_path ~= path then
      UIUtil.destroy_go(go)
      return
    end
    self._floor_plan_go = go
    self:_collect_room_togs(go)
    self._last_room_id = nil
    if self.is_active then
      self:_refresh_room_topbar()
    end
  end, self._trans_floor_plan, true)
end

function M:_clear_floor_plan()
  if not is_null(self._floor_plan_go) then
    UIUtil.destroy_go(self._floor_plan_go)
  end
  self._floor_plan_go = nil
  self._room_togs = {}
end

function M:_collect_room_togs(go)
  self._room_togs = {}
  if is_null(go) then
    return
  end
  local togs_trans = go.transform:Find("togs")
  if is_null(togs_trans) then
    Logger.LogError("[WorldEditorRoomNormalViewPanel] floor plan prefab has no 'togs' node")
    return
  end
  for i = 0, togs_trans.childCount - 1 do
    local child = togs_trans:GetChild(i)
    local tog = UIUtil.find_cmpt(child, nil, typeof(ToggleEx))
    if not_null(tog) then
      table.insert(self._room_togs, tog)
    end
  end
end

function M:_refresh_room_topbar()
  local count = EditorViewModeController.GetIndoorRoomCount()
  local ref_pos = CsGameplayUtilitiesCameraUtil.TryGetFollowPosition()
  local room_id = EditorViewModeController.GetActiveRoomIdValue(ref_pos)
  local ordinal = EditorViewModeController.GetRoomOrdinalOf(room_id)
  if self._last_room_id == room_id and self._last_count == count and self._last_ordinal == ordinal then
    return
  end
  self._last_room_id = room_id
  self._last_count = count
  self._last_ordinal = ordinal
  if not_null(self._txt_room_info) then
    UIUtil.set_text(self._txt_room_info, string.format("%d/%d", ordinal, count))
  end
  if not_null(self._txt_room_name) then
    UIUtil.set_text(self._txt_room_name, self:_get_room_display_name(room_id, ordinal))
  end
  self:_sync_room_tog(ordinal)
end

function M:_get_room_display_name(room_id, ordinal)
  local override = EditorViewModeController.GetRoomNameOverride(room_id)
  if override ~= nil and override ~= "" then
    return override
  end
  return UIUtil.get_text_by_id("WorldEditor_Room_DefaultName", ordinal)
end

function M:_sync_room_tog(ordinal)
  for i, tog in ipairs(self._room_togs) do
    if not_null(tog) then
      tog.isOnValue = i == ordinal
    end
  end
end

function M:_on_arrow_left()
  local rt = get_runtime_editor()
  if rt then
    rt:StepRoomKeepingMode(-1)
  end
end

function M:_on_arrow_right()
  local rt = get_runtime_editor()
  if rt then
    rt:StepRoomKeepingMode(1)
  end
end

function M:_on_enter_overview()
  local rt = get_runtime_editor()
  if rt then
    rt:EnterOverview()
  end
end

return M
