menu_wheel_module = menu_wheel_module or {}
menu_wheel_module.MENU_WHEEL_DEBUG = true

function menu_wheel_module:log_mw(msg)
  if self.MENU_WHEEL_DEBUG then
    Logger.Log("[MenuWheel] " .. msg)
  end
end

menu_wheel_module.GAMEPAD_STICK_DEADZONE = 0.3
menu_wheel_module.MENU_WHEEL_ITEM_NUM = 8
menu_wheel_module.INDEX_START_OFFSET = -1
menu_wheel_module.QUICK_FOOD_SLOT_COUNT = 3

function menu_wheel_module:_get_islandbuild_phone_app_cfg()
  if self._islandbuild_phone_app_cfg == nil then
    local cfg_tbl = LocalDataUtil.get_table(typeof(PhoneAppButtonCfg))
    self._islandbuild_phone_app_cfg = cfg_tbl and cfg_tbl[FunctionEntranceType.IslandEdit]
  end
  return self._islandbuild_phone_app_cfg
end

function menu_wheel_module:_get_first_quick_food_guid()
  for slot_index = 0, menu_wheel_module.QUICK_FOOD_SLOT_COUNT - 1 do
    local success, slot_guid = CsCookModuleUtil.TryGetFoodQuickBarSlotGuid(slot_index)
    if success and slot_guid and 0 < slot_guid then
      return slot_guid
    end
  end
  return 0
end

function menu_wheel_module:is_entry_scene_matched(entry)
  if entry.scene_id == nil then
    return true
  end
  local cur_scene_id = level_module:get_cur_scene_id()
  if type(entry.scene_id) == "table" then
    for _, id in ipairs(entry.scene_id) do
      if id == cur_scene_id then
        return true
      end
    end
    return false
  end
  return entry.scene_id == cur_scene_id
end

