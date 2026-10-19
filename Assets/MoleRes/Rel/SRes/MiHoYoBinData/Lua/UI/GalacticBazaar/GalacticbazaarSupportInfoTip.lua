local M = G.Class("GalacticbazaarSupportInfoTip", G.UIWindow)
local base = G.UIWindow
local AUTO_CLOSE_SEC = 3
local _cheer_table

local function _get_cheer_table()
  if _cheer_table == nil then
    _cheer_table = ExcelDataUtil.get_table(typeof(BPersonalCheerValueCfg))
  end
  return _cheer_table
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GalacticBazaar/GalacticbazaarSupportInfoTip"
  self.config.type = EUIType.Tip
  self._close_timer = nil
end

function M:on_create()
  base.on_create(self)
end

function M:on_open()
  base.on_open(self)
  self:_apply_notify(self:get_extra_data())
end

function M:on_disable()
  base.on_disable(self)
  self._close_timer = nil
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:_apply_notify(data)
  if is_null(data) then
    return
  end
  local uid = data.uid
  local cheer_count = data.num
  local player_name = self:_get_player_name(uid)
  UIUtil.set_text(self._txt_name_dynamic, player_name or tostring(uid or ""))
  UIUtil.set_text_by_id(self._txt_num_dynamic, "TOTAL_CHEER_TEXT", cheer_count or 0)
  local trigger_text = self:_get_cheer_trigger_text(cheer_count)
  if trigger_text and trigger_text ~= "" then
    UIUtil.set_text(self._txt_title_dynamic, trigger_text)
  else
    UIUtil.set_text(self._txt_title_dynamic, "")
  end
  self._close_timer = AUTO_CLOSE_SEC
end

function M:_get_cheer_trigger_text(cheer_count)
  local count = tonumber(cheer_count)
  if not count then
    return nil
  end
  local cheer_table = _get_cheer_table()
  if not cheer_table then
    return nil
  end
  local best_text, best_value
  for _, row in pairs(cheer_table) do
    local reached = row.cheervaluereached
    if reached ~= nil and count >= reached and (best_value == nil or best_value < reached) then
      best_value = reached
      best_text = row.triggertext
    end
  end
  return best_text
end

function M:_get_player_name(uid)
  if uid == nil then
    return nil
  end
  local guid = EntityUtil.get_player_entity_guid_by_uid(uid)
  if EntityUtil.is_valid(guid) then
    return EntityUtil.get_display_name_by_guid(guid)
  end
  return nil
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if not self._close_timer then
    return
  end
  self._close_timer = self._close_timer - deltaTime
  if self._close_timer <= 0 then
    self._close_timer = nil
    self:close_self()
  end
end

return M
