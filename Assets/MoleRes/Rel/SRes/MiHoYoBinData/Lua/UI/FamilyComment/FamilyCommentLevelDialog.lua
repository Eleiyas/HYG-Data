local M = G.Class("FamilyCommentLevelDialog", G.UIWindow)
local base = G.UIWindow
local level_item_cls = "UI/FamilyComment/FamilyCommentLevelItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/FamilyComment/FamilyCommentLevelDialog"
  self.config.type = EUIType.Dialog
  self._level_cfgs = {}
  self._level_items = {}
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_bg)
  self:_init_level_items()
end

function M:_init_level_items()
  self._level_cfgs = {}
  for _, cfg in pairs(ExcelDataUtil.get_table(typeof(BSocialActivityLevelCfg)) or {}) do
    table.insert(self._level_cfgs, cfg)
  end
  table.sort(self._level_cfgs, function(a, b)
    return a.socialactivitylevel < b.socialactivitylevel
  end)
  for index = 1, #self._level_cfgs do
    local trans = self._list_binder:AddItem(0, true)
    if not_null(trans) then
      self._level_items[index] = self:add_panel(level_item_cls, trans)
      self._level_items[index]:set_active(true)
    end
  end
end

function M:_refresh_level_items(current_level)
  local target_hot_num = 0
  for index, cfg in ipairs(self._level_cfgs) do
    local item = self._level_items[index]
    if item then
      item:refresh(cfg, current_level, target_hot_num)
    end
    target_hot_num = target_hot_num + (tonumber(cfg.levelscore) or 0)
  end
end

function M:_scroll_to_current_level(current_level)
  local target_item
  for index, cfg in ipairs(self._level_cfgs) do
    if tonumber(cfg.socialactivitylevel) == current_level then
      target_item = self._level_items[index]
      break
    end
  end
  if target_item == nil or is_null(target_item.rect_trans) or is_null(self._scroll_level) then
    return
  end
  local content = self._scroll_level.content
  local viewport = self._scroll_level.viewport
  if is_null(content) or is_null(viewport) then
    return
  end
  Canvas.ForceUpdateCanvases()
  LayoutRebuilder.ForceRebuildLayoutImmediate(content)
  local scrollable_width = content.rect.width - viewport.rect.width
  local normalized_position = 0
  if 0 < scrollable_width then
    local target_rect = target_item.rect_trans
    local target_center_x = target_rect.anchoredPosition.x + (0.5 - target_rect.pivot.x) * target_rect.rect.width
    local target_offset = target_center_x - viewport.rect.width * 0.5
    normalized_position = math.max(0, math.min(1, target_offset / scrollable_width))
  end
  self._scroll_level:StopMovement()
  self._scroll_level.horizontalNormalizedPosition = normalized_position
end

function M:on_enable()
  base.on_enable(self)
  local data = family_comment_module:get_social_level() or {}
  local current_level = math.max(0, tonumber(data.level) or 0)
  UIUtil.set_text(self._txt_current_level, UIUtil.get_text_by_id("Liuyanban_Lv") .. TextMapFormatUtil.FormatInteger(current_level))
  UIUtil.set_text(self._txt_hot_value, TextMapFormatUtil.FormatAbbreviation(data.value or 0))
  local has_icon = string.is_valid(data.icon)
  UIUtil.set_active(self._img_current_level, has_icon)
  if has_icon then
    UIUtil.set_image(self._img_current_level, data.icon, self:get_load_proxy())
  end
  self:_refresh_level_items(current_level)
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    if is_null(self.game_obj) or not self.is_active then
      return
    end
    self:_scroll_to_current_level(current_level)
  end)
end

return M
