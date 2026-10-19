local base = require("UI/Gacha/GachaPoolPanelBase")
local M = G.Class("GachaPremiumPoolPanel", base)

function M:init()
  base.init(self)
  self.config.prefab_path = GachaConst.panel_path.pool_premium
end

function M:_on_create_extend()
  if not_null(self._btn_play_video) then
    self:bind_callback(self._btn_play_video, pack(self, M._on_btn_video_click))
  end
  if not_null(self._btn_draw_once) then
    self:bind_callback(self._btn_draw_once, pack(self, M._on_btn_single_click))
  end
  if not_null(self._btn_draw_ten) then
    self:bind_callback(self._btn_draw_ten, pack(self, M._on_btn_ten_click))
  end
end

function M:_refresh_extend()
  self:_refresh_draw_item()
  self:_try_auto_play_video()
end

function M:_refresh_draw_item()
  self:refresh_draw_ticket_price(GachaConst.draw_count.once, self._txt_num_once, self._img_icon_coin_once)
  self:refresh_draw_ticket_price(GachaConst.draw_count.ten, self._txt_num_ten_disc, self._img_icon_coin_ten)
end

function M:_try_auto_play_video()
  local video_id = self._activity_cfg and self._activity_cfg.advvideoid or 0
  UIUtil.set_active(self._btn_play_video, 0 < video_id)
  local auto_video_id = self._activity_cfg and self._activity_cfg.videoautoplay or 0
  if 0 < auto_video_id and not gacha_module:is_video_played(auto_video_id) then
    gacha_module:mark_video_played(auto_video_id)
    self:_play_video(auto_video_id)
  end
end

function M:_on_btn_video_click()
  if self._activity_cfg ~= nil and 0 < (self._activity_cfg.advvideoid or 0) then
    self:_play_video(self._activity_cfg.advvideoid)
  end
end

function M:_on_btn_single_click()
  self:do_draw(false)
end

function M:_on_btn_ten_click()
  self:do_draw(true)
end

function M:_play_video(video_id)
  local task = VideoTask()
  if video_id and 0 < video_id and not task:InitByCfgId(video_id) then
    return
  end
  task.isLoop = false
  task.canSkip = true
  EventCenter.Broadcast(EventID.LuaShowFullScreenVideo, task)
end

return M
