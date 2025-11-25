memo_module = memo_module or {}
memo_module.grouping_item_cls_name = "UI/Memo/MemoGroupingItem"
memo_module.empty_grouping_item_cls_name = "UI/Memo/EmptyMemoGroupingItem"
memo_module.node_item_cls_name = "UI/Memo/MemoNodeItem"
memo_module.top_node_item_cls_name = "UI/Memo/MemoTopNodeItem"
memo_module.award_item_cls_name = "UI/Memo/MemoAwardItem"
memo_module.memo_page_condition_item_cls_name = "UI/Memo/MemoPageConditionItem"
memo_module.memo_hud_condition_item_cls_name = "UI/Memo/MemoHUDConditionItem"
memo_module.grouping_type = {
  none = 0,
  main_task = 1,
  branch_task = 2,
  npc = 3,
  top = 1000,
  bottom = 1001
}
memo_module.tab_type = {
  none = 0,
  task = 1,
  npc = 2
}
return memo_module
