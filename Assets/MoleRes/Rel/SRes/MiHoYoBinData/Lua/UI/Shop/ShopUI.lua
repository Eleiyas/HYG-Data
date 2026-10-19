shop_module = shop_module or {}

function shop_module:open_buy_item_dialog(data)
  return UIManagerInstance:open("UI/ConfirmView/CommonConfirmBuyItemDialog", data)
end

function shop_module:open_npc_cloth_gelian_sell_page(data)
  UIManagerInstance:open("UI/NpcCloth/NpcClothGelianSellPage", data or {})
end

function shop_module:open_npc_cloth_confirm_detail_dialog(data)
  return UIManagerInstance:open("UI/NpcCloth/NpcClothConfirmDetailDialog", data or {})
end

function shop_module:open_npc_cloth_choose_npc_dialog(data)
  UIManagerInstance:open("UI/NpcCloth/NpcClothChooseNpcDialog", data or {})
end

function shop_module:open_npc_cloth_machine_sell_page(data)
  UIManagerInstance:open("UI/NpcCloth/NpcClothMachineSellPage", data or {})
end

function shop_module:open_npc_cloth_recycle_page(data)
  data = data or {}
  data.tab = "recycle"
  data.recycle_only = true
  UIManagerInstance:open("UI/NpcCloth/NpcClothGelianSellPage", data)
end

return shop_module
