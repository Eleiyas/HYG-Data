local M = G.Class("SettingDisplayEffectDemonstrationDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Setting/SettingDisplayEffectDemonstrationDialog"
  self.config.type = EUIType.Dialog
  self._effect_item_views = {}
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_back)
  self:bind_close_btn(self._btn_bg)
end

function M:on_open()
  base.on_open(self)
  self:_refresh_view()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, M._on_back)
end

function M:on_destroy()
  self._effect_item_views = {}
  base.on_destroy(self)
end

function M:_on_back(_action)
  self:close_self()
end

function M:_refresh_view()
  local extra_data = self:get_extra_data()
  local detail_data = extra_data and extra_data.detail_data or nil
  if detail_data == nil then
    Logger.LogWarning("[SettingDisplayEffectDemonstrationDialog] Detail data is missing.")
    self:close_self()
    return
  end
  local title
  if detail_data.useEntryTitle then
    title = self:_get_text_map_content_text(extra_data.fallback_title)
  else
    title = self:_get_text_map_content_text(detail_data.titleTextMapContent)
    if not string.is_valid(title) then
      title = self:_get_text_map_content_text(extra_data.fallback_title)
    end
  end
  UIUtil.set_text(self._txt_title, title or "")
  UIUtil.set_text(self._txt_illustrate, self:_get_text_map_content_text(detail_data.illustrateTextMapContent))
  self:_refresh_effect_items(detail_data.effectItems)
end

function M:_refresh_effect_items(effect_items)
  if is_null(self._layout_list) then
    Logger.LogWarning("[SettingDisplayEffectDemonstrationDialog] ListItemBinder is missing.")
    return
  end
  local item_list = effect_items ~= nil and list_to_table(effect_items) or {}
  for index, item_data in ipairs(item_list) do
    local item_view = self._effect_item_views[index]
    if item_view == nil then
      item_view = self:_create_effect_item()
      if item_view == nil then
        item_view = {is_valid = false}
      end
      self._effect_item_views[index] = item_view
    end
    if item_view.is_valid then
      self:_refresh_effect_item(item_view, item_data)
      UIUtil.set_active(item_view.trans, true)
    end
  end
  for index = #item_list + 1, #self._effect_item_views do
    local item_view = self._effect_item_views[index]
    if item_view ~= nil and item_view.is_valid then
      UIUtil.set_active(item_view.trans, false)
    end
  end
end

function M:_create_effect_item()
  local item_trans = self._layout_list:AddItem(0)
  if is_null(item_trans) then
    return nil
  end
  local item_fields = UIUtil.get_mono_binder_field(item_trans)
  local image = item_fields._img_style_dynamic
  local text = item_fields._txt_style
  if image == nil or is_null(image) or text == nil or is_null(text) then
    Logger.LogWarning("[SettingDisplayEffectDemonstrationDialog] Effect item Binder fields are missing.")
    UIUtil.set_active(item_trans, false)
    return nil
  end
  return {
    is_valid = true,
    trans = item_trans,
    image = image,
    text = text,
    default_sprite = image.sprite
  }
end

function M:_refresh_effect_item(item_view, item_data)
  if item_data == nil then
    UIUtil.set_active(item_view.trans, false)
    return
  end
  if string.is_valid(item_data.imagePath) then
    UIUtil.set_image(item_view.image, item_data.imagePath, self:get_load_proxy())
  else
    UIUtil.set_image(item_view.image, item_view.default_sprite, self:get_load_proxy())
  end
  UIUtil.set_text(item_view.text, self:_get_text_map_content_text(item_data.textMapContent))
end

function M:_get_text_map_content_text(text_map_content)
  if text_map_content == nil then
    return ""
  end
  if text_map_content.textId ~= nil and string.is_valid(text_map_content.textId) then
    return UIUtil.get_text_by_id(text_map_content.textId)
  end
  if text_map_content.ToStringExplicit ~= nil then
    return text_map_content:ToStringExplicit()
  end
  return ""
end

return M
