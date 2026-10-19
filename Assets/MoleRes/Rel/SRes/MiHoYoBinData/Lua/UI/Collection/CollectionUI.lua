collection_module = collection_module or {}

function collection_module:open_collection_app_page()
  collection_module:set_submit_panel_type(collection_module.submit_panel_type.track)
  UIManagerInstance:open("UI/Collection/CollectionAppPage")
end

function collection_module:open_collection_submit_page()
  collection_module:set_submit_panel_type(collection_module.submit_panel_type.submit)
  UIManagerInstance:open("UI/Collection/CollectionSubmitPage")
end

function collection_module:open_collection_diary_page()
  UIManagerInstance:open("UI/Collection/CollectionDiaryPage")
end

return collection_module
