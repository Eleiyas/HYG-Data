local M = G.Class("ChatActionPanel", G.UIPanel)
local base = G.UIPanel
local action_ite_class = "UI/ChatAction/ActionItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/ChatAction/ChatActionPanel"
  self.config.type = EUIType.Page
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._action_items = {}
  self._reaction_cfgs = LocalDataUtil.get_table(typeof(CS.BReactionCfg))
end

function M:on_enable()
  base.on_enable(self)
  self:_set_actions()
  InputManagerIns:set_mouse_active(true, false)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if GameplayUtility.Player.UIDefaultValidatePlayerStates() then
    for id, item in pairs(self._action_items) do
      item:get_btn().interactable = true
      item._canvas_group.alpha = 1
    end
  end
  if GameplayUtility.Player.UIReactionGetPlayerState() == 1 then
    for id, item in pairs(self._action_items) do
      if self._reaction_cfgs[id].canplaywhensit ~= 1 then
        item:get_btn().interactable = false
        item._canvas_group.alpha = 0.5
      end
    end
  end
  if GameplayUtility.Player.UIReactionGetPlayerState() == 2 then
    item:get_btn().interactable = false
    item._canvas_group.alpha = 0.5
  end
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_callback(self._btn_close, function()
    lua_event_module:send_event(lua_event_module.event_type.set_main_chat_action_state)
  end)
end

function M:_add_ui_listener()
end

function M:_set_actions()
  for _, cfg in pairs(self._reaction_cfgs) do
    if GameplayUtility.CheckReactionUnlock(cfg.id) then
      local action
      if self._action_items[cfg.id] then
        action = self._action_items[cfg.id]
      else
        local item = UIUtil.load_prefab_set_parent(self._trans_item, self._trans_content)
        action = self:add_panel(action_ite_class, item)
        self._action_items[cfg.id] = action
      end
      action:set_data(cfg)
      local btn = action:get_btn()
      self:bind_callback(btn, function()
        CsBuriedPointReportManagerUtil.ReportActionFromLuaTable(BuriedPointReportActionEnum.furnish_reaction, "Reaction", {
          id = cfg.id
        })
        lua_event_module:send_event(lua_event_module.event_type.set_main_chat_action_state)
        CsReactionModuleUtil.EnterReactionState(player_module:get_player_guid(), cfg.id)
      end)
    end
  end
end

return M
