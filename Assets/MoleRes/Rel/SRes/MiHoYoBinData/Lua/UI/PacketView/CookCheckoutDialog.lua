local M = G.Class("CookCheckoutDialog", G.UIWindow)
local base = G.UIWindow
local auto_close_duration = 3
local cook_proficiency_state = {
  exp_add = 0,
  lv_up = 1,
  lv_max = 2,
  daily_max = 3
}
local chef_level_state = {
  exp_add = 0,
  lv_up = 1,
  lv_max = 2,
  daily_max = 3
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/PacketView/CookCheckoutDialog"
  self.config.type = EUIType.Dialog
  self._cook_recipe_guess_panel = nil
  self._chef_level_up_item = nil
  self._extra_info = nil
  self._change_info = nil
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._trans_chef_level) then
    self._chef_level_up_item = self:add_panel("UI/PacketView/ChefLevelUpItem", self._trans_chef_level)
  end
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh()
  self:_start_auto_close_if_needed()
end

function M:on_disable()
  base.on_disable(self)
  CoolDownManagerIns:unregister(self)
end

function M:on_destroy()
  base.on_destroy(self)
  self._chef_level_up_item = nil
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
end

function M:on_before_close()
  CoolDownManagerIns:unregister(self)
  CsCookModuleUtil.ClearChefLevelChangeInfo()
  self._cook_recipe_guess_panel:change_state(EUIState.Hide)
  EventCenter.Broadcast(EventID.Performance.LuaCookCheckoutDialogEnd, 0)
end

function M:_start_auto_close_if_needed()
  CoolDownManagerIns:unregister(self)
  if self._checkout_type ~= CookCheckoutType.CookSuccess then
    return
  end
  CoolDownManagerIns:register(self, auto_close_duration, function()
    self:close_self()
  end)
end

function M:_refresh()
  local extra_data = self:get_extra_data() or {}
  self._checkout_type = extra_data.checkout_type
  self._change_info = extra_data.change_info
  self._extra_info = not is_null(self._change_info) and self._change_info.extraInfo or nil
  self._ui_state_type:SetState(self._checkout_type)
  if self._checkout_type == CookCheckoutType.GuessFail or self._checkout_type == CookCheckoutType.GuessSuccess then
    self:_refresh_guess_ui(extra_data)
  else
    self._cook_recipe_guess_panel:change_state(EUIState.Hide)
    if self._checkout_type == CookCheckoutType.CookSuccessGold or self._checkout_type == CookCheckoutType.CookSuccessAdvanced then
      self:_refresh_success_title()
    end
    self:_refresh_food_name()
    self:_refresh_cook_state()
    self:_refresh_chef_state()
  end
  self:_refresh_chef_level()
end

function M:_refresh_guess_ui(extra_data)
  if is_null(self._change_info) or is_null(self._extra_info) then
    return
  end
  self._cook_recipe_guess_panel:set_extra_data({
    change_info = self._change_info,
    is_show_cookware = true
  })
  self._cook_recipe_guess_panel:set_recipe_id(self._extra_info.RecipeId)
  self._cook_recipe_guess_panel:change_state(EUIState.Show)
  if self._checkout_type == CookCheckoutType.GuessFail then
    UIUtil.set_text(self._txt_tips, self._change_info.tipsText)
  end
end

function M:_refresh_success_title()
  local item_id = self:_get_output_item_id()
  if item_id == nil or item_id == 0 then
    return
  end
  if self._checkout_type == CookCheckoutType.CookSuccessGold then
    if is_null(self._txt_success_gold_title) then
      return
    end
    local item_name = item_module:get_item_name_by_id(item_id) or ""
    UIUtil.set_text(self._txt_success_gold_title, UIUtil.get_text_by_id("Cook_DishKing_Tips", item_name))
    return
  end
  if is_null(self._txt_success_advanced_title) then
    return
  end
  local id_cfg = ExcelDataUtil.get_value(typeof(BIdCfg), item_id)
  local show_type = ""
  if not is_null(id_cfg) and string.is_valid(id_cfg.tag_showtype) then
    show_type = CsGameplayTagUtilUtil.GetTagNameInGameByString(id_cfg.tag_showtype) or ""
  end
  UIUtil.set_text(self._txt_success_advanced_title, UIUtil.get_text_by_id("Cook_AdvancedDish_Tips", show_type))
end

function M:_get_output_item_id()
  local extra_info = self._extra_info
  if is_null(extra_info) then
    return 0
  end
  local guid = extra_info.ItemGuid or 0
  if guid ~= 0 then
    local item = back_bag_module:get_item_by_guid(guid)
    if not is_null(item) then
      local cfg_id = item.ConFigID or item.config_id or 0
      if 0 < cfg_id then
        return cfg_id
      end
    end
  end
  local recipe_id = extra_info.OutputRecipeId or 0
  if recipe_id == 0 then
    recipe_id = extra_info.RecipeId or 0
  end
  if recipe_id == 0 then
    return 0
  end
  local recipe_cfg = ExcelDataUtil.get_value(typeof(BCookRecipeCfg), recipe_id)
  if is_null(recipe_cfg) then
    return 0
  end
  return recipe_cfg.itemid or 0
end

function M:_get_cook_recipe_id()
  if not is_null(self._extra_info) and 0 < (self._extra_info.RecipeId or 0) then
    return self._extra_info.RecipeId
  end
  return 0
end

function M:_refresh_food_name()
  if is_null(self._txt_food_name) then
    return
  end
  local recipe_id = self:_get_cook_recipe_id()
  if recipe_id == 0 then
    return
  end
  local recipe_cfg = ExcelDataUtil.get_value(typeof(BCookRecipeCfg), recipe_id)
  if is_null(recipe_cfg) or (recipe_cfg.itemid or 0) == 0 then
    return
  end
  item_module:set_item_name(self._txt_food_name, recipe_cfg.itemid)
