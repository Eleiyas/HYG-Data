local M = G.Class("QteGameRoundInfoDialog", G.UIWindow)
local base = G.UIWindow
local HEAD_ITEM_CLS = "UI/QteGame/QteGameHeadInfoItem"
local AUTO_CLOSE_SECONDS = 3

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/QteGame/QteGameRoundInfoDialog"
  self.config.type = EUIType.Dialog
  self._context = nil
  self._winner_item = nil
  self._round_items = {}
  self._callback_invoked = false
  self._remain_time = 0
end

function M:on_create()
  base.on_create(self)
  self._winner_item = self:add_panel(HEAD_ITEM_CLS, self._winner_item_trans)
end

function M:on_enable()
  base.on_enable(self)
  self._context = self:get_extra_data() or {}
  self._callback_invoked = false
  self._remain_time = AUTO_CLOSE_SECONDS
  self:_refresh()
end

function M:on_close()
  base.on_close(self)
  self:_invoke_callback()
end

function M:update(delta_time)
  base.update(self, delta_time)
  if self._remain_time <= 0 then
    return
  end
  self._remain_time = self._remain_time - delta_time
  if self._remain_time <= 0 then
    self:close_self()
  end
end

function M:_refresh()
  local data = self._context
  local npc_id = self:_get_npc_id()
  local winner_name = self:_get_winner_name(data.currentRoundIsPlayerWin, npc_id)
  self._winner_item:set_result(true, data.currentRoundIsPlayerWin == true, npc_id)
  UIUtil.set_text(self._txt_name_dynamic, winner_name or "")
  local total_round = math.max(0, tonumber(data.totalRound) or 0)
  self:_ensure_round_items(total_round)
  local finished_count = data.roundWinList and data.roundWinList.Count or 0
  for index = 1, total_round do
    local item = self._round_items[index]
    item:set_active(true)
    local is_finished = index <= finished_count
    local is_player_win = is_finished and data.roundWinList[index - 1] == true
    local play_result_anim = is_finished and index == finished_count
    item:set_result(is_finished, is_player_win, npc_id, false, play_result_anim)
  end
  for index = total_round + 1, #self._round_items do
    self._round_items[index]:set_active(false)
  end
end

function M:_get_npc_id()
  local interaction_cfg = ExcelDataUtil.get_value(typeof(BNpcSpecialInteractionCfg), self._context.specialInteractionId)
  if is_null(interaction_cfg) then
    return 0
  end
  return interaction_cfg.npcid
end

function M:_get_winner_name(is_player_win, npc_id)
  if is_player_win then
    return player_module:get_player_name()
  else
    return npc_module:get_npc_name_by_id(npc_id)
  end
end

function M:_ensure_round_items(count)
  for index = #self._round_items + 1, count do
    local trans = self._round_item_binder:AddItem(0, true)
    self._round_items[index] = self:add_panel(HEAD_ITEM_CLS, trans)
  end
end

function M:_invoke_callback()
  if self._callback_invoked then
    return
  end
  self._callback_invoked = true
  if self._context and self._context.onClose then
    self._context.onClose()
  end
end

return M
