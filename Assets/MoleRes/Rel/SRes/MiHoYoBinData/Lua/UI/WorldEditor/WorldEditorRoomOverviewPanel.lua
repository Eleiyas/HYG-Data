local M = G.Class("WorldEditorRoomOverviewPanel", G.UIPanel)
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
  self:bind_callback(self._btn_overview_back, pack(self, M._on_overview_back))
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_overview()
end

function M:update(_delta_time)
  if not self.is_active then
    return
  end
  self:_refresh_overview()
end

function M:_refresh_overview()
  local count = EditorViewModeController.GetIndoorRoomCount()
  self._overview_items = self._overview_items or {}
  for i = 1, count do
    local entry = self._overview_items[i]
    if not entry then
      local trans = self._item_list:AddItem(0, false)
      local binder = not_null(trans) and UIUtil.find_cmpt(trans, nil, typeof(MonoViewBinder)) or nil
      entry = {
        trans = trans,
        txt = not_null(binder) and binder:GetComponentField("txt_name") or nil,
        btn_edit = not_null(binder) and binder:GetComponentField("btn_edit") or nil,
        room_id = 0
      }
      self._overview_items[i] = entry
      if entry.btn_edit then
        entry.btn_edit.onClick:AddListener(function()
          self:_on_overview_item_rename(entry)
        end)
      end
    end
    if not_null(entry.trans) then
      UIUtil.set_active(entry.trans, true)
      do
        local room_id = EditorViewModeController.GetOrderedRoomIdValueAt(i - 1)
        entry.room_id = room_id
        local new_name = self:_get_room_display_name(room_id, i)
        if entry.txt and entry.last_name ~= new_name then
          UIUtil.set_text(entry.txt, new_name)
          entry.last_name = new_name
        end
        self:_position_overview_item(entry.trans, room_id)
      end
    end
  end
  for i = count + 1, #self._overview_items do
    if not_null(self._overview_items[i].trans) then
      UIUtil.set_active(self._overview_items[i].trans, false)
    end
  end
end

function M:_position_overview_item(trans, room_id)
  local b = EditorViewModeController.GetRoomWorldBounds(room_id)
  local c = b.center
  local ux, uy = UIUtil.world_to_ui(c.x, b.max.y, c.z)
  trans.transform:SetLocalPosition(ux, uy, 0)
end

function M:_get_room_display_name(room_id, ordinal)
  local override = EditorViewModeController.GetRoomNameOverride(room_id)
  if override ~= nil and override ~= "" then
    return override
  end
  return UIUtil.get_text_by_id("WorldEditor_Room_DefaultName", ordinal)
end

function M:_on_overview_item_rename(entry)
  if entry.room_id == 0 then
    return
  end
  local ordinal = EditorViewModeController.GetRoomOrdinalOf(entry.room_id)
  common_ui_module:show_name_edit_dialog({
    title = UIUtil.get_text_by_id("WorldEditor_Room_RenameTitle", ordinal),
    confirm_btn_text = UIUtil.get_text_by_id("Common_Yes"),
    init_input_txt = self:_get_room_display_name(entry.room_id, ordinal),
    max_char_limit = 24,
    confirm_callback = function(new_name)
      EditorViewModeController.SetRoomNameOverride(entry.room_id, new_name)
      local display = self:_get_room_display_name(entry.room_id, ordinal)
      if entry.txt then
        UIUtil.set_text(entry.txt, display)
        entry.last_name = display
      end
    end
  })
end

function M:_on_overview_back()
  local rt = get_runtime_editor()
  if rt then
    rt:ExitOverviewToPrevious()
  end
end

return M
