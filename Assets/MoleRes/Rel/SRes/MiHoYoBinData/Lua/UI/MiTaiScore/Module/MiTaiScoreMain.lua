mi_tai_score_module = mi_tai_score_module or {}

function mi_tai_score_module:add_event()
  mi_tai_score_module:remove_event()
  self._events = {}
  self._events[EventID.LuaSetLoadingState] = pack(self, mi_tai_score_module.on_loading_end)
  self._events[EventID.MiTaiEvaluateCameraShow] = pack(self, mi_tai_score_module.show_result_performance_camera_show)
  self._events[EventID.ShowMiTaiEvaluateResultPage] = pack(self, mi_tai_score_module.show_result_page)
  self._events[EventID.BuildMiTaiEvaluateResultData] = pack(self, mi_tai_score_module._on_commit_evaluate)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function mi_tai_score_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function mi_tai_score_module:_on_commit_evaluate(result)
  if result and result.Retcode == 0 then
    self:build_evaluate_data(CsMiTaiModuleUtil.mostRecentScore, CsMiTaiModuleUtil.historyMaxScore, result.CommitScore, result.HistoryMaxScore)
  end
end

function mi_tai_score_module:on_loading_end(state)
end

function mi_tai_score_module:show_result_page()
  UIManagerInstance:open("UI/MiTaiScore/MiTaiResultPage")
end

function mi_tai_score_module:show_bubble(content)
end

function mi_tai_score_module:show_result_performance_camera_show(type)
  if self.score_cam_ctrl then
    if type == 1 then
      self.score_cam_ctrl:SwitchToShow()
    elseif type == 2 then
      self.score_cam_ctrl:SwitchToResult()
    end
  end
end

function mi_tai_score_module:show_result_performance()
  local guid = UIManagerInstance:open("UI/Performance/BlankPage", nil)
  
  local function on_early_stop()
    UIManagerInstance:close(guid)
  end
  
  EntityUtil.hide_or_show_all_avatar(false, 0.1)
  CsBlackScreenManagerUtil.ShowBlackScreen(0)
  self.evaluate_npc = EntityUtil.create_virtual_npc(self.evaluate_npc_id)
  if self.evaluate_npc ~= 0 then
    self:_init_cam_root(function(succeeded)
      CsBlackScreenManagerUtil.HideBlackScreen(0.15)
      if succeeded then
        self:start_to_score_result_camera()
        if self.score_cam_ctrl then
          self.score_cam_ctrl:SwitchToWalk()
        end
        CsUIUtil.MiTaiEvaluateResultShow(self.evaluate_npc, function(finish)
          if finish then
            CsBlackScreenManagerUtil.StartBlackScreen(0.2, 0.4, 0.2, function()
              if self.score_cam_ctrl then
                self.score_cam_ctrl:SwitchToStand()
              end
              local succ, pos = self:_get_empty_pos()
              if succ then
                EntityUtil.stop_avavar_move(self.evaluate_npc)
                EntityUtil.set_entity_position_by_guid(self.evaluate_npc, pos.x, pos.y, pos.z)
                self.cam_look:LookAt(self.cam_target)
                self.cam_look:SetLocalEulerAnglesX(0)
                self.cam_look:SetLocalEulerAnglesZ(0)
                local target_quaternion = self.cam_look.rotation
                EntityUtil.set_entity_rotation_by_guid(self.evaluate_npc, target_quaternion.x, target_quaternion.y, target_quaternion.z, target_quaternion.w)
                CsPerformanceManagerUtil.ShowPerformance(3001180001, function()
                  self:result_performance_end()
                  self:exit_score_result_camera()
                end, self.evaluate_npc)
              else
                self:result_performance_end()
                self:exit_score_result_camera()
                on_early_stop()
              end
            end)
          else
            self:result_performance_end()
            self:exit_score_result_camera()
            on_early_stop()
          end
        end)
      else
        self:result_performance_end()
        self:exit_score_result_camera()
        on_early_stop()
      end
    end)
  end
end

function mi_tai_score_module:_get_empty_pos()
  local succ, pos = GameSceneUtility.TryGetEmptyPos2X2()
  if not succ then
    succ, pos = GameSceneUtility.TryGetEmptyPos()
  end
  return succ, pos
end

function mi_tai_score_module:result_performance_end()
  if self.evaluate_npc ~= 0 then
    EntityUtil.destroy_entity_by_guid(self.evaluate_npc)
  end
  EntityUtil.hide_or_show_all_avatar(true, 0.1)
  self.evaluate_npc = 0
end

return mi_tai_score_module
