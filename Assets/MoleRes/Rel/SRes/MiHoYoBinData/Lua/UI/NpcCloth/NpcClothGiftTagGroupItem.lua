local M = G.Class("NpcClothGiftTagGroupItem", G.UIPanel)
local base = G.UIPanel
local tag_type = {
  favor = 1,
  hate = 2,
  ability = 3
}

function M:init()
  base.init(self)
  self._tag_items = {}
end

function M:on_create()
  base.on_create(self)
end

function M:on_destroy()
  self._tag_items = nil
  base.on_destroy(self)
end

function M:refresh(npc_id, label_cfg)
  if is_null(label_cfg) then
    return
  end
  UIUtil.set_text(self._txt_title, label_cfg.labelname)
  local tag_cfgs = companion_star_module:get_tag_list_by_label(npc_id, label_cfg.labelemotion) or {}
  local tag_t = self:_get_tag_type_by_label(label_cfg.labelemotion)
  local max_num = math.max(#self._tag_items, #tag_cfgs)
  for i = 1, max_num do
    local cfg = tag_cfgs[i]
    local item = self._tag_items[i]
    if item == nil and cfg then
      local trans = self._tag_item_binder:AddItem(0, true)
      item = self:add_panel("UI/CompanionStarDetail/Info/StarNpcInfoTagItem", trans)
      self._tag_items[i] = item
    end
    if item then
      if cfg then
        item:set_active(true)
        item:set_type(tag_t)
        item:refresh(cfg)
      else
        item:set_active(false)
      end
    end
  end
end

function M:_get_tag_type_by_label(cfg_label)
  if cfg_label == 1 or cfg_label == 2 then
    return tag_type.favor
  elseif cfg_label == 4 then
    return tag_type.hate
  else
    return tag_type.ability
  end
end

return M
