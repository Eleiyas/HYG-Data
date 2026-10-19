local M = G.Class("GachaTabItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._activity_cfg = nil
  self._on_select = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._toggle) then
    self:bind_callback(self._toggle, pack(self, M._on_toggle_changed))
  end
end

function M:refresh(activity_cfg, is_selected, on_select)
  self._activity_cfg = activity_cfg
  self._on_select = on_select
  UIUtil.set_text(self._txt_card_name, activity_cfg.name)
  self:_refresh_bg()
  self:_refresh_select_state(is_selected)
  if is_selected then
    self:_record_red_point()
  else
    self:refresh_red_point()
  end
end

function M:_refresh_bg()
  if self._activity_cfg == nil then
    return
  end
  local activity_cfg = self._activity_cfg
  if not_null(self._img_bg_dynamic) and activity_cfg.tagpic ~= nil and activity_cfg.tagpic ~= "" then
    UIUtil.set_image(self._img_bg_dynamic, activity_cfg.tagpic, self:get_load_proxy())
  end
  if not_null(self._img_bg_select_dynamic) and activity_cfg.tagsuitpic ~= nil and activity_cfg.tagsuitpic ~= "" then
    UIUtil.set_image(self._img_bg_select_dynamic, activity_cfg.tagsuitpic, self:get_load_proxy())
  end
end

function M:_record_red_point()
  if self._activity_cfg == nil then
    return
  end
  gacha_module:mark_pool_seen(self._activity_cfg.gachaid)
  self:refresh_red_point()
end

function M:refresh_red_point()
  if is_null(self._red_point) or self._activity_cfg == nil then
    return
  end
  local is_new = gacha_module:is_pool_new(self._activity_cfg.gachaid)
  local red_point_type = RedPointType.None
  if not is_new then
    red_point_type = gacha_module:get_accum_reward_red_point_type(self._activity_cfg.gachaid)
  else
    red_point_type = RedPointType.NewRp
  end
  self._red_point:ShowRedPoint(red_point_type)
end

function M:_refresh_select_state(is_selected)
  if not_null(self._toggle) then
    self._toggle:SetIsOnWithoutNotify(is_selected)
  end
end

function M:_on_toggle_changed(is_on)
  if self._activity_cfg == nil then
    return
  end
  if is_on and self._on_select ~= nil then
    self._on_select(self._activity_cfg.gachaid)
    self:_record_red_point()
  end
end

return M
