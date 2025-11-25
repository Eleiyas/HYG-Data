hand_book_module = hand_book_module or {}

function hand_book_module:_load_item_cfg()
  local item_cfg_list = LocalDataUtil.get_table(typeof(CS.BItemCfg))
  local ret_cfgs = {}
  local is_add, add_type = false, -1
  local id
  for _, cfg in pairs(item_cfg_list) do
    is_add = false
    id = tonumber(cfg.id)
    if table.contains(self.all_furniture_type, cfg.bagtype) then
      is_add = true
      add_type = self.hand_book_type_furniture
    else
      add_type = cfg.bagtype
      if cfg.bagtype == self.hand_book_type_biota then
        is_add = true
      else
        if cfg.bagtype == self.hand_book_type_clothing then
          is_add = true
        else
        end
      end
    end
    if is_add then
      if ret_cfgs[add_type] == nil then
        ret_cfgs[add_type] = {}
      end
      if cfg.show == self.item_show_type_is_show then
        table.insert(ret_cfgs[add_type], cfg)
      end
    end
  end
  for _, v in pairs(ret_cfgs) do
    table.sort(v, function(a, b)
      return a.id < b.id
    end)
  end
  return ret_cfgs
end

function hand_book_module:_load_scene_item_cfg()
  return nil
end

function hand_book_module:get_item_cfg_by_show_type(show_type)
  if self._item_cfg_list == nil then
    self._item_cfg_list = hand_book_module:_load_item_cfg()
  end
  if self._item_cfg_list[show_type] == nil then
    Logger.LogError("无效的图鉴类型!!!show_type = " .. show_type)
  end
  return self._item_cfg_list[show_type] or {}
end

function hand_book_module:get_item_cfg(item_id)
  return item_module:get_cfg_by_id(item_id)
end

function hand_book_module:get_item_size(item_id)
  if item_id then
    if self._item_size_cfg_list == nil then
      self._item_size_cfg_list = hand_book_module:_load_scene_item_cfg()
    end
    local cfg = self._item_size_cfg_list[item_id]
    if cfg then
      return cfg.sizex, cfg.sizez
    end
  end
  return 0, 0
end

return hand_book_module or {}
