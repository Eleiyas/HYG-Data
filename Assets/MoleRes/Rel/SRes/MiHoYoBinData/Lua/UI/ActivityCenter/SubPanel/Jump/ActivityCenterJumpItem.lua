local M = G.Class("ActivityCenterJumpItem", G.UIPanel)
local base = G.UIPanel
local default_jump_cd = 0.5

function M:init()
  base.init(self)
  self._jump_id = 0
  self._jump_cooldown = 0
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn, pack(self, M._on_click))
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if self._jump_cooldown > 0 then
    self._jump_cooldown = self._jump_cooldown - deltaTime
  end
end

function M:refresh(jump_id, btn_text)
  self._jump_id = jump_id or 0
  if not is_null(self._txt) then
    UIUtil.set_text(self._txt, btn_text or "")
  end
end

function M:_on_click()
  if self._jump_cooldown > 0 then
    return
  end
  self._jump_cooldown = default_jump_cd
  activity_center_module:request_jump(self._jump_id)
end

function M:set_btn_enable(enable)
  self._btn.interactable = enable
end

return M
