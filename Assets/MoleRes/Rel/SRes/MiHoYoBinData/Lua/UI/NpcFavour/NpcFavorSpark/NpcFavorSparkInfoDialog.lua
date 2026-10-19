local M = G.Class("NpcFavorSparkInfoDialog", G.UIWindow)
local base = G.UIWindow
local spark_days_text_id = "Companion_Star_Spark_Days"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NpcFavorSpark/NpcFavorSparkInfoDialog"
  self.config.type = EUIType.Dialog
  self._npc_id = 0
  self._last_npc_id = 0
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data()
  self._npc_id = data and data.npc_id or 0
  self:refresh()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_bg)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_bg, pack(self, M.close_self))
  self:bind_close_btn(self._btn_close)
end

function M:refresh()
  if not self._npc_id or self._npc_id == 0 then
    return
  end
  self:_refresh_level_state()
  self:_refresh_npc_icon()
  self:_refresh_npc_name()
  self:_refresh_level_names()
  self:_refresh_days()
  self._last_npc_id = self._npc_id
end

function M:_refresh_level_state()
  if is_null(self._state_group_level) then
    return
  end
  local spark_data = CsNpcGrowthModuleUtil.GetNpcFavorSparkDisplayData(self._npc_id)
  local level = spark_data and spark_data.level or 1
  local max_level_days = spark_data and spark_data.maxLevelDays or 1
  local state = level - 1
  self._state_group_level:SetState(state)
  UIUtil.set_text_by_id(self._txt_day_num_dynamic, "Companion_Star_Spark_Days", max_level_days)
  local text = self:_get_spark_level_title_text(level)
  local cfg = npc_favour_module:get_favor_spark_cfg(self._npc_id, level)
  if not_null(text) and not_null(cfg) then
    UIUtil.set_text(text, cfg.desc)
  end
end

function M:_refresh_npc_icon()
  npc_module:set_npc_icon_by_id(self._img_head, self._npc_id, self:get_load_proxy())
end

function M:_refresh_npc_name()
  npc_module:set_npc_name_by_id(self._txt_name_dynamic, self._npc_id)
end

function M:_refresh_level_names()
  self:_set_level_name_text(self._txt_level_1, 1)
  self:_set_level_name_text(self._txt_level_2, 2)
  self:_set_level_name_text(self._txt_level_3, 3)
end

function M:_set_level_name_text(text, level)
  local cfg = npc_favour_module:get_favor_spark_cfg(self._npc_id, level)
  if not cfg then
    UIUtil.set_text(text, "")
    return
  end
  UIUtil.set_text(text, cfg.desc or "")
end

function M:_refresh_days()
  local cfg_lv1 = npc_favour_module:get_favor_spark_cfg(self._npc_id, 1)
  local cfg_lv2 = npc_favour_module:get_favor_spark_cfg(self._npc_id, 2)
  local cfg_lv3 = npc_favour_module:get_favor_spark_cfg(self._npc_id, 3)
  self:_set_days_text(self._txt_days_1, cfg_lv1 and cfg_lv1.upgradedays or 0)
  self:_set_days_text(self._txt_days_2, cfg_lv2 and cfg_lv2.upgradedays or 0)
  self:_set_days_text(self._txt_days_3, cfg_lv3 and cfg_lv3.downgradedays or 0)
  self:_set_days_text(self._txt_days_4, cfg_lv2 and cfg_lv2.downgradedays or 0)
end

function M:_get_spark_level_title_text(level)
  if level == 1 then
    return self._txt_title_1
  elseif level == 2 then
    return self._txt_title_2
  elseif level == 3 then
    return self._txt_title_3
  end
  return nil
end

function M:_set_days_text(text, days)
  UIUtil.set_text_by_id(text, spark_days_text_id, days or 0)
end

return M
