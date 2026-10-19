local base_cls = require("UI/BlueprintHabitat/BlueprintInfoPageBase")
local M = G.Class("BlueprintInfoPage", base_cls)
local base = base_cls

function M:_refresh_view()
  base._refresh_view(self)
  if self._cur_key > 0 and not new_blueprint_module:is_blueprint_unlock_recorded(self._cur_key) then
    new_blueprint_module:record_blueprint_unlock(self._cur_key)
  end
end

function M:_domain()
  return new_blueprint_module.BLUEPRINT_DOMAIN.official
end

function M:_type_state()
  return 0
end

function M:_read_key_from_extra(extra)
  return extra and extra.blueprint_id or 0
end

function M:_key_of(entry)
  return entry.id
end

function M:_get_sorted_list()
  return new_blueprint_module:get_discovered_sorted_list()
end

function M:_preview_rotate()
  local cfg = new_blueprint_module:get_official_cfg(self._cur_key)
  local extra_rotate = cfg and cfg.showitemrotate or 0
  return new_blueprint_module:get_preview_base_yaw() + extra_rotate
end

function M:_refresh_title_and_extra()
  local cfg = new_blueprint_module:get_official_cfg(self._cur_key)
  if cfg then
    UIUtil.set_text(self._txt_name, cfg.name)
  end
end

function M:_apply_preview_framing(entry)
  local cfg = new_blueprint_module:get_official_cfg(self._cur_key)
  local dummy_list = cfg and lua_str_split(cfg.cameradummypos, ",", true)
  local look_at_list = cfg and lua_str_split(cfg.cameralookatpos, ",", true)
  local has_dummy = dummy_list and 3 <= #dummy_list
  local has_look_at = look_at_list and 3 <= #look_at_list
  if not has_dummy and not has_look_at then
    self:_apply_auto_framing()
    return
  end
  if not_null(self._follow_trans) then
    self._follow_trans.localPosition = has_dummy and Vector3(dummy_list[1], dummy_list[2], dummy_list[3]) or self._default_follow_pos
  end
  if not_null(self._look_at_trans) then
    self._look_at_trans.localPosition = has_look_at and Vector3(look_at_list[1], look_at_list[2], look_at_list[3]) or self._default_look_at_pos
  end
end

return M
