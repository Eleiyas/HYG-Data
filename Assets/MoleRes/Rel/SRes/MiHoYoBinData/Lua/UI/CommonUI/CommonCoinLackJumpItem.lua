local M = G.Class("CommonCoinLackJumpItem", G.UIBase)
local base = G.UIBase
local STATE_JUMPABLE = 0
local STATE_NOT_JUMPABLE = 1

function M:init()
  base.init(self)
  self._jump_callback = nil
  self._ui_state_group_jump = nil
  self._txt_title = nil
  self._btn_go_to = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_destroy()
  self._jump_callback = nil
  base.on_destroy(self)
end

function M:_add_ui_listener()
  if not_null(self._btn_go_to) then
    self:bind_callback(self._btn_go_to, pack(self, M._on_btn_go_to_click))
  end
end

function M:set_data(data)
  if data == nil then
    return
  end
  if not_null(self._txt_title) then
    UIUtil.set_text_by_id(self._txt_title, data.text_key)
  end
  local jumpable = type(data.jump) == "function"
  self._jump_callback = jumpable and data.jump or nil
  if not_null(self._ui_state_group_jump) then
    self._ui_state_group_jump:SetState(jumpable and STATE_JUMPABLE or STATE_NOT_JUMPABLE)
  end
  if not_null(self._btn_go_to) then
    self._btn_go_to.interactable = jumpable
  end
end

function M:_on_btn_go_to_click()
  if self._jump_callback ~= nil then
    self._jump_callback()
  end
end

return M
