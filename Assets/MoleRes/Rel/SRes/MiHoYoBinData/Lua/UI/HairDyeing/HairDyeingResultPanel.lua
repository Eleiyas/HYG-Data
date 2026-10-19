local M = G.Class("HairDyeingResultPanel", G.UIPanel)
local base = G.UIPanel
local tip_out_anim_delay = 3
local tip_out_anim_name = "anim_hairdyeingfailtip_out"

function M:init()
  base.init(self)
  self._on_close = nil
  self._tip_out_timer_co = nil
  self.config.prefab_path = hair_dyeing_module.ui_prefab_path.fail_result
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_confirm, pack(self, M._on_btn_close))
  self:bind_callback(self._btn_share, pack(self, M._on_btn_share))
end

function M:set_on_close(on_close)
  self._on_close = on_close
end

function M:on_enable()
  base.on_enable(self)
  self:_start_tip_out_timer()
end

function M:on_disable()
  self:_stop_tip_out_timer()
  base.on_disable(self)
end

function M:_start_tip_out_timer()
  self:_stop_tip_out_timer()
  self._tip_out_timer_co = CsCoroutineManagerUtil.Invoke(tip_out_anim_delay, function()
    self._tip_out_timer_co = nil
    if is_null(self.game_obj) or not self.is_active then
      return
    end
    self.binder:PlayAnimation(tip_out_anim_name)
  end)
end

function M:_stop_tip_out_timer()
  if self._tip_out_timer_co ~= nil then
    CsCoroutineManagerUtil.StopCoroutine(self._tip_out_timer_co)
    self._tip_out_timer_co = nil
  end
end

function M:_on_btn_close()
  self:_stop_tip_out_timer()
  if self._on_close ~= nil then
    self._on_close()
  end
end

function M:_on_btn_share()
end

return M