menu_wheel_module.MENU_WHEEL_ENTRIES = {
  {
    key = "footprint",
    entrance_type = FunctionEntranceType.Lemi,
    is_unlocked = function()
      return not OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateMilestone) or CsBattlePassUtil.IsInBPScene() or level_module:cur_level_is_main()
    end
  },
  {
    key = "season",
    entrance_type = FunctionEntranceType.ThemeSeason,
    icon_override = function()
      return theme_season_module:get_hud_icon_path()
    end,
    is_unlocked = function()
      theme_season_module:update_season_time_state()
      return theme_season_module:is_season_active()
    end
  },
  {
    key = "activity",
    entrance_type = FunctionEntranceType.ActivityCenter,
    is_unlocked = function()
      return activity_center_module:is_unlocked()
    end
  },
  {
    key = "gacha",
    entrance_type = FunctionEntranceType.Gacha,
    is_unlocked = function()
      return OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateCurioGacha)
    end
  },
  {
    key = "starbay",
    entrance_type = FunctionEntranceType.CompanionStar,
    is_unlocked = function()
      return CsCompanionStarModuleUtil.companionStarUnlock and not CsBattlePassUtil.IsInBPScene()
    end
  },
  {
    key = "memo",
    entrance_type = FunctionEntranceType.Task,
    is_unlocked = function()
      return OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateTaskBoard)
    end
  },
  {
    key = "islandbuild",
    entrance_id = FunctionEntranceType.IslandEdit,
    icon_override = function()
      local cfg = menu_wheel_module:_get_islandbuild_phone_app_cfg()
      return cfg and cfg.buttonIcon
    end,
    name_override = function()
      local cfg = menu_wheel_module:_get_islandbuild_phone_app_cfg()
      return cfg and cfg.buttonName
    end,
    is_unlocked = function()
      return OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateSceneOverheadEdit)
    end,
    open = function()
      if CsGameplayUtilitiesEmergencySwitchUtil.IsSwitchOnByType(EmergencySwitchType.EmergencySwitchCloseIslandBuild) then
        CsGameplayUtilitiesEmergencySwitchUtil.ShowEmergencySwitchTip()
        return
      end
      world_editor_module:enter_world_editor()
    end,
    scene_id = {2}
  },
  {
    key = "galactic_bazaar",
    entrance_type = FunctionEntranceType.GalacticBazaar,
    is_unlocked = function()
      return GameSceneUtility.CurInAllGalacticBazaar() and galactic_bazaar_module:get_is_first_galactic_bazaar_board() and not CsBattlePassUtil.IsInBPScene()
    end,
    scene_id = {
      13,
      10027,
      10029
    }
  },
  {
    key = "edit",
    entrance_type = FunctionEntranceType.Edit,
    is_unlocked = function()
      return GameSceneUtility.IsCurrentScenePlayerHome() and OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateHomeDecoration) and not CsInteractionUtil.IsFeastInEnjoyProgress()
    end,
    scene_id = GameSceneCfg.PlayerHomeId
  },
  {
    key = "mi_tai_score",
    entrance_type = FunctionEntranceType.Evaluate,
    is_unlocked = function()
      return GameSceneUtility.IsCurrentScenePlayerHome() and OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateHouseScore)
    end,
    scene_id = GameSceneCfg.PlayerHomeId
  }
}
menu_wheel_module.PLACE_HOLDER_ENTRY = {
  key = "placeHolder",
  is_placeholder = true
}
menu_wheel_module.MENU_WHEEL_BUTTON_ENTRIES = {
  [ActionType.Act.DPad_Up] = {
    {
      key = "online",
      icon = "UISprite/Load/MainPageIcon/HUD_Online.png",
      open = function()
        UIManagerInstance:open("UI/MainPage/OnlineAuthorityPage")
      end
    }
  },
  [ActionType.Act.DPad_Down] = {
    {
      key = "matching",
      name_text_id = "RhythmShow_WaitingList_UI_1",
      icon = "Assets/MoleRes/Rel/SRes/UISprite/Load/MainPageIcon/HUD_Match.png",
      open = function()
        local activity_id = galactic_bazaar_module:get_current_match_activity_id()
        if activity_id == 0 then
          return
        end
        UIManagerInstance:open("UI/GalacticBazaar/GalacticBazaarActivityMatchDialog", {activity_id = activity_id})
      end,
      is_unlocked = function()
        return galactic_bazaar_module:get_match_state()
      end
    },
    {
      key = "invite",
      icon_override = function()
        local npc_cfg = npc_module:get_npc_cfg(npc_module:get_following_npc_id())
        if not_null(npc_cfg) then
          return npc_cfg.iconnamesmall
        end
      end,
      open = function(panel)
        local npc_walk_together_panel = panel.holder:get_panel(MainPanelType.NpcWalkTogether)
        if npc_walk_together_panel then
          npc_walk_together_panel:on_invite_shortcut()
        end
      end,
      is_unlocked = function()
        return npc_module:is_npc_following()
      end
    }
  },
  [ActionType.Act.ButtonNorth] = {
    {
      key = "appearance",
      entrance_id = FunctionEntranceType.Appearance,
      icon = "UISprite/Load/MobileApp/Icon_MobileApp_Appearance.png",
      is_unlocked = function()
        return OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateAppearanceApp)
      end,
      open = function()
        if not star_express_module:has_tracking_order() then
          appearance_module:open_appearance_page()
        else
          star_express_module:show_confirm_exit_work_pop_up(function()
            star_express_module:change_working_state(function()
              if not star_express_module:is_working() then
                star_express_module:take_off_express_clothes()
                appearance_module:open_appearance_page()
              end
            end)
          end)
        end
      end
    }
  },
  [ActionType.Act.ButtonWest] = {
    {
      key = "map",
      entrance_id = FunctionEntranceType.Map,
      open = function()
        if GameplayUtilities_Avatar.UIDefaultValidatePlayerStates() == false then
          return
        end
        CsMap3DManagerUtil.OpenMapUI()
        local params = {}
        params.opreate_type = "1"
        params.scene_id = tostring(level_module:get_cur_scene_id())
        CsBuriedPointReportManagerUtil.ReportActionFromLuaTable(BuriedPointReportActionEnum.enter_map, "EnterMap", params)
      end
    }
  },
  [ActionType.Act.ButtonEast] = {
    {
      key = "eat",
      icon = "UISprite/Load/LayerIcon/Icon_HUD_EatMeal.png",
      open = function(panel)
        local entrance_panel = panel.holder:get_panel(MainPanelType.EntranceButton)
        if entrance_panel then
          entrance_panel:on_eat_shortcut()
        end
      end
    }
  },
  [ActionType.Act.ButtonSouth] = {
    {
      key = "exit",
      icon = "UISprite/Load/MainPageIcon/HUD_Leave.png",
      open = function(panel)
        local entrance_panel = panel.holder:get_panel(MainPanelType.EntranceButton)
        if entrance_panel then
          entrance_panel:on_exit_shortcut()
        end
      end,
      scene_id = {
        13,
        10027,
        10029
      }
    }
  }
}
return menu_wheel_module
