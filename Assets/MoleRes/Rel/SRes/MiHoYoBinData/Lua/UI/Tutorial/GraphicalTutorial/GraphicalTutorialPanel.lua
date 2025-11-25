local M = G.Class("GraphicalTutorialPanel", G.TutorialPanelBase)
local base = G.TutorialPanelBase
local teaching_tutorial_round_class_name = "UI/Tutorial/TutorialDetailRound"
local img_data_type = typeof(ImageData)
local video_data_type = typeof(VideoData)

function M:init()
  base.init(self)
  self._is_close = false
  self._cur_index = 0
  self._weak_graphic_panel = false
end

function M:on_create()
  base.on_create(self)
  UIUtil.set_active(self._trans_round, false)
  self._rounds = {}
end

function M:on_disable()
  base.on_disable(self)
  self:release_video_task()
end

function M:set_active(active)
  if self.is_active == active then
    return
  end
  if active then
    self:_inner_set_active(true)
    self:on_enable()
    self:play_enter_anim()
  else
    self:play_exit_anim()
  end
end

function M:play_exit_anim()
  if self._has_binder and self._cur_data then
    self._is_play_anim = true
    if self.show_complete_ani then
      self.binder:PlayAnimation("TutorialArrowExitAnim", function()
        self._canvas_group.alpha = 0
        UIUtil.set_active(self._complete_tip_obj, true)
        self.binder:PlayAnimation("CompleteEnter", function()
          self.binder:PlayAnimation("CompleteExit", function()
            UIUtil.set_active(self._complete_tip_obj, false)
            self._is_play_anim = false
            self:exit_anim_call_back()
          end)
        end)
      end)
    else
      self.binder:PlayAnimation("TutorialArrowExitAnim", function()
        self._is_play_anim = false
        self:exit_anim_call_back()
      end)
    end
  else
    self:exit_anim_call_back()
  end
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if self.is_active and self._is_show_close and self._count_down > 0 then
    self._count_down = self._count_down - deltaTime
    if self._count_down > 0 then
      local time_str = "(" .. tostring(math.ceil(self._count_down)) .. "s)"
      local str = UIUtil.get_text_by_id("TutorialPage_txt_donate_title_2", time_str)
      UIUtil.set_text(self._txt_count_down, str)
      if self._btn_close.interactable then
        self._btn_close.interactable = false
      end
    else
      local str = UIUtil.get_text_by_id("TutorialPage_txt_donate_title_2", "")
      UIUtil.set_text(self._txt_count_down, str)
      self._btn_close.interactable = true
    end
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_close, function()
    self:_on_btn_close_click()
  end)
  self:bind_callback(self._btn_pre, pack(self, M._on_pre_btn))
  self:bind_callback(self._btn_next, pack(self, M._on_next_btn))
end

function M:_on_btn_close_click()
  if self._is_close then
    return
  end
  self._is_close = true
  self:close_panel()
end

function M:refresh(data)
  self._cur_data = data
  if not self._weak_graphic_panel then
    self._canvas_group.alpha = 1
    self.show_complete_ani = data.showCompeteAni
    self._complete_tip_canvas_group.alpha = 0
    UIUtil.set_active(self._complete_tip_obj, false)
  end
  if CsGameManagerUtil.noGraphicTutorialTime then
    self._count_down = 0
  else
    self._count_down = data.completeCountdown
  end
  self._is_close = false
  self._cur_index = 1
  self._all_graphical_data = list_to_table(data.steps)
  self._is_show_close = false
  self:_refresh_view()
  self:_init_round()
  UIUtil.set_active(self._btn_close, self._is_show_close)
  local str = UIUtil.get_text_by_id("TutorialPage_txt_donate_title_2", "")
  UIUtil.set_text(self._txt_count_down, str)
  if not_null(self._scroll_view) then
    self._scroll_view.verticalNormalizedPosition = 1
  end
end

