memo_module = memo_module or {}

function memo_module:open_memo_page(is_top)
  UIManagerInstance:open("UI/Memo/MemoPage", is_top)
end

function memo_module:open_feature_dialog()
  UIManagerInstance:open("UI/Memo/FeatureDialog")
end

return memo_module
