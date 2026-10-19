local M = G.Class("LittleCornerLvRightsDialog", G.UIWindow)
local base = G.UIWindow
local rights_item_cls = "UI/LittleCorner/LittleCornerLvRightsItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LittleCorner/LittleCornerLvRightsDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self._rights_items = {}
  self:bind_callbacks()
end

function M:on_open()
  base.on_open(self)
  self:_refresh()
end

function M:bind_callbacks()
  self:bind_close_btn(self._btn_close_popup_light)
  self:bind_close_btn(self._btn_bg_close)
end

function M:_refresh()
  local extra_data = self:get_extra_data() or {}
  local level = extra_data.level or 0
  UIUtil.set_text_by_id(self._txt_num, "LittleCorner_UI_010", level)
  local cfg = little_corner_module:get_creator_level_cfg(level)
  if cfg == nil then
    return
  end
  self:_refresh_list(self:_collect_rights(cfg))
end

function M:_collect_rights(cfg)
  local rights = {}
  if cfg.desc1 and cfg.desc1 ~= "" then
    table.insert(rights, {
      icon = cfg.descicon1,
      desc = cfg.desc1
    })
  end
  if cfg.desc2 and cfg.desc2 ~= "" then
    table.insert(rights, {
      icon = cfg.descicon2,
      desc = cfg.desc2
    })
  end
  return rights
end

function M:_refresh_list(rights)
  for i, right in ipairs(rights) do
    local item = self._rights_items[i]
    if item == nil then
      local obj = self._list_item:AddItem(0)
      item = self:add_panel(rights_item_cls, obj)
      self._rights_items[i] = item
    end
    item:refresh(i, right.icon, right.desc)
    item:set_active(true)
  end
  for i = #rights + 1, #self._rights_items do
    self._rights_items[i]:set_active(false)
  end
end

return M
