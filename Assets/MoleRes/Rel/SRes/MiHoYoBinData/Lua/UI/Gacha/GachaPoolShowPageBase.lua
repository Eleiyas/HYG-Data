local M = G.Class("GachaPoolShowPageBase", G.UIWindow)
local base = G.UIWindow
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls
local exchange_title_cls = GachaConst.item_path.exchange_title
local exchange_item_cls = GachaConst.item_path.exchange
local model_preview_view_cls = "UI/CommonUI/CommonModelPreviewView"

function M:init()
  base.init(self)
  self.config.prefab_path = GachaConst.page_path.exchange
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
  self.config.scene_prefab_path = "Scene/Map/4_UI/SceneMap_UI_GachaExchangeDetail"
  
  function self._on_item_select_callback(pool_cfg)
    self:_on_item_select(pool_cfg)
  end
  
  self:_init_custom_data()
end

function M:on_create()
  base.on_create(self)
  self:_bind_callbacks()
  self._model_preview_view = self:add_panel(model_preview_view_cls, self._obj_common_model_group)
end

function M:on_enable()
  base.on_enable(self)
  self._is_first_show_suit = true
  self:_init_panel_info()
  self:_refresh_coin()
  self:_refresh_tab_groups()
end

function M:on_disable()
  base.on_disable(self)
  self:_hide_suit_preview()
  self:_hide_other_model_preview()
end

function M:on_destroy()
  self:_init_custom_data()
  self:_close_scroller(self._scroll_card_list)
  self:_destroy_suit_preview()
  base.on_destroy(self)
end

function M:_bind_callbacks()
  self:bind_close_btn(self._btn_close)
  if not_null(self._btn_exchange) then
    self:bind_callback(self._btn_exchange, pack(self, M._on_btn_exchange))
  end
  if not_null(self._btn_go_draw) then
    self:bind_callback(self._btn_go_draw, pack(self, M._on_btn_go_draw))
  end
  if not_null(self._btn_info_dark) then
    self:bind_callback(self._btn_info_dark, pack(self, M._on_btn_info_dark_click))
  end
  self.binder:BindViewCallback(self._trans_3d_cloth_touch_rect, EventTriggerType.PointerDown, pack(self, M._on_pointer_down))
  self.binder:BindViewCallback(self._trans_3d_cloth_touch_rect, EventTriggerType.PointerUp, pack(self, M._on_pointer_up))
  self.binder:BindViewCallback(self._trans_3d_cloth_touch_rect, EventTriggerType.Drag, pack(self, M._on_drag))
end

function M:_init_panel_info()
  local gacha_id = gacha_module:get_cur_gacha_id()
  local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
  if activity_cfg == nil then
    return
  end
  local title_text_id = "Gacha_T0_ClothShop_Title"
  if activity_cfg.subtab == GachaConst.sub_tab.furniture then
    title_text_id = "Gacha_T0_FurnitureShop_Title"
  end
  UIUtil.set_text_by_id(self._txt_panel_title, title_text_id)
  self._is_cloth_pool = activity_cfg.subtab == GachaConst.sub_tab.cloth
  self._is_show_all_suit = true
end

function M:_refresh_coin()
  if is_null(self._obj_coin_item) then
    return
  end
  local cur_gacha_id = gacha_module:get_cur_gacha_id()
  local activity_cfg = gacha_module:get_activity_cfg(cur_gacha_id)
  if activity_cfg == nil then
    return
  end
  local exchange_coin_id = activity_cfg.exchangeshopcoinid or 0
  if self._coin_item == nil then
    self._coin_item = self:add_panel(coin_item_view_cls, self._obj_coin_item, {
      coin_id = exchange_coin_id,
      auto_update = true,
      show_detail = true
    })
    self._coin_item_coin_id = exchange_coin_id
  elseif self._coin_item_coin_id ~= exchange_coin_id then
    self._coin_item:set_coin_id(exchange_coin_id)
    self._coin_item_coin_id = exchange_coin_id
  end
end

function M:_init_custom_data()
  self._coin_item = nil
  self._coin_item_coin_id = 0
  self._cur_select_cfg = nil
  self._tab_item_cls_map = {}
  self._tab_title_cls_map = {}
  self._tab_groups = {}
  self._drawn_map = nil
  self._exchanged_map = nil
  self._is_cloth_pool = false
end

function M:_get_tab_groups(gachapoolid)
  return {}
end

function M:_get_cur_select_index()
  return 0
end

