local M = G.Class("CookingConfirmIngredientItem", G.UIPanel)
local base = G.UIPanel
local item_v2_cls = item_module.item_v2_panel_cls_name

function M:init()
  base.init(self)
  self._tag_item = nil
  self._stack_entries = {}
end

function M:on_create()
  base.on_create(self)
  self._tag_item = self:add_panel("UI/PacketView/IngredientTagItem", self._trans_ingredient_tag_item)
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:set_data(data)
  self._data = data
  self:_refresh_tag_item(data)
  self:_refresh_stack_list(data)
end

function M:_refresh_tag_item(data)
  if is_null(self._tag_item) then
    return
  end
  local info = data and data.info
  if is_null(info) then
    self._tag_item:set_active(false)
    return
  end
  self._tag_item:set_active(true)
  self._tag_item:refresh(info, true)
end

function M:_refresh_stack_list(data)
  local binder = self._list_item
  if is_null(binder) then
    return
  end
  local info = data and data.info
  local stacks = data and data.stacks or {}
  local count = #stacks
  for i = 1, count do
    local stack_data = stacks[i]
    local entry = self._stack_entries[i]
    if entry == nil then
      local obj = binder:AddItem(0)
      if not is_null(obj) then
        local panel = self:add_panel(item_v2_cls, obj)
        entry = {obj = obj, panel = panel}
        self._stack_entries[i] = entry
      end
    end
    if entry and not is_null(entry.obj) and entry.panel then
      UIUtil.set_active(entry.obj, true)
      entry.panel:set_item_data(stack_data.cfg_id, stack_data.num, stack_data.server_data)
      entry.panel:bind_item_info_btn(stack_data.cfg_id)
      UIUtil.set_active(entry.panel._img_undonated, self:_should_show_mark(stack_data, info))
    end
  end
  for i = count + 1, #self._stack_entries do
    local entry = self._stack_entries[i]
    if entry and not is_null(entry.obj) then
      UIUtil.set_active(entry.obj, false)
    end
  end
end

function M:_should_show_mark(stack_data, info)
  if is_null(stack_data) then
    return false
  end
  local sd = stack_data.server_data
  if not_null(sd) and sd.isProtectedItem then
    return true
  end
  local cfg = item_module:get_cfg_by_id(stack_data.cfg_id)
  if is_null(cfg) then
    return false
  end
  if item_module:is_animal(stack_data.cfg_id, cfg) and not CsGalleryModuleUtil.HasDonated(stack_data.cfg_id) then
    return true
  end
  return self:_is_rank_mismatch(cfg, info)
end

function M:_is_rank_mismatch(id_cfg, info)
  if is_null(id_cfg) or is_null(info) or info:IsNull() then
    return false
  end
  local ingredient_rank = id_cfg.rank or 0
  local slot_rank_tag = info:GetRankTag() or 0
  if slot_rank_tag == 0 then
    local req_id = info.id or 0
    if 0 < req_id then
      local req_cfg = item_module:get_cfg_by_id(req_id)
      local req_rank = req_cfg and (req_cfg.rank or 0) or 0
      return ingredient_rank ~= req_rank
    end
    return 2 <= ingredient_rank
  elseif slot_rank_tag == EntityTagTags.Tags.ingredients_ingredients_rank_ingredients_purple then
    return ingredient_rank ~= 2
  elseif slot_rank_tag == EntityTagTags.Tags.ingredients_ingredients_rank_ingredients_golden then
    return ingredient_rank ~= 3
  end
  return false
end

return M
