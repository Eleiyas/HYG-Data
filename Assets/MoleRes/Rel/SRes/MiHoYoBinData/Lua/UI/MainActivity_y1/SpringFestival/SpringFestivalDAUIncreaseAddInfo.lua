local M = G.Class("SpringFestivalDAUIncreaseAddInfo", G.UIWindow)
local base = G.UIWindow
local FLY_TIME = 0.65
local ANIM_IN = "anim_springfestival_dauincreasedialog__addinfo_in"
local ANIM_OUT = "anim_springfestival_dauincreasedialog__addinfo_out"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_DAUIncreaseDialog_AddInfo"
  self.config.type = EUIType.Info
  self._from_position = nil
  self._dt_x = nil
  self._dt_y = nil
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh()
end

function M:on_disable()
  base.on_disable(self)
  self:_kill_fly_tween()
end

function M:_refresh()
  local data = self:get_extra_data() or {}
  self._from_position = data.from_position
  if self._from_position == nil then
    Logger.LogWarning("[SpringFestivalDAUIncreaseAddInfo] from_position is nil, skip play")
    self:close_self()
    return
  end
  self._trans_fire:SetPosition(self._from_position.x, self._from_position.y, self._from_position.z)
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    self:play_anim(ANIM_IN, function()
      self:_fly()
    end)
  end)
end

function M:_fly()
  self:_kill_fly_tween()
  local target = self:_get_fly_target_local_pos()
  if target == nil then
    self:_on_fly_end()
    return
  end
  self._dt_x = self._trans_fire:DOAnchorPosX(target.x, FLY_TIME):SetEase(Ease.OutSine)
  self._dt_y = self._trans_fire:DOAnchorPosY(target.y, FLY_TIME):SetEase(Ease.OutCubic)
  self._dt_y:OnComplete(function()
    self:_on_fly_end()
  end)
end

function M:_get_fly_target_local_pos()
  local btn_trans = self:_get_activity_center_btn_trans()
  if is_null(btn_trans) then
    return nil
  end
  local parent_rect = self._trans_fire.parent
  if is_null(parent_rect) then
    return nil
  end
  local ui_camera = UIManagerInstance.ui_camera
  local screen_pos = CsUIUtil.WorldToScreenPoint(ui_camera, btn_trans.position)
  local success, local_pos = RectTransformUtility.ScreenPointToLocalPointInRectangle(parent_rect, Vector2(screen_pos.x, screen_pos.y), ui_camera)
  if not success then
    return nil
  end
  return local_pos
end

function M:_get_activity_center_btn_trans()
  local main_page = UIManagerInstance:is_show_by_guid(UIManagerInstance.main_page_guid)
  if is_null(main_page) then
    return nil
  end
  local entrance_panel = main_page:get_panel(MainPanelType.EntranceButton)
  if entrance_panel == nil then
    return nil
  end
  return entrance_panel:get_activity_center_btn_trans()
end

function M:_on_fly_end()
  self:play_anim(ANIM_OUT, function()
    self:close_self()
  end)
end

function M:_kill_fly_tween()
  if self._dt_x ~= nil then
    self._dt_x:Kill()
    self._dt_x = nil
  end
  if self._dt_y ~= nil then
    self._dt_y:Kill()
    self._dt_y = nil
  end
end

return M
