accompanying_module = accompanying_module or {}

function accompanying_module:open_dialog()
  UIManagerInstance:open("UI/Accompanying/AccompanyingDialog")
end

function accompanying_module:open_settlement_tips(bonus_num)
  UIManagerInstance:open("UI/Accompanying/AccompanyingSettlementTips", {bonus_num = bonus_num})
end

return accompanying_module
