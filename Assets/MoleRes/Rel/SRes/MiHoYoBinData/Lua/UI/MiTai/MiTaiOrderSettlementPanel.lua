local M = G.Class("MiTaiOrderSettlementPanel", "UI/MiTai/MiTaiBasePanel")
local base = M.super

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MiTai/MiTaiOrderSettlementPanel"
end

function M:on_create()
  base.on_create(self)
  self:bind_callbacks()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:refresh_panel(result_code)
  self._result_code = result_code
  UIUtil.set_active(self._btn_continue_settlement, true)
  UIUtil.set_active(self._trans_continue_settle_tips, true)
end

function M:bind_callbacks()
  self:bind_callback(self._btn_continue_settlement, pack(self, M._on_btn_continue))
end

function M:_on_btn_continue()
  local result_code = self._result_code
  UIUtil.set_active(self._btn_continue_settlement, false)
  UIUtil.set_active(self._trans_continue_settle_tips, false)
  self:set_on_exit_anim_done(function()
    self.holder:close_self()
    if result_code == 5 then
      CsCoroutineManagerUtil.InvokeAfterFrames(15, function()
        CsMiTaiModuleUtil.PlayMiTaiPlayerGetItemAnim()
      end)
    end
  end)
  self:change_state(EUIState.Hide)
end

return M
