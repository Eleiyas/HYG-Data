cooking_module = cooking_module or {}
cooking_module.cook_recipe_item_cls_name = "UI/Cooking/CookRecipeItem"
cooking_module.ingredient_item_cls_name = "UI/Cooking/IngredientItem"
cooking_module.new_ingredient_item_cls_name = "UI/Cooking/NewIngredientItem"
cooking_module.single_ingredient_item_cls_name = "UI/Cooking/SingleIngredientItem"
cooking_module.new_single_ingredient_item_cls_name = "UI/Cooking/NewSingleIngredientItem"
cooking_module.cook_recipe_detail_panel_cls_name = "UI/Cooking/CookRecipeDetailPanel"
cooking_module.ingredient_item_type = {cook = 1, dine_together = 2}
cooking_module.ingredient_volume_ui_type = {cook_menu = 1, cooking_bag = 2}
cooking_module.condiment_state = {
  no_need = 1,
  correct = 2,
  wrong = 3,
  none = 4
}
cooking_module.recipe_change_reason = {
  none = 0,
  cooking = 1,
  use_item = 2,
  gm = 3,
  innate_unlock = 4,
  unlock_by_use = 5,
  unlock_by_cook = 6
}
cooking_module.default_food_item_id = 30161
return cooking_module
