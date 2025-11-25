dine_together_module = dine_together_module or {}

function dine_together_module:get_dine_together_cfg_by_id(id)
  if id <= 0 then
    return nil
  end
  return LocalDataUtil.get_value(typeof(CS.BDineTogetherCfg), id)
end

function dine_together_module:get_npc_like_cfg_by_add_favor_exp(add_exp)
  local cfgs = LocalDataUtil.get_table(typeof(CS.BDineNpcLikeScoreCfg))
  if cfgs then
    for _, cfg in pairs(cfgs) do
      if cfg.favorexp == add_exp then
        return cfg
      end
    end
  end
  return nil
end

return dine_together_module
