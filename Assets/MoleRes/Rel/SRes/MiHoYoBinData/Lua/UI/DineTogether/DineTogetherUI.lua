dine_together_module = dine_together_module or {}

function dine_together_module:open_dine_together_prepare_page()
  GameplayUtility.Camera.SetFollowActive("MealActivity", CsDineTogetherManagerUtil.GetCameraFollowTran(), CsDineTogetherManagerUtil.GetCameraLookAtTran())
  UIManagerInstance:open("UI/DineTogether/DineTogetherPreparePage")
end

function dine_together_module:open_dine_together_npc_select_page()
  dine_together_module:close_select_recipe()
  CsDineTogetherManagerUtil.ClearNpcAndCookRecipe()
  UIManagerInstance:open("UI/DineTogether/DineTogetherNpcSelectPage")
end

function dine_together_module:open_dine_together_cook_menu_page()
  UIManagerInstance:open("UI/DineTogether/DineTogetherCookMenuPage")
end

function dine_together_module:open_dine_together_start_page()
  UIManagerInstance:open("UI/DineTogether/DineTogetherStartPage")
end

function dine_together_module:open_dine_together_settlement_page()
  UIManagerInstance:open("UI/DineTogether/DineTogetherSettlementPage")
end

return dine_together_module
