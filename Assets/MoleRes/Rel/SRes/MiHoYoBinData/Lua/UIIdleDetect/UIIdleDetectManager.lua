local M = G.Class("UIIdleDetectManager")
local processor_cls = "UIIdleDetect/UIIdleTransactionProcessor"
local wait_main_page_idle_frame = 5

function M:__ctor()
  self._events = nil
  self:_add_event()
  self._processor = require(processor_cls)
  self._processor:init()
  self.main_idle = false
  self._cur_wait_main_page_idle_frame = 0
  self.main_active = false
  self._cur_wait_main_page_active_frame = 0
end

function M:destroy()
  self:_remove_event()
  self._processor:destroy()
end

function M:_add_event()
  self:_remove_event()
  self._events = {}
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function M:_remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function M:update(deltaTime)
  self._processor:tick(deltaTime)
  local current_is_idle = UIManagerInstance:is_main_page_in_idle()
  if current_is_idle then
    if not self.main_idle then
      self._cur_wait_main_page_idle_frame = self._cur_wait_main_page_idle_frame + 1
      if self._cur_wait_main_page_idle_frame >= wait_main_page_idle_frame then
        self.main_idle = true
        self._processor:on_main_page_become_idle()
      end
    end
  else
    if self.main_idle then
      self._processor:on_main_page_become_non_idle()
    end
    self.main_idle = false
    self._cur_wait_main_page_idle_frame = 0
  end
  local current_is_active = UIManagerInstance:is_main_page_on_enable()
  if current_is_active then
    if not self.main_active then
      self._cur_wait_main_page_active_frame = self._cur_wait_main_page_active_frame + 1
      if self._cur_wait_main_page_active_frame >= wait_main_page_idle_frame then
        self.main_active = true
        self._processor:on_main_page_become_active()
      end
    end
  else
    if self.main_active then
      self._processor:on_main_page_become_non_active()
    end
    self.main_active = false
    self._cur_wait_main_page_active_frame = 0
  end
end

function M:clear_on_back_home()
end

function M:force_show_favour_level_up_tip()
  if self._processor then
    self._processor:force_show_favour_level_up_tip()
  end
end

return M
