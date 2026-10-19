local M = G.Class("BattlePassSeasonEndDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BattlePass/BattlePassSeasonEndDialog"
  self.config.type = EUIType.Dialog
  self._on_confirm_callback = nil
  self._txt_title = nil
  self._list_content = nil
  self._btn_close = nil
  self._btn_close_bg = nil
  self._btn_confim = nil
  self._item_pool = {}
end

function M:on_create()
  base.on_create(self)
  self:_bind_callbacks()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data()
  self._on_confirm_callback = data and data.on_confirm or nil
  self:_refresh_task_list(data and data.task_names or {})
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
  local callback = self._on_confirm_callback
  self._on_confirm_callback = nil
  if callback then
    callback()
  end
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:_bind_callbacks()
  self:bind_close_btn(self._btn_close)
  self:bind_close_btn(self._btn_close_bg)
  self:bind_callback(self._btn_confim, pack(self, M._on_confirm_click))
end

function M:_on_confirm_click()
  self:close_self()
end

function M:_refresh_task_list(task_names)
  local count = #task_names
  for i = 1, count do
    local item_go = self._item_pool[i]
    if item_go == nil then
      item_go = self._list_content:AddItem(0)
      self._item_pool[i] = item_go
    end
    if not_null(item_go) then
      UIUtil.set_active(item_go, true)
      local txt = UIUtil.find_trans(item_go, "txt_title")
      UIUtil.set_text(txt, task_names[i])
    end
  end
  for i = count + 1, #self._item_pool do
    local item_go = self._item_pool[i]
    if not_null(item_go) then
      UIUtil.set_active(item_go, false)
    end
  end
end

return M
