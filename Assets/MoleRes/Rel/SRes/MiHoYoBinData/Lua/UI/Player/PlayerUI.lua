player_module = player_module or {}

function player_module:set_player_icon(img, proxy, is_big)
  if is_null(proxy) then
    return
  end
  local icon_path = "UISprite/Load/RoleItem/Role_Pic_s"
  if is_big then
    icon_path = "UISprite/Load/RoleItem/Role_Pic_b"
  end
  if not is_null(img) and string.is_valid(icon_path) then
    UIUtil.set_image(img, icon_path, proxy)
  end
end

return player_module
