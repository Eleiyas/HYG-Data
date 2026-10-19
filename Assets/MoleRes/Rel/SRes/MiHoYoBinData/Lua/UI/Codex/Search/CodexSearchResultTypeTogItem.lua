local M = G.Class("CodexSearchResultTypeTogItem", G.UIBase)
local base = G.UIBase
local TYPE_ICON_PATH = {
  [CodexDataType.Creature] = "UISprite/Load/TabIcon/Icon_Common_Tab_New_Fish",
  [CodexDataType.Plant] = "UISprite/Load/TabIcon/Icon_Common_PlantingPlants",
  [CodexDataType.Cloth] = "UISprite/Load/TabIcon/Icon_Common_Tab_Clothe",
  [CodexDataType.Food] = "UISprite/Load/TabIcon/Tab_Icon_Ugc_003_c",
  [CodexDataType.Furniture] = "UISprite/Load/TabIcon/Icon_Common_Tab_Furniture",
  [CodexDataType.Item] = "UISprite/Load/TabIcon/Tab_Icon_Ugc_003_d"
}

function M:init()
  base.init(self)
  self._type = nil
  self._count = 0
  self._on_select = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._tog_select) then
    self:bind_callback(self._tog_select, pack(self, M._on_toggle))
  end
end

function M:refresh(data)
  self._type = data.type
  self._count = data.count or 0
  self._on_select = data.on_select
  if not_null(self._txt_name) then
    UIUtil.set_text(self._txt_name, data.type_name or "")
  end
  if not_null(self._txt_num) then
    UIUtil.set_text(self._txt_num, self._count)
  end
  if not_null(self._img_select_icon) and not_null(self._img_unselect_icon) then
    local icon_path = TYPE_ICON_PATH[self._type]
    UIUtil.set_image(self._img_select_icon, icon_path, self:get_load_proxy())
    UIUtil.set_image(self._img_unselect_icon, icon_path, self:get_load_proxy())
  end
  if not_null(self._red_dot) then
    self._red_dot:ShowRedPoint(RedPointType.None)
  end
  self:_unselected_state()
  self:set_active(true)
end

function M:select()
  if not_null(self._tog_select) then
    self._tog_select:SetIsOnWithoutNotify(true)
  end
  self:_selected_state()
end

function M:un_select()
  if not_null(self._tog_select) then
    self._tog_select:SetIsOnWithoutNotify(false)
  end
  self:_unselected_state()
end

function M:_on_toggle(is_on)
  if is_on then
    self:_selected_state()
    if self._on_select then
      self._on_select(self._type)
    end
  else
    self:_unselected_state()
  end
end

function M:_selected_state()
  if not_null(self._trans_unselect_bg_1) then
    UIUtil.set_active(self._trans_unselect_bg_1, false)
  end
  if not_null(self._trans_unselect_bg_2) then
    UIUtil.set_active(self._trans_unselect_bg_2, false)
  end
end

function M:_unselected_state()
  if not_null(self._trans_unselect_bg_1) then
    UIUtil.set_active(self._trans_unselect_bg_1, true)
  end
  if not_null(self._trans_unselect_bg_2) then
    UIUtil.set_active(self._trans_unselect_bg_2, true)
  end
end

return M
