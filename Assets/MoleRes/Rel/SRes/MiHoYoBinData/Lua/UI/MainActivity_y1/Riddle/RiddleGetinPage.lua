local M = G.Class("RiddleGetinPage", G.UIWindow)
local base = G.UIWindow

local function _apply_alpha(img, alpha)
  if is_null(img) then
    return
  end
  local c = img.color
  img.color = Color(c.r, c.g, c.b, alpha)
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_LanternRiddlesGetinPanel"
  self.config.type = EUIType.Page
end

function M:on_create()
  base.on_create(self)
  self._mask_tween = nil
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaCloseLanternRiddlesGetinPage, pack(self, M._on_close_event))
end

function M:on_enable()
  base.on_enable(self)
  local args = self:get_extra_data()
  self:_refresh_view(args.npcId)
  _apply_alpha(self._img_bg_mask, 0)
  self:_start_mask_fade(0, 1, args.fadeInDuration, nil)
end

function M:on_disable()
  base.on_disable(self)
  self:_kill_mask_tween()
end

function M:_on_close_event(fade_out_duration)
  self:_start_mask_fade(1, 0, fade_out_duration, function()
    self:close_self()
  end)
end

function M:_kill_mask_tween()
  if self._mask_tween ~= nil then
    self._mask_tween:Kill()
    self._mask_tween = nil
  end
end

function M:_start_mask_fade(from, to, duration, on_done)
  self:_kill_mask_tween()
  if is_null(self._img_bg_mask) then
    if on_done ~= nil then
      on_done()
    end
    return
  end
  if duration <= 0 then
    _apply_alpha(self._img_bg_mask, to)
    if on_done ~= nil then
      on_done()
    end
    return
  end
  _apply_alpha(self._img_bg_mask, from)
  self._mask_tween = UIUtil.dt_to_anim(from, to, duration, function(v)
    _apply_alpha(self._img_bg_mask, v)
  end, function()
    self._mask_tween = nil
    if on_done ~= nil then
      on_done()
    end
  end)
end

function M:_refresh_view(npc_id)
  local icon_path
  local ok_npc_cfg, npc_cfg = pcall(ExcelDataUtil.get_value, typeof(BNpcCfg), npc_id)
  if ok_npc_cfg and not is_null(npc_cfg) then
    icon_path = npc_cfg.iconnamesmall
  end
  if not is_null(self._icon_npc) then
    local show_icon = icon_path ~= nil and icon_path ~= ""
    UIUtil.set_active(self._icon_npc, show_icon)
    if show_icon then
      UIUtil.set_image(self._icon_npc, icon_path, self:get_load_proxy())
    end
  end
end

return M
