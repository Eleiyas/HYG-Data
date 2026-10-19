local M = G.Class("NpcClothSizeItem", G.UIBase)
local base = G.UIBase
local exclusive_state = {
  npc_only = 0,
  npc_cloth = 1,
  player_same = 2
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NpcCloth/NpcClothSizeItem"
end

function M:refresh_by_item_id(item_id, item_cfg, option)
  item_id = tonumber(item_id) or 0
  if item_id <= 0 then
    self:set_active(false)
    return
  end
  local outfit_cfg = npc_cloth_module.get_outfit_cfg(item_id)
  if outfit_cfg then
    self:_refresh_npc_cloth(item_id, outfit_cfg)
    return
  end
  local show_player_same = option == nil or option.show_player_same ~= false
  if show_player_same and item_module:is_clothing(item_id, item_cfg and item_cfg.idCfg) and npc_cloth_module.has_player_same_npc_cloth(item_id, item_cfg) then
    self:_refresh_player_same(item_id, item_cfg)
    return
  end
  self:set_active(false)
end

function M:_refresh_npc_cloth(item_id, outfit_cfg)
  self:set_active(true)
  local npc_id = outfit_cfg.npcid or 0
  self._state_group_exclusive:SetState(0 < npc_id and exclusive_state.npc_only or exclusive_state.npc_cloth)
  if 0 < npc_id then
    self:_refresh_npc_icon(npc_id)
    return
  end
  self:_refresh_npc_icon(0)
  UIUtil.set_text(self._txt_size, npc_cloth_module.get_goods_size_text(item_id))
end

function M:_refresh_player_same(item_id, item_cfg)
  self:set_active(true)
  self:_refresh_npc_icon(0)
  if self._state_group_exclusive then
    self._state_group_exclusive:SetState(exclusive_state.player_same)
  end
  if self._txt_size then
    UIUtil.set_text(self._txt_size, npc_cloth_module.get_player_same_size_text(item_id, item_cfg))
  end
end

function M:_refresh_npc_icon(npc_id)
  if not self._img_npc_dynamic then
    return
  end
  UIUtil.set_active(self._img_npc_dynamic, 0 < npc_id)
  if 0 < npc_id then
    npc_module:set_npc_icon_by_id(self._img_npc_dynamic, npc_id, self:get_load_proxy())
  end
end

return M
