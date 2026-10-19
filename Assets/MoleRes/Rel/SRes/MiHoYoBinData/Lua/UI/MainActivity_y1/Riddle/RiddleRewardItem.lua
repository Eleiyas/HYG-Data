local item_v2_cls = item_module.item_v2_panel_cls_name
local LANTERN_CONSTANT_CFG_ID = 1
local M = G.Class("RiddleRewardItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._item_panel = nil
  self._stage = 0
  self._state = 0
  self._on_claim_callback = nil
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._obj_item_v2_basic) then
    self._item_panel = self:add_panel(item_v2_cls, self._obj_item_v2_basic)
  end
  if not is_null(self._btn) then
    self:bind_callback(self._btn, pack(self, M._on_click_claim))
  end
end

function M:_on_click_claim()
  if self._state ~= 1 then
    return
  end
  if self._on_claim_callback ~= nil then
    self._on_claim_callback(self._stage)
  end
end

function M:_get_stage_c_gift_pic_path()
  local cfg_type
  local ok = pcall(function()
    cfg_type = typeof(CS.miHoYo.HYG.ExcelData.BLanternRiddlesConstantCfg)
  end)
  if not ok or cfg_type == nil then
    return nil
  end
  local ok_table, table_obj = pcall(function()
    return CS.miHoYo.HYG.UI.CsExcelDataUtil.GetTable(cfg_type)
  end)
  if not ok_table or table_obj == nil then
    return nil
  end
  local ok_get, cfg = pcall(function()
    return ExcelDataUtil.get_value(cfg_type, LANTERN_CONSTANT_CFG_ID)
  end)
  if not ok_get then
    return nil
  end
  if is_null(cfg) then
    return nil
  end
  local pic
  local ok_pic = pcall(function()
    pic = cfg.StageCGiftPng or cfg.stagecgiftpng
  end)
  if not ok_pic then
    return nil
  end
  if pic == nil or pic == "" then
    return nil
  end
  return pic
end

function M:refresh(data)
  if data == nil then
    return
  end
  local state = tonumber(data.state) or 0
  local stage = tonumber(data.stage) or 0
  local need_active = tonumber(data.need_active) or 0
  local prev_need_active = tonumber(data.prev_need_active) or 0
  local current_active = tonumber(data.current_active) or 0
  local is_last = data.is_last == true
  local reward_item_id = tonumber(data.reward_item_id) or 0
  local reward_count = tonumber(data.reward_count) or 0
  self._stage = stage
  self._state = state
  self._on_claim_callback = data.on_click_claim
  if not is_null(self._state_finish) then
    self._state_finish:SetState(state)
  end
  if not is_null(self._state_lastone) then
    self._state_lastone:SetState(is_last and 1 or 0)
  end
  if not is_null(self._text_num) then
    UIUtil.set_text(self._text_num, tostring(need_active))
  end
  if not is_null(self._text_name) then
    local item_name = ""
    if 0 < reward_item_id then
      item_name = item_module:get_item_name_by_id(reward_item_id) or ""
    end
    UIUtil.set_text(self._text_name, item_name)
  end
  if not is_null(self._img_showhandle) then
    local pic_path
    if is_last then
      pic_path = self:_get_stage_c_gift_pic_path()
    end
    local show_handle = pic_path ~= nil and pic_path ~= ""
    UIUtil.set_active(self._img_showhandle, show_handle)
    if show_handle then
      UIUtil.set_image(self._img_showhandle, pic_path, self:get_load_proxy())
    end
  end
  if not is_null(self._slider_dot) then
    local show_slider = 1 < stage
    if self._slider_dot.gameObject ~= nil then
      UIUtil.set_active(self._slider_dot.gameObject, show_slider)
    end
    local slider_value = 0
    if show_slider and 0 < current_active and prev_need_active < current_active then
      local range = need_active - prev_need_active
      if 0 < range then
        slider_value = (current_active - prev_need_active) / range
        if slider_value < 0 then
          slider_value = 0
        elseif 1 < slider_value then
          slider_value = 1
        end
      end
    end
    self._slider_dot.value = slider_value
  end
  if self._item_panel ~= nil then
    if 0 < reward_item_id then
      self._item_panel:set_active(true)
      self._item_panel:set_item_data(reward_item_id, reward_count)
      self._item_panel:bind_item_info_btn(reward_item_id)
      self._item_panel:set_red_point(state == 1, RedPointType.GiftRP)
    else
      self._item_panel:set_active(false)
    end
  end
end

return M
