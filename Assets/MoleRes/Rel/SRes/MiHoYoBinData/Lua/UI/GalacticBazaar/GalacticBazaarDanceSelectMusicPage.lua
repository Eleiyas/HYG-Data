local M = G.Class("GalacticBazaarDanceSelectMusicPage", G.UIWindow)
local base = G.UIWindow
M.Difficulty = {
  Easy = 0,
  Normal = 1,
  Hard = 2
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GalacticBazaar/GalacticBazaarDanceSelectMusicPage"
  self.config.type = EUIType.Page
  self._music_item_panels = {}
  self._music_data = nil
  self._music_list_inited = false
end

function M:on_create()
  base.on_create(self)
  self._music_item_cls = "UI/GalacticBazaar/GalacticBazaarDanceSelectMusicItem"
  self:_add_btn_listener()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  local extra = self:get_extra_data()
  if extra and extra.on_result then
    self._on_result = extra.on_result
    self:set_extra_data(nil)
  end
  self._go_selected = false
  self:_refresh_music_list()
end

local function _notify_result(self, result)
  if self._on_result then
    self._on_result(result)
    self._on_result = nil
  end
end

function M:close_self()
  if not self._go_selected then
    _notify_result(self, 0)
  end
  base.close_self(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  if not_null(self._music_list) then
    self._music_list:Close()
  end
  self._music_item_panels = {}
  self._music_data = nil
  self._music_list_inited = false
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:_add_btn_listener()
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._tog_easy, function()
    galactic_bazaar_module:set_dance_music_diffi(0)
    self:_refresh_hostory_score()
  end)
  self:bind_callback(self._tog_mid, function()
    galactic_bazaar_module:set_dance_music_diffi(1)
    self:_refresh_hostory_score()
  end)
  self:bind_callback(self._tog_hard, function()
    galactic_bazaar_module:set_dance_music_diffi(2)
    self:_refresh_hostory_score()
  end)
  self:bind_callback(self._btn_tutorial, function()
    tutorial_module:open_tutorial_handbook_page_with_tutorial_id(5, 5, 1)
  end)
  self:bind_callback(self._btn_go, function()
    self._go_selected = true
    _notify_result(self, 1)
    local is_in_matching = CsSceneActivityModuleUtil.IsLocalPlayerInActivityMatchPlayerList(galactic_bazaar_module:get_cur_activity_id())
    if is_in_matching then
      CsSceneActivityModuleUtil.ChangeDanceCompetitionJoinInfo(CsSceneActivityModuleUtil.GetCurActivityId(), galactic_bazaar_module:get_dance_music_id(), galactic_bazaar_module:get_dance_music_diffi())
    else
      CsSceneActivityModuleUtil.JoinDanceCompetition(CsSceneActivityModuleUtil.GetCurActivityId(), galactic_bazaar_module:get_dance_music_id(), galactic_bazaar_module:get_dance_music_diffi())
    end
    base.close_self(self)
  end)
end

function M:_get_music_list()
  return galactic_bazaar_module:get_dance_music_list()
end

function M:_find_music_cfg_in_list(music_id, music_list)
  if not music_id or not music_list then
    return nil
  end
  for _, row in ipairs(music_list) do
    if row.id == music_id then
      return row
    end
  end
  return nil
end

function M:_update_music_detail_ui(cfg)
  if is_null(cfg) then
    return
  end
  UIUtil.set_image(self._img_music, cfg.theme, self:get_load_proxy())
  UIUtil.set_text(self._txt_music, cfg.name)
  self:_refresh_hostory_score()
end

function M:_refresh_hostory_score()
  local music_id = galactic_bazaar_module:get_dance_music_id()
  local diffi = galactic_bazaar_module:get_dance_music_diffi()
  local diffi_to_score = galactic_bazaar_module:get_dance_music_history_best_score(music_id)
  local best_score = 0
  if not_null(diffi_to_score) then
    best_score = diffi_to_score[diffi] or 0
  end
  UIUtil.set_text(self._txt_score, best_score)
  local appraise = galactic_bazaar_module:get_dance_appraise_by_score(best_score, music_id, diffi)
  UIUtil.set_text(self._txt_evaluate, appraise)
  self:_set_diffi_state(diffi)
end

function M:_on_circular_item_update(go, index)
  if is_null(go) or not self._music_data then
    return
  end
  local data = self._music_data[index + 1]
  if not data then
    return
  end
  local instance_id = go:GetInstanceID()
  local item = self._music_item_panels[instance_id]
  if not item then
    item = self:add_panel(self._music_item_cls, go)
    self._music_item_panels[instance_id] = item
  end
  item:set_active(true)
  item:set_data(data, function(cfg)
    self:_on_music_selected(cfg)
  end)
  item:set_selected(galactic_bazaar_module:get_dance_music_id() == data.id)
end

function M:_refresh_music_list()
  if is_null(self._music_list) then
    return
  end
  local music_list = self:_get_music_list()
  self._music_data = music_list
  if music_list[1] then
    galactic_bazaar_module:set_dance_music_id(music_list[1].id)
  end
  
  local function on_update(go, index)
    self:_on_circular_item_update(go, index)
  end
  
  if not self._music_list_inited then
    self._music_list:Init(#music_list, on_update)
    self._music_list_inited = true
  else
    self._music_list:Reload(#music_list, on_update)
  end
  local sel_cfg = self:_find_music_cfg_in_list(galactic_bazaar_module:get_dance_music_id(), music_list)
  if sel_cfg then
    self:_update_music_detail_ui(sel_cfg)
    self._tog_easy.isOn = true
  end
end

function M:_on_music_selected(cfg)
  if is_null(cfg) then
    return
  end
  local id_changed = galactic_bazaar_module:get_dance_music_id() ~= cfg.id
  galactic_bazaar_module:set_dance_music_id(cfg.id)
  if id_changed then
    galactic_bazaar_module:set_dance_music_diffi(0)
    if not_null(self._tog_easy) then
      self._tog_easy.isOn = true
    end
  end
  self:_update_music_detail_ui(cfg)
  if not id_changed then
    return
  end
  if not_null(self._music_list) and self._music_list_inited and self._music_data then
    self._music_list:Reload(#self._music_data, function(go, index)
      self:_on_circular_item_update(go, index)
    end)
  end
end

function M:_set_diffi_state(diffi)
  if not_null(self._diffi_state) then
    self._diffi_state:SetState(diffi)
  end
end

function M:get_cur_music_diffi_cfg(level)
  return galactic_bazaar_module:get_dance_music_diffi_cfg(galactic_bazaar_module:get_dance_music_id(), level)
end

return M
