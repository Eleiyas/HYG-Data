local StarPanelBase = require("UI/CompanionStarDetail/Base/StarPanelBase")
local M = G.Class("StarBayNpcExchangePanel", StarPanelBase)
local base = StarPanelBase
local npc_panel_cls = "UI/ThemeSeason/NpcImpressionHallPanel"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BattlePass/StarBayNpcImpressionHallPanel"
  self._npc_panel = nil
  self._cur_npc_id = 0
  self._trans_npc_exchange = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._trans_npc_exchange) then
    self._npc_panel = self:add_panel(npc_panel_cls, self._trans_npc_exchange)
  end
end

function M:on_destroy()
  self._npc_panel = nil
  base.on_destroy(self)
end

function M:show()
  base.show(self)
  if self.holder and self.holder.cur_star_data then
    self:refresh_by_npc_id(self.holder.cur_star_data.npcid)
  end
end

function M:on_disable()
  if self._npc_panel and self._npc_panel.hide_model_preview then
    self._npc_panel:hide_model_preview()
  end
  base.on_disable(self)
end

function M:get_topbar_config()
  return {type = "exchange"}
end

function M:refresh_by_npc_id(npc_id)
  if not npc_id or npc_id <= 0 then
    return
  end
  self._cur_npc_id = npc_id
  local npc_cfg = ExcelDataUtil.get_value(typeof(BNpcCfg), npc_id)
  local npc_data = {
    config_id = npc_id,
    is_season = theme_season_module:is_season_npc(npc_id),
    name = npc_cfg and npc_cfg.name or "",
    icon = npc_cfg and npc_cfg.iconnamesmall or ""
  }
  if self._npc_panel then
    self._npc_panel:refresh(npc_data)
  end
end

return M
