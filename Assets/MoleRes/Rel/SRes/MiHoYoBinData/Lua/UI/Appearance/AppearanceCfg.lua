appearance_module = appearance_module or {}

function appearance_module:_init_cfg()
  self._tbl_change_outfit_ids = nil
end

function appearance_module:_init_change_outfit_ids()
  local cfgs = LocalDataUtil.get_table(typeof(CS.BChangeOutfitCfg))
  self._tbl_change_outfit_ids = {}
  for _, cfg in pairs(cfgs or {}) do
    if self._tbl_change_outfit_ids[cfg.showtab] == nil then
      self._tbl_change_outfit_ids[cfg.showtab] = {}
    end
    table.insert(self._tbl_change_outfit_ids[cfg.showtab], cfg.sort)
  end
  for _, cfg_lst in pairs(self._tbl_change_outfit_ids) do
    table.sort(cfg_lst, function(a, b)
      return a < b
    end)
  end
end

function appearance_module:get_change_outfit_ids_by_tab_id(tab_id)
  if tab_id == nil or tab_id <= 0 then
    return nil
  end
  if self._tbl_change_outfit_ids == nil then
    appearance_module:_init_change_outfit_ids()
  end
  return table.shallow_copy(self._tbl_change_outfit_ids[tab_id])
end

return appearance_module
