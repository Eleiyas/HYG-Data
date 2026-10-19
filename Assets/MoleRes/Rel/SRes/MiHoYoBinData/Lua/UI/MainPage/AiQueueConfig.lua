local AiQueueConfig = {}
AiQueueConfig.GAMEPLAY = {
  COFFEE = 1,
  COFFEE_PRIVATE = 2,
  APPRAISAL = 3
}
AiQueueConfig.APPRAISAL_ACTIVITY_ID = 2
AiQueueConfig.config = {
  [AiQueueConfig.GAMEPLAY.COFFEE] = {
    name_text_id = "AiQueue_Name_CoffeeRp_Public",
    auto_confirm = false,
    is_duo = false
  },
  [AiQueueConfig.GAMEPLAY.COFFEE_PRIVATE] = {
    name_text_id = "AiQueue_Name_CoffeeRp_Private",
    auto_confirm = false,
    is_duo = false
  },
  [AiQueueConfig.GAMEPLAY.APPRAISAL] = {
    name_text_id = "AiQueue_Name_Appraisal",
    activity_id = AiQueueConfig.APPRAISAL_ACTIVITY_ID,
    auto_confirm = true,
    is_duo = true,
    match_player_capacity = 2,
    single_start_confirm_timeout = 20
  }
}
local DEFAULT_NAME_TEXT_ID = "AiQueue_Name_Default"

function AiQueueConfig.get(gameplay_type)
  return AiQueueConfig.config[gameplay_type]
end

function AiQueueConfig.is_auto_confirm(gameplay_type)
  local cfg = AiQueueConfig.config[gameplay_type]
  return cfg ~= nil and cfg.auto_confirm == true
end

function AiQueueConfig.is_duo(gameplay_type)
  local cfg = AiQueueConfig.config[gameplay_type]
  return cfg ~= nil and cfg.is_duo == true
end

function AiQueueConfig.get_activity_id(gameplay_type)
  local cfg = AiQueueConfig.config[gameplay_type]
  return cfg and cfg.activity_id or nil
end

function AiQueueConfig.get_name_text_id(gameplay_type)
  local cfg = AiQueueConfig.config[gameplay_type]
  return cfg and cfg.name_text_id or DEFAULT_NAME_TEXT_ID
end

function AiQueueConfig.get_single_start_confirm_timeout(gameplay_type)
  local cfg = AiQueueConfig.config[gameplay_type]
  return cfg and cfg.single_start_confirm_timeout or nil
end

function AiQueueConfig.get_match_player_capacity(gameplay_type)
  local cfg = AiQueueConfig.config[gameplay_type]
  return cfg and cfg.match_player_capacity or nil
end

return AiQueueConfig
