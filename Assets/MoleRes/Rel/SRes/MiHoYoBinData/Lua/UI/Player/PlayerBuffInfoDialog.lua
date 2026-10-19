local M = G.Class("PlayerBuffInfoDialog", G.UIWindow)
local base = G.UIWindow
local DIALOG_OFFSET_Y = 80

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Player/PlayerBuffInfoDialog"
  self.config.type = EUIType.Dialog
  self._buff = nil
  self._buff_id = 0
  self._buff_cfg = nil
  self._duration = 0
  self._countdown = 0
  self._last_countdown = 0
  self._parent_trans = nil
  self._countdown_txt_id = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_init_data()
  self:_refresh_ui()
  self:_register_buff_events(true)
end

function M:on_disable()
  base.on_disable(self)
  self:_register_buff_events(false)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if self._duration > 0 and 0 < self._countdown then
    self._countdown = self._countdown - deltaTime
    if self._last_countdown - self._countdown >= 1 then
      self:_refresh_countdown_ui()
    end
  end
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
end

function M:_init_data()
  if self._extra_data then
    self._buff = self._extra_data.buff
    self._parent_trans = self._extra_data.parent
    if not_null(self._buff) then
      self._buff_id = self._buff.Id
      self._buff_cfg = CsGameplayUtilitiesBuffUtil.GetBuffConfig(self._buff_id)
    end
  end
end

function M:_register_buff_events(is_register)
  if is_register then
    function self._buff_change_action(entity, buff_id, _last_count, _new_count)
      if entity.Guid ~= EntityUtil.get_player_entity_guid() then
        return
      end
      if buff_id == self._buff_id then
        self._buff = CsGameplayUtilitiesBuffUtil.GetPlayerActiveBuffById(buff_id)
        self:_refresh_buff_ui()
      end
    end
    
    function self._buff_remove_action(entity, buff_id, _reason)
      if entity.Guid ~= EntityUtil.get_player_entity_guid() then
        return
      end
      if buff_id == self._buff_id then
        self:close_self()
      end
    end
    
    CsGameplayUtilitiesBuffUtil.RegisterOnBuffStackCountChanged(true, self._buff_change_action)
    CsGameplayUtilitiesBuffUtil.RegisterOnBuffRemoved(true, self._buff_remove_action)
  else
    if self._buff_change_action then
      CsGameplayUtilitiesBuffUtil.RegisterOnBuffStackCountChanged(false, self._buff_change_action)
      self._buff_change_action = nil
    end
    if self._buff_remove_action then
      CsGameplayUtilitiesBuffUtil.RegisterOnBuffRemoved(false, self._buff_remove_action)
      self._buff_remove_action = nil
    end
  end
end

function M:_refresh_ui()
  if is_null(self._buff_cfg) then
    self:close_self()
    return
  end
  self:_refresh_cfg_ui()
  self:_refresh_buff_ui()
  self:refresh_content_pos()
end

function M:_refresh_cfg_ui()
  if is_null(self._buff_cfg) then
    return
  end
  UIUtil.set_text(self._txt_name, self._buff_cfg.BuffName)
  UIUtil.set_text(self._txt_info, player_module:get_buff_effect_text(self._buff_id))
  self._state_group_type:SetState(self._buff_cfg.IconShowType)
end

function M:_refresh_buff_ui()
  local is_show = not_null(self._buff)
  if not is_show then
    self:close_self()
    return
  end
  self._duration = self._buff.Duration
  local stack_count = self._buff.StackCount
  UIUtil.set_active(self._txt_count, 1 < stack_count)
  UIUtil.set_active(self._txt_countdown, self._duration > 0)
  if 1 < stack_count and self._duration > 0 then
    UIUtil.set_text_by_id(self._txt_count, "Buff_Remaining_Stacks", tostring(stack_count))
    self._countdown = CsGameplayUtilitiesBuffUtil.GetPlayerBuffRemainingTime(self._buff_id)
    self._countdown_txt_id = "Buff_Stack_Time_Remaining"
    self:_refresh_countdown_ui()
  else
    if 1 < stack_count then
      UIUtil.set_text_by_id(self._txt_count, "Buff_Remaining_Uses", tostring(stack_count))
    end
    if self._duration > 0 then
      self._countdown = CsGameplayUtilitiesBuffUtil.GetPlayerBuffRemainingTime(self._buff_id)
      self._countdown_txt_id = "Buff_Time_Remaining"
      self:_refresh_countdown_ui()
    end
  end
end

function M:_refresh_countdown_ui()
  self._last_countdown = self._countdown
  if self._countdown <= 0 then
    UIUtil.set_text_by_id(self._txt_countdown, self._countdown_txt_id, "0")
    return
  end
  UIUtil.set_text_by_id(self._txt_countdown, self._countdown_txt_id, tostring(math.floor(self._countdown)))
end

function M:refresh_content_pos()
  if is_null(self._parent_trans) then
    return
  end
  local x, y, z = self._parent_trans:GetPosition()
  self._trams_content:SetPosition(x, y, z)
end

return M
