fortune_wheel_module = fortune_wheel_module or {}

function fortune_wheel_module:_get_fortune_wheel_config()
  local cfgs = LocalDataUtil.get_table(typeof(CS.BFortuneWheelParamsCfg))
  for _, cfg in pairs(cfgs) do
    return cfg
  end
  return nil
end

function fortune_wheel_module:get_extra_reward_config()
  local cfgs = LocalDataUtil.get_table(typeof(CS.BFortuneWheelCfg))
  for _, cfg in pairs(cfgs) do
    if cfg.rank == 0 then
      return cfg
    end
  end
  return nil
end

return fortune_wheel_module
