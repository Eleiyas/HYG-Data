local base = require("UI/Gacha/GachaPoolPanelBase")
local M = G.Class("GachaFurniturePoolPanel", base)

function M:init()
  base.init(self)
  self.config.prefab_path = GachaConst.panel_path.pool_furniture
end

function M:_on_create_extend()
  if not_null(self._btn_draw_once) then
    self:bind_callback(self._btn_draw_once, pack(self, M._on_btn_single_click))
  end
  if not_null(self._btn_draw_ten) then
    self:bind_callback(self._btn_draw_ten, pack(self, M._on_btn_ten_click))
  end
end

function M:_refresh_extend()
  self:_refresh_prices()
  self:_refresh_howtoget()
end

function M:_refresh_prices()
  self:refresh_draw_ticket_price(GachaConst.draw_count.once, self._txt_num_once, self._img_icon_coin_once)
  self:refresh_draw_ticket_price(GachaConst.draw_count.ten, self._txt_num_ten_disc, self._img_icon_coin_ten)
end

function M:_refresh_howtoget()
  if not_null(self._txt_howtoget) then
    UIUtil.set_text(self._txt_howtoget, self._activity_cfg.advdiscrip or "")
  end
end

function M:_on_btn_single_click()
  self:_smash(false)
end

function M:_on_btn_ten_click()
  self:_smash(true)
end

function M:_smash(is_ten)
  self:do_draw(is_ten)
end

return M
