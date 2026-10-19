local CodexScoreProgressItem = require("UI/Codex/CodexScoreProgressItem")
local M = G.Class("CodexScoreProgressItemFinal", CodexScoreProgressItem)
local base = CodexScoreProgressItem

function M:init()
  base.init(self)
  self._dot_anims = {}
end

function M:on_create()
  base.on_create(self)
  self._dot_anims = self:_collect_dotween_anims()
end

function M:_collect_dotween_anims()
  local anims = {}
  local dt_anims = self.trans:GetComponents(typeof(DOTweenAnimation))
  if is_null(dt_anims) then
    return anims
  end
  for i = 0, dt_anims.Length - 1 do
    local dt = dt_anims[i]
    if not_null(dt) then
      anims[dt.id] = dt
    end
  end
  return anims
end

function M:refresh(total_score_data, rewarded_id_table, load_proxy)
  self:refresh_by_score(total_score_data.TotalScore, total_score_data, rewarded_id_table, load_proxy)
end

function M:refresh_by_score(score, total_score_data, rewarded_id_table, load_proxy, show_reward)
  base.refresh_by_score(self, score, total_score_data, rewarded_id_table, load_proxy, show_reward)
  local is_reached = self:get_state() ~= CodexScoreProgressItem.State.UNCOMPLETED
  if not_null(self._trans_anim_final) then
    UIUtil.set_active(self._trans_anim_final, is_reached)
  end
end

function M:play_final_anim()
  self:_play_dotween("bigger")
end

function M:play_smaller()
  self:_play_dotween("smaller")
end

function M:_play_dotween(id)
  local dt = self._dot_anims[id]
  if is_null(dt) or is_null(dt.tween) then
    return
  end
  dt.tween:Restart()
  dt.tween:PlayForward()
end

function M:set_dot_scale(scale)
  if not_null(self._trans_dot) then
    self._trans_dot.transform:SetLocalScale(scale, scale, scale)
  end
end

function M:clear_cache()
  if base.clear_cache then
    base.clear_cache(self)
  end
  self._dot_anims = {}
end

return M
