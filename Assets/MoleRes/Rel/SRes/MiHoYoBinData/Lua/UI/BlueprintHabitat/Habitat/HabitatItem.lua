local M = G.Class("HabitatItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._habitat_id = 0
  self._star_objs = {}
end

function M:on_create()
  base.on_create(self)
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:refresh(habitat_id)
  if habitat_id == nil or habitat_id == 0 then
    self:set_active(false)
    return
  end
  self._habitat_id = habitat_id
  local ui_cfg = blueprint_habitat_module:get_habitat_ui_cfg(self._habitat_id)
  local ok_logic, logic_cfg = CsHabitatModuleUtil.TryGetHabitatCfg(self._habitat_id)
  if not ok_logic or ui_cfg == nil then
    return
  end
  self:set_active(true)
  self:_refresh_info(ui_cfg)
  self:_refresh_npc(logic_cfg)
  self:_refresh_stars(logic_cfg)
  self:_refresh_red_point()
end

function M:_refresh_info(ui_cfg)
  if string.is_valid(ui_cfg.name) then
    UIUtil.set_text(self._txt_name, ui_cfg.name)
  end
  if string.is_valid(ui_cfg.tooltableicon) then
    UIUtil.set_image(self._img_pic, ui_cfg.tooltableicon, self:get_load_proxy())
  end
  if blueprint_habitat_module:has_habitat_ever_been_restored(self._habitat_id) then
    self._state_group:SetState(0)
  else
    self._state_group:SetState(1)
  end
end

function M:_refresh_npc(logic_cfg)
  local npc_icon
  if logic_cfg.RelatedNpcID ~= 0 then
    local npc_cfg = npc_module:get_npc_cfg(logic_cfg.RelatedNpcID)
    if npc_cfg and string.is_valid(npc_cfg.iconnamesmall) then
      npc_icon = npc_cfg.iconnamesmall
    end
  end
  if string.is_valid(npc_icon) then
    UIUtil.set_active(self._img_npc_icon, true)
    UIUtil.set_image(self._img_npc_icon, npc_icon, self:get_load_proxy())
  else
    UIUtil.set_active(self._img_npc_icon, false)
  end
end

function M:_refresh_stars(logic_cfg)
  local star_count = logic_cfg.Star or 0
  for i = 1, star_count do
    local obj = self._star_objs[i]
    if obj == nil then
      obj = self._list_stars:AddItem(0)
      self._star_objs[i] = obj
    end
    UIUtil.set_active(obj, true)
  end
  for i = star_count + 1, #self._star_objs do
    UIUtil.set_active(self._star_objs[i], false)
  end
end

function M:_refresh_red_point()
  if self._habitat_id == 0 then
    self._red_point:ShowRedPoint(RedPointType.None)
    return
  end
  local red_state = RedPointType.None
  if blueprint_habitat_module:has_habitat_ever_been_restored(self._habitat_id) and not blueprint_habitat_module:is_habitat_reward_claimed(self._habitat_id) then
    red_state = RedPointType.GiftRP
  end
  if not blueprint_habitat_module:is_habitat_unlock_recorded(self._habitat_id) then
    blueprint_habitat_module:record_habitat_unlock(self._habitat_id)
    if red_state == RedPointType.None then
      red_state = RedPointType.NewRp
    end
  end
  self._red_point:ShowRedPoint(red_state)
end

function M:get_btn()
  return self._btn_item
end

function M:get_habitat_id()
  return self._habitat_id
end

return M
