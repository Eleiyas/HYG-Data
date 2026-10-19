local M = G.Class("LittleCornerSetUpDialog", G.UIWindow)
local base = G.UIWindow
local visibility_option_text_ids = {
  "LittleCorner_UI_Setup_VisPublic",
  "LittleCorner_UI_Setup_VisMutual",
  "LittleCorner_UI_Setup_VisSelf"
}
local tab_defs = {
  {
    key = "favorite",
    label_text_id = "LittleCorner_UI_Setup_TabFavorite"
  },
  {
    key = "following",
    label_text_id = "LittleCorner_UI_Setup_TabFollowing"
  },
  {
    key = "follower",
    label_text_id = "LittleCorner_UI_Setup_TabFollower"
  }
}
local ITEM_LABEL_NODE = "Name"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LittleCorner/LittleCornerSetUpDialog"
  self.config.type = EUIType.Dialog
  self._dropdowns = {}
  self._suppress_callback = false
  self._list_inited = false
  self._btn_close = nil
  self._btn_close_2 = nil
  self._list_item = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close))
  if not_null(self._btn_close_2) then
    self:bind_callback(self._btn_close_2, pack(self, M._on_btn_close))
  end
  self:_build_list()
end

function M:on_open()
  base.on_open(self)
  if CsLittleCornerModuleUtil.HasProfileSettings then
    self:_refresh_all_dropdowns()
  end
  CsLittleCornerModuleUtil.GetXhsProfileSettings()
end

function M:on_close()
  base.on_close(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnXhsProfileSettingsUpdated, function(arg)
    self:_refresh_all_dropdowns()
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:_on_btn_close()
  self:close_self()
end

function M:_build_list()
  if self._list_inited then
    return
  end
  if is_null(self._list_item) then
    return
  end
  for _, def in ipairs(tab_defs) do
    self:_create_dropdown_row(def)
  end
  self._list_inited = true
end

function M:_create_dropdown_row(def)
  local row_trans = self._list_item:AddItem(0)
  if is_null(row_trans) then
    return
  end
  local label_trans = UIUtil.find_trans(row_trans, ITEM_LABEL_NODE)
  if not_null(label_trans) then
    UIUtil.set_text_by_id(label_trans, def.label_text_id)
  end
  local dropdown = UIUtil.find_cmpt(row_trans, nil, typeof(Dropdown))
  if is_null(dropdown) then
    return
  end
  dropdown:ClearOptions()
  for _, text_id in ipairs(visibility_option_text_ids) do
    local option = Dropdown.OptionData()
    option.text = UIUtil.get_text_by_id(text_id)
    dropdown.options:Add(option)
  end
  dropdown:RefreshShownValue()
  self._dropdowns[def.key] = dropdown
  local tab_key = def.key
  self:bind_callback(dropdown, function(index)
    self:_on_visibility_changed(tab_key, index)
  end)
end

function M:_on_visibility_changed(tab_key, index)
  if self._suppress_callback then
    return
  end
  if little_corner_module:try_block_little_corner_with_tip() then
    self:_refresh_all_dropdowns()
    return
  end
  self:_submit_privacy()
end

function M:_refresh_all_dropdowns()
  self._suppress_callback = true
  self:_set_dropdown_value("favorite", CsLittleCornerModuleUtil.FavoriteTabVisibility)
  self:_set_dropdown_value("following", CsLittleCornerModuleUtil.FollowingTabVisibility)
  self:_set_dropdown_value("follower", CsLittleCornerModuleUtil.FollowerTabVisibility)
  self._suppress_callback = false
end

function M:_set_dropdown_value(tab_key, visibility)
  local dropdown = self._dropdowns[tab_key]
  if is_null(dropdown) then
    return
  end
  dropdown.value = visibility
  dropdown:RefreshShownValue()
end

function M:_submit_privacy()
  local favorite = self:_get_dropdown_value("favorite")
  local following = self:_get_dropdown_value("following")
  local follower = self:_get_dropdown_value("follower")
  CsLittleCornerModuleUtil.SetXhsProfilePrivacy(favorite, following, follower)
end

function M:_get_dropdown_value(tab_key)
  local dropdown = self._dropdowns[tab_key]
  if is_null(dropdown) then
    return 0
  end
  return dropdown.value
end

return M
