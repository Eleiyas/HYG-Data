appearance_module = appearance_module or {}

function appearance_module:open_appearance_page()
  UIManagerInstance:open("UI/Appearance/AppearancePage")
end

function appearance_module:open_attrib_unlock_tips(data)
  UIManagerInstance:open("UI/Appearance/AttribUnlockTips", data)
end

return appearance_module
