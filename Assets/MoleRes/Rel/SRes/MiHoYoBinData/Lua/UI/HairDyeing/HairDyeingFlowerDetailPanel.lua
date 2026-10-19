local M = G.Class("HairDyeingFlowerDetailPanel", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._item_id = 0
  self._server_data = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_show_info, pack(self, M._on_btn_show_info))
end

function M:on_destroy()
  self._server_data = nil
  base.on_destroy(self)
end

function M:refresh(data)
  local item_id = data and (data.item_id or self:_get_item_id_by_server_data(data.server_data)) or 0
  if item_id == nil or item_id <= 0 then
    self._item_id = 0
    self._server_data = nil
    self:set_active(false)
    return
  end
  local cfg = item_module:get_cfg_by_id(item_id)
  if cfg == nil then
    self._item_id = 0
    self._server_data = nil
    self:set_active(false)
    return
  end
  self._item_id = item_id
  self._server_data = data and data.server_data or nil
  self:set_active(true)
  item_module:set_item_icon(self._img_icon, 0, cfg, self._server_data, self:get_load_proxy())
  UIUtil.set_text(self._txt_name, item_module:get_item_name_by_id(item_id, self._server_data))
  self._ui_state_group_quality:SetState(cfg.rank or 0)
  self:_refresh_color(item_id)
end

function M:_get_item_id_by_server_data(server_data)
  if is_null(server_data) then
    return 0
  end
  return server_data.ConfigId or server_data.ConFigID or 0
end

function M:_refresh_color(item_id)
  local colors = hair_dyeing_module:get_flower_display_colors_by_item_id(item_id)
  self:_refresh_color_image(self._img_color, colors[1])
  self:_refresh_color_image(self._img_color_2, colors[2])
end

function M:_refresh_color_image(image, color)
  if is_null(image) then
    return
  end
  UIUtil.set_active(image, color ~= nil)
  if color ~= nil then
    UIUtil.set_image_color(image, color)
  end
end

function M:_on_btn_show_info()
  if self._item_id == nil or self._item_id <= 0 then
    return
  end
  item_module:open_item_info_dialog(self._item_id, back_bag_module:get_item_num(self._item_id), self._server_data)
end

return M
