local M = G.Class("ActivityIntroductionDialog", G.UIWindow)
local base = G.UIWindow
local TIME_REFRESH_INTERVAL = 1
local ENDED_TIME_TEXT_ID = "LeadingStarFestival_Activity_tips"
local TIME_STATE = {
  hidden = 0,
  show = 1,
  ended = 2
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Mail/SystemMailIntroductionDialog"
  self.config.type = EUIType.Dialog
  self._activity_id = 0
  self._introduction_cfg = nil
  self._trans_sub_parent = nil
  self._groups = nil
  self._time_elapsed = 0
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self._time_elapsed = 0
  self:_refresh()
end

function M:on_disable()
  base.on_disable(self)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if self._activity_id == 0 then
    return
  end
  self._time_elapsed = self._time_elapsed + deltaTime
  if self._time_elapsed < TIME_REFRESH_INTERVAL then
    return
  end
  self._time_elapsed = 0
  self:_refresh_time()
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
end

function M:_refresh()
  local data = self:get_extra_data()
  if type(data) ~= "table" then
    self:close_self()
    Logger.LogError("[ActivityIntroductionDialog] extra_data 需要 { activity_id, introduction_cfg_id }")
    return
  end
  self._activity_id = tonumber(data.activity_id) or 0
  local introduction_cfg_id = tonumber(data.introduction_cfg_id) or 0
  if introduction_cfg_id <= 0 then
    self:close_self()
    Logger.LogError("[ActivityIntroductionDialog] introduction_cfg_id 非法: " .. tostring(data.introduction_cfg_id))
    return
  end
  self._introduction_cfg = LocalDataUtil.get_value(typeof(CS.IntroductionDialogCfg), introduction_cfg_id)
  if is_null(self._introduction_cfg) then
    self:close_self()
    Logger.LogError("[ActivityIntroductionDialog] IntroductionDialogCfg 不存在: " .. introduction_cfg_id)
    return
  end
  UIUtil.set_text(self._txt_title, self._introduction_cfg.mainTitle)
  self:_refresh_sub_items()
  self:_refresh_time()
end

function M:_refresh_sub_items()
  local parent = self:_get_sub_parent()
  if parent == nil then
    return
  end
  self._groups = self._groups or {
    {
      title = self._obj_sub_title,
      desc = self._obj_sub_desc,
      line = self._obj_sub_line
    }
  }
  local sub_infos = list_to_table(self._introduction_cfg.subIntroductionInfos)
  local max_num = math.max(#self._groups, #sub_infos)
  for i = 1, max_num do
    local group = self._groups[i]
    if group == nil then
      group = self:_create_group(parent)
      self._groups[i] = group
    end
    local sub_info = sub_infos[i]
    local is_show = not_null(sub_info)
    UIUtil.set_active(group.title, is_show)
    UIUtil.set_active(group.desc, is_show)
    UIUtil.set_active(group.line, is_show and i < #sub_infos)
    if is_show then
      UIUtil.set_text(group.title, sub_info.title)
      UIUtil.set_text(group.desc, sub_info.desc)
    end
  end
  parent:SetAnchoredPosY(0)
  LayoutRebuilder.ForceRebuildLayoutImmediate(parent)
end

function M:_get_sub_parent()
  if self._trans_sub_parent ~= nil then
    return self._trans_sub_parent
  end
  if is_null(self._obj_sub_title) then
    Logger.LogError("[ActivityIntroductionDialog] prefab 缺少 _obj_sub_title")
    return nil
  end
  self._trans_sub_parent = self._obj_sub_title.transform.parent
  return self._trans_sub_parent
end

function M:_create_group(parent)
  return {
    title = parent:AddChildFromPrefab(self._obj_sub_title.transform),
    desc = parent:AddChildFromPrefab(self._obj_sub_desc.transform),
    line = parent:AddChildFromPrefab(self._obj_sub_line.transform)
  }
end

function M:_refresh_time()
  if is_null(self._ui_state_time) then
    Logger.LogWarning("[ActivityIntroductionDialog] _ui_state_time is missing on prefab.")
    return
  end
  local phase_enum = activity_center_module.activity_time_phase
  local phase, remain = activity_center_module:get_activity_time_phase(self._activity_id)
  if phase == phase_enum.ended then
    self._ui_state_time:SetState(TIME_STATE.ended)
    UIUtil.set_text(self._txt_time, UIUtil.get_text_by_id(ENDED_TIME_TEXT_ID))
    return
  end
  if remain <= 0 then
    self._ui_state_time:SetState(TIME_STATE.hidden)
    return
  end
  self._ui_state_time:SetState(TIME_STATE.show)
  UIUtil.set_text(self._txt_time, UIUtil.format_left_time(remain))
end

return M
