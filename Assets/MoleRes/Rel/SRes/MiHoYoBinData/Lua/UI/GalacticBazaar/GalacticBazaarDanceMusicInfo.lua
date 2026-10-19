local M = G.Class("GalacticBazaarDanceMusicInfo", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GalacticBazaar/GalacticBazaarDanceMusicInfo"
  self.config.type = EUIType.Page
end

function M:on_create()
  base.on_create(self)
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_music_info()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_refresh_music_info()
  local music_id = CsSceneActivityModuleUtil.GetDanceMusicId(galactic_bazaar_module:get_cur_activity_id())
  local diffi = CsSceneActivityModuleUtil.GetDanceMusicIdDifficulty(galactic_bazaar_module:get_cur_activity_id())
  local cfg
  local music_list = galactic_bazaar_module:get_dance_music_list()
  for _, row in ipairs(music_list) do
    if row.id == music_id then
      cfg = row
      break
    end
  end
  if cfg then
    UIUtil.set_image(self._img_theme, cfg.theme, self:get_load_proxy())
    UIUtil.set_text(self._txt_name, cfg.name)
  end
  local diffi_cfg = galactic_bazaar_module:get_dance_music_diffi_cfg(music_id, diffi)
  UIUtil.set_text(self._txt_difficulty, diffi_cfg and diffi_cfg.leveldesc or "")
end

return M
