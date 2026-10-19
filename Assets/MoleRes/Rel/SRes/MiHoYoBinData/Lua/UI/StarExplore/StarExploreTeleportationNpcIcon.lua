local M = G.Class("StarExploreTeleportationNpcIcon", G.UIPanel)
local base = G.UIPanel

local function _is_npc_unlocked(npc_id)
  if npc_id == nil or npc_id == 0 then
    return false
  end
  if CsNpcInvitationModuleUtil.IsNull and CsNpcInvitationModuleUtil.IsNull() then
    return false
  end
  local invitation_data = CsNpcInvitationModuleUtil.GetInvitationData(npc_id)
  if invitation_data == nil then
    return false
  end
  local invitation_status = CsNpcInvitationModuleUtil.InvitationStatus
  if invitation_status ~= nil and invitation_status.Unacquired ~= nil then
    return invitation_data.Status ~= invitation_status.Unacquired
  end
  return invitation_data.Status ~= 1
end

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
end

function M:set_data(npc_id, is_encountered)
  local npc_cfg = ExcelDataUtil.get_value(typeof(BNpcCfg), npc_id)
  local icon = ""
  if npc_cfg ~= nil then
    icon = npc_cfg.iconnamesmall or ""
  end
  UIUtil.set_image(self._img_icon, icon, self:get_load_proxy())
  if is_encountered == nil then
    is_encountered = _is_npc_unlocked(npc_id)
  end
  if not is_null(self._ui_state_group) then
    self._ui_state_group:SetState(is_encountered and 1 or 0)
  end
end

return M
