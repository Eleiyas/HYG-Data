local M = G.Class("StarFriendTitleItem", G.UIPanel)
local base = G.UIPanel
local motion_effects_state = {hidden = 0, visible = 1}
local hide_title_bg_state = {hidden = 0, visible = 1}
local independent_title_display_order = 2

function M:init()
  base.init(self)
  self._default_bg_sprite = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._img_bg) then
    self._default_bg_sprite = self._img_bg.sprite
  end
  if not_null(self._trans_hide_title_bg) then
    self._ui_state_group_hide_title_bg = self._trans_hide_title_bg:GetComponent(typeof(UIStateChangeGroup))
  end
end

function M:on_destroy()
  self._default_bg_sprite = nil
  self._ui_state_group_hide_title_bg = nil
  base.on_destroy(self)
end

function M:refresh(title_list, title)
  UIUtil.set_text(self._txt_title, title or "")
  self:_refresh_title_res(self:_get_title_res_cfg(title_list))
end

function M:set_text_color(color)
  UIUtil.set_text_color(self._txt_title, color)
end

function M:_lookup_title_res_cfg(title_id)
  local title_res_cfg = ExcelDataUtil.get_value(typeof(BPlayerTitleResCfg), title_id)
  if not_null(title_res_cfg) then
    return title_res_cfg
  end
  local title_cfg = ExcelDataUtil.get_value(typeof(BPlayerTitleCfg), title_id)
  if not_null(title_cfg) and title_cfg.itemid and title_cfg.itemid ~= 0 then
    return ExcelDataUtil.get_value(typeof(BPlayerTitleResCfg), title_cfg.itemid)
  end
  return nil
end

function M:_get_title_res_cfg(title_list)
  for _, title_id in ipairs(title_list or {}) do
    if title_id and title_id ~= 0 then
      local title_cfg = ExcelDataUtil.get_value(typeof(BPlayerTitleCfg), title_id)
      if not_null(title_cfg) and title_cfg.displayorder == independent_title_display_order then
        return self:_lookup_title_res_cfg(title_id)
      end
    end
  end
  return nil
end

function M:_refresh_title_res(title_res_cfg)
  if not_null(self._img_bg) then
    if not_null(title_res_cfg) and string.is_valid(title_res_cfg.titlebg) then
      UIUtil.set_image(self._img_bg, title_res_cfg.titlebg, self:get_load_proxy())
    else
      self._img_bg.sprite = self._default_bg_sprite
    end
    if not_null(title_res_cfg) and string.is_valid(title_res_cfg.titlebgcolor) then
      UIUtil.set_image_color(self._img_bg, title_res_cfg.titlebgcolor)
    else
      UIUtil.set_image_color(self._img_bg, "#FFFFFFFF")
    end
  end
  if not_null(self._ui_state_group_motion_effects) then
    local has_motion_effects = not_null(title_res_cfg) and title_res_cfg.hastitlebgtexture
    self._ui_state_group_motion_effects:SetState(has_motion_effects and motion_effects_state.visible or motion_effects_state.hidden)
  end
  if not_null(self._ui_state_group_hide_title_bg) then
    self._ui_state_group_hide_title_bg:SetState(not_null(title_res_cfg) and hide_title_bg_state.visible or hide_title_bg_state.hidden)
  end
end

return M
