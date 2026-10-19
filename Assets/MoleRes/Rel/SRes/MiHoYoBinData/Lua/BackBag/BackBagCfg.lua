back_bag_module = back_bag_module or {}

function back_bag_module:_init_cfg()
end

function back_bag_module:get_back_pack_filter_cfg_by_back_pack_type(back_pack_type)
  return LocalDataUtil.get_value(typeof(CS.BackPackFilterCfg), back_pack_type)
end

function back_bag_module:get_bag_show_type_filter_cfg_by_bag_show_type(bag_show_type)
  return LocalDataUtil.get_value(typeof(CS.BagShowTypeFilterCfg), bag_show_type)
end

return back_bag_module
