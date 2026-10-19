local M = G.Class("SourceItemJump", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  self._source_cfg = nil
  self._item_id = 0
  local btn = self._btn_jump
  self:bind_callback(btn, pack(self, M._on_click))
end

function M:refresh(source_cfg, item_id)
  self._source_cfg = source_cfg
  self._item_id = item_id or 0
  UIUtil.set_text(self._txt, source_cfg.sourcedescription)
end

function M:_check_diy_recipe_tips()
  if not self._source_cfg then
    return false
  end
  if self._source_cfg.systemjump ~= open_lua_ui_module.lua_ui_type.diy_handbook then
    return false
  end
  if self._item_id <= 0 then
    return false
  end
  local recipe_cfg = recipe_module:get_recipe_cfg_by_item_id(self._item_id)
  if is_null(recipe_cfg) then
    EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id("Memo_MiyoNoItem"))
    return true
  end
  if recipe_module:recipe_is_learn(recipe_cfg.id) then
    return false
  end
  local tips_id
  if 0 < back_bag_module:get_item_num(recipe_cfg.id) then
    tips_id = "Memo_DIYCardInBag"
  else
    tips_id = "Memo_NoDIYCard"
  end
  EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id(tips_id))
  return true
end

function M:_on_click()
  if self._source_cfg and self._source_cfg.systemjump > 0 then
    if self:_check_diy_recipe_tips() then
      return
    end
    lua_event_module:send_event(lua_event_module.event_type.system_jump_by_source_item_click)
    if self:_try_open_diy_recipe_detail() then
      return
    end
    local params
    local jt = self._source_cfg.jumptype
    if jt and jt ~= "" then
      params = lua_str_split(jt, ",", true)
    end
    open_lua_ui_module:open_lua_ui(self._source_cfg.systemjump, params)
  end
end

function M:_try_open_diy_recipe_detail()
  if self._source_cfg.systemjump ~= open_lua_ui_module.lua_ui_type.diy_handbook then
    return false
  end
  if self._item_id <= 0 then
    return false
  end
  local recipe_cfg = recipe_module:get_recipe_cfg_by_item_id(self._item_id)
  if is_null(recipe_cfg) then
    return false
  end
  if not recipe_module:recipe_is_learn(recipe_cfg.id) then
    return false
  end
  recipe_module:set_is_tool_table_state(false)
  ModelPreviewManagerIns:hide()
  recipe_module:open_diy_recipe_info_page(recipe_cfg.id, {
    recipe_cfg.id
  })
  return true
end

return M