end

function M:_refresh_cook_state()
  if is_null(self._state_group_cook_state) then
    return
  end
  local state = cook_proficiency_state.exp_add
  local recipe_id = self:_get_cook_recipe_id()
  local info = cooking_module._last_recipe_proficiency_info
  local cur_lv = 0
  if not is_null(info) and (info.recipe_id or 0) == recipe_id and not info.is_learn then
    cur_lv = info.cur_lv or 0
    if info.is_max then
      state = cook_proficiency_state.lv_max
    elseif info.last_lv ~= info.cur_lv then
      state = cook_proficiency_state.lv_up
    elseif info.daily_exp_max then
      state = cook_proficiency_state.daily_max
    else
      state = cook_proficiency_state.exp_add
    end
  else
    local recipe = 0 < recipe_id and CsCookModuleUtil.GetCookRecipeDataById(recipe_id) or nil
    if not is_null(recipe) then
      cur_lv = recipe.Lv or 0
    end
    local is_max = not is_null(self._extra_info) and self._extra_info.IsFullyProficient or not is_null(recipe) and (recipe.ProficiencyRatio or 0) >= 100
    local daily = not is_null(recipe) and recipe.DailyProficiencyProgress or nil
    local daily_max = not is_null(daily) and daily.Current == daily.Goal
    if is_max then
      state = cook_proficiency_state.lv_max
    elseif daily_max then
      state = cook_proficiency_state.daily_max
    else
      state = cook_proficiency_state.exp_add
    end
  end
  self._state_group_cook_state:SetState(state)
  self:_refresh_lv_up_info(state, recipe_id, cur_lv)
end

function M:_refresh_lv_up_info(state, recipe_id, cur_lv)
  if state ~= cook_proficiency_state.lv_up then
    return
  end
  local lv = cur_lv or 0
  if lv <= 0 and 0 < (recipe_id or 0) then
    local recipe = CsCookModuleUtil.GetCookRecipeDataById(recipe_id)
    if not is_null(recipe) then
      lv = recipe.Lv or 0
    end
  end
  local star_cfg = ExcelDataUtil.get_value(typeof(BCookStarCfg), lv)
  if is_null(star_cfg) then
    return
  end
  if not is_null(self._txt_lv_name) then
    UIUtil.set_text(self._txt_lv_name, star_cfg.proficiencyname or "")
  end
  if not is_null(self._txt_unlock_info) then
    UIUtil.set_text(self._txt_unlock_info, star_cfg.unlockdesc or "")
  end
end

function M:_refresh_chef_state()
  if is_null(self._state_group_chef) then
    return
  end
  local change = self:_get_chef_level_change_info()
  local level = CsCookModuleUtil.GetChefLevel() or 1
  local daily = CsCookModuleUtil.GetDailyRepeatCookExpObtained() or 0
  local daily_limit = 0
  local const_cfg = ExcelDataUtil.get_value(typeof(BCookConstantCfg), 1)
  if not is_null(const_cfg) then
    daily_limit = const_cfg.value or 0
  end
  local max_lv = self:_get_max_chef_level()
  local state = chef_level_state.exp_add
  if level >= max_lv then
    state = chef_level_state.lv_max
  elseif not is_null(change) and change.IsLevelUp then
    state = chef_level_state.lv_up
  elseif 0 < daily_limit and daily >= daily_limit then
    state = chef_level_state.daily_max
  else
    state = chef_level_state.exp_add
  end
  self._state_group_chef:SetState(state)
end

function M:_get_max_chef_level()
  local max_lv = 1
  local cfg_table = dic_to_list_table(ExcelDataUtil.get_table(typeof(BChefLevelCfg))) or {}
  for _, cfg in pairs(cfg_table) do
    if not is_null(cfg) then
      local lv = cfg.cheflevel or 0
      if max_lv < lv then
        max_lv = lv
      end
    end
  end
  return max_lv
end

function M:_get_chef_level_change_info()
  local change_info = CsCookModuleUtil.GetChefLevelChangeInfo()
  if not is_null(change_info) then
    return change_info
  end
  local level = CsCookModuleUtil.GetChefLevel() or 1
  local exp = CsCookModuleUtil.GetChefLevelExp() or 0
  return {
    lastLevel = level,
    curLevel = level,
    lastExp = exp,
    curExp = exp,
    IsLevelUp = false
  }
end

function M:_refresh_chef_level()
  if is_null(self._chef_level_up_item) then
    return
  end
  self._chef_level_up_item:refresh(self:_get_chef_level_change_info())
end

function M:_show_result_tips(extra_data)
  if extra_data == nil or extra_data.change_info == nil or extra_data.change_info.extraInfo == nil then
    return
  end
  local type = extra_data.checkout_type
  local extra_info = extra_data.change_info.extraInfo
  if type == CookCheckoutType.CookFail then
    UIUtil.show_tips_by_text_id("Cook_Fail_Tips")
  elseif type == CookCheckoutType.CookSuccessGold then
    local dish_name = self:_get_dish_name_by_guid(extra_info.ItemGuid)
    UIUtil.show_tips_by_text_id("Cook_DishKing_Tips", dish_name)
  end
end

function M:_get_dish_name_by_guid(item_guid)
  if item_guid == nil or item_guid == 0 then
    return ""
  end
  local item = back_bag_module:get_item_by_guid(item_guid)
  if is_null(item) or not item_module:has_cfg_by_id(item.ConFigID) then
    return ""
  end
  return item_module:get_item_name_by_id(item.ConFigID)
end

return M
