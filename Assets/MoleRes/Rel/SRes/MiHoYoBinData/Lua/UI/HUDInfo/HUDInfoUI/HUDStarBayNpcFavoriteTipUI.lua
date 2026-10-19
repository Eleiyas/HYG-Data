local M = G.Class("HUDStarBayNpcFavoriteTipUI", "UI/HUDInfo/HUDInfoUI/HUDInfoBaseUI")
local base = G.HUDInfoBaseUI
local default_show_time = 3

local function normalize_tip_text(text)
  if not string.is_valid(text) then
    return nil
  end
  local normalized = string.gsub(text, "^%s*(.-)%s*$", "%1")
  return string.is_valid(normalized) and normalized or nil
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CompanionStar/StarBay/HUDStarBayNpcFavoriteTip"
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data()
  if is_null(data) then
  end
  local tip_text = normalize_tip_text(data.tipText)
  if tip_text == nil then
    self:close_self()
    return
  end
  if self._trans_tips_1 then
    UIUtil.set_active(self._trans_tips_1, true)
  end
  UIUtil.set_text(self._tips_text, tip_text)
  local npc_cfg = ExcelDataUtil.get_value(typeof(BNpcCfg), data.npcId or 0)
  if npc_cfg and string.is_valid(npc_cfg.iconnamesmall) then
    UIUtil.set_image(self._img_icon_archiboo, npc_cfg.iconnamesmall, self:get_load_proxy())
  end
  local show_duration = tonumber(data.showDuration)
  local duration = show_duration and 0 < show_duration and show_duration or default_show_time
  self:start_close_timer(duration, function(ui)
    if ui.binder and ui.binder.PlayExitAnim then
      ui.binder:PlayExitAnim(pack(ui, M.close_self))
    else
      ui:close_self()
    end
  end)
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

return M