function M:_set_cur_select_index(index)
end

function M:_get_pool_cfg(pool_id, index)
  return nil
end

function M:_is_exchange_panel()
  return true
end

function M:_refresh_detail()
end

function M:_refresh_tab_groups()
  local gacha_id = gacha_module:get_cur_gacha_id()
  local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
  if activity_cfg == nil then
    return
  end
  self._tab_groups = self:_get_tab_groups(activity_cfg.gachapoolid)
  local item_index = self:_get_cur_select_index()
  self._cur_select_cfg = item_index ~= nil and 0 < item_index and self:_get_pool_cfg(activity_cfg.gachapoolid, item_index) or nil
  if self._cur_select_cfg == nil then
    local first_group = self._tab_groups[1]
    local first = first_group ~= nil and first_group.items ~= nil and first_group.items[1] or nil
    if first == nil then
      Logger.LogError("[GachaPoolShowPageBase] empty tab groups, pool: " .. tostring(activity_cfg.gachapoolid))
      return
    end
    self._cur_select_cfg = first
    self:_set_cur_select_index(first.index)
  end
  self._drawn_map, self._exchanged_map = gacha_module:build_owned_data_snapshot(gacha_id)
  self:_refresh_tabs()
  self:_on_item_select(self._cur_select_cfg)
end

function M:_refresh_tabs()
  self:_refresh_scroller(self._scroll_card_list, self._tab_groups, M._on_tab_item_bind, M._on_tab_node_init)
end

function M:_refresh_scroller(scroller, groups, item_bind_func, node_init_func)
  if is_null(scroller) then
    return
  end
  local node_count = #groups
  UIUtil.set_active(scroller, 0 < node_count)
  scroller:SetNodeCount(node_count)
  if node_count <= 0 then
    return
  end
  local bind_cb = pack(self, item_bind_func)
  local init_cb = pack(self, node_init_func)
  for i, group in ipairs(groups) do
    local node_index = i - 1
    local item_count = group.items and #group.items or 0
    scroller:Init(node_index, 0, item_count, bind_cb, init_cb)
    scroller:ExpandNode(node_index, 0)
  end
  scroller:RebindAllVisibleItems()
  if not self._not_move_item_scroller then
    local item_node_index, item_index = self:_refresh_scroll_to_item(groups)
    local items_per_line = scroller:GetItemsPerLine(item_node_index) or 0
    if item_node_index <= 0 and item_index < items_per_line then
      scroller:MoveToNode(item_node_index)
    else
      scroller:MoveToItem(item_node_index, item_index)
    end
  end
  self._not_move_item_scroller = false
end

function M:_refresh_scroll_to_item(groups)
  local cur_select_index = self:_get_cur_select_index()
  for i, group in ipairs(groups) do
    if group.items then
      for j, item in ipairs(group.items) do
        if item.index == cur_select_index then
          return i - 1, j - 1
        end
      end
    end
  end
  return 0, 0
end

function M:_on_tab_node_init(node_trans, node_index)
  local group = self._tab_groups[node_index + 1]
  if not group then
    return
  end
  local title_trans = node_trans:Find(GachaConst.group_title_child_name)
  if is_null(title_trans) then
    title_trans = node_trans
  end
  local title_obj_id = title_trans:GetInstanceID()
  local cls = self._tab_title_cls_map[title_obj_id]
  if not cls then
    cls = self:add_panel(exchange_title_cls, title_trans)
    self._tab_title_cls_map[title_obj_id] = cls
  end
  cls:refresh(group.pool_id, group.pool_index, self:_is_exchange_panel(), self._drawn_map, self._exchanged_map)
end

function M:_on_tab_item_bind(item_trans, node_index, item_index)
  local group = self._tab_groups[node_index + 1]
  if not group or not group.items then
    return
  end
  local pool_cfg = group.items[item_index + 1]
  if pool_cfg == nil then
    return
  end
  local item_obj_id = item_trans:GetInstanceID()
  local cls = self._tab_item_cls_map[item_obj_id]
  if not cls then
    cls = self:add_panel(exchange_item_cls, item_trans)
    self._tab_item_cls_map[item_obj_id] = cls
  end
  local item_info = {
    pool_cfg = pool_cfg,
    selected = pool_cfg.index == self:_get_cur_select_index(),
    is_exchange = self:_is_exchange_panel(),
    on_click = self._on_item_select_callback,
    drawn_map = self._drawn_map,
    exchanged_map = self._exchanged_map
  }
  cls:refresh(item_info)
