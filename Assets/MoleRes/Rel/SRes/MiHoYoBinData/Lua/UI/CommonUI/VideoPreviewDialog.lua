local M = G.Class("VideoPreviewDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CommonUI/VideoPreviewDialog"
  self.config.type = EUIType.Dialog
  self._playing_id = 0
  self._video_task = nil
  self._ctx = nil
  self._btn_bg = nil
  self._txt_title = nil
  self._img_video = nil
  self._txt = nil
  self._btn_start = nil
  self._btn_close_popup = nil
end

function M:on_create()
  base.on_create(self)
  self:_bind_listeners()
end

function M:on_enable()
  base.on_enable(self)
  self._ctx = self:get_extra_data() or {}
  self:_refresh_ui()
  if self._ctx.auto_play ~= false then
    self:_start_play()
  end
end

function M:on_disable()
  base.on_disable(self)
  self:_stop_play()
end

function M:on_destroy()
  self._ctx = nil
  base.on_destroy(self)
end

function M:_bind_listeners()
  if not_null(self._btn_bg) then
    self:bind_callback(self._btn_bg, pack(self, M._on_close))
  end
  if not_null(self._btn_close_popup) then
    self:bind_callback(self._btn_close_popup, pack(self, M._on_close))
  end
  if not_null(self._btn_start) then
    self:bind_callback(self._btn_start, pack(self, M._on_btn_start_click))
  end
end

function M:_refresh_ui()
  local ctx = self._ctx
  if not_null(self._txt_title) then
    if ctx.title then
      UIUtil.set_text(self._txt_title, ctx.title)
    elseif ctx.title_text_id then
      UIUtil.set_text(self._txt_title, UIUtil.get_text_by_id(ctx.title_text_id))
    else
      UIUtil.set_text(self._txt_title, "")
    end
  end
  if not_null(self._txt) then
    if ctx.desc then
      UIUtil.set_text(self._txt, ctx.desc)
    elseif ctx.desc_text_id then
      UIUtil.set_text(self._txt, UIUtil.get_text_by_id(ctx.desc_text_id))
    else
      UIUtil.set_text(self._txt, "")
    end
  end
  if not_null(self._btn_start) then
    UIUtil.set_active(self._btn_start.gameObject, ctx.auto_play == false)
  end
end

function M:_start_play()
  if self._playing_id ~= 0 then
    return
  end
  local ctx = self._ctx
  if not ctx then
    return
  end
  local task = VideoTask()
  if ctx.video_cfg_id and 0 < ctx.video_cfg_id then
    if not task:InitByCfgId(ctx.video_cfg_id) then
      return
    end
  elseif ctx.video_path then
    task.displayType = DisplayType.LocalPartial
    task.path = ctx.video_path
  else
    return
  end
  task.screenImage = self._img_video
  task.isLoop = ctx.is_loop == true
  task.canSkip = ctx.can_skip ~= false
  task.onFinishPlay = pack(self, M._on_video_finish)
  self._video_task = task
  self._playing_id = CsVideoManagerUtil.Play(task)
end

function M:_stop_play()
  if self._playing_id ~= 0 then
    CsVideoManagerUtil.Stop(self._playing_id)
    self._playing_id = 0
  end
  if self._video_task then
    self._video_task:ClearCallback()
    self._video_task = nil
  end
end

function M:_on_video_finish()
  self._playing_id = 0
  if self._ctx and self._ctx.on_video_finish then
    self._ctx.on_video_finish()
  end
end

function M:_on_btn_start_click()
  if self._playing_id == 0 then
    self:_start_play()
  end
end

function M:_on_close()
  self:_stop_play()
  local on_close = self._ctx and self._ctx.on_close
  UIManagerInstance:close(self.guid)
  if on_close then
    on_close()
  end
end

return M
