local M = G.Class("CurioEmporiumTopUpItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:_add_btn_listener()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_btn_listener()
  self:bind_callback(self._btn_buy, pack(self, M._on_buy_click))
end

function M:refresh(cfg, goods_data)
  self._cfg = cfg
  self._goods_data = goods_data
  if not cfg:icon_is_empty() then
    UIUtil.set_image(self._img_icon, cfg.icon, self:get_load_proxy())
  end
  if not goods_data then
    return
  end
  UIUtil.set_text(self._txt_name, cfg.goodsname or "")
  if not is_null(goods_data.price) then
    UIUtil.set_text(self._txt_price, goods_data.price.amountDisplay)
  end
  if not is_null(goods_data.virtualCurrency) then
    local vc = goods_data.virtualCurrency
    local has_double = vc.bonusOnceEligible and vc.countBonus > 0
    local has_add = not has_double and vc.countBonus > 0
    UIUtil.set_active(self._obj_double_rebate, has_double)
    UIUtil.set_active(self._obj_add_part, has_add)
    if has_double then
      UIUtil.set_text(self._txt_double_num, "+" .. tostring(vc.countBonus))
    elseif has_add then
      UIUtil.set_text(self._txt_bonus_num, "+" .. tostring(vc.countBonus))
    end
  else
    UIUtil.set_active(self._obj_double_rebate, false)
    UIUtil.set_active(self._obj_add_part, false)
  end
end

function M:_on_buy_click()
  if curio_emporium_module:try_block_store_with_tip() or curio_emporium_module:try_block_recharge_with_tip() then
    return
  end
  if not self._cfg or self._cfg:goodsid_is_empty() then
    return
  end
  local paid_goods_data = self._goods_data
  local goods_name = self._cfg.goodsname
  CsGameStoreModuleUtil.PayGoods(self._cfg.goodsid, function(ret, msg)
    if ret == 0 then
      Logger.Log("[CurioEmporiumTopUpItem] Pay success, goodsId=" .. self._cfg.goodsid)
    else
      Logger.LogWarning("[CurioEmporiumTopUpItem] Pay failed, ret=" .. tostring(ret) .. " msg=" .. tostring(msg))
    end
    if ret == 0 then
      curio_emporium_module:show_top_up_reward(paid_goods_data, goods_name)
    end
    if is_null(self.game_obj) then
      return
    end
    local goods_data = CsGameStoreModuleUtil.GetGoods(self._cfg.goodsid)
    self:refresh(self._cfg, goods_data)
  end, self._cfg.goodsname)
end

return M
