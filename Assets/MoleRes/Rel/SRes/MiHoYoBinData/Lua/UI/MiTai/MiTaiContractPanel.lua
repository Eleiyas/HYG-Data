local M = G.Class("MiTaiContractPanel", "UI/MiTai/MiTaiBasePanel")
local base = M.super
local MiTaiUtil = require("UI/MiTai/MiTaiUtil")

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MiTai/MiTaiContractPanel"
end

function M:on_create()
  base.on_create(self)
  self:bind_callbacks()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:refresh_panel(order, selected_color_id)
  self._order = order
  self._selected_color_id = selected_color_id or 0
  self._is_placing_order = false
end

function M:bind_callbacks()
  self:bind_callback(self._btn_sign, pack(self, M._on_btn_sign))
  self:bind_callback(self._btn_contract_back, pack(self, M._on_btn_back))
end

function M:_on_btn_sign()
  if self._is_placing_order or not self._order then
    return
  end
  self._is_placing_order = true
  local house_cfg = ExcelDataUtil.get_value(typeof(BHouseServerCfg), self._order.Id)
  if not house_cfg then
    self._is_placing_order = false
    return
  end
  if house_cfg.housetype == 2 then
    local _, material = next(MiTaiUtil.parse_material(self._order, true))
    if material then
      local required_total = material.discounted_num or material.original_num
      local saved_coin = 0
      if self._order.UnlockOrder and self._order.UnlockOrder.PurchaseSavedItemMap and self._order.UnlockOrder.PurchaseSavedItemMap:ContainsKey(material.mat_id) then
        saved_coin = self._order.UnlockOrder.PurchaseSavedItemMap[material.mat_id]
      end
      local required_coin = required_total - saved_coin
      if 0 < required_coin then
        CsMiTaiModuleUtil.SaveOrderPurchase(self._order.GroupId, self._order.Id, material.mat_id, required_coin, function(rsp)
          if rsp.Retcode == 0 then
            self:try_place_order(house_cfg)
          else
            UIUtil.show_tips_by_text_id("MiTai_Save_Fail")
            self._is_placing_order = false
          end
        end)
        return
      end
    end
  end
  self:try_place_order(house_cfg)
end

function M:try_place_order(house_cfg)
  local order = self._order
  local selected_color_id = self._selected_color_id
  CsMiTaiModuleUtil.TryPlaceMiTaiOrder(order.GroupId, order.Id, selected_color_id, function(rsp)
    local result_code = 0
    local is_success = rsp.Retcode == 0
    if is_success then
      if house_cfg.locatingtool == 1 then
        result_code = CsPacketModuleUtil.GetBagFullState() and 4 or 5
      else
        result_code = 1
      end
    elseif rsp.Retcode == 602 then
      result_code = 2
    else
      result_code = 3
      UIUtil.show_tips_by_text_id("MiTai_Server_Error")
    end
    self._is_placing_order = false
    self.holder:on_place_order_finished(order, result_code, is_success)
  end)
end

function M:_on_btn_back()
  self.holder:on_btn_contract_back_clicked()
end

function M:guard_buttons(interactable)
  if self._btn_sign then
    self._btn_sign.interactable = interactable
  end
  if self._btn_contract_back then
    self._btn_contract_back.interactable = interactable
  end
end

return M
