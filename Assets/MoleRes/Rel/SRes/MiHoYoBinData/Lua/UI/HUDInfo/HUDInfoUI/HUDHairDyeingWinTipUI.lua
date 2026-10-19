local M = G.Class("HUDHairDyeingWinTipUI", "UI/HUDInfo/HUDInfoUI/HUDInfoBaseUI")
local base = G.HUDInfoBaseUI
local SHOW_TIME = 1.5
local STATE_SUCCESS = 0
local STATE_REPEAT = 1

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/HairDyeing/HairDyeingWinTip"
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data() or {}
  self:_refresh_view(data)
  self:start_close_timer(data.duration or SHOW_TIME, function(panel)
    local on_close = data.on_close
    panel:close_self()
    if type(on_close) == "function" then
      on_close()
    end
  end)
end

function M:_refresh_view(data)
  local is_repeat = data.is_repeat == true
  if not is_null(self._ui_state_group) then
    self._ui_state_group:SetState(is_repeat and STATE_REPEAT or STATE_SUCCESS)
  end
  self:_refresh_title(data)
  self:_refresh_repeat_tip(data, is_repeat)
  self:_refresh_color_icon(data)
end

function M:_refresh_title(data)
  if is_null(self._txt_info) then
    return
  end
  local part_name = data.part_name or M._get_part_name(data.dye_part)
  local color_name = data.color_name or UIUtil.get_text_by_id("HairDyeing_Result_NewColor")
  local title = data.title
  if not string.is_valid(title) then
    title = UIUtil.get_text_by_id("HairDyeing_Result_Obtain_Tips", part_name, color_name)
  end
  UIUtil.set_text(self._txt_info, title)
end

function M:_refresh_repeat_tip(data, is_repeat)
  if is_null(self._txt_info_down) then
    return
  end
  UIUtil.set_text(self._txt_info_down, is_repeat and (data.repeat_tip or UIUtil.get_text_by_id("HairDyeing_Result_DuplicateFlower")) or "")
end

function M:_refresh_color_icon(data)
  if is_null(self._img_color) then
    return
  end
  local color_id = data.color_id or 0
  local icon_path = data.color_icon
  if not string.is_valid(icon_path) and 0 < color_id then
    icon_path = CsDyeingModuleUtil.GetColorBlockIconPath(color_id)
  end
  if string.is_valid(icon_path) then
    UIUtil.set_image(self._img_color, icon_path, self:get_load_proxy())
  end
  if 0 < color_id then
    UIUtil.set_image_color(self._img_color, CsDyeingModuleUtil.GetDisplayColorByColorBlockId(color_id))
  end
end

function M._get_part_name(dye_part)
  if dye_part == hair_dyeing_module.dye_part.region then
    return UIUtil.get_text_by_id("HairDyeing_Result_Global")
  end
  return UIUtil.get_text_by_id("HairDyeing_Result_Region")
end

return M
