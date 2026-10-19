local M = G.Class("CommonNpcSelectDialog", G.UIWindow)
local base = G.UIWindow
local NPC_ITEM_CLS = "UI/CommonUI/CommonNpcSelectItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CommonUI/CommonNpcSelectDialog"
  self.config.type = EUIType.Dialog
  self._npc_pool = {
    active = {},
    pool = {}
  }
  self._npc_list = {}
  self._select_npc_id = 0
  self._ctx = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  local ctx = self:get_extra_data() or {}
  self._ctx = ctx
  UIUtil.set_text_by_id(self._txt_title_dynamic, ctx.title_key)
  self._state_group:SetState(ctx.button_state)
  self._current_npc_id = ctx.current_npc_id or 0
  self._npc_list = self:_sort_npc_list(ctx.npc_list or {})
  if #self._npc_list == 0 then
    galactic_bazaar_module:reset_items(self._npc_pool.active, self._npc_pool.pool)
    self._select_npc_id = 0
    return
  end
  self._select_npc_id = self._current_npc_id ~= 0 and self._current_npc_id or self._npc_list[1].id
  galactic_bazaar_module:generate_and_refreshitems(self, self._npc_pool, self._npc_list, self._item_binder:GetItem(0), self._item_binder.transform, NPC_ITEM_CLS, function(item, npc_data)
    item:set_data(npc_data, npc_data.id == self._current_npc_id)
    local tog = item:get_toggle()
    if tog then
      self:bind_callback(tog, function(is_on)
        if is_on then
          tog.interactable = false
          self._select_npc_id = npc_data.id
          self:_refresh_npc_detail(npc_data)
        else
          tog.interactable = true
        end
      end)
    end
  end)
  self:_sync_toggle_state()
  for _, npc_data in ipairs(self._npc_list) do
    if npc_data.id == self._select_npc_id then
      self:_refresh_npc_detail(npc_data)
      break
    end
  end
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_confirm_delegation, pack(self, M._on_btn_confirm_delegation_click))
  self:bind_callback(self._btn_cancel_delegation, pack(self, M._on_btn_cancel_delegation_click))
  self:bind_callback(self._btn_confirm, pack(self, M._on_btn_confirm_click))
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._btn_close_2, pack(self, M._on_btn_close_2_click))
end

function M:_on_btn_confirm_delegation_click()
  if self._ctx and self._ctx.on_invite then
    self._ctx.on_invite(self._select_npc_id)
  end
  self:close_self()
end

function M:_on_btn_cancel_delegation_click()
  if self._ctx and self._ctx.on_cancel then
    self._ctx.on_cancel()
  end
  self:close_self()
end

function M:_on_btn_confirm_click()
  if self._ctx and self._ctx.on_confirm then
    self._ctx.on_confirm(self._select_npc_id)
  end
  self:close_self()
end

function M:_on_btn_close_2_click()
  self:close_self()
end

function M:_sync_toggle_state()
  for _, item in ipairs(self._npc_pool.active) do
    local tog = item:get_toggle()
    if tog then
      tog:SetIsOnWithoutNotify(item:get_npc_id() == self._select_npc_id)
      tog.interactable = item:get_npc_id() ~= self._select_npc_id
    end
  end
end

function M:_refresh_npc_detail(detail)
  local is_using = detail.id == self._current_npc_id
  self._state_group:SetState(is_using and 1 or 2)
  UIUtil.set_text(self._txt_npc_name_dynamic, detail.name)
  UIUtil.set_text(self._txt_npc_info, "")
  local star_map_cfg = companion_star_module:get_star_map_cfg_by_npc_id(detail.id)
  if star_map_cfg and string.is_valid(star_map_cfg.npccardassetpath) then
    UIUtil.set_image(self._img_npc_dynamic, star_map_cfg.npccardassetpath, self:get_load_proxy())
  end
  if string.is_valid(detail.iconnamesmall) then
    UIUtil.set_image(self._img_npc_detail_icon, detail.iconnamesmall, self:get_load_proxy())
    self._outline_npc:ForceUpdate()
  end
end

function M:_sort_npc_list(list)
  if not list or #list == 0 then
    return list
  end
  local current_id = self._current_npc_id
  table.sort(list, function(a, b)
    local a_using = a.id == current_id
    local b_using = b.id == current_id
    if a_using ~= b_using then
      return a_using
    end
    return a.id < b.id
  end)
  return list
end

return M
