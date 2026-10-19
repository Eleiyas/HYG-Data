local M = G.Class("JoyStickTriggerElement", G.PlayerControlInputElementBase)
local base = G.PlayerControlInputElementBase
local JoyStickDragProxy = typeof(CS.miHoYo.HYG.Input.JoyStickDragProxy)
local CanvasGroup = typeof(CS.UnityEngine.CanvasGroup)

function M:init()
  base.init(self)
  self._proxy = nil
  self._target_name = "SnowBall"
end

function M:on_create()
  base.on_create(self)
  self:_setup_proxy()
end

function M:on_enable()
  base.on_enable(self)
  if not is_null(self.canvas_group) then
    self.canvas_group.alpha = 1
  end
end

function M:on_disable()
  base.on_disable(self)
end

function M:_setup_proxy()
  local go = self.game_obj
  if is_null(go) then
    return
  end
  if is_null(self.canvas_group) then
    self.canvas_group = go:AddComponent(CanvasGroup)
  end
  self._proxy = go:GetComponent(JoyStickDragProxy)
  if is_null(self._proxy) then
    self._proxy = go:AddComponent(JoyStickDragProxy)
  end
  self._proxy:FindTargetByName(self._target_name)
  if not is_null(self._proxy.targetJoyStick) then
    self._proxy.targetJoyStick.uiCam = UIManagerInstance.ui_camera
  end
  
  function self._proxy.onBeginDrag()
    if not is_null(self.canvas_group) then
      self.canvas_group.alpha = 0
    end
  end
  
  function self._proxy.onEndDrag()
    if not is_null(self.canvas_group) then
      self.canvas_group.alpha = 1
    end
  end
end

return M
