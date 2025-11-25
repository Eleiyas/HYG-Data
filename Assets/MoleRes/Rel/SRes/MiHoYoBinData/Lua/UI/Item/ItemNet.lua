item_module = item_module or {}

function item_module:register_cmd_handler()
  item_module:un_register_cmd_handler()
  self._tbl_rep = {}
  self._tbl_rep[PlayEateRsp] = pack(self, item_module._handle_play_eate_rep)
  self._tbl_rep[MakeByRecipeRsp] = pack(self, item_module._handle_make_by_recipe_rep)
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:register_cmd_handler(k, v)
  end
end

function item_module:un_register_cmd_handler()
  if self._tbl_rep == nil then
    return
  end
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:unregister_cmd_handler(k)
  end
end

function item_module:_handle_play_eate_rep(data)
  if data then
    if data.Retcode == 0 then
      local id_cfg = item_module:get_id_cfg_by_id(data.EateInfor.ItemConfID)
      if id_cfg then
        if TagUtil.config_has_tag(data.EateInfor.ItemConfID, EntityTagTags.Tags.cfunction_taskitem) or item_module:item_is_recipe(data.EateInfor.ItemConfID) then
          if 0 < data.EateInfor.Count then
            recipe_module:get_group_state_by_id(data.EateInfor.ItemConfID)
            red_point_module:record_with_id(red_point_module.red_point_type.diy_card_book, data.EateInfor.ItemConfID)
            item_module:play_recipe_Anim(data.EateInfor)
          end
        else
          item_module:auto_use_recipe()
        end
      end
    elseif data.Retcode == 602 then
      EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id("BagCountIsMax_UseItem"))
    end
  end
end

function item_module:set_auto_learn_secretly(auto_learn_secretly)
  self._auto_learn_secretly = auto_learn_secretly
end

function item_module:play_eate_req(item_data)
  if is_null(item_data) then
    return
  end
  local data = {
    PlayGUID = player_module:get_player_data().PlayerGuid,
    ItemGUID = item_data.GUID,
    ItemConfID = item_data.ConFigID,
    Count = 1
  }
  NetHandlerIns:send_data(PlayEateReq, data)
end

function item_module:make_by_recipe_req(cfg_id, count)
  local data = {RecipeID = cfg_id, Count = count}
  NetHandlerIns:send_data(MakeByRecipeReq, data)
end

function item_module:_handle_make_by_recipe_rep(rep)
  if rep and rep.Retcode == 0 then
    local is_has, save_value = CsMemoryManagerUtil.TryGetGlobalBoolValue(562949953421316)
    if not (is_has ~= nil and is_has) or not save_value then
      CsMemoryManagerUtil.TrySetGlobalBoolValue(562949953421316, true)
    end
    CsMemoryManagerUtil.TryPlusGlobalIntValue(562949953421462)
    CsMemoryManagerUtil.TryPlusGlobalIntValue(562949953421463)
    AqibaoCreation.CreateFromCrafting()
    if tracking_module:is_tracking_by_track_type(tracking_module.track_type.feature, tracking_module.data_source_type.recipe, rep.RecipeID) then
      tracking_module:set_tracking_by_track_type(tracking_module.track_type.feature, tracking_module.data_source_type.recipe, rep.RecipeID, false, false)
      tracking_module:set_cur_track_type(tracking_module.track_type.memo)
    end
  elseif rep.Retcode == 602 then
    UIUtil.show_tips_by_text_id("Packet_NumIsMax_CatchInsect")
  end
  red_point_module:record_with_id(red_point_module.red_point_type.diy_card_book, rep.RecipeID * 10)
  lua_event_module:send_event(lua_event_module.event_type.recipe_make_success, rep.Retcode == 0)
end

return item_module or {}