function M:_refresh_btn()
  UIUtil.set_active(self._trans_pre, self._cur_index > 1)
  UIUtil.set_active(self._trans_next, self._cur_index < #self._all_graphical_data)
  if self._cur_index >= #self._all_graphical_data then
    self._is_show_close = true
  end
  UIUtil.set_active(self._btn_close, self._is_show_close)
end

function M:_hide_btn()
  UIUtil.set_active(self._trans_pre, false)
  UIUtil.set_active(self._trans_next, false)
end

function M:_refresh_view()
  local data = self._all_graphical_data[self._cur_index]
  local desc = data.content
  local graphic_data = data.graphicData
  self:release_video_task()
  if not_null(graphic_data) then
    local type = graphic_data:GetType()
    if type == img_data_type then
      local img_path = graphic_data.path
      UIUtil.set_active(self._video_root_obj, false)
      UIUtil.set_active(self._picture_root_obj, true)
      UIUtil.set_text_with_dynamic_sprite(self._txt_guide, desc)
      if not is_null(img_path) and img_path ~= "" then
        UIUtil.set_image(self._img_guide, img_path, self:get_load_proxy())
      end
      self:_refresh_btn()
    elseif type == video_data_type then
      local video_path = self:_get_video_path(graphic_data.path)
      self:_hide_btn()
      UIUtil.set_active(self._video_root_obj, true)
      UIUtil.set_active(self._picture_root_obj, false)
      UIUtil.set_text_with_dynamic_sprite(self._txt_guide, desc)
      self._cur_task = VideoTask()
      self._cur_task.displayType = DisplayType.LocalPartial
      self._cur_task.screenImage = self._video_img
      self._cur_task.path = video_path
      self._cur_task.isLoop = true
      
      function self._cur_task.onStartPlay()
        self:_refresh_btn()
      end
      
      function self._cur_task.onPlayError()
        self:_refresh_btn()
      end
      
      UIUtil.set_active(self._video_img, true)
      self.playing_id = CsVideoManagerUtil.Play(self._cur_task)
    end
  end
  self:_refresh_round_state()
end

function M:_get_video_path(path)
  if string.is_valid(path) then
    local first_slash_index = string.find(path, "/")
    if first_slash_index then
      return string.sub(path, first_slash_index + 1)
    else
      return path
    end
  end
  return ""
end

function M:release_video_task()
  if self._cur_task then
    self._cur_task.onStartPlay = nil
    self._cur_task.onPlayError = nil
  end
  self._cur_task = nil
  if self.playing_id and self.playing_id ~= 0 then
    CsVideoManagerUtil.Stop(self.playing_id)
  end
end

function M:_init_round()
  local count = #self._all_graphical_data
  if count <= table.count(self._rounds) then
    for index, round in ipairs(self._rounds) do
      if index == 1 then
        round:set_color(0)
      else
        round:set_color(1)
      end
      if index <= count and 1 < count then
        UIUtil.set_active(round.trans, true)
      else
        UIUtil.set_active(round.trans, false)
      end
    end
    return
  end
  if 1 < count then
    local round
    for i = 1, #self._all_graphical_data do
      if self._rounds[i] == nil then
        local round_trans = UIUtil.load_prefab_set_parent(self._trans_round, self._trans_page_num)
        round = self:add_panel(teaching_tutorial_round_class_name, round_trans)
        table.insert(self._rounds, round)
      else
        round = self._rounds[i]
      end
      UIUtil.set_active(round.trans, true)
      if i == 1 then
        round:set_color(0)
      else
        round:set_color(1)
      end
    end
  end
end

function M:_refresh_round_state()
  for index, round in ipairs(self._rounds) do
    if index == self._cur_index then
      round:set_color(0)
    else
      round:set_color(1)
    end
  end
end

function M:_on_pre_btn()
  self._cur_index = self._cur_index - 1
  self._cur_index = math.max(0, self._cur_index)
  self:_refresh_view()
end

function M:_on_next_btn()
  self._cur_index = self._cur_index + 1
  self._cur_index = math.min(self._cur_index, #self._all_graphical_data)
  self:_refresh_view()
end

return M
