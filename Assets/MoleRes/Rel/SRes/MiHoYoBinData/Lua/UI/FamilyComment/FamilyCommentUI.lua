family_comment_module = family_comment_module or {}

function family_comment_module:open_main_page()
  UIManagerInstance:open("UI/FamilyComment/FamilyCommentMainPage")
end

function family_comment_module:open_edit_dialog()
  UIManagerInstance:open("UI/FamilyComment/FamilyCommentEditDialog")
end

function family_comment_module:open_level_dialog()
  UIManagerInstance:open("UI/FamilyComment/FamilyCommentLevelDialog")
end

function family_comment_module:open_read_dialog(data)
  UIManagerInstance:open("UI/FamilyComment/FamilyCommentReadDialog", data)
end

function family_comment_module:open_setting_dialog()
  UIManagerInstance:open("UI/FamilyComment/LightTowerSettingDialog")
end

function family_comment_module:open_confirm_dialog(data)
  UIManagerInstance:open("UI/FamilyComment/FamilyCommentConfirmDialog", data)
end

function family_comment_module:open_delete_confirm_dialog(data)
  UIManagerInstance:open("UI/FamilyComment/FamilyCommentDeleteConfirmDialog", data)
end

return family_comment_module
