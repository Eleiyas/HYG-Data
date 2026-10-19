local M = G.Class("SpringFestivalWishSupportInfo", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestivalWishSupportInfo"
  self.config.type = EUIType.Info
  self.config.handle_input = true
  self._callback = nil
  self._from_target = nil
  self._to_world_pos = nil
  self._dt = nil
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh()
end

function M:on_disable()
  base.on_disable(self)
  if not is_null(self._dt) then
    self._dt:Kill()
    self._dt:OnComplete(nil)
    self._dt = nil
  end
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:_refresh()
  local data = self:get_extra_data() or {}
  self._callback = data.callback
  self._from_target = data.from_target
  self._to_world_pos = data.to_world_pos
  if is_null(self._from_target) then
    Logger.LogWarning("[SpringFestivalWishSupportInfo] from_target is nil, skip play")
    self:_exit()
    return
  end
  self._trans_fire:SetPosition(self._from_target:GetPosition())
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    self:play_anim("anui_springfestival_wishsupportinfo_in", function()
      self:_fly()
    end)
  end)
end

function M:_fly()
  if not is_null(self._dt) then
    self._dt:Kill()
    self._dt:OnComplete(nil)
    self._dt = nil
  end
  local target = self:_project_world_to_local(self._to_world_pos)
  if target == nil then
    self:_on_fly_end()
    return
  end
  self._trans_fire:DOAnchorPosX(target.x, 0.65):SetEase(Ease.OutSine)
  self._dt = self._trans_fire:DOAnchorPosY(target.y, 0.65):SetEase(Ease.OutCubic)
  self._dt:OnComplete(function()
    self:_on_fly_end()
  end)
end

function M:_project_world_to_local(world_pos)
  if is_null(world_pos) then
    return nil
  end
  local camera = CsGameplayUtilitiesCameraUtil.GetMainCamera()
  if is_null(camera) then
    return nil
  end
  local screen_pos = CsUIUtil.WorldToScreenPoint(camera, world_pos)
  if screen_pos.z <= 0 then
    return nil
  end
  local parent_rect = self._trans_fire.parent
  if is_null(parent_rect) then
    return nil
  end
  local success, local_pos = RectTransformUtility.ScreenPointToLocalPointInRectangle(parent_rect, Vector2(screen_pos.x, screen_pos.y), UIManagerInstance.ui_camera)
  if not success then
    return nil
  end
  return local_pos
end

function M:_on_fly_end()
  self:play_anim("anui_springfestival_wishsupportinfo_out", function()
    self:_exit()
  end)
end

function M:_exit()
  if self._callback then
    self._callback()
    self._callback = nil
  end
  self:close_self()
end

return M
