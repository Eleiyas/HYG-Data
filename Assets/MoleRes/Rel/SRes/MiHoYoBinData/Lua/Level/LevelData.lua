level_module = level_module or {}

local function is_cur_scene_of_type(game_scene_type)
  if not GameSceneUtility.HasScene() then
    return false
  end
  return GameSceneUtility.GetCurrentSceneType() == game_scene_type
end

local function get_cur_scene_id()
  return GameSceneUtility.GetCurrentSceneId()
end

local function get_cur_scene_type()
  return GameSceneUtility.GetCurrentSceneType()
end

function level_module:get_cur_scene_id()
  return get_cur_scene_id()
end

function level_module:cur_world_type_is_star_core()
  return is_cur_scene_of_type(GameSceneType.StarCore)
end

function level_module:cur_world_type_is_main()
  return is_cur_scene_of_type(GameSceneType.MainLevel)
end

function level_module:cur_world_type_is_material_star()
  return is_cur_scene_of_type(GameSceneType.MaterialStar)
end

function level_module:cur_world_type_is_on_line_square()
  return is_cur_scene_of_type(GameSceneType.OnlineSquare)
end

function level_module:cur_level_is_player_house()
  return GameSceneUtility.IsCurrentScenePlayerHome()
end

function level_module:cur_level_is_fish_island()
  return false
end

function level_module:cur_level_is_main()
  return get_cur_scene_id() == GameSceneCfg.MainLevelId
end

function level_module:get_cur_world_type(is_number)
  if is_number then
    return get_cur_scene_type().value__
  end
  return get_cur_scene_type()
end

function level_module:is_cur_public_scene()
  return GameSceneUtility.IsCurrentScenePublic()
end

return level_module or {}
