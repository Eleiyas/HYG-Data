local M = G.Class("HomeRatingPage", G.UIWindow)
local base = G.UIWindow
local level_item_cls = "UI/MiTaiScore/HomeRatingLevelAwardItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MiTaiScore/HomeRatingPage"
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
  self._level_items = {}
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._btn_info, pack(self, M._on_btn_info_click))
  self:_init_level_list()
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_ui()
end

function M:_on_btn_info_click()
  common_ui_module:show_introduction_dialog(common_ui_module.introduction_dialog_type.mitai_score)
end

function M:_init_level_list()
  local cfgs = mi_tai_score_module:get_all_score_level_cfg() or {}
  for _, cfg in ipairs(cfgs) do
    if cfg.level ~= 0 then
      local trans = self._list_item:AddItem(0)
      local item = self:add_panel(level_item_cls, trans)
      table.insert(self._level_items, item)
      item.trans:SetAsFirstSibling()
      item:set_active(false)
    end
  end
end

function M:_refresh_ui()
  local score = CsMiTaiModuleUtil.historyMaxScore or 0
  local cfgs = mi_tai_score_module:get_all_score_level_cfg() or {}
  local current_cfg = mi_tai_score_module:get_score_level_cfg(score)
  local next_cfg = mi_tai_score_module:get_score_next_level_cfg(score)
  local current_level = current_cfg and current_cfg.level or 0
  local is_max_level = current_cfg ~= nil and next_cfg ~= nil and current_cfg.level == next_cfg.level
  self._state_group_exp:SetState(is_max_level and 1 or 0)
  UIUtil.set_text(self._txt_level, tostring(current_level))
  if not is_max_level then
    UIUtil.set_text_by_id(self._txt_info, "MitaiScore_Progress_Next")
    UIUtil.set_text(self._txt_exp, string.format("%s/%s", TextMapFormatUtil.FormatInteger(score), TextMapFormatUtil.FormatInteger(next_cfg and next_cfg.score or score)))
  else
    UIUtil.set_text_by_id(self._txt_info, "")
  end
  local level_cfgs = {}
  for _, cfg in ipairs(cfgs) do
    if cfg.level ~= 0 then
      table.insert(level_cfgs, cfg)
    end
  end
  local target_index = 1
  for item_index, cfg in ipairs(level_cfgs) do
    local item = self._level_items[item_index]
    if item then
      local next_cfg = level_cfgs[item_index + 1]
      item:refresh(cfg, score, current_level, item_index, #level_cfgs, next_cfg)
      item:set_active(true)
      if score >= cfg.score then
        target_index = item_index
      end
    end
  end
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    if self.is_active then
      self:_scroll_to_item(target_index)
    end
  end)
end

function M:_scroll_to_item(index)
  local count = #self._level_items
  if self._scroll_rect == nil or count <= 1 then
    return
  end
  local normalized = 1 - (math.max(1, math.min(index, count)) - 1) / (count - 1)
  self._scroll_rect.verticalNormalizedPosition = normalized
end

return M
