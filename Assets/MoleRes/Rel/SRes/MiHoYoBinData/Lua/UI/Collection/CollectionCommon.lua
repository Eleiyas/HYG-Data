collection_module = collection_module or {}
collection_module.summing_up_item_cls = "UI/Collection/SummingUpItem"
collection_module.collection_tog_item_cls = "UI/Collection/CollectionTogItem"
collection_module.collection_submit_item_cls = "UI/Collection/CollectionSubmitItem"
collection_module.collection_submit_panel_cls = "UI/Collection/CollectionSubmitPanel"
collection_module.collection_step_task_panel_cls = "UI/Collection/CollectionStepTaskPanel"
collection_module.submit_panel_type = {
  none = 0,
  track = 1,
  submit = 2
}
return collection_module
