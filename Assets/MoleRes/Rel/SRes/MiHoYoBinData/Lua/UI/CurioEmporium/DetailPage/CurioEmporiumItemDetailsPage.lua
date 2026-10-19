local M = G.Class("CurioEmporiumItemDetailsPage", G.UIWindow)
local base = G.UIWindow
local group_cls = "UI/CurioEmporium/DetailPage/Panel/CurioEmporiumItemDetailsGroup"
local model_preview_view_cls = "UI/CommonUI/CommonModelPreviewView"
local quality_state = {
  Grey = 0,
  Green = 1,
  Purple = 2,
  Gold = 3
}
local DEBUG_TEST_SUIT = false

local function _resolve_color_block_id(unlock_cfg_id)
  local cfg = ExcelDataUtil.get_value(typeof(BColorUnlockCfg), unlock_cfg_id)
  if is_null(cfg) then
    return nil
  end
  local group_id = tonumber(cfg.colorgroupid)
  if not group_id or group_id <= 0 then
    return nil
  end
  local block_ids = CsDyeingModuleUtil.GetColorBlockIdsByGroupId(group_id)
  if is_null(block_ids) or 0 >= block_ids.Count then
    return nil
  end
  return block_ids[0]
end

local function _build_debug_data()
  local CLOTH_IDS = {}
  local HAIR_STYLE_CARDS = {84007}
  local HAIR_COLOR_CARDS = {85002}
  local EYE_STYLE_CARDS = {84502}
  local EYE_COLOR_CARDS = {85504}
  local EYEBROW_STYLE_CARDS = {1160631}
  local EYEBROW_COLOR_CARDS = {86309}
  local SKIN_STYLE_CARDS = {1260650}
  local SKIN_IDS = {}
  local OTHER_IDS = {200010, 21995}
  local items = {}
  
  local function add_items(tag, ids)
    for _, id in ipairs(ids) do
      items[#items + 1] = {
        itemid = id,
        num = 1,
        tag = tag
      }
    end
  end
  
  local wearable_ids = {}
  for _, v in ipairs(CLOTH_IDS) do
    wearable_ids[#wearable_ids + 1] = v
  end
  for _, v in ipairs(SKIN_IDS) do
    wearable_ids[#wearable_ids + 1] = v
  end
  add_items(1, wearable_ids)
  local card_ids = {}
  for _, v in ipairs(HAIR_STYLE_CARDS) do
    card_ids[#card_ids + 1] = v
  end
  for _, v in ipairs(HAIR_COLOR_CARDS) do
    card_ids[#card_ids + 1] = v
  end
  for _, v in ipairs(EYE_STYLE_CARDS) do
    card_ids[#card_ids + 1] = v
  end
  for _, v in ipairs(EYE_COLOR_CARDS) do
    card_ids[#card_ids + 1] = v
  end
  for _, v in ipairs(EYEBROW_STYLE_CARDS) do
    card_ids[#card_ids + 1] = v
  end
  for _, v in ipairs(EYEBROW_COLOR_CARDS) do
    card_ids[#card_ids + 1] = v
  end
  for _, v in ipairs(SKIN_STYLE_CARDS) do
    card_ids[#card_ids + 1] = v
  end
  add_items(2, card_ids)
  add_items(3, OTHER_IDS)
  local cloth_ids = {}
  for _, v in ipairs(CLOTH_IDS) do
    cloth_ids[#cloth_ids + 1] = v
  end
  for _, v in ipairs(SKIN_IDS) do
    cloth_ids[#cloth_ids + 1] = v
  end
  local style_color_list = {}
  local hair_style_id, eye_style_id, eyebrow_style_id
  for _, id in ipairs(HAIR_STYLE_CARDS) do
    local cfg = ExcelDataUtil.get_value(typeof(BColorUnlockCfg), id)
    if not_null(cfg) and cfg.styleid > 0 then
      hair_style_id = cfg.styleid
      style_color_list[#style_color_list + 1] = {
        style_id = cfg.styleid
      }
    end
  end
  for _, id in ipairs(EYE_STYLE_CARDS) do
    local cfg = ExcelDataUtil.get_value(typeof(BColorUnlockCfg), id)
    if not_null(cfg) and cfg.styleid > 0 then
      eye_style_id = cfg.styleid
      style_color_list[#style_color_list + 1] = {
        style_id = cfg.styleid
      }
    end
  end
  for _, id in ipairs(EYEBROW_STYLE_CARDS) do
    local cfg = ExcelDataUtil.get_value(typeof(BColorUnlockCfg), id)
    if not_null(cfg) and cfg.styleid > 0 then
      eyebrow_style_id = cfg.styleid
      style_color_list[#style_color_list + 1] = {
        style_id = cfg.styleid
      }
    end
  end
  for _, id in ipairs(SKIN_STYLE_CARDS) do
    local cfg = ExcelDataUtil.get_value(typeof(BColorUnlockCfg), id)
    if not_null(cfg) and cfg.styleid > 0 then
      style_color_list[#style_color_list + 1] = {
        style_id = cfg.styleid
      }
    end
  end
  for _, id in ipairs(HAIR_COLOR_CARDS) do
    if hair_style_id then
      local color_block_id = _resolve_color_block_id(id)
      if color_block_id then
        style_color_list[#style_color_list + 1] = {
          style_id = hair_style_id,
          color_id = color_block_id,
          area_id = 1
        }
      end
    end
  end
  for _, id in ipairs(EYE_COLOR_CARDS) do
    if eye_style_id then
      local color_block_id = _resolve_color_block_id(id)
      if color_block_id then
        style_color_list[#style_color_list + 1] = {
          style_id = eye_style_id,
          color_id = color_block_id,
          area_id = 1
        }
      end
    end
  end
  for _, id in ipairs(EYEBROW_COLOR_CARDS) do
    if eyebrow_style_id then
      local color_block_id = _resolve_color_block_id(id)
      if color_block_id then
        style_color_list[#style_color_list + 1] = {
          style_id = eyebrow_style_id,
          color_id = color_block_id,
          area_id = 1
        }
      end
    end
  end
  local other_items = {}
  for _, id in ipairs(OTHER_IDS) do
    other_items[#other_items + 1] = {config_id = id, num = 1}
  end
  local suit_split = {
    cloth_ids = cloth_ids,
    style_color_list = style_color_list,
    other_items = other_items
  }
  return items, suit_split
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CurioEmporium/CurioEmporiumItemDetailsPage"
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
  self.config.scene_prefab_path = "Scene/Map/4_UI/SceneMap_UI_CurioEmporiumDetail"
end

function M:on_create()
  base.on_create(self)
  self._group = nil
  self._selected_cfg = nil
  self._selected_item = nil
  self:_add_ui_listener()
  self._model_preview_view = self:add_panel(model_preview_view_cls, self._obj_common_model_group)
end

function M:on_open()
  base.on_open(self)
  local extra = self:get_extra_data()
  self._gift_id = extra and extra.gift_id or nil
  self:_refresh()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
  if self._suit_preview then
    self._suit_preview:hide()
    self._suit_preview = nil
  end
  if self._model_preview_view then
    self._model_preview_view:hide_preview()
  end
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._btn_info, pack(self, M._on_btn_info_click))
  if not_null(self._trans_suit_touch_rect) then
    self.binder:BindViewCallback(self._trans_suit_touch_rect, EventTriggerType.PointerDown, pack(self, M._on_suit_pointer_down))
    self.binder:BindViewCallback(self._trans_suit_touch_rect, EventTriggerType.Drag, pack(self, M._on_suit_drag))
    self.binder:BindViewCallback(self._trans_suit_touch_rect, EventTriggerType.PointerUp, pack(self, M._on_suit_pointer_up))
  end
end

function M:_set_suit_touch_active(active)
  if not_null(self._trans_suit_touch_rect) then
    UIUtil.set_active(self._trans_suit_touch_rect, active)
  end
end

function M:_on_suit_pointer_down(evt)
  if self._suit_preview then
    self._suit_preview:on_begin_drag(evt)
  end
end

function M:_on_suit_drag(evt)
  if self._suit_preview then
    self._suit_preview:on_drag(evt)
  end
end

function M:_on_suit_pointer_up(evt)
  if self._suit_preview then
    self._suit_preview:on_end_drag(evt)
  end
end

function M:_refresh()
  self:_cleanup_previews()
  if DEBUG_TEST_SUIT then
    self._items, self._suit_split = _build_debug_data()
    self._group_title = "DEBUG礼包"
    self._is_suit_gift = true
    self:_refresh_group()
    self:_start_suit_preview()
    self:_select_first_item()
    return
  end
  self._items = curio_emporium_module:get_gift_item_cfgs(self._gift_id)
  if not self._items or #self._items <= 0 then
    return
  end
  self._group_title = item_module:get_item_name_by_id(self._gift_id) or ""
  self._is_suit_gift = curio_emporium_module:is_suit_auto_claim_gift(self._gift_id)
  if self._is_suit_gift then
    self._suit_split = curio_emporium_module:split_suit_gift_items(self._gift_id)
  end
  self:_refresh_group()
  if self._is_suit_gift then
    self:_start_suit_preview()
  end
  self:_select_first_item()
end

function M:_refresh_group()
  if not self._group then
    local obj = self._good_list_item_binder:AddItem(0)
    if not_null(obj) then
      self._group = self:add_panel(group_cls, obj)
    end
  end
  if self._group then
    self._group:refresh(self._group_title, self._items, pack(self, M._on_item_selected))
    UIUtil.set_active(self._group.game_obj, true)
  end
end

function M:_select_first_item()
  if not self._items or #self._items <= 0 then
    return
  end
  local first_cfg = self._items[1]
  local first_item
  if self._group and self._group._item_pool then
    first_item = self._group._item_pool[1]
  end
  self:_on_item_selected(first_cfg, first_item)
end

function M:_on_item_selected(cfg, item)
  if not cfg then
    return
  end
  self._selected_cfg = cfg
  if self._selected_item and self._selected_item ~= item then
    self._selected_item:set_select(false)
  end
  self._selected_item = item
  if item then
    item:set_select(true)
  end
  self:_refresh_selected_detail()
end

function M:_refresh_selected_detail()
  self:_refresh_name()
  self:_refresh_quality()
  self:_refresh_holding_num()
  if self._is_suit_gift then
    self:_switch_preview_by_item()
  else
    UIUtil.set_active(self._obj_common_model_group, true)
    self:_refresh_model_preview()
  end
end

function M:_switch_preview_by_item()
  local item_id = self._selected_cfg.itemid
  local is_wearable = item_module:is_clothing(item_id) or item_module:is_eyes(item_id) or item_module:is_hair(item_id) or item_module:is_skin(item_id) or item_module:is_unlock_appearance_card(item_id)
  if is_wearable then
    self:_set_suit_preview_visible(true)
    UIUtil.set_active(self._obj_common_model_group, false)
    self._suit_preview:play_item_pose(item_id)
  else
    self:_set_suit_preview_visible(false)
    UIUtil.set_active(self._obj_common_model_group, true)
    self:_refresh_model_preview()
  end
end

function M:_set_suit_preview_visible(visible)
  if self._suit_preview then
    self._suit_preview:set_visible(visible)
  end
  self:_set_suit_touch_active(visible)
end

function M:_cleanup_previews()
  if self._suit_preview then
    self._suit_preview:hide()
  end
  self:_set_suit_touch_active(false)
  if not_null(self._obj_common_model_group) then
    UIUtil.set_active(self._obj_common_model_group, false)
  end
end

function M:_refresh_name()
  local name = item_module:get_item_name_by_id(self._selected_cfg.itemid) or ""
  UIUtil.set_text(self._txt_name, name)
end

function M:_refresh_quality()
  if is_null(self._ui_state_change_group_quality) then
    return
  end
  local item_id = self._selected_cfg.itemid
  if not item_id or item_id <= 0 then
    self._ui_state_change_group_quality:SetState(quality_state.Grey)
    return
  end
  local cfg = item_module:get_cfg_by_id(item_id)
  if cfg == nil then
    self._ui_state_change_group_quality:SetState(quality_state.Grey)
    return
  end
  self._ui_state_change_group_quality:SetState(cfg.rank or 0)
end

function M:_refresh_holding_num()
  if is_null(self._txt_holding_num) then
    return
  end
  local item_id = self._selected_cfg.itemid
  local owned = back_bag_module:get_item_num(item_id) or 0
  UIUtil.set_text_by_id(self._txt_holding_num, "Curio_Emporium_Good_Holding_Tip", tostring(owned))
end

function M:_refresh_model_preview()
  if not self._model_preview_view then
    return
  end
  local item_id = self._selected_cfg.itemid
  if item_id and 0 < item_id then
    self._model_preview_view:show_item(item_id, self:get_load_proxy())
  end
end

function M:_start_suit_preview()
  local player_root = UIUtil.find_trans(self.ui_scene_obj, "Art/ModelPos/pos")
  if is_null(player_root) then
    return
  end
  if not self._suit_preview then
    self._suit_preview = G.New(require("ModelPreview/SuitPreviewController"), player_root)
  end
  local split = self._suit_split
  self._suit_preview:show_by_cloth_ids(split.cloth_ids, split.style_color_list)
end

function M:_on_btn_info_click()
  if not self._selected_cfg then
    return
  end
  item_module:open_item_info_dialog(self._selected_cfg.itemid)
end

return M