end

function M:_on_item_select(pool_cfg)
  self:_set_cur_select_index(pool_cfg.index)
  self._cur_select_cfg = pool_cfg
  self:_refresh_detail()
end

function M:_close_scroller(scroller)
  if not is_null(scroller) then
    scroller:Close()
  end
end

function M:_refresh_model_preview()
  if not self._cur_select_cfg then
    return
  end
  UIUtil.set_active(self._trans_3d_cloth_touch_rect, self._is_cloth_pool)
  if self._is_cloth_pool then
    self:_refresh_suit_preview()
  else
    self:_hide_suit_preview()
    UIUtil.set_active(self._obj_common_model_group, true)
    self:_refresh_other_model_preview()
  end
end

function M:_refresh_suit_preview()
  local is_all_suit = self._is_show_all_suit == true
  self._is_show_all_suit = false
  if not is_all_suit then
    local tool_cfg_id = CsToolSkinModuleUtil.GetToolCfgIdBySkinCfgId(self._cur_select_cfg.itemid)
    if tool_cfg_id and 0 < tool_cfg_id then
      self:_show_tool_and_skin(tool_cfg_id, self._cur_select_cfg.itemid)
      return
    end
  end
  local suit_info = gacha_module:get_model_suit_info(gacha_module:get_cur_gacha_id(), self._cur_select_cfg.itemid, is_all_suit)
  self:_show_suit_preview(suit_info, is_all_suit)
end

function M:_refresh_other_model_preview()
  if not self._model_preview_view or self._cur_select_cfg == nil then
    return
  end
  local item_id = self._cur_select_cfg.itemid
  if item_id and 0 < item_id then
    self._model_preview_view:set_data({
      item_id = item_id,
      enable_touch_rotate = true,
      enable_auto_rotate = false,
      load_proxy = self:get_load_proxy()
    })
  end
end

function M:_hide_other_model_preview()
  if self._model_preview_view then
    self._model_preview_view:hide_preview()
  end
end

function M:_show_suit_preview(split, is_all_suit)
  if not split then
    return
  end
  if not self._suit_preview then
    local scene_obj = self.ui_scene_obj
    if is_null(scene_obj) then
      return
    end
    local player_root = UIUtil.find_trans(scene_obj, "Art/ModelPos/pos")
    if is_null(player_root) then
      return
    end
    self._suit_preview = G.New(require("ModelPreview/SuitPreviewController"), player_root)
  end
  self._suit_preview:show_by_cloth_ids(split.cloth_ids, split.style_color_list, is_all_suit, is_all_suit)
  UIUtil.set_active(self._obj_common_model_group, false)
  if self._is_first_show_suit then
    self._is_first_show_suit = false
    local gacha_id = gacha_module:get_cur_gacha_id()
    local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
    if activity_cfg == nil then
      return
    end
    local suit_id = gacha_module:get_first_suit_exchange_id(activity_cfg.gachapoolid)
    if suit_id and 0 < suit_id then
      self._suit_preview:play_pose_by_suit_id(suit_id)
    end
  end
end

function M:_show_tool_and_skin(tool_cfg_id, skin_cfg_id)
  if self._suit_preview then
    self._suit_preview:show_by_tool_and_skin(tool_cfg_id, skin_cfg_id)
  end
end

function M:_hide_suit_preview()
  if self._suit_preview then
    self._suit_preview:hide()
  end
end

function M:_destroy_suit_preview()
  if self._suit_preview then
    self._suit_preview:destroy()
    self._suit_preview = nil
  end
end

function M:_on_btn_exchange()
  self:_on_do_exchange_click()
end

function M:_on_do_exchange_click()
end

function M:_on_btn_go_draw()
  self:_on_do_go_draw_click()
end

function M:_on_do_go_draw_click()
end

function M:_on_pointer_down(evt)
  if self._suit_preview then
    self._suit_preview:on_begin_drag(evt)
  end
end

function M:_on_drag(evt)
  if self._suit_preview then
    self._suit_preview:on_drag(evt)
  end
end

function M:_on_pointer_up(evt)
  if self._suit_preview then
    self._suit_preview:on_end_drag(evt)
  end
end

function M:_on_btn_info_dark_click()
  if self._cur_select_cfg == nil then
    return
  end
  local item_id = self._cur_select_cfg.itemid
  if item_id == nil or item_id <= 0 then
    return
  end
  item_module:open_item_info_dialog(item_id)
end

return M
