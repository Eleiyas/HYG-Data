local M = G.Class("NpcClothGiftPreviewPanel", G.UIPanel)
local base = G.UIPanel
local RECENT_GIFT_DAYS_PLAYER_CFG_ID = 247
local DEFAULT_RECENT_GIFT_DAYS = 7

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NpcCloth/NpcClothGiftPreviewDialog"
  self._tag_group_items = {}
  self._gift_items = {}
  self._is_expanded = false
  self._hide_on_create = false
end

function M:on_create()
  base.on_create(self)
  self._npc_info_panel = self:add_panel("UI/NpcCloth/NpcClothGiftInfoItem", self._npc_info_item.transform)
  self:bind_callback(self._tog_fold, function(is_on)
    self:_on_fold_click(is_on)
  end)
  self._state_group_fold:SetState(0)
  self:change_state(self._hide_on_create and EUIState.Hide or EUIState.Show)
  if self.npc_id and 0 < self.npc_id then
    self:_refresh_npc_info(self.npc_id)
    self:_refresh_npc_name(self.npc_id)
  end
end

function M:on_enable()
  base.on_enable(self)
  self._is_expanded = false
  self._state_group_fold:SetState(0)
  self._tog_fold:SetIsOnWithoutNotify(false)
end

function M:on_destroy()
  self._tag_group_items = nil
  self._gift_items = nil
  self._npc_info_panel = nil
  base.on_destroy(self)
end

function M:refresh(npc_id)
  if not npc_id or npc_id <= 0 then
    return
  end
  self.npc_id = npc_id
  if self._npc_info_panel then
    self:_refresh_npc_info(npc_id)
    self:_refresh_npc_name(npc_id)
  end
  if self._is_expanded then
    self:_refresh_favorite_tags(npc_id)
    self:_refresh_recent_gifts(npc_id)
  end
end

function M:_refresh_npc_info(npc_id)
  self._npc_info_panel:refresh(npc_id)
end

function M:_refresh_npc_name(npc_id)
  local npc_name = npc_module:get_npc_name_by_id(npc_id)
  UIUtil.set_text_by_id(self._txt_name_dynamic, "NpcGiftDaliy_txt_Title_AimNpc", npc_name)
end

function M:_on_fold_click(is_on)
  if is_on then
    self._state_group_fold:SetState(1)
    if not self._is_expanded then
      self._is_expanded = true
      self:_refresh_favorite_tags(self.npc_id)
      self:_refresh_recent_gifts(self.npc_id)
    end
  else
    self._state_group_fold:SetState(0)
  end
end

function M:_refresh_favorite_tags(npc_id)
  local label_cfgs = dic_to_table(ExcelDataUtil.get_table(typeof(BLabelColumnCfg)))
  local cfg_list = {}
  for _, cfg in pairs(label_cfgs) do
    if cfg.labelemotion ~= 100 then
      table.insert(cfg_list, cfg)
    end
  end
  local max_num = math.max(#self._tag_group_items, #cfg_list)
  for i = 1, max_num do
    local label_cfg = cfg_list[i]
    local item = self._tag_group_items[i]
    if item == nil and label_cfg then
      local trans = self._tag_group_binder:AddItem(0, true)
      item = self:add_panel("UI/NpcCloth/NpcClothGiftTagGroupItem", trans)
      self._tag_group_items[i] = item
    end
    if item then
      if label_cfg then
        item:set_active(true)
        item:refresh(npc_id, label_cfg)
      else
        item:set_active(false)
      end
    end
  end
end

function M:_refresh_recent_gifts(npc_id)
  local player_cfg = ExcelDataUtil.get_value(typeof(BPlayerCfg), RECENT_GIFT_DAYS_PLAYER_CFG_ID)
  local recent_gift_days = not_null(player_cfg) and player_cfg.value or DEFAULT_RECENT_GIFT_DAYS
  local cfg_ids = CsGameplayUtilitiesWarehouseUtil.FilterNpcRecentGiftCfgIds(npc_id, 0, recent_gift_days - 1)
  if cfg_ids == nil or cfg_ids.Count == 0 then
    self._state_group_recently:SetState(1)
    local npc_name = npc_module:get_npc_name_by_id(npc_id)
    UIUtil.set_text_by_id(self._txt_none_tip, "NpcGiftDaliy_txt_Des_NoGift", recent_gift_days, npc_name)
    for _, item in ipairs(self._gift_items) do
      item:set_active(false)
    end
    return
  end
  self._state_group_recently:SetState(0)
  local count = cfg_ids.Count
  for i = 0, count - 1 do
    local cfg_id = cfg_ids[i]
    local idx = i + 1
    local item = self._gift_items[idx]
    if item == nil then
      local trans = self._gift_item_binder:AddItem(0, true)
      item = self:add_panel(item_module.item_v2_panel_cls_name, trans)
      self._gift_items[idx] = item
    end
    item:set_active(true)
    item:set_item_data(cfg_id)
  end
  for i = count + 1, #self._gift_items do
    self._gift_items[i]:set_active(false)
  end
end

function M:set_hide_on_create()
  self._hide_on_create = true
  self:change_state(EUIState.Hide)
end

return M
